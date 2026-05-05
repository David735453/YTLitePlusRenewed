#import "YTLite.h"
#import <objc/runtime.h>

@interface YTRightNavigationButtons (SponsorBlock)
@property (nonatomic, strong) YTQTMButton *sbButton;
- (void)sbButtonPressed:(id)sender;
@end

%hook YTRightNavigationButtons

%property (nonatomic, strong) YTQTMButton *sbButton;

- (void)layoutSubviews {
    %orig;

    if (!self.sbButton) {
        self.sbButton = [%c(YTQTMButton) iconButton];
        
        // Load the icon from the iSponsorBlock bundle which is already in the IPA
        NSBundle *sbBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"iSponsorBlock" ofType:@"bundle"]];
        UIImage *icon = [UIImage imageNamed:@"PlayerInfoIconSponsorBlocker256px-20" inBundle:sbBundle compatibleWithTraitCollection:nil];
        
        if (!icon) {
            icon = [UIImage systemImageNamed:@"shield.fill"];
        }
        
        if (icon) {
            [self.sbButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        }
        
        [self.sbButton addTarget:self action:@selector(sbButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.sbButton];
    }

    // Identify the search button and notification button to align perfectly
    UIView *search = nil;
    for (UIView *sub in self.subviews) {
        if (sub == self.sbButton) continue;
        // Search button usually has a specific identifier or is a YTQTMButton
        if ([sub isKindOfClass:%c(YTQTMButton)]) {
            if (!search || sub.frame.origin.x < search.frame.origin.x) {
                search = sub;
            }
        }
    }

    if (search) {
        CGRect frame = search.frame;
        // Move to the left of the leftmost button
        frame.origin.x -= frame.size.width;
        self.sbButton.frame = frame;
        
        // If we are off-screen (X < 0), we need to tell our parent to grow!
        if (frame.origin.x < 0) {
            CGRect parentFrame = self.frame;
            CGFloat offset = fabs(frame.origin.x);
            parentFrame.origin.x -= offset;
            parentFrame.size.width += offset;
            self.frame = parentFrame;
            
            // Re-layout our button at 0
            frame.origin.x = 0;
            self.sbButton.frame = frame;
            
            // Shift all other buttons to the right
            for (UIView *sub in self.subviews) {
                if (sub == self.sbButton) continue;
                CGRect f = sub.frame;
                f.origin.x += offset;
                sub.frame = f;
            }
        }
    }
}

%new
- (void)sbButtonPressed:(id)sender {
    @try {
        Class managerClass = %c(YTSettingsSectionItemManager);
        [managerClass performSelector:@selector(showSponsorBlockSettings)];
    } @catch (NSException *e) {}
}

%end
