#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, YTLSponsorBlockAction) {
    YTLSponsorBlockActionSkipAutomatically = 0,
    YTLSponsorBlockActionShowOnly = 1,
    YTLSponsorBlockActionIgnore = 2,
};

@interface YTLSponsorBlockSegment : NSObject

@property (nonatomic, copy, readonly) NSString *category;
@property (nonatomic, assign, readonly) NSTimeInterval startTime;
@property (nonatomic, assign, readonly) NSTimeInterval endTime;
@property (nonatomic, assign, readonly) YTLSponsorBlockAction action;
@property (nonatomic, copy, readonly) NSString *UUID;

- (instancetype)initWithCategory:(NSString *)category
                       startTime:(NSTimeInterval)startTime
                         endTime:(NSTimeInterval)endTime
                          action:(YTLSponsorBlockAction)action
                            UUID:(NSString *)UUID;

- (BOOL)containsTime:(NSTimeInterval)time;

@end

@interface YTLSponsorBlockFetchResult : NSObject

@property (nonatomic, copy, readonly) NSString *videoID;
@property (nonatomic, copy, readonly) NSArray<YTLSponsorBlockSegment *> *segments;
@property (nonatomic, strong, readonly, nullable) NSError *error;

- (instancetype)initWithVideoID:(NSString *)videoID
                       segments:(NSArray<YTLSponsorBlockSegment *> *)segments
                          error:(nullable NSError *)error;

@end

@interface YTLSponsorBlockService : NSObject

+ (instancetype)sharedService;
- (void)fetchSegmentsForVideoID:(NSString *)videoID
                     completion:(void (^)(YTLSponsorBlockFetchResult *result))completion;

@end

@interface YTLSponsorBlockManager : NSObject

+ (instancetype)sharedManager;
- (void)preloadSegmentsForVideoID:(NSString *)videoID;
- (NSArray<YTLSponsorBlockSegment *> *)cachedSegmentsForVideoID:(NSString *)videoID;
- (nullable YTLSponsorBlockSegment *)segmentForVideoID:(NSString *)videoID atTime:(NSTimeInterval)time;
- (nullable YTLSponsorBlockSegment *)nextAutoSkipSegmentForVideoID:(NSString *)videoID atTime:(NSTimeInterval)time;

@end

NS_ASSUME_NONNULL_END
