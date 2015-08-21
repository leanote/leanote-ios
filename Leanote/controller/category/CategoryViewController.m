//
//  CategoryViewController.m
//  Leanote
//
//  Created by life on 15/7/19.
//  Copyright © 2015年 Leanote. All rights reserved.
//

#import "CategoryViewController.h"
#import "NotebookController.h"
#import "TagController.h"
#import "AddNotebookViewController.h"

@interface CategoryViewController ()

@property (strong, nonatomic) UIViewController *currentViewController;

@property NotebookController *notebookView;
@property TagController *tagView;

@end

@implementation CategoryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
	
	[self.segmentControl setTitle:NSLocalizedString(@"Notebook", nil) forSegmentAtIndex:0];
	[self.segmentControl setTitle:NSLocalizedString(@"Tag", nil) forSegmentAtIndex:1];
	
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
										initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
										target:self
										action:@selector(gotoAddNotebook)];
	
	// add viewController so you can switch them later.
	[self setSegmentView];
	
	/*
	vc.view.translatesAutoresizingMaskIntoConstraints = NO;
	// 宽度和view一样
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:vc.view
							   　　attribute:NSLayoutAttributeWidth
							   　　relatedBy:NSLayoutRelationEqual
							   　　toItem:self.view
							   　　attribute:NSLayoutAttributeWidth
							   　　multiplier:1.0
							   　　constant:0]];
	
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:vc.view
							  　　attribute:NSLayoutAttributeTop
							  　　relatedBy:NSLayoutRelationEqual
							  　　toItem:self.view
							  　　attribute:NSLayoutAttributeTop
							  　　multiplier:1.0
							  　　constant:64]];
	[self.view addConstraint:[NSLayoutConstraint constraintWithItem:vc.view
							  　　attribute:NSLayoutAttributeBottomMargin
							  　　relatedBy:NSLayoutRelationEqual
							  　　toItem:self.view
							  　　attribute:NSLayoutAttributeBottomMargin
							  　　multiplier:1.0
							  　　constant:100.0]];
	*/
//	
//	NSLayoutConstraint *constraint = [NSLayoutConstraint
//									  constraintWithItem:vc.view
//									  attribute:NSLayoutAttributeHeight
//									  relatedBy:NSLayoutRelationEqual
//									  toItem:self.view
//									  attribute:NSLayoutAttributeHeight
//									  multiplier:1.0f
//									  constant:0.0f];
 
//	[self.view addConstraint:constraint];
	
//	self.view = vc;
	
    // Do any additional setup after loading the view.
}

- (void)setSegmentView
{
	UIViewController *vc = [self viewControllerForSegmentIndex:self.segmentControl.selectedSegmentIndex];
	[self addChildViewController:vc];
	vc.view.frame = CGRectMake(0, 64,
							   self.view.bounds.size.width,
							   [self getCancelSearchViewHeight]);
	
	[self.view addSubview:vc.view];
	
	self.currentViewController = vc;
	
	// 为了返回的文字
	self.navigationItem.title = vc.title;
}

// 到笔记那一步, 就会让view的y变成64, 导致navigationBar.translucent = NO了
- (void) viewWillAppear:(BOOL)animated
{
	self.navigationController.navigationBar.translucent = YES;
	/*
	if(self.view.frame.origin.y > 0) {
		
	}
	NSLog(@"self.currentViewController.view.frame.origin.y: %f", self.view.frame.origin.y);
	*/
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
	[self setSegmentView];
	/*
	UIViewController *vc = [self viewControllerForSegmentIndex:sender.selectedSegmentIndex];
	[self addChildViewController:vc];
	
	[self.currentViewController.view removeFromSuperview];

	vc.view.frame = CGRectMake(0, 64, self.view.bounds.size.width, 400);
	[self.view addSubview:vc.view];
	
	[vc didMoveToParentViewController:self];
	[self.currentViewController removeFromParentViewController];
	self.currentViewController = vc;
	*/
	
	/*
	// 不要动画
	[self transitionFromViewController:self.currentViewController toViewController:vc duration:0.5 options:UIViewAnimationOptionTransitionNone animations:^{
		[self.currentViewController.view removeFromSuperview];
//		vc.view.frame = self.contentView.bounds;
//		[self.contentView addSubview:vc.view];
		
		vc.view.frame = CGRectMake(0, 64, self.contentView.bounds.size.width, 400);
		//	self.contentView
		[self.view addSubview:vc.view];
		
	} completion:^(BOOL finished) {
		[vc didMoveToParentViewController:self];
		[self.currentViewController removeFromParentViewController];
		self.currentViewController = vc;
	}];
	*/
}

- (UIViewController *)viewControllerForSegmentIndex:(NSInteger)index {
	switch (index) {
		case 0: {
			if(!self.notebookView) {
				self.notebookView = [self.storyboard instantiateViewControllerWithIdentifier:@"Notebook"];
				self.notebookView.delegate = self;
			}
			
			self.navigationItem.rightBarButtonItem.enabled = YES;
			self.navigationItem.rightBarButtonItem.tintColor = [UIColor whiteColor];
			
			return self.notebookView;
		}
		case 1:
		{
			if(!self.tagView) {
				self.tagView = [self.storyboard instantiateViewControllerWithIdentifier:@"Tag"];
				self.tagView.delegate = self;
			}
			
			self.navigationItem.rightBarButtonItem.tintColor = [UIColor clearColor];
			self.navigationItem.rightBarButtonItem.enabled = NO;
			
			return self.tagView;
		}
	}
	return nil;
}

# pragma add
-(void) gotoAddNotebook
{
	AddNotebookViewController *vc = [[AddNotebookViewController alloc] init];
	
	UINavigationController *navController = [[UINavigationController alloc] initWithRootViewController:vc];
	[self.navigationController presentViewController:navController animated:YES completion:nil];
}

#pragma CategoryProtocol

-(CGFloat)getCancelSearchViewHeight
{
	return self.view.bounds.size.height - [[[self tabBarController] tabBar] bounds].size.height - 64;
}

-(CGFloat)getSearchedViewHeight
{
	NSLog(@"tabBar height: %f", [[[self tabBarController] tabBar] bounds].size.height);
	return self.view.bounds.size.height - [[[self tabBarController] tabBar] bounds].size.height - [UIApplication sharedApplication].statusBarFrame.size.height;
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}
@end
