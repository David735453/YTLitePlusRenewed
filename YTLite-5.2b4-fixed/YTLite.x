#import "YTLite.h"
#import "Utils/YTLSponsorBlockCore.h"
#import <objc/message.h>
#import <objc/runtime.h>

// SponsorBlock Logic
static NSString *lastSkippedVideoID = nil;
static NSTimeInterval lastSkippedTime = 0;

void handleSponsorBlock(YTPlayerViewController *self, YTSingleVideoTime *time) {
    if (!self || !time || !ytlBool(@"enableSponsorBlock")) return;
    if (!self.contentVideoID.length) return;

    BOOL isAd = NO;
    if ([self respondsToSelector:@selector(isPlayingAd)]) {
        isAd = ((BOOL (*)(id, SEL))objc_msgSend)(self, @selector(isPlayingAd));
    }
    if (isAd) return;

    if ([self.contentVideoID isEqualToString:lastSkippedVideoID] && fabs(time.time - lastSkippedTime) < 1.0) {
        return;
    }

    YTLSponsorBlockSegment *segment = [[%c(YTLSponsorBlockManager) sharedManager] segmentForVideoID:self.contentVideoID atTime:time.time];
    if (segment) {
        lastSkippedVideoID = [self.contentVideoID copy];
        lastSkippedTime = segment.endTime + 0.1;
        if ([self respondsToSelector:@selector(seekToTime:)]) {
            ((void (*)(id, SEL, CGFloat))objc_msgSend)(self, @selector(seekToTime:), lastSkippedTime);
        }
        @try {
            id category = segment.category ?: @"segment";
            if ([category isKindOfClass:[NSString class]]) {
                NSString *msg = [NSString stringWithFormat:@"Skipped %@", [category capitalizedString]];
                if (msg) {
                    [[%c(YTToastResponderEvent) eventWithMessage:msg firstResponder:self] send];
                }
            }
        } @catch (NSException *e) {}
    }
}

%hook YTPlayerViewController
- (void)singleVideo:(id)video currentVideoTimeDidChange:(YTSingleVideoTime *)time {
    %orig;
    handleSponsorBlock(self, time);
}
- (void)potentiallyMutatedSingleVideo:(id)video currentVideoTimeDidChange:(YTSingleVideoTime *)time {
    %orig;
    handleSponsorBlock(self, time);
}
%end

%ctor {
    // Delay initialization to avoid blocking the splash screen
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.google.ios.youtube"]) return;
        %init;
        NSLog(@"[SponsorBlockPlus] Initialized");
    });
}
