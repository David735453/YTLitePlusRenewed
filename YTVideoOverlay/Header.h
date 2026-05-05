// YTVideoOverlay Header - for YouSpeed integration
#import <UIKit/UIKit.h>
#import <objc/runtime.h>

// Forward declaration for MLHAMPlayerItem
@class MLHAMPlayerItem;

// Key constants
#define AccessibilityLabelKey @"AccessibilityLabel"
#define SelectorKey @"Selector"
#define AsTextKey @"AsText"
#define ExtraBooleanKeys @"ExtraBooleanKeys"

// PS_ROOT_PATH_NS macro - strips the leading @ if present
#define PS_ROOT_PATH_NS(path) (path)

// Tweak key - will be defined by the tweak
extern NSString *TweakKey;

// Function to initialize overlay
void initYTVideoOverlay(NSString *tweakKey, NSDictionary *settings);

// Localization macro
#define LOC(key) key
