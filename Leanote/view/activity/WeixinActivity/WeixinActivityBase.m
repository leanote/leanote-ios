//
//  WeixinActivity.m
//  WeixinActivity
//
//  Created by Johnny iDay on 13-12-2.
//  Copyright (c) 2013年 Johnny iDay. All rights reserved.
//

#import "WeixinActivityBase.h"

@implementation WeixinActivityBase

+ (UIActivityCategory)activityCategory
{
    return UIActivityCategoryShare;
}

- (NSString *)activityType
{
    return NSStringFromClass([self class]);
}

- (BOOL)canPerformWithActivityItems:(NSArray *)activityItems
{
	// life, isWXAppInstalled返回false, 但isWXAppSupportApi返回true
//	NSLog([WXApi isWXAppInstalled] ? @"weixin installed" : @"NO installl");
//	NSLog([WXApi isWXAppSupportApi] ? @"weixin isWXAppSupportApi" : @"NO isWXAppSupportApi");
	NSLog(@"getApiVersion %@", [WXApi getApiVersion]);
    if ([WXApi isWXAppSupportApi]) {
        for (id activityItem in activityItems) {
            if ([activityItem isKindOfClass:[UIImage class]]) {
                return YES;
            }
            if ([activityItem isKindOfClass:[NSURL class]]) {
                return YES;
            }
        }
    }
    return NO;
}

- (void)prepareWithActivityItems:(NSArray *)activityItems
{
	title = nil;
    for (id activityItem in activityItems) {
        if ([activityItem isKindOfClass:[UIImage class]]) {
            image = activityItem;
        }
        if ([activityItem isKindOfClass:[NSURL class]]) {
            url = activityItem;
        }
        if ([activityItem isKindOfClass:[NSString class]]) {
			if(title) {
				desc = activityItem;
			} else {
				title = activityItem;
			}
        }
    }
}

- (void)setThumbImage:(SendMessageToWXReq *)req
{
    if (image) {
        CGFloat width = 100.0f;
        CGFloat height = image.size.height * 100.0f / image.size.width;
        UIGraphicsBeginImageContext(CGSizeMake(width, height));
        [image drawInRect:CGRectMake(0, 0, width, height)];
        UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        [req.message setThumbImage:scaledImage];
    }
}

- (void)performActivity
{
    SendMessageToWXReq *req = [[SendMessageToWXReq alloc] init];
    req.scene = scene;
//    req.bText = NO;
    req.message = WXMediaMessage.message;
	// TODO 这里, 分享, 不用Leanote ? 用用户名
    if (scene == WXSceneSession) {
		req.message.title = title; // [NSString stringWithFormat:NSLocalizedString(@"%@ Share",nil), NSLocalizedStringFromTable(@"CFBundleDisplayName", @"InfoPlist", nil)];
        req.message.description = desc;
    } else {
        req.message.title = title;
    }
    [self setThumbImage:req];
    if (url) {
        WXWebpageObject *webObject = WXWebpageObject.object;
        webObject.webpageUrl = [url absoluteString];
        req.message.mediaObject = webObject;
    } else if (image) {
        WXImageObject *imageObject = WXImageObject.object;
        imageObject.imageData = UIImageJPEGRepresentation(image, 1);
        req.message.mediaObject = imageObject;
    }
    [WXApi sendReq:req];
    [self activityDidFinish:YES];
}

@end
