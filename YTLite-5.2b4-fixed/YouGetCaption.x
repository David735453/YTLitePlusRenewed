// YouGetCaption - Copy video captions from video overlay
// Based on: https://github.com/PoomSmart/YouGetCaption
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <YouTubeHeader/GOOHUDManagerInternal.h>
#import <YouTubeHeader/YTHUDMessage.h>
#import <YouTubeHeader/MLCaption.h>
#import <YouTubeHeader/MLFormat3Captions.h>
#import <YouTubeHeader/YTAlertView.h>
#import <YouTubeHeader/YTFormat3CaptionViewController.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>
#import <YouTubeHeader/YTUIResources.h>

#define TweakKey @"YouGetCaption"
#define PS_ROOT_PATH_NS(path) path

@interface YTInlinePlayerBarContainerView (YouGetCaption)
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
- (void)didPressYouGetCaption:(id)arg;
@end

@interface YTMainAppControlsOverlayView (YouGetCaption)
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
- (void)didPressYouGetCaption:(id)arg;
@end

@class YTInterval;
@class YTIntervalTree;

static void showTranscript(YTFormat3CaptionViewController *cvc) {
    MLFormat3Captions *currentCaptions = [cvc valueForKey:@"_currentCaptions"];
    YTIntervalTree *tree = currentCaptions.captions;
    NSMutableString *transcript = [NSMutableString string];
    [tree enumerateAllIntervalsWithBlock:^(YTInterval *interval) {
        MLCaption *caption = (MLCaption *)interval;
        NSArray <MLCaptionSegment *> *segments = caption.segments;
        for (MLCaptionSegment *segment in segments) {
            [transcript appendString:segment.text];
        }
    }];
    if (transcript.length == 0) {
        YTAlertView *alertView = [%c(YTAlertView) infoDialog];
        alertView.title = @"Captions";
        alertView.subtitle = @"No captions available";
        alertView.shouldDismissOnBackgroundTap = YES;
        [alertView show];
        return;
    }
    YTAlertView *alertView = [%c(YTAlertView) confirmationDialogWithAction:^{
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        pasteboard.string = transcript;
        [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"Copied to clipboard"]];
    } actionTitle:@"Copy to clipboard"];
    alertView.title = @"Captions";
    alertView.subtitle = transcript;
    alertView.shouldDismissOnBackgroundTap = YES;
    [alertView show];
}

%group Top

%hook YTMainAppControlsOverlayView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? [%c(YTUIResources) outlineTextWithColor:[UIColor whiteColor]] : %orig;
}

%new(v@:@)
- (void)didPressYouGetCaption:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self valueForKey:@"_eventsDelegate"];
    YTFormat3CaptionViewController *cvc = [c valueForKey:@"_captionOverlayViewController"];
    showTranscript(cvc);
}

%end

%end

%group Bottom

%hook YTInlinePlayerBarContainerView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? [%c(YTUIResources) outlineTextWithColor:[UIColor whiteColor]] : %orig;
}

%new(v@:@)
- (void)didPressYouGetCaption:(id)arg {
    YTMainAppVideoPlayerOverlayViewController *c = [self.delegate valueForKey:@"_delegate"];
    YTFormat3CaptionViewController *cvc = [c valueForKey:@"_captionOverlayViewController"];
    showTranscript(cvc);
}

%end

%end

%ctor {
    // Import init function from Init.x
    extern void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings);
    initYTVideoOverlay(TweakKey, @{
        @"AccessibilityLabel": @"Caption",
        @"Selector": @"didPressYouGetCaption:",
    });
    %init(Top);
    %init(Bottom);
}
