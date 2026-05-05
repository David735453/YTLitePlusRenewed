// YouShare - Copy video URL faster from video overlay
// Based on: https://github.com/aricloverEXTRA/YouShare
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTMainAppVideoPlayerOverlayViewController.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>
#import <YouTubeHeader/YTPlayerViewController.h>
#import <YouTubeHeader/GOOHUDManagerInternal.h>
#import <YouTubeHeader/YTHUDMessage.h>
#import <YouTubeHeader/QTMIcon.h>
#import <YouTubeHeader/YTColor.h>

#define TweakKey @"YouShare"
#define ROOT_PATH_NS(path) path

@interface YTMainAppVideoPlayerOverlayViewController (YouShare)
@property (nonatomic, assign) YTPlayerViewController *parentViewController;
@end

@interface YTMainAppVideoPlayerOverlayView (YouShare)
@property (nonatomic, weak, readwrite) YTMainAppVideoPlayerOverlayViewController *delegate;
@end

@interface YTPlayerViewController (YouShare)
@property (nonatomic, assign) CGFloat currentVideoMediaTime;
@property (nonatomic, assign) NSString *currentVideoID;
- (void)didPressYouShare;
@end

@interface YTMainAppControlsOverlayView (YouShare)
@property (nonatomic, assign) YTPlayerViewController *playerViewController;
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
- (void)didPressYouShare:(id)arg;
@end

@interface YTInlinePlayerBarController : NSObject
@end

@interface YTInlinePlayerBarContainerView (YouShare)
@property (nonatomic, strong) YTInlinePlayerBarController *delegate;
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
- (void)didPressYouShare:(id)arg;
@end

static NSBundle *YouShareBundle() {
    static NSBundle *bundle = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSString *tweakBundlePath = [[NSBundle mainBundle] pathForResource:TweakKey ofType:@"bundle"];
        if (tweakBundlePath)
            bundle = [NSBundle bundleWithPath:tweakBundlePath];
        else
            bundle = [NSBundle bundleWithPath:[NSString stringWithFormat:@"/Library/Application Support/%@.bundle", TweakKey]];
    });
    return bundle;
}

static UIImage *shareImage(NSString *qualityLabel) {
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"Share@%@", qualityLabel] inBundle:YouShareBundle() compatibleWithTraitCollection:nil];
    return [%c(QTMIcon) tintImage:image color:[%c(YTColor) white1]];
}

%group Main
%hook YTPlayerViewController
%new
- (void)didPressYouShare {
    if (self.currentVideoID) {
        NSString *videoId = [NSString stringWithFormat:@"https://youtube.com/watch?v=%@", self.currentVideoID];
        UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
        [pasteboard setString:videoId];
        [[%c(GOOHUDManagerInternal) sharedInstance] showMessageMainThread:[%c(YTHUDMessage) messageWithText:@"URL copied to clipboard"]];
    } else {
        NSLog(@"[YouShare] No video ID available");
    }
}
%end
%end

%group Top
%hook YTMainAppControlsOverlayView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? shareImage(@"3") : %orig;
}

%new(v@:@)
- (void)didPressYouShare:(id)arg {
    YTMainAppVideoPlayerOverlayView *mainOverlayView = (YTMainAppVideoPlayerOverlayView *)self.superview;
    YTMainAppVideoPlayerOverlayViewController *mainOverlayController = (YTMainAppVideoPlayerOverlayViewController *)mainOverlayView.delegate;
    YTPlayerViewController *playerViewController = mainOverlayController.parentViewController;
    if (playerViewController) {
        [playerViewController didPressYouShare];
    }
}

%end
%end

%group Bottom
%hook YTInlinePlayerBarContainerView

- (UIImage *)buttonImage:(NSString *)tweakId {
    return [tweakId isEqualToString:TweakKey] ? shareImage(@"3") : %orig;
}

%new(v@:@)
- (void)didPressYouShare:(id)arg {
    YTInlinePlayerBarController *delegate = self.delegate;
    YTMainAppVideoPlayerOverlayViewController *_delegate = [delegate valueForKey:@"_delegate"];
    YTPlayerViewController *parentViewController = _delegate.parentViewController;
    if (parentViewController) {
        [parentViewController didPressYouShare];
    }
}

%end
%end

%ctor {
    // Import init function from Init.x
    extern void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings);
    initYTVideoOverlay(TweakKey, @{
        @"AccessibilityLabel": @"Copy Video URL",
        @"Selector": @"didPressYouShare:",
    });
    %init(Main);
    %init(Top);
    %init(Bottom);
}
