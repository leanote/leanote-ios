//
//  NoteCell.h
//  Leanote
//
//  Created by life on 15/6/27.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Note.h"

#import "Common.h"

#import <SWTableViewCell.h>

@interface NoteCell : SWTableViewCell // UITableViewCell
{
	UILabel *_label1;
	UILabel *_label2;
}

@property (nonatomic, strong) Note * note;

+ (UIFont *)statusFont;
+ (NSDictionary *)statusAttributes;
+ (UIFont *)titleFont;
+ (UIFont *)dateFont;

+ (CGFloat)rowHeightForContentProvider:(Note *)note andWidth:(CGFloat)width;

- (void)setNote:(Note *) note;

@end
