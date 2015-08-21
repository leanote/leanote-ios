//
//  Leanote
//
//  Created by life on 03/06/15.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "CategoryTab.h"
#import "NotebookController.h"

@interface CategoryTab ()

@end

@implementation CategoryTab


- (void)viewDidLoad
{
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    // 设置图片
    if (!self.tabbarItemImagePath) { //如果没有设置过图片则设置
        self.tabbarItemImagePath = @"tabbed_icon.bundle/cate-icon";
        [self setTabBarImage];
		
		self.title = NSLocalizedString(@"Category", nil);
		
		/*
		NotebookControllerForTest *a = [[NotebookControllerForTest alloc] init];
		// [self initWithRootViewController:a];
		
		[self initWithRootViewController:[self.storyboard instantiateViewControllerWithIdentifier:@"Notebook"]];
		*/
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



@end
