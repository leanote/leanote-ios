//
//  BaseViewController.h
//  Leanote
//
//  Created by life on 15/6/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIViewController(BaseViewController)

// 是否是在search状态
@property BOOL isSelectOnSearch;

-(void) showProgress;
-(void) hideProgress;
-(void) showErrorMsg:(NSString *) baseMsg ret:(id)ret;
-(void) showSuccessMsg:(NSString *)msg;
-(void) beautifySearchBar;
- (void) beautifySearchBar:(UISearchDisplayController *)controller;
-(void) setBarStyle;
-(void) restoreBarStyle;
-(void) setBarStyleBlack;
//-(void) setBarStyleBlackWhenIsSearch;
-(void) alert:(NSString *)msg;
-(void) setTableStyle:(UITableView *) tableView;
-(UIView *) iniNoResultView:(UITableView *) tableView;
@end
