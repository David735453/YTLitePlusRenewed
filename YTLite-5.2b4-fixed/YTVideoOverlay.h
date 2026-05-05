// Minimal YTVideoOverlay replacement for YouSpeed
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Forward declarations
@class YTMainAppControlsOverlayView;
@class YTInlinePlayerBarContainerView;
@class MLHAMPlayerItem;

#define AccessibilityLabelKey @"AccessibilityLabel"
#define SelectorKey @"Selector"
#define AsTextKey @"AsText"
#define ExtraBooleanKeys @"ExtraBooleanKeys"

// PS_ROOT_PATH_NS macro replacement
#define PS_ROOT_PATH_NS(path) path

// initYTVideoOverlay function declaration
void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings);

// Localization macro
#define LOC(key) key
