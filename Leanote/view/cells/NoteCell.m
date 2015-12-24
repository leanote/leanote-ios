//
//  NoteCell.m
//  Leanote
//
//  Created by life on 15/6/27.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "NoteCell.h"
#import <WordPress-iOS-Shared/WordPressShared/WPFontManager.h>
#import <WordPress-iOS-Shared/WordPressShared/WPStyleGuide.h>
//#import "NotebookService.h"
#import "Leas.h"

@interface NoteCell()
{
	UILabel *_statusLabel;
	UILabel *_titleLabel;
	UILabel *_dateLabel;
	UILabel *_notebookLabel;
	UIImageView *_dateImageView;
	UIImageView *_notebookImageView;
	UIImageView *_unreadView;
}
@end

@implementation NoteCell


CGFloat const WPContentCellStandardOffset                   = 10.0;
CGFloat const WPContentCellVerticalPadding                  = 10.0;
CGFloat const WPContentCellTitleAndDateVerticalOffset       = 3.0;
CGFloat const WPContentCellLabelAndTitleHorizontalOffset    = -0.5;
CGFloat const WPContentCellAccessoryViewOffset              = 10.0; // 右侧padding
CGFloat const WPContentCellImageWidth                       = 70.0;
CGFloat const WPContentCellTitleNumberOfLines               = 3;
CGFloat const WPContentCellUnreadViewSide                   = 10.0;
CGFloat const WPContentCellUnreadDotSize                    = 8.0;
CGFloat const WPContentCellDateImageSide                    = 16.0;
CGFloat const WPContentCellDefaultOrigin                    = 15.0f;



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
		_titleLabel.numberOfLines = WPContentCellTitleNumberOfLines;
		_titleLabel.lineBreakMode = NSLineBreakByTruncatingTail; // NSLineBreakByWordWrapping; // 省略号
		_titleLabel.font = [[self class] titleFont];
		_titleLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_titleLabel.textColor = [WPStyleGuide littleEddieGrey];
		[self.contentView addSubview:_titleLabel];
		
		_dateLabel = [[UILabel alloc] init];
		_dateLabel.backgroundColor = [UIColor clearColor];
		_dateLabel.textAlignment = NSTextAlignmentLeft;
		_dateLabel.lineBreakMode = NSLineBreakByWordWrapping;
		_dateLabel.font = [[self class] dateFont];
		_dateLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_dateLabel.textColor = [WPStyleGuide allTAllShadeGrey];
		[self.contentView addSubview:_dateLabel];
		
		_dateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"reader-postaction-time"]];
		[_dateImageView sizeToFit];
		[self.contentView addSubview:_dateImageView];
		
		_notebookLabel = [[UILabel alloc] init];
		_notebookLabel.backgroundColor = [UIColor clearColor];
		_notebookLabel.textAlignment = NSTextAlignmentLeft;
		_notebookLabel.lineBreakMode = NSLineBreakByTruncatingTail;
		_notebookLabel.font = [[self class] dateFont];
		_notebookLabel.shadowOffset = CGSizeMake(0.0, 0.0);
		_notebookLabel.textColor = [WPStyleGuide allTAllShadeGrey];
		[self.contentView addSubview:_notebookLabel];
		
		_notebookImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"notebook3"]];
		[_dateImageView sizeToFit];
		[self.contentView addSubview:_notebookImageView];
		
		/*
		if ([[self class] supportsUnreadStatus]) {
			_unreadView = [[UIImageView alloc] init];
			
			// create circular image
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(WPContentCellUnreadViewSide, WPContentCellUnreadViewSide), NO, 0);
			CGContextRef context = UIGraphicsGetCurrentContext();
			CGContextAddPath(context, [UIBezierPath bezierPathWithRoundedRect:CGRectMake(0,0, WPContentCellUnreadDotSize, WPContentCellUnreadDotSize) cornerRadius:3.0].CGPath);
			
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
	
	CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:self.note maxWidth:maxWidth];
	CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:self.note previousFrame:statusFrame maxWidth:maxWidth];
	CGRect dateFrame = [[self class] dateLabelFrameForContentProvider:self.note previousFrame:titleFrame maxWidth:maxWidth];
	
	CGRect notebookFrame = [[self class] notebookLabelFrameForContentProvider:_notebookLabel.text previousFrame:dateFrame
			maxWidth:maxWidth];
	
	// Center title and date frame if Gravatar is shown
	/*
	if ([[self class] showGravatarImage] && CGRectGetMaxY(dateFrame) < CGRectGetMaxY(_gravatarImageView.frame)) {
		CGFloat heightOfControls = CGRectGetMaxY(dateFrame) - CGRectGetMinY(statusFrame);
		CGFloat startingYForCenteredControls = floorf((CGRectGetHeight(_gravatarImageView.frame) - heightOfControls)/2.0) + CGRectGetMinY(_gravatarImageView.frame);
		CGFloat offsetToCenter = MIN(CGRectGetMinY(statusFrame) - startingYForCenteredControls, 0);
		
		statusFrame.origin.y -= offsetToCenter;
		titleFrame.origin.y -= offsetToCenter;
		dateFrame.origin.y -= offsetToCenter;
	}
	*/
	
	_statusLabel.frame = statusFrame;
	_titleLabel.frame = titleFrame;
	_dateLabel.frame = dateFrame;
	_notebookLabel.frame = notebookFrame;
	_unreadView.frame = [[self class] unreadFrameForHeight:CGRectGetHeight(self.bounds)];
	
	// layout date image
	_dateImageView.hidden = !(_dateLabel.text.length > 0);
	if (!_dateImageView.hidden) {
		_dateImageView.frame = CGRectMake(CGRectGetMinX(dateFrame) - WPContentCellDateImageSide - 2, CGRectGetMidY(dateFrame) - WPContentCellDateImageSide / 2.0, WPContentCellDateImageSide, WPContentCellDateImageSide);
	}
	
	_notebookImageView.frame = CGRectMake(
										  CGRectGetMaxX(dateFrame),
										  CGRectGetMidY(dateFrame) - WPContentCellDateImageSide / 2.0,
										  WPContentCellDateImageSide,
										  WPContentCellDateImageSide);
}

