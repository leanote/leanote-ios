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
	[super setActive: visible animated: animated];
	
	/*
	[self.searchContentsController.navigationController setNavigationBarHidden: NO animated: NO];
	
//	[super setActive: visible animated: animated];
	
//	[self.searchContentsController.navigationController setNavigationBarHidden:YES animated: YES];
	
	if(self.active == visible) return;
	[self.searchContentsController.navigationController setNavigationBarHidden:YES animated:NO];
	[super setActive:visible animated:animated];
	[self.searchContentsController.navigationController setNavigationBarHidden:NO animated:NO];
	if (visible) {
		[self.searchBar becomeFirstResponder];
	} else {
		[self.searchBar resignFirstResponder];
	}
	*/
}

@end
