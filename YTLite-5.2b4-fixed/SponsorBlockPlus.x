#import "YTLite.h"
#import "Utils/YTLSponsorBlockCore.h"
#import <objc/runtime.h>
#import <objc/message.h>

// UI Overlay - Button in top navigation
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
        NSBundle *sbBundle = [NSBundle bundleWithPath:[[NSBundle mainBundle] pathForResource:@"iSponsorBlock" ofType:@"bundle"]];
        UIImage *icon = [UIImage imageNamed:@"PlayerInfoIconSponsorBlocker256px-20" inBundle:sbBundle compatibleWithTraitCollection:nil];
        if (!icon) icon = [UIImage systemImageNamed:@"shield.fill"];
        if (icon) [self.sbButton setImage:[icon imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        [self.sbButton addTarget:self action:@selector(sbButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:self.sbButton];
    }
    UIView *search = nil;
    for (UIView *sub in self.subviews) {
        if (sub == self.sbButton) continue;
        if ([sub isKindOfClass:%c(YTQTMButton)]) {
            if (!search || sub.frame.origin.x < search.frame.origin.x) search = sub;
        }
    }
    if (search) {
        CGRect frame = search.frame;
        frame.origin.x -= frame.size.width;
        self.sbButton.frame = frame;
        if (frame.origin.x < 0) {
            CGRect parentFrame = self.frame;
            CGFloat offset = fabs(frame.origin.x);
            parentFrame.origin.x -= offset;
            parentFrame.size.width += offset;
            self.frame = parentFrame;
            frame.origin.x = 0;
            self.sbButton.frame = frame;
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

// Core SponsorBlock Logic - Using NEW YTLSponsorBlockCore
static NSString *lastSkippedVideoID = nil;
static NSTimeInterval lastSkippedTime = 0;

void handleSponsorBlockSkip(YTPlayerViewController *self, YTSingleVideoTime *time) {
    if (!self || !time || !ytlBool(@"enableSponsorBlock")) return;
    if (!self.contentVideoID.length) return;
    BOOL isAd = NO;
    if ([self respondsToSelector:@selector(isPlayingAd)]) {
        isAd = ((BOOL (*)(id, SEL))objc_msgSend)(self, @selector(isPlayingAd));
    }
    if (isAd) return;
    if ([self.contentVideoID isEqualToString:lastSkippedVideoID] && fabs(time.time - lastSkippedTime) < 1.0) return;
    
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
                if (msg) [[%c(YTToastResponderEvent) eventWithMessage:msg firstResponder:self] send];
            }
        } @catch (NSException *e) {}
    }
}

%hook YTPlayerViewController
- (void)singleVideo:(id)video currentVideoTimeDidChange:(YTSingleVideoTime *)time {
    %orig;
    handleSponsorBlockSkip(self, time);
}
- (void)potentiallyMutatedSingleVideo:(id)video currentVideoTimeDidChange:(YTSingleVideoTime *)time {
    %orig;
    handleSponsorBlockSkip(self, time);
}
%end

// Settings UI
@interface YTSettingsSectionItemManager (SponsorBlock)
- (YTSettingsSectionItem *)sbSwitch:(NSString *)title key:(NSString *)key;
- (NSArray <YTSettingsSectionItem *> *)sbSettings;
+ (void)showSponsorBlockSettings;
@end

%hook YTSettingsSectionItemManager
%new
- (YTSettingsSectionItem *)sbSwitch:(NSString *)title key:(NSString *)key {
    Class itemClass = NSClassFromString(@"YTSettingsSectionItem");
    return [itemClass switchItemWithTitle:title titleDescription:nil accessibilityIdentifier:@"SBSwitch" switchOn:ytlBool(key) switchBlock:^BOOL(YTSettingsCell *cell, BOOL enabled) {
        ytlSetBool(enabled, key);
        return YES;
    } settingItemId:0];
}

%new
- (NSArray <YTSettingsSectionItem *> *)sbSettings {
    NSMutableArray *rows = [NSMutableArray array];
    [rows addObject:[self sbSwitch:@"Enable SponsorBlock" key:@"enableSponsorBlock"]];
    [rows addObject:[self sbSwitch:@"Skip Sponsors" key:@"sb_sponsor"]];
    [rows addObject:[self sbSwitch:@"Skip Intros" key:@"sb_intro"]];
    [rows addObject:[self sbSwitch:@"Skip Outros" key:@"sb_outro"]];
    [rows addObject:[self sbSwitch:@"Skip Interaction Reminders" key:@"sb_interaction"]];
    [rows addObject:[self sbSwitch:@"Skip Self-Promotion" key:@"sb_selfpromo"]];
    [rows addObject:[self sbSwitch:@"Skip Non-Music Sections" key:@"sb_music_offtopic"]];
    return rows;
}

%new
+ (void)showSponsorBlockSettings {
    YTSettingsSectionItemManager *manager = [[%c(YTSettingsSectionItemManager) alloc] initWithSettingsViewControllerDelegate:nil];
    NSArray *rows = [manager sbSettings];
    YTSettingsPickerViewController *pickerVC = [[%c(YTSettingsPickerViewController) alloc] initWithNavTitle:@"SponsorBlock" pickerSectionTitle:nil rows:rows selectedItemIndex:NSNotFound parentResponder:nil];
    UIWindow *window = nil;
    if (@available(iOS 13.0, *)) {
        for (UIWindowScene *scene in [UIApplication sharedApplication].connectedScenes) {
            if (scene.activationState == UISceneActivationStateForegroundActive) {
                window = scene.windows.firstObject;
                break;
            }
        }
    }
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wdeprecated-declarations"
    if (!window) window = [UIApplication sharedApplication].keyWindow;
    #pragma clang diagnostic pop
    UIViewController *rootVC = window.rootViewController;
    while (rootVC.presentedViewController) rootVC = rootVC.presentedViewController;
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:pickerVC];
    [rootVC presentViewController:nav animated:YES completion:nil];
}
%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (![[NSBundle mainBundle].bundleIdentifier isEqualToString:@"com.google.ios.youtube"]) return;
        %init;
        NSLog(@"[SponsorBlockPlus] Initialized with new core");
    });
}
