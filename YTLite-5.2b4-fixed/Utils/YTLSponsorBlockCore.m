#import "YTLSponsorBlockCore.h"

static NSString *const YTLSponsorBlockAPIBaseURL = @"https://sponsor.ajay.app/api/skipSegments";
static NSTimeInterval const YTLSponsorBlockCacheTTL = 15.0 * 60.0;

@interface YTLSponsorBlockSegment ()
@property (nonatomic, copy, readwrite) NSString *category;
@property (nonatomic, assign, readwrite) NSTimeInterval startTime;
@property (nonatomic, assign, readwrite) NSTimeInterval endTime;
@property (nonatomic, assign, readwrite) YTLSponsorBlockAction action;
@property (nonatomic, copy, readwrite) NSString *UUID;
@end

@implementation YTLSponsorBlockSegment

- (instancetype)initWithCategory:(NSString *)category
                       startTime:(NSTimeInterval)startTime
                         endTime:(NSTimeInterval)endTime
                          action:(YTLSponsorBlockAction)action
                            UUID:(NSString *)UUID {
    self = [super init];
    if (!self) return nil;

    _category = [category copy];
    _startTime = MAX(0.0, startTime);
    _endTime = MAX(_startTime, endTime);
    _action = action;
    _UUID = [UUID copy];
    return self;
}

- (BOOL)containsTime:(NSTimeInterval)time {
    return time >= self.startTime && time < self.endTime;
}

@end

@interface YTLSponsorBlockFetchResult ()
@property (nonatomic, copy, readwrite) NSString *videoID;
@property (nonatomic, copy, readwrite) NSArray<YTLSponsorBlockSegment *> *segments;
@property (nonatomic, strong, readwrite, nullable) NSError *error;
@end

@implementation YTLSponsorBlockFetchResult

- (instancetype)initWithVideoID:(NSString *)videoID
                       segments:(NSArray<YTLSponsorBlockSegment *> *)segments
                          error:(NSError *)error {
    self = [super init];
    if (!self) return nil;

    _videoID = [videoID copy];
    _segments = [segments copy];
    _error = error;
    return self;
}

@end

@interface YTLSponsorBlockCacheEntry : NSObject
@property (nonatomic, copy) NSArray<YTLSponsorBlockSegment *> *segments;
@property (nonatomic, strong) NSDate *timestamp;
@end

@implementation YTLSponsorBlockCacheEntry
@end

@interface YTLSponsorBlockService ()
@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSCache<NSString *, YTLSponsorBlockCacheEntry *> *memoryCache;
@end

@implementation YTLSponsorBlockService

+ (instancetype)sharedService {
    static dispatch_once_t onceToken;
    static YTLSponsorBlockService *service = nil;
    dispatch_once(&onceToken, ^{
        service = [[self alloc] init];
    });
    return service;
}

- (instancetype)init {
    self = [super init];
    if (!self) return nil;

    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
    configuration.timeoutIntervalForRequest = 10.0;
    configuration.timeoutIntervalForResource = 15.0;

    _session = [NSURLSession sessionWithConfiguration:configuration];
    _memoryCache = [[NSCache alloc] init];
    _memoryCache.countLimit = 256;
    return self;
}

- (void)fetchSegmentsForVideoID:(NSString *)videoID
                     completion:(void (^)(YTLSponsorBlockFetchResult *result))completion {
    if (!videoID.length) {
        NSError *error = [NSError errorWithDomain:@"YTLSponsorBlockErrorDomain" code:1 userInfo:@{NSLocalizedDescriptionKey: @"Missing video ID"}];
        completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:@"" segments:@[] error:error]);
        return;
    }

    YTLSponsorBlockCacheEntry *cachedEntry = [self.memoryCache objectForKey:videoID];
    if (cachedEntry && [[NSDate date] timeIntervalSinceDate:cachedEntry.timestamp] < YTLSponsorBlockCacheTTL) {
        completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:videoID segments:cachedEntry.segments error:nil]);
        return;
    }

    NSURLComponents *components = [NSURLComponents componentsWithString:YTLSponsorBlockAPIBaseURL];
    components.queryItems = @[
        [NSURLQueryItem queryItemWithName:@"videoID" value:videoID],
        [NSURLQueryItem queryItemWithName:@"categories" value:@"[\"sponsor\",\"intro\",\"outro\",\"interaction\",\"selfpromo\",\"music_offtopic\",\"preview\",\"poi_highlight\",\"filler\"]"]
    ];

    NSURL *URL = components.URL;
    if (!URL) {
        NSError *error = [NSError errorWithDomain:@"YTLSponsorBlockErrorDomain" code:2 userInfo:@{NSLocalizedDescriptionKey: @"Invalid SponsorBlock request URL"}];
        completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:videoID segments:@[] error:error]);
        return;
    }

    [[self.session dataTaskWithURL:URL completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error || !data.length) {
            completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:videoID segments:@[] error:error]);
            return;
        }

        NSError *jsonError = nil;
        id object = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
        if (jsonError || ![object isKindOfClass:[NSArray class]]) {
            completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:videoID segments:@[] error:jsonError]);
            return;
        }

        NSArray<YTLSponsorBlockSegment *> *segments = [self parsedSegmentsFromJSONArray:(NSArray *)object];
        YTLSponsorBlockCacheEntry *entry = [[YTLSponsorBlockCacheEntry alloc] init];
        entry.segments = segments;
        entry.timestamp = [NSDate date];
        [self.memoryCache setObject:entry forKey:videoID];

        completion([[YTLSponsorBlockFetchResult alloc] initWithVideoID:videoID segments:segments error:nil]);
    }] resume];
}

