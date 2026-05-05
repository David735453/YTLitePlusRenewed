/* YouTube Native Share - An iOS Tweak to replace YouTube's share sheet and remove source identifiers.
 * Copyright (C) 2024 YouTube Native Share Contributors
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <https://www.gnu.org/licenses/>.
 *
 * SPDX-License-Identifier: GPL-3.0-or-later
 */

// Source code can be found here: https://github.com/jkhsjdhjs/youtube-native-share (Thanks to @jkhsjdhjs) 

#include <UIKit/UIActivityViewController.h>

#import <YouTubeHeader/YTUIUtils.h>

#import "protobuf/objectivec/GPBDescriptor.h"
#import "protobuf/objectivec/GPBMessage.h"
#import "protobuf/objectivec/GPBUnknownField.h"
#import "protobuf/objectivec/GPBUnknownFields.h"

#define ytlBool(key)  [[[NSUserDefaults alloc] initWithSuiteName:@"com.dvntm.ytlite"] boolForKey:key]

@interface CustomGPBMessage : GPBMessage
+ (instancetype)deserializeFromString:(NSString *)string;
@end

@interface YTICommand : GPBMessage
@end

@interface ELMPBCommand : GPBMessage
@end

@interface ELMPBShowActionSheetCommand : GPBMessage
@property (nonatomic, strong, readwrite) ELMPBCommand *onAppear;
@property (nonatomic, assign, readwrite) BOOL hasOnAppear;
@end

@interface YTIUpdateShareSheetCommand
@property (nonatomic, assign, readwrite) BOOL hasSerializedShareEntity;
@property (nonatomic, copy, readwrite) NSString *serializedShareEntity;
+ (GPBExtensionDescriptor*)updateShareSheetCommand;
@end

@interface YTIInnertubeCommandExtensionRoot
+ (GPBExtensionDescriptor*)innertubeCommand;
@end

typedef NS_ENUM(NSInteger, ShareEntityType) {
    ShareEntityFieldVideo = 1,
    ShareEntityFieldPlaylist = 2,
    ShareEntityFieldChannel = 3,
    ShareEntityFieldClip = 8
};

static inline NSString* extractIdWithFormat(GPBUnknownFields *fields, NSInteger fieldNumber, NSString *format) {
    if (!fields)
        return nil;
    NSData *data = [fields firstLengthDelimited:fieldNumber];
    if (!data)
        return nil;
    NSString *id = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    if (!id)
        return nil;
    return [NSString stringWithFormat:format, id];
}

%hook ELMPBShowActionSheetCommand
- (void)executeWithCommandContext:(id)_context handler:(id)_handler {
    if (!ytlBool(@"nativeShare"))
        return %orig;

    if (!self.hasOnAppear)
        return %orig;
    GPBExtensionDescriptor *innertubeCommandDescriptor = [%c(YTIInnertubeCommandExtensionRoot) innertubeCommand];
    if (![self.onAppear hasExtension:innertubeCommandDescriptor])
        return %orig;
    YTICommand *innertubeCommand = [self.onAppear getExtension:innertubeCommandDescriptor];
    GPBExtensionDescriptor *updateShareSheetCommandDescriptor = [%c(YTIUpdateShareSheetCommand) updateShareSheetCommand];
    if(![innertubeCommand hasExtension:updateShareSheetCommandDescriptor])
        return %orig;
    YTIUpdateShareSheetCommand *updateShareSheetCommand = [innertubeCommand getExtension:updateShareSheetCommandDescriptor];
    if (!updateShareSheetCommand.hasSerializedShareEntity)
        return %orig;

    GPBMessage *shareEntity = [%c(GPBMessage) deserializeFromString:updateShareSheetCommand.serializedShareEntity];
    GPBUnknownFields *fields = [[%c(GPBUnknownFields) alloc] initFromMessage:shareEntity];
    NSString *shareUrl;

    NSData *clipData = [fields firstLengthDelimited:ShareEntityFieldClip];
    if (clipData) {
        GPBMessage *clipMessage = [%c(GPBMessage) parseFromData:clipData error:nil];
        GPBUnknownFields *clipFields = [[%c(GPBUnknownFields) alloc] initFromMessage:clipMessage];
        shareUrl = extractIdWithFormat(clipFields, 1, @"https://youtube.com/clip/%@");
    }

    if (!shareUrl)
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldChannel, @"https://youtube.com/channel/%@");

    if (!shareUrl) {
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldPlaylist, @"%@");
        if (shareUrl) {
            if (![shareUrl hasPrefix:@"PL"] && ![shareUrl hasPrefix:@"FL"])
                shareUrl = [shareUrl stringByAppendingString:@"&playnext=1"];
            shareUrl = [@"https://youtube.com/playlist?list=" stringByAppendingString:shareUrl];
        }
    }

    if (!shareUrl)
        shareUrl = extractIdWithFormat(fields, ShareEntityFieldVideo, @"https://youtube.com/watch?v=%@");

    if (!shareUrl)
        return %orig;

    UIViewController *presenter = [%c(YTUIUtils) topViewControllerForPresenting];
    if (!presenter)
        return %orig;

    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:@[shareUrl] applicationActivities:nil];
    [presenter presentViewController:activityViewController animated:YES completion:^{}];
}
%end
