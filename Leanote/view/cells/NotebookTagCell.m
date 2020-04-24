//
//  NoteCell.m
//  Leanote
//
//  Created by life on 15/6/27.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "NotebookTagCell.h"
#import "WPFontManager.h"
#import "WPStyleGuide.h"
#import "NotebookService.h"

@interface NotebookTagCell()
{
	UILabel *_statusLabel;
	UILabel *_titleLabel;
	UILabel *_countLabel;
	UIImageView *_countImageView;
	
//	UIImageView *_notebookImageView;
//	UILabel *_notebookLabel;
	
	UIImageView *_unreadView;
}

@property (nonatomic) NSString *selectedId;

@end

@implementation NotebookTagCell


CGFloat const WPContentCellStandardOffset2                   = 10.0;
CGFloat const WPContentCellVerticalPadding2                  = 10.0;
CGFloat const WPContentCellTitleAndcountVerticalOffset2       = 3.0;
CGFloat const WPContentCellLabelAndTitleHorizontalOffset2    = -0.5;
CGFloat const WPContentCellAccessoryViewOffset2              = 10.0; // 右侧padding
CGFloat const WPContentCellImageWidth2                       = 70.0;
CGFloat const WPContentCellTitleNumberOfLines2               = 3;
CGFloat const WPContentCellUnreadViewSide2                   = 10.0;
CGFloat const WPContentCellUnreadDotSize2                    = 8.0;
CGFloat const WPContentCellCountImageSide                    = 16.0;
CGFloat const WPContentCellDefaultOrigin2                    = 15.0f;


- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
	self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
	if (self) {
		
		_statusLabel = [[UILabel alloc] init];
		_statusLabel.backgroundColor = [UIColor clearColor];
		_statusLabel.textAlignment = NSTextAlignmentLeft;
		_statusLabel.numberOfLines = 0;
		_statusLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_statusLabel.font = [[self class] statusFont];
		_statusLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_statusLabel.textColor = [UIColor colorWithRed:30/255.0f green:140/255.0f blue:190/255.0f alpha:1.0f];
		[self.contentView addSubview:_statusLabel];
		
		_titleLabel = [[UILabel alloc] init];
		_titleLabel.backgroundColor = [UIColor clearColor];
		_titleLabel.textAlignment = NSTextAlignmentLeft;
		_titleLabel.numberOfLines = WPContentCellTitleNumberOfLines2;
		_titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; // NSLineBreakByWordWrapping; // 省略号
		_titleLabel.font = [[self class] titleFont];
		_titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_titleLabel.textColor = [WPStyleGuide littleEddieGrey];
		[self.contentView addSubview:_titleLabel];
		
		_countLabel = [[UILabel alloc] init];
		_countLabel.backgroundColor = [UIColor clearColor];
		_countLabel.textAlignment = NSTextAlignmentLeft;
		_countLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_countLabel.font = [[self class] countFont];
		_countLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_countLabel.textColor = [WPStyleGuide allTAllShadeGrey];
		[self.contentView addSubview:_countLabel];
		
		_countImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reader-postaction-time"]];
		[_countImageView sizeToFit];
		[self.contentView addSubview:_countImageView];
		
		// _countImageView.hidden = YES;
		
		/*
		_notebookLabel = [[UILabel alloc] init];
		_notebookLabel.backgroundColor = [UIColor clearColor];
		_notebookLabel.textAlignment = NSTextAlignmentLeft;
		_notebookLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_notebookLabel.font = [[self class] countFont];
		_notebookLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_notebookLabel.textColor = [WPStyleGuide allTAllShadeGrey];
		[self.contentView addSubview:_notebookLabel];
		
		_notebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notebook3"]];
		[_countImageView sizeToFit];
		[self.contentView addSubview:_notebookImageView];
		*/
		
		/*
		if ([[self class] supportsUnreadStatus]) {
			_unreadView = [[UIImageView alloc] init];
			
			// create circular image
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(WPContentCellUnreadViewSide2, WPContentCellUnreadViewSide2), NO, 0);
			CGContextRef context = UIGraphicsGetCurrentContext();
			CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, WPContentCellUnreadDotSize2, WPContentCellUnreadDotSize2) cornerRadius:3.0].CGPath);
			
			CGContextSetFillColorWithColor(context, [WPStyleGuide newKidOnTheBlockBlue].CGColor);
			CGContextFillPath(context);
			_unreadView.image = UIGraphicsGetImageFromCurrentImageContext();
			
			[self.contentView addSubview:_unreadView];
		}
		*/
	}
	return self;
}

