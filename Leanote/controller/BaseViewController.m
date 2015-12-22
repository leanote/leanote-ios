//
//  BaseViewController.m
//  Leanote
//
//  Created by life on 15/6/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "BaseViewController.h"
#import "SVProgressHUD.h"
#import "ApiMsg.h"

#import "Common.h"
#import <WordPress-iOS-Shared/WordPressShared/WPStyleGuide.h>
#import <objc/runtime.h>

NSString const *key = @"isSelectOnSearchKey";

@implementation UIViewController(BaseViewController)

- (void)setIsSelectOnSearch:(BOOL)ok
{
	NSString *okStr = @"";
	if(ok) {
		okStr = @"1";
	}
	objc_setAssociatedObject(self, &key, okStr, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (BOOL)isSelectOnSearch
{
	NSString *okStr = objc_getAssociatedObject(self, &key);
	if([okStr isEqualToString:@"1"]) {
		return YES;
	}
	return NO;
}

-(void) showProgress
{
	[Common showProgress];
}
-(void) hideProgress
{
	[Common hideProgress];
}

-(void) showSuccessMsg:(NSString *)msg
{
	[SVProgressHUD showSuccessWithStatus:msg];
}

-(void) showErrorMsg:(NSString *) baseMsg ret:(id)ret
{
	// tips 提示同步失败
	NSString *msg = [ApiMsg getMsg:ret];
	NSString *errMsg;
	if(msg) {
		errMsg = [NSString stringWithFormat:@"%@: %@", baseMsg, msg];
	}
	else {
		errMsg = baseMsg;
	}
	
	[SVProgressHUD showErrorWithStatus:errMsg];
}

- (void) beautifySearchBar
{
	[self beautifySearchBar:self.searchDisplayController];
}

- (void) beautifySearchBar: (UISearchDisplayController *)controller
{
	UITextField *searchField;
	if ([[[UIDevice currentDevice] systemVersion] floatValue]<7.0)
		searchField=[self.searchDisplayController.searchBar.subviews objectAtIndex:1];
	else
		searchField=[((UIView *)[controller.searchBar.subviews objectAtIndex:0]).subviews lastObject];
	//	searchField.hidden = YES;
	
	// 设置search bar的背景色, 需要先删除之前的, 不然设置了后不明显
	// http://stackoverflow.com/questions/10532995/how-to-change-color-of-search-bar
	[self removeUISearchBarBackgroundInViewHierarchy:controller.searchBar];
	controller.searchBar.backgroundColor = [UIColor colorWithRed:235.0/255 green:236.0/255 blue:237.0/255 alpha:1.0];
	
	/*
	 CGRect frame = self.searchDisplayController.searchBar.frame;
	 frame.size.height = 30;
	 self.searchDisplayController.searchBar.frame = frame;
	 */

}

// 删除search bar的背景
- (void) removeUISearchBarBackgroundInViewHierarchy:(UIView *)view
{
	for (UIView *subview in [view subviews]) {
		if ([subview isKindOfClass:NSClassFromString(@"UISearchBarBackground")]) {
			[subview removeFromSuperview];
			break; //To avoid an extra loop as there is only one UISearchBarBackground
		} else {
			[self removeUISearchBarBackgroundInViewHierarchy:subview];
		}
	}
}

-(void)setBarStyle
{
	if(self.isSelectOnSearch && !IS_IPAD) {
		[self setBarStyleBlack];
	}
	else {
		[self restoreBarStyle];
	}
}

-(void)restoreBarStyle
{
	NSLog(@"restoreBarStyle");
	// 亮色, 恢复
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
}

-(void)setBarStyleBlackWhenIsSearch
{
	if(self.isSelectOnSearch) {
		[self setBarStyleBlack];
	}
}

-(void)setBarStyleBlack
{
	NSLog(@"setBarStyleBlack");
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
}

-(void)alert:(NSString *)msg
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Tip", nil)
													message:msg
												   delegate:nil
										  cancelButtonTitle:nil
										  otherButtonTitles:NSLocalizedString(@"OK", nil), nil];
	[alert show];
}

-(void) setTableStyle:(UITableView *) tableView
{
	// table的样式
	[WPStyleGuide configureColorsForView:self.view andTableView:tableView];
	// footer不要有分割线, 防止断片
	tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, 0.0, 44.0)]; // add some vertical padding
	
	// 为了解决左侧少15px 分隔线
	if ([tableView respondsToSelector:@selector(setSeparatorInset:)]) {
		[tableView setSeparatorInset:UIEdgeInsetsZero];
	}
	
	if ([tableView respondsToSelector:@selector(setLayoutMargins:)]) {
		[tableView setLayoutMargins:UIEdgeInsetsZero];
	}
}

-(UIView *) iniNoResultView:(UITableView *) tableView
{
	UIView *nomatchesView = [[UIView alloc] initWithFrame:self.view.frame];
	nomatchesView.backgroundColor = [UIColor clearColor];
	
	UILabel *matchesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 320)];
	//	matchesLabel.font = [UIFont boldSystemFontOfSize:18];
	matchesLabel.minimumScaleFactor = 14.0f;
	matchesLabel.numberOfLines = 1;
	matchesLabel.lineBreakMode = NSLineBreakByWordWrapping;
	matchesLabel.shadowColor = [UIColor lightTextColor];
	matchesLabel.textColor = [UIColor grayColor];
	matchesLabel.shadowOffset = CGSizeMake(0, 1);
	matchesLabel.backgroundColor = [UIColor clearColor];
	matchesLabel.textAlignment =  NSTextAlignmentCenter;
	
	//Here is the text for when there are no results
	matchesLabel.text = NSLocalizedString(@"No Data", nil);
	[nomatchesView addSubview:matchesLabel];
	
	nomatchesView.hidden = YES;
	
//	[tableView insertSubview:nomatchesView belowSubview:tableView];
	[tableView addSubview:nomatchesView];
	return nomatchesView;
}

// 为了解决分隔线左侧少15px的情况, iphone, ipad都会存在

-(void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
	if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
		[cell setSeparatorInset:UIEdgeInsetsZero];
	}

	if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
		[cell setLayoutMargins:UIEdgeInsetsZero];
	}
}

@end
