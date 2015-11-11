//
//  WealthTVC.m
//  AlipayFinal
//
//  Created by wushuyu on 14-11-14.
//  Copyright (c) 2014年 wsy.Inc. All rights reserved.
//

#import "MeController.h"

#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/UIImage+Util.h>
#import <WordPress-iOS-Shared/WPFontManager.h>
#import <WordPress-iOS-Shared/WPStyleGuide.h>
#import <WordPress-iOS-Shared/WPTableViewCell.h>
#import <WordPress-iOS-Shared/UITableViewTextFieldCell.h>
#import <WordPress-iOS-Shared/WPTableViewSectionHeaderView.h>

#import "LoginViewController.h"
#import "UserService.h"
#import "SyncService.h"

#import "LeaWebViewController.h"

#import "Common.h"
#import "User.h"

@interface MeController ()
@property (strong, nonatomic) User *curUser;
@property (strong, nonatomic) NSIndexPath *curIndexPath;

@end

NSArray *users;

@implementation MeController

- (id)initWithStyle:(UITableViewStyle)style
{
	self = [super initWithStyle:style];
	if (self) {
		// Custom initialization
	}
	return self;
}

- (void)viewDidLoad
{
	UIBarButtonItem *anotherButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Add account", @"") style:UIBarButtonItemStylePlain target:self action:@selector(addAccount)];
	self.navigationItem.rightBarButtonItem = anotherButton;
	
	[super viewDidLoad];
	
	// table的样式
	[WPStyleGuide configureColorsForView:self.view andTableView:self.tableView];
	
	users = [UserService getUsers];
	
	self.title = NSLocalizedString(@"Me", nil);
}

- (void) viewWillAppear:(BOOL)animated
{
	[self setBarStyle];
}

- (void)didReceiveMemoryWarning
{
	[super didReceiveMemoryWarning];
}

- (void) addUserSync
{
	[Common showProgressWithStatus:NSLocalizedString(@"Add account successful and Synchronizing...", nil)];
	// 同步
	[SyncService incrSync:^(BOOL ok) {
		[Common hideProgress];
	} progress:nil];
}

- (void) notifyChangeUser:(BOOL) isAdd
{
	// 取得ios系统唯一的全局的广播站 通知中心
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	
	// 设置广播内容
	NSString *name = @"设置颜色";
	UIColor *color_ = [UIColor redColor];
	NSDictionary *dict = [NSDictionary dictionaryWithObjectsAndKeys:
						  name, @"ThemeName",
						  color_, @"ThemeColor", nil];
	
	// 将内容封装到广播中 给ios系统发送广播
	// ChangeTheme频道
	[nc postNotificationName:@"changeUser" object:self userInfo:dict];
	NSLog(@"通知发送完闭");
	
	// 本界面刷新
	users = [UserService getUsers];
	[self.tableView reloadData];
	[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]
		withRowAnimation:UITableViewRowAnimationLeft];
	
	// 取消当前的sync
	[SyncService cancelSync];
	
	// UITableViewRowAnimationBottom
	if(isAdd) {
		[self addUserSync];
		// 1s后同步
//		[self performSelector:@selector(addUserSync) withObject:nil afterDelay:1.0f];
	}
	else {
		[self showSuccessMsg:NSLocalizedString(@"Toggle account successful", nil)];
	}
}

// 跳转到登录界面
- (void)addAccount
{
	[self _addAccount:NO];
}
- (void)_addAccount:(BOOL)noAnyUser
{
//	LoginViewController *vc = [[[LoginViewController class] alloc] initWithNote:self.note shouldHideStatusBar:YES];
	
	LoginViewController *loginViewController = [[LoginViewController alloc] init];
	UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:loginViewController];
	navigationController.navigationBar.translucent = NO;
	navigationController.navigationBar.hidden = YES;
	
	[loginViewController fromAddAccount:YES noAnyUser:noAnyUser loginOkCb:^{
		// 成功后, 如果不是之前的用户, 则刷新tableview, 启动incrSync
		// 发广播, 其它table reload table
		[self notifyChangeUser:YES];
		NSLog(@"fromAddAccount");
		// 关闭子view
		[self.presentedViewController dismissViewControllerAnimated:YES completion:nil];
	}];
	loginViewController.hidesBottomBarWhenPushed = YES;

	[self.navigationController presentViewController:navigationController animated:YES completion:nil];
//	[self.navigationController pushViewController:vc animated:YES];
}

#pragma mark tableview protocol

// 可编辑, 因为可删除
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
	// 如果有多个用户, 且当前用户不是active用户, 则可以删除
	if(indexPath.section == 0) {
		User *user = users[indexPath.row];
		if(![user.isActive boolValue]) {
			return YES;
		}
		
		// 如果只有一个用户, 则可以删除
		if ([users count] == 1) {
			return YES;
		}
	}
	return NO;
}

// 单元格操作, 删除
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
	// 删除用户
	if (editingStyle == UITableViewCellEditingStyleDelete) {
		// 弹框是否真的删除?
		User *user = users[indexPath.row];
		self.curUser = user;
		self.curIndexPath = indexPath;
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"Warning", @"")
														message:NSLocalizedString(@"The account's data will be removed, are you sure?", @"")
													   delegate:self
											  cancelButtonTitle:NSLocalizedString(@"NO", @"")
											  otherButtonTitles:NSLocalizedString(@"YES", @""), nil];
		[alert show];
		