- (void)layoutSubviews
{
	[super layoutSubviews];
	
	// 得到宽度
	CGFloat maxWidth = CGRectGetWidth(self.bounds);
	
	CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:self.cellInfo maxWidth:maxWidth];
	CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:self.cellInfo previousFrame:statusFrame maxWidth:maxWidth];
	CGRect countFrame = [[self class] countLabelFrameForContentProvider:self.cellInfo previousFrame:titleFrame maxWidth:maxWidth];
	
	// CGRect notebookFrame = [[self class] notebookLabelFrameForContentProvider:self.cellInfo previousFrame:countFrame maxWidth:maxWidth];
	
	_statusLabel.frame = statusFrame;
	_titleLabel.frame = titleFrame;
	_countLabel.frame = countFrame;
	
//	_notebookLabel.frame = notebookFrame;
	_unreadView.frame = [[self class] unreadFrameForHeight:CGRectGetHeight(self.bounds)];
	
	// layout count image
	_countImageView.hidden = YES; // !(_countLabel.text.length > 0);
	if (!_countImageView.hidden) {
		_countImageView.frame = CGRectMake(CGRectGetMinX(countFrame) - WPContentCellCountImageSide - 2, CGRectGetMidY(countFrame) - WPContentCellCountImageSide / 2.0, WPContentCellCountImageSide, WPContentCellCountImageSide);
	}
	
	/*
	_notebookImageView.frame = CGRectMake(
										  CGRectGetMaxX(countFrame),
										  CGRectGetMidY(countFrame) - WPContentCellCountImageSide / 2.0,
										  WPContentCellCountImageSide,
										  WPContentCellCountImageSide);
	*/
}

// 行高
+ (CGFloat)rowHeightForContentProvider:(CellInfo *)cellInfo andWidth:(CGFloat)width
{
	CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:cellInfo maxWidth:width];
	CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:cellInfo previousFrame:statusFrame maxWidth:width];
	CGRect countFrame = [[self class] countLabelFrameForContentProvider:cellInfo previousFrame:titleFrame maxWidth:width];
	
//	return MAX(CGRectGetMaxY(gravatarFrame), CGRectGetMaxY(countFrame)) + WPContentCellVerticalPadding2;
	
	return CGRectGetMaxY(countFrame) + WPContentCellVerticalPadding2;
}

+ (BOOL)shortcountString
{
	return YES;
}

+ (BOOL)showGravatarImage
{
	return NO;
}

+ (BOOL)supportsUnreadStatus
{
	return NO;
}

+ (UIFont *)statusFont
{
	return [WPStyleGuide labelFont];
}

+ (NSDictionary *)statusAttributes
{
	return [WPStyleGuide labelAttributes];
}

+ (NSString *)statusTextForContentProvider:(CellInfo *) cellInfo
{
	if(cellInfo.isDirty) {
		long status = [cellInfo.status integerValue];
		if(status == -1) {
			return NSLocalizedString(@"Syncing...", nil);
		}
		return NSLocalizedString(@"Need sync", nil);
	}
	return @"";
	
	// return @"";
	return cellInfo.isDirty ? NSLocalizedString(@"Need sync", nil) : @"";
};

+ (UIColor *)statusColorForContentProvider:(CellInfo *) cellInfo
{
	return [WPStyleGuide jazzyOrange];
}

+ (UIFont *)titleFont
{
	return [WPFontManager systemRegularFontOfSize:14.0];
}


+ (UIFont *)titleFontBold
{
	return [WPFontManager systemBoldFontOfSize:14.0];
}

+ (NSDictionary *)titleAttributes
{
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.minimumLineHeight = 18;
	paragraphStyle.maximumLineHeight = 18;
	return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFont]};}

+ (NSDictionary *)titleAttributesBold
{
	NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
	paragraphStyle.minimumLineHeight = 18;
	paragraphStyle.maximumLineHeight = 18;
	return @{NSParagraphStyleAttributeName: paragraphStyle, NSFontAttributeName : [self titleFontBold]};
}

+ (NSAttributedString *)titleAttributedTextForContentProvider:(CellInfo *)cellInfo
{
	// remove new lines from title
	NSString *titleText = [Common isBlankString:cellInfo.title] ? NSLocalizedString(@"Untitled", nil) : cellInfo.title;
	return [[NSAttributedString alloc] initWithString:titleText attributes:[self titleAttributes]];
}

+ (UIFont *)countFont
{
	return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)countAttributes
{
	return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)countTextForContentProvider:(CellInfo *) cellInfo
{
	return [NSString stringWithFormat:@"%ld %@", (long)[cellInfo.count integerValue], NSLocalizedString(@"note", nil)];
}

#pragma private

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
	CGFloat padding = 0.0;
	padding += [[self class] textXOrigin];  // left padding
	padding += WPContentCellStandardOffset2 + WPContentCellAccessoryViewOffset2; // right padding
	return maxWidth - padding;
}

+ (CGFloat)contentXOrigin
{
	CGFloat x = 15.0;
	x += ([[self class] supportsUnreadStatus] ? 10.0 : 0.0);
	x += IS_RETINA ? -0.5 : 0.0;
	return x;
}

