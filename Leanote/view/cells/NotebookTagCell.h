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
#import "CellInfo.h"

#import <SWTableViewCell.h>

@interface NotebookTagCell : SWTableViewCell
{
	UILabel *_label1;
	UILabel *_label2;
}

@property (nonatomic, strong) CellInfo * cellInfo;

+ (UIFont *)statusFont;
+ (NSDictionary *)statusAttributes;
+ (UIFont *)titleFont;
+ (CGFloat)rowHeightForContentProvider:(CellInfo *)cellInfo andWidth:(CGFloat)width;

- (void)setCellInfo:(CellInfo *)cellInfo selectedId: (NSString *) selectedId;
- (void)setCellInfo:(CellInfo *) cellInfo;

@end
