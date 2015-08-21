//
//  RootTabBarController.m
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "RootTabBarController.h"

@interface RootTabBarController ()

@end

@implementation RootTabBarController

- (void)viewDidLoad
{
    [super viewDidLoad];
    // 把它下面的viewcontroller都加载了,强制显示tabbarImage
    UIViewController * i;
    for (i in self.viewControllers) {
        [i viewDidLoad];
    }
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