+ (CGFloat)textXOrigin
{
	if ([[self class] showGravatarImage]) {
		return ([[self class] gravatarXOrigin] + WPContentCellImageWidth2 + WPContentCellStandardOffset2);
	}
	
	return WPContentCellDefaultOrigin2;
}

+ (CGFloat)gravatarXOrigin
{
	return [[self class] contentXOrigin];
}


+ (CGRect)statusLabelFrameForContentProvider:(CellInfo *)cellInfo maxWidth:(CGFloat)maxWidth
{
	NSString *statusText = [self statusTextForContentProvider:cellInfo]; // [cellInfo.isDirty boolValue] ? @"未同步" : @"已同步";
	if ([statusText length] != 0) {
		CGSize size;
		size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
		
		return CGRectMake([[self class] textXOrigin], WPContentCellVerticalPadding2, size.width, size.height);
	}
	
	// 如果没有, 则不显示
	return CGRectMake(0, WPContentCellVerticalPadding2, 0, 0);
}

+ (CGRect)titleLabelFrameForContentProvider:(CellInfo *)cellInfo previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
	BOOL hasStatus = YES;
	
	CGSize size;
	NSAttributedString *attributedTitle = [[self class] titleAttributedTextForContentProvider:cellInfo];
	CGFloat lineHeight = attributedTitle.size.height;
	size = [attributedTitle boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
	size.height = ceilf(MIN(size.height, lineHeight * (WPContentCellTitleNumberOfLines2 - (hasStatus ? 1 : 0)))) + 1;
	
	CGFloat offset = -2.0; // Account for line height of title
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset += WPContentCellTitleAndcountVerticalOffset2;
	}
	
	return CGRectIntegral(CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)countLabelFrameForContentProvider:(CellInfo *)cellInfo previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
	CGSize size;
	size = [[[self class] countTextForContentProvider:cellInfo] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth] - WPContentCellCountImageSide, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] countAttributes] context:nil].size;
	
	CGFloat offset = 0.0;
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset = WPContentCellTitleAndcountVerticalOffset2;
	}
	
	return CGRectIntegral(CGRectMake([[self class] textXOrigin]/* + WPContentCellCountImageSide*/, CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)notebookLabelFrameForContentProvider:(CellInfo *)cellInfo previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
	CGSize size;
	size = [[[self class] countTextForContentProvider:cellInfo] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth] - WPContentCellCountImageSide, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] countAttributes] context:nil].size;
	
	CGFloat offset = 0.0;
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset = WPContentCellTitleAndcountVerticalOffset2;
	}
	
	return CGRectIntegral(CGRectMake(CGRectGetMaxX(previousFrame) + WPContentCellCountImageSide,
									 CGRectGetMinY(previousFrame), size.width, size.height));
}

+ (CGRect)unreadFrameForHeight:(CGFloat)height
{
	CGFloat side = WPContentCellUnreadViewSide2;
	return CGRectMake(([[self class] gravatarXOrigin] - side) / 2.0, (height - side) / 2.0 , side, side);
}

// 没用
- (void)setCellInfo:(CellInfo *)cellInfo selectedId:(NSString *)selectedId
{
	[self setCellInfo:cellInfo];
	self.selectedId = selectedId;
	
	// checkmark
	if(selectedId && [cellInfo.idd isEqualToString:selectedId]) {
		self.accessoryType = UITableViewCellAccessoryCheckmark;
	}
	else {
		self.accessoryType = UITableViewCellAccessoryNone;
	}
}

- (void)setCellInfo:(CellInfo *)cellInfo
{
	_cellInfo = cellInfo;

	_titleLabel.attributedText = [[self class] titleAttributedTextForContentProvider:cellInfo];
	
	_statusLabel.text = [[self class] statusTextForContentProvider:cellInfo];
	_statusLabel.textColor = [[self class] statusColorForContentProvider:cellInfo];
	_countLabel.text = [[self class] countTextForContentProvider:cellInfo];
	// _notebookLabel.text = [NotebookService getNotebookTitleByNotebookId:cellInfo.notebookId];
	
	if (_statusLabel.text != nil) {
		_statusLabel.attributedText = [[NSAttributedString alloc] initWithString:_statusLabel.text attributes:[[self class] statusAttributes]];
		_titleLabel.numberOfLines = WPContentCellTitleNumberOfLines2 - 1;
	}
	
	if (_countLabel.text != nil) {
		NSRange barRange = [_countLabel.text rangeOfString:@"|"];
		NSMutableAttributedString *countText = [[NSMutableAttributedString alloc] initWithString:_countLabel.text attributes:[[self class] countAttributes]];
		[countText addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide readGrey] range:barRange];
		_countLabel.attributedText = countText;
	}
	
	// 不然文字的宽度不变
	[self layoutSubviews];
	
	_countImageView.hidden = YES;
}


@end
