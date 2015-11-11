//
//  LeaSearchDisplayController.m
//  Leanote
//
//  Created by life on 15/7/19.
//  Copyright © 2015年 Leanote. All rights reserved.
//

#import "LeaSearchDisplayController.h"

@implementation LeaSearchDisplayController

- (void)setActive:(BOOL)visible animated:(BOOL)animated
{
	// 以下只是为了在ipad下搜索框不上移
	// http://stackoverflow.com/a/3257456/4269908
	if (IS_IPAD) {
		if(self.active == visible) return;
		[self.searchContentsController.navigationController setNavigationBarHidden:YES animated:NO];
		[super setActive:visible animated:animated];
		[self.searchContentsController.navigationController setNavigationBarHidden:NO animated:NO];
		if (visible) {
			[self.searchBar becomeFirstResponder];
		} else {
			[self.searchBar resignFirstResponder];
		}
	}
	else {
		[super setActive:visible animated:animated];
	}
}

@end
