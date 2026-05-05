#import "YTLUserDefaults.h"

@implementation YTLUserDefaults

static NSString *const kDefaultsSuiteName = @"com.dvntm.ytlite";

+ (YTLUserDefaults *)standardUserDefaults {
    static dispatch_once_t onceToken;
    static YTLUserDefaults *defaults = nil;

    dispatch_once(&onceToken, ^{
        defaults = [[self alloc] initWithSuiteName:kDefaultsSuiteName];
        [defaults registerDefaults];
    });

    return defaults;
}

- (void)reset {
    [self removePersistentDomainForName:kDefaultsSuiteName];
}

- (void)registerDefaults {
    [self registerDefaults:@{
        @"noAds": @YES,
        @"backgroundPlayback": @YES,
        @"clearCacheAtStart": @NO,
        @"removeUploads": @YES,
        @"speedIndex": @1,
        @"speedMode": @0,
        @"autoSpeedIndex": @3,
        @"wiFiQualityIndex": @0,
        @"cellQualityIndex": @0,
        @"pivotIndex": @0,
        @"shortsProgress": @YES,
        @"advancedMode": @NO,
        @"enableSponsorBlock": @YES,
        @"sb_sponsor": @YES,
        @"sb_selfpromo": @YES,
        @"sb_interaction": @NO,
        @"sb_intro": @NO,
        @"sb_outro": @NO,
        @"sb_music_offtopic": @NO,
        @"blockUpgrade": @YES,
        @"hideShortsShelf": @NO,
        @"hideCommunityShelf": @NO,
        @"hideLatestPosts": @NO,
        @"YSMS": @YES,
        @"YSSS": @NO,
        @"YSFNS": @NO,
        @"YSRLS": @NO,
        @"YSSSHT": @NO,
        @"YSOMS": @YES
    }];
}

+ (void)resetUserDefaults {
    [[self standardUserDefaults] reset];
}

@end
