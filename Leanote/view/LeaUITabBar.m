//
//  LeaUITabBar.m
//  Leanote
//
//  Created by life on 15/7/22.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "LeaUITabBar.h"

@implementation LeaUITabBar

//#define kTabBarHeight = 40 // Input the height we want to set for Tabbar here
-(CGSize)sizeThatFits:(CGSize)size
{
	CGSize sizeThatFits = [super sizeThatFits:size];
	sizeThatFits.height = 40;
	return sizeThatFits;
}


/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
