//
//  ApiMsg.m
//  Leanote
//
//  Created by life on 15/6/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "ApiMsg.h"
#import "SVProgressHUD.h"

@implementation ApiMsg

+(NSString *) getMsg: (id) ret
{
	NSString *msg = ret[@"Msg"];
	
	if(!msg) {
		return nil;
	}
	
	if([msg isEqualToString:@"notebookIdNotExists"]) {
		return NSLocalizedString(@"The note's notebook is not exists, please try to pull to sync", nil);
	}
	else if([msg isEqualToString:@"conflict"]) {
		return NSLocalizedString(@"Conflict", nil);
	}
	else if([msg isEqualToString:@"notExists"]) {
		return NSLocalizedString(@"Not exists", nil);
	}
	else if([msg isEqualToString:@"fileUploadError"]) {
		return NSLocalizedString(@"File/Image upload failure", nil);
	}
	
	
	return msg;
}

@end