// 行高
+ (CGFloat)rowHeightForContentProvider:(Note *)note andWidth:(CGFloat)width
{
	CGRect statusFrame = [[self class] statusLabelFrameForContentProvider:note maxWidth:width];
	CGRect titleFrame = [[self class] titleLabelFrameForContentProvider:note previousFrame:statusFrame maxWidth:width];
	CGRect dateFrame = [[self class] dateLabelFrameForContentProvider:note previousFrame:titleFrame maxWidth:width];
	
//	return MAX(CGRectGetMaxY(gravatarFrame), CGRectGetMaxY(dateFrame)) + WPContentCellVerticalPadding;
	
	return CGRectGetMaxY(dateFrame) + WPContentCellVerticalPadding;
}

+ (BOOL)shortDateString
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

+ (NSString *)statusTextForContentProvider:(Note *) note
{
	if([note.isDirty boolValue]) {
		long status = [note.status integerValue];
		if(status == -1) {
			return NSLocalizedString(@"Syncing...", nil);
		}
		return NSLocalizedString(@"Need sync", nil);
	}
	return @"";
};

+ (UIColor *)statusColorForContentProvider:(Note *) note
{
	return [WPStyleGuide jazzyOrange];
}

+ (UIFont *)titleFont
{
	return [WPFontManager openSansRegularFontOfSize:14.0];
}


+ (UIFont *)titleFontBold
{
	return [WPFontManager openSansBoldFontOfSize:14.0];
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

+ (NSAttributedString *)titleAttributedTextForContentProvider:(Note *)note
{
	// remove new lines from title
	NSString *titleText = [Common isBlankString:note.title] ? NSLocalizedString(@"Untitled", nil) : note.title;
	return [[NSAttributedString alloc] initWithString:titleText attributes:[self titleAttributes]];
}

+ (UIFont *)dateFont
{
	return [WPStyleGuide subtitleFont];
}

+ (NSDictionary *)dateAttributes
{
	return [WPStyleGuide subtitleAttributes];
}

+ (NSString *)dateTextForContentProvider:(Note *) note
{
	NSDateFormatter *dateFormatter2 = [[NSDateFormatter alloc] init];
	
	// 如果当前语言是英文
	if([NSLocalizedString(@"YES", nil) isEqualToString:@"YES"]) {
		[dateFormatter2 setDateFormat:@"MM-dd-yyyy HH:mm"];
	}
	else {
		[dateFormatter2 setDateFormat:@"yyyy-MM-dd HH:mm"];
	}
	
	return [NSString stringWithFormat:@"%@ %@", [dateFormatter2 stringFromDate:note.updatedTime], @""];
	
	NSDate *date = note.updatedTime;
	
	static NSDateFormatter *dateFormatter = nil;
	
	if (dateFormatter == nil) {
		dateFormatter = [[NSDateFormatter alloc] init];
		[dateFormatter setTimeStyle:NSDateFormatterShortStyle];
		[dateFormatter setDateStyle:NSDateFormatterMediumStyle];
	}
	
	return [dateFormatter stringFromDate:date];
}


#pragma private

+ (CGFloat)textWidth:(CGFloat)maxWidth
{
	CGFloat padding = 0.0;
	padding += [[self class] textXOrigin];  // left padding
	padding += WPContentCellStandardOffset + WPContentCellAccessoryViewOffset; // right padding
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
		return ([[self class] gravatarXOrigin] + WPContentCellImageWidth + WPContentCellStandardOffset);
	}
	
	return WPContentCellDefaultOrigin;
}

