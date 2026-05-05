#import "YTLite.h"
#import <objc/message.h>

@interface YTSettingsSectionItemManager (SponsorBlock)
- (YTSettingsSectionItem *)sbSwitch:(NSString *)title key:(NSString *)key;
- (NSArray <YTSettingsSectionItem *> *)sbSettings;
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
