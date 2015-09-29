//
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "BlogTab.h"
#import "NoteController.h"

@interface BlogTab ()

@end

@implementation BlogTab

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (!self.tabbarItemImagePath) { //如果没有设置过图片则设置
        self.tabbarItemImagePath = @"tabbed_icon.bundle/blog4";
        [self setTabBarImage];
		
		NoteController *view = [self.storyboard instantiateViewControllerWithIdentifier:@"Note"];
		view.isBlog = YES;
        [self.navigationController initWithRootViewController:view];
		
		self.title = NSLocalizedString(@"Post", nil);
    }
	else {
        return; 
    }
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