+ (CGFloat)gravatarXOrigin
{
	return [[self class] contentXOrigin];
}


+ (CGRect)statusLabelFrameForContentProvider:(Note *)note maxWidth:(CGFloat)maxWidth
{
	NSString *statusText = [self statusTextForContentProvider:note]; // [note.isDirty boolValue] ? @"未同步" : @"已同步";
	if ([statusText length] != 0) {
		CGSize size;
		size = [statusText boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] statusAttributes] context:nil].size;
		
		return CGRectMake([[self class] textXOrigin], WPContentCellVerticalPadding, size.width, size.height);
	}
	
	// 如果没有, 则不显示
	return CGRectMake(0, WPContentCellVerticalPadding, 0, 0);
}

+ (CGRect)titleLabelFrameForContentProvider:(Note *)note previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
	BOOL hasStatus = YES;
	
	CGSize size;
	NSAttributedString *attributedTitle = [[self class] titleAttributedTextForContentProvider:note];
	CGFloat lineHeight = attributedTitle.size.height;
	size = [attributedTitle boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth], CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin context:nil].size;
	size.height = ceilf(MIN(size.height, lineHeight * (WPContentCellTitleNumberOfLines - (hasStatus ? 1 : 0)))) + 1;
	
	CGFloat offset = -2.0; // Account for line height of title
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset += WPContentCellTitleAndDateVerticalOffset;
	}
	
	return CGRectIntegral(CGRectMake([[self class] textXOrigin], CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)dateLabelFrameForContentProvider:(Note *)note previousFrame:(CGRect)previousFrame maxWidth:(CGFloat)maxWidth
{
	CGSize size;
	size = [[[self class] dateTextForContentProvider:note] boundingRectWithSize:CGSizeMake([[self class] textWidth:maxWidth] - WPContentCellDateImageSide, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:[[self class] dateAttributes] context:nil].size;
	
	CGFloat offset = 0.0;
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset = WPContentCellTitleAndDateVerticalOffset;
	}
	
	return CGRectIntegral(CGRectMake([[self class] textXOrigin] + WPContentCellDateImageSide, CGRectGetMaxY(previousFrame) + offset, size.width, size.height));
}

+ (CGRect)notebookLabelFrameForContentProvider:(NSString *)title
								 previousFrame:(CGRect)previousFrame
									  maxWidth:(CGFloat)maxWidth
{
	CGSize size;
	// TODO
	size = [title boundingRectWithSize:CGSizeMake(
												  [[self class] textWidth:maxWidth] - WPContentCellDateImageSide, CGFLOAT_MAX)
							   options:NSStringDrawingUsesLineFragmentOrigin
							attributes:[[self class] dateAttributes] context:nil].size;
	
	CGFloat offset = 0.0;
	if (!CGSizeEqualToSize(previousFrame.size, CGSizeZero)) {
		offset = WPContentCellTitleAndDateVerticalOffset;
	}
	
	CGFloat _max = maxWidth - 160; // 这里, 不然长度超出了
	if(size.width > _max) {
		size.width = _max;
	}
	
	return CGRectIntegral(CGRectMake(CGRectGetMaxX(previousFrame) + WPContentCellDateImageSide,
									 CGRectGetMinY(previousFrame) - 2, // 自从减了160, 就下移了, 不知道为什么
									 size.width, size.height + 2));
}

+ (CGRect)unreadFrameForHeight:(CGFloat)height
{
	CGFloat side = WPContentCellUnreadViewSide;
	return CGRectMake(([[self class] gravatarXOrigin] - side) / 2.0, (height - side) / 2.0 , side, side);
}


- (void)setNote:(Note *) note
{
	_note = note;

	_titleLabel.attributedText = [[self class] titleAttributedTextForContentProvider:note];
	
	_statusLabel.text = [[self class] statusTextForContentProvider:note];
	_statusLabel.textColor = [[self class] statusColorForContentProvider:note];
	_dateLabel.text = [[self class] dateTextForContentProvider:note];
	_notebookLabel.text = [Leas.notebook getNotebookTitleByNotebookId:note.notebookId];
	
	if (_statusLabel.text != nil) {
		_statusLabel.attributedText = [[NSAttributedString alloc] initWithString:_statusLabel.text attributes:[[self class] statusAttributes]];
		_titleLabel.numberOfLines = WPContentCellTitleNumberOfLines - 1;
	}
	
	if (_dateLabel.text != nil) {
		NSRange barRange = [_dateLabel.text rangeOfString:@"|"];
		NSMutableAttributedString *dateText = [[NSMutableAttributedString alloc] initWithString:_dateLabel.text attributes:[[self class] dateAttributes]];
		[dateText addAttribute:NSForegroundColorAttributeName value:[WPStyleGuide readGrey] range:barRange];
		_dateLabel.attributedText = dateText;
	}
	
	// 不然文字的宽度不变
	[self layoutSubviews];
}


@end
