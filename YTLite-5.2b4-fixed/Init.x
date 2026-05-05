// YTVideoOverlay Init - Framework for video overlay tweaks
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>

static char overlayButtonsKey;

// Constants for tweak initialization
#define AccessibilityLabelKey @"AccessibilityLabel"
#define SelectorKey @"Selector"
#define AsTextKey @"AsText"
#define ExtraBooleanKeys @"ExtraBooleanKeys"

@interface YTMainAppControlsOverlayView (YTVideoOverlay)
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
@end

@interface YTInlinePlayerBarContainerView (YTVideoOverlay)
@property (nonatomic, strong) NSMutableDictionary *overlayButtons;
@end

%group YTVideoOverlayGroup

%hook YTMainAppControlsOverlayView

%new
- (NSMutableDictionary *)overlayButtons {
    NSMutableDictionary *buttons = objc_getAssociatedObject(self, &overlayButtonsKey);
    if (!buttons) {
        buttons = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &overlayButtonsKey, buttons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return buttons;
}

%new
- (void)setOverlayButtons:(NSMutableDictionary *)overlayButtons {
    objc_setAssociatedObject(self, &overlayButtonsKey, overlayButtons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%hook YTInlinePlayerBarContainerView

%new
- (NSMutableDictionary *)overlayButtons {
    NSMutableDictionary *buttons = objc_getAssociatedObject(self, &overlayButtonsKey);
    if (!buttons) {
        buttons = [NSMutableDictionary dictionary];
        objc_setAssociatedObject(self, &overlayButtonsKey, buttons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return buttons;
}

%new
- (void)setOverlayButtons:(NSMutableDictionary *)overlayButtons {
    objc_setAssociatedObject(self, &overlayButtonsKey, overlayButtons, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

%end

%end

// Stub function - actual button creation is handled in individual tweak hooks
void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings) {
    NSLog(@"[YTVideoOverlay] Initialized for %@ with settings: %@", tweakKey, settings);
}

%ctor {
    %init(YTVideoOverlayGroup);
}