- (NSArray<YTLSponsorBlockSegment *> *)parsedSegmentsFromJSONArray:(NSArray *)JSONArray {
    NSMutableArray<YTLSponsorBlockSegment *> *segments = [NSMutableArray array];

    for (NSDictionary *entry in JSONArray) {
        if (![entry isKindOfClass:[NSDictionary class]]) continue;

        NSArray *segmentRange = entry[@"segment"];
        NSString *category = entry[@"category"];
        NSString *UUID = entry[@"UUID"] ?: @"";
        if (![segmentRange isKindOfClass:[NSArray class]] || segmentRange.count < 2 || ![category isKindOfClass:[NSString class]]) continue;

        NSTimeInterval startTime = [segmentRange[0] doubleValue];
        NSTimeInterval endTime = [segmentRange[1] doubleValue];
        if (endTime <= startTime) continue;

        YTLSponsorBlockAction action = [self actionForCategory:category];
        [segments addObject:[[YTLSponsorBlockSegment alloc] initWithCategory:category startTime:startTime endTime:endTime action:action UUID:UUID]];
    }

    [segments sortUsingComparator:^NSComparisonResult(YTLSponsorBlockSegment *lhs, YTLSponsorBlockSegment *rhs) {
        if (lhs.startTime < rhs.startTime) return NSOrderedAscending;
        if (lhs.startTime > rhs.startTime) return NSOrderedDescending;
        return NSOrderedSame;
    }];

    return segments;
}

- (YTLSponsorBlockAction)actionForCategory:(NSString *)category {
    static NSDictionary<NSString *, NSString *> *keyMap;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        keyMap = @{
            @"sponsor": @"sb_sponsor",
            @"intro": @"sb_intro",
            @"outro": @"sb_outro",
            @"interaction": @"sb_interaction",
            @"selfpromo": @"sb_selfpromo",
            @"music_offtopic": @"sb_music_offtopic",
        };
    });

    NSString *key = keyMap[category];
    if (key) {
        return [[NSUserDefaults standardUserDefaults] boolForKey:key] ? YTLSponsorBlockActionSkipAutomatically : YTLSponsorBlockActionIgnore;
    }

    if ([category isEqualToString:@"preview"] || [category isEqualToString:@"poi_highlight"] || [category isEqualToString:@"filler"]) {
        return YTLSponsorBlockActionShowOnly;
    }

    return YTLSponsorBlockActionIgnore;
}

@end

@implementation YTLSponsorBlockManager

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    static YTLSponsorBlockManager *manager = nil;
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
    });
    return manager;
}

- (void)preloadSegmentsForVideoID:(NSString *)videoID {
    [[YTLSponsorBlockService sharedService] fetchSegmentsForVideoID:videoID completion:^(__unused YTLSponsorBlockFetchResult *result) {
    }];
}

- (NSArray<YTLSponsorBlockSegment *> *)cachedSegmentsForVideoID:(NSString *)videoID {
    __block NSArray<YTLSponsorBlockSegment *> *segments = @[];
    dispatch_semaphore_t semaphore = dispatch_semaphore_create(0);

    [[YTLSponsorBlockService sharedService] fetchSegmentsForVideoID:videoID completion:^(YTLSponsorBlockFetchResult *result) {
        segments = result.segments ?: @[];
        dispatch_semaphore_signal(semaphore);
    }];

    dispatch_semaphore_wait(semaphore, dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)));
    return segments;
}

- (YTLSponsorBlockSegment *)segmentForVideoID:(NSString *)videoID atTime:(NSTimeInterval)time {
    for (YTLSponsorBlockSegment *segment in [self cachedSegmentsForVideoID:videoID]) {
        if ([segment containsTime:time]) {
            return segment;
        }
    }
    return nil;
}

- (YTLSponsorBlockSegment *)nextAutoSkipSegmentForVideoID:(NSString *)videoID atTime:(NSTimeInterval)time {
    for (YTLSponsorBlockSegment *segment in [self cachedSegmentsForVideoID:videoID]) {
        if (segment.action != YTLSponsorBlockActionSkipAutomatically) continue;
        if (segment.endTime <= time + 0.05) continue; // Already passed or almost passed
        if (segment.startTime - time > 0.15 && ![segment containsTime:time]) continue; // Too far in future
        return segment;
    }
    return nil;
}

@end
