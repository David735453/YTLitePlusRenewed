// YTVideoOverlay Init - for YouSpeed integration
#import "Header.h"
#import <YouTubeHeader/YTMainAppControlsOverlayView.h>
#import <YouTubeHeader/YTInlinePlayerBarContainerView.h>

static char overlayButtonsKey;

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

// Stub function - actual button creation is handled in YouSpeed.x hooks
void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings) {
    NSLog(@"[YTVideoOverlay] Initialized for %@ with settings: %@", tweakKey, settings);
    %init(YTVideoOverlayGroup);
}
