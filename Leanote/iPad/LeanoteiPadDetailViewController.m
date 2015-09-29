//
//  LeanoteiPadDetailViewController.m
//  Leanote
//
//  Created by Wong Zigii on 15/9/19.
//  Copyright © 2015年 Leanote. All rights reserved.
//

#import "LeanoteiPadDetailViewController.h"

@interface LeanoteiPadDetailViewController ()

@end

@implementation LeanoteiPadDetailViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemBookmarks
                                                                                          target:self
                                                                                          action:@selector(bookmark)];
}

#pragma mark - Action
- (void)bookmark
{
    NSLog(@"%s",__func__);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