//		[self notifyChangeUser];
	}
}


- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
	NSString *title = [alertView buttonTitleAtIndex:buttonIndex];
	if([title isEqualToString:NSLocalizedString(@"NO", @"")])
	{
		NSLog(@"Nothing to do here");
		
		[self setEditing:NO animated:YES];
	}
	else if([title isEqualToString:NSLocalizedString(@"YES", @"")])
	{
		NSLog(@"Delete the cell");
		
		BOOL isActive = [self.curUser.isActive boolValue];
		
		[UserService deleteAllData:self.curUser];
		
		// 如果当前active, 证明是最后一个用户, 删除了要回到login界面
		if (isActive) {
			[self _addAccount:true];
			return;
		}
		
		[self setEditing:NO animated:YES];

		users = [UserService getUsers];
		
		[self.tableView reloadData];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 1)]
					  withRowAnimation:UITableViewRowAnimationLeft];
		
		[self showSuccessMsg:NSLocalizedString(@"Remove account successful", @"")];
	}
}

// 单击row
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
	// 激活用户
	if(indexPath.section == 0) {
		User *user = users[indexPath.row];
		if(![user.isActive boolValue]) {
			[UserService activeUser:user];
			[self notifyChangeUser:NO];
		}
	}
	// normal & markdown
	else if(indexPath.section == 1) {
		
		[UserService setDefaultEditor:![UserService isNormalEditor]];
		[self.tableView reloadSections:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(1, 1)]
					  withRowAnimation:UITableViewRowAnimationLeft];
	}
	// 访问博客
	else {
		LeaWebViewController *webViewController = [[LeaWebViewController alloc] init];
		webViewController.needsLogin = YES;
		User *user = [UserService getCurUser];
		webViewController.host = user.host;
		webViewController.email = user.email;
		webViewController.pwd = user.pwd;
		
//		if(indexPath.row == 0) {
//			webViewController.url = [NSURL URLWithString:[UserService getMyBlogUrl]];
//		}
//		else {
			webViewController.url = [NSURL URLWithString:@"http://lea.leanote.com?from=ios"];
//		}
		[self.navigationController pushViewController:webViewController animated:YES];
	}
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
	return 3;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
	// 有两个id id_subTitle id_rightDetail
	
	//判断在哪个section，设置不同cellid
	NSString *cellid;;
	if (indexPath.section == 0) {
		cellid = @"id_subTitle";
	}
	else {
		cellid = @"id_rightDetail";
	}
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellid];
	
	// 用户
	if (indexPath.section == 0) {
		User *user = users[indexPath.row];
//		cell.imageView.image = [UIImage imageNamed:@"Wea_avatar"];
		[cell.textLabel setText:user.username];
		NSString *desc = [NSString stringWithFormat:@"%@(%@)", user.email, user.host];
		[cell.detailTextLabel setText:desc];
		if([user.isActive boolValue]) {
			cell.accessoryType = UITableViewCellAccessoryCheckmark;
		}
	}
	else if (indexPath.section == 1) {
		//3.0
//		cell.imageView.image=[UIImage imageNamed:@"Wea_wodebaozhang"];
		[cell.textLabel setText:NSLocalizedString(@"Default editor", nil)];
		
		NSString *editor = [UserService isNormalEditor] ? NSLocalizedString(@"Rich text", @"") : NSLocalizedString(@"Markdown", @"");
		[cell.detailTextLabel setText:editor];
	}
	else if (indexPath.section == 2) {
//		if(indexPath.row == 0) {
//			cell.imageView.image=[UIImage imageNamed:@"icon-menu-viewsite"];
//			[cell.textLabel setText:NSLocalizedString(@"Visit my blog", @"")];
//			[cell.detailTextLabel setText:@""];
//		} else {
			cell.imageView.image = [UIImage imageNamed:@"leanote-icon-blue"];
//			cell.imageView.tintColor = [UIColor redColor];
			
			[cell.textLabel setText:@"Lea++"];
			[cell.detailTextLabel setText:@""];
//		}
	}
	return  cell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	if (section == 0) {
		return [users count];
	} else if(section == 1) {
		return 1;
	} else {
		return 1;
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	if (indexPath.section == 0) {
		return 60.;
	}
	else{
		return 49.;
	}
}

-(CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
	return 5;
}

// section title
- (NSString *)titleForHeaderInSection:(NSInteger)section
{
	return @"";
	
	// NSInteger sec = [[self.sections objectAtIndex:section] integerValue];
	if (section == 0) {
		return NSLocalizedString(@"Account", @"Label for the Taxonomy area (categories, keywords, ...) in post settings.");
		
	} else if (section == 1) {
		return NSLocalizedString(@"Settings", @"The grandiose Publish button in the Post Editor! Should use the same translation as core WP.");
	}
	return NSLocalizedString(@"Blog & Lea++", nil);
}

// 必须要这个, 不然viewForHeaderInSection不执行
- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
	return @"Hehe";
}

// 必须要, 不然不好看
- (CGFloat) tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
	return 20.0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
	WPTableViewSectionHeaderView *header = [[WPTableViewSectionHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, CGRectGetWidth(self.view.bounds), 0.0f)];
	header.title = [self titleForHeaderInSection:section];
	header.backgroundColor = self.tableView.backgroundColor;
	return header;
}



@end
