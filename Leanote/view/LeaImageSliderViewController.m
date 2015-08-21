//
//  LeaImageSliderViewController.m
//  Leanote
//
//  Created by life on 15/7/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "LeaImageSliderViewController.h"
#import "LeaImageViewController.h"

#import "FileService.h"

#import "Common.h"

@interface LeaImageSliderViewController ()
{
	UILabel *_label;
}

@property (nonatomic, strong) UIButton *saveBtn;

@property int count;
@property (strong, nonatomic) NSMutableArray *views;
@end

@implementation LeaImageSliderViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	self.view.backgroundColor = [UIColor blackColor];
	
	// 初始化所有数据
	if(![self createContentPages]) {
		return;
	}
	
	// 设置UIPageViewController的配置项
	NSDictionary *options = @{
							  @"UIPageViewControllerOptionInterPageSpacingKey": [NSNumber numberWithInt:20]
							  };
	
	// 实例化UIPageViewController对象，根据给定的属性
	self.pageController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
														  navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
																		options: options];
	// 设置UIPageViewController对象的代理
	_pageController.dataSource = self;
	
	_pageController.delegate = self;
	
	// 定义“这本书”的尺寸
	[[_pageController view] setFrame:[[self view] bounds]];
	
	// 在页面上，显示UIPageViewController对象的View
	[self addChildViewController:_pageController];
	
	// 让UIPageViewController对象，显示相应的页数据。
	LeaImageViewController *initialViewController = [self viewControllerAtIndex:self.curIndex];// 得到第一页
	if(!initialViewController) {
		[self dismissViewControllerAnimated:YES completion:nil];
		return;
	}
	NSArray *viewControllers = [NSArray arrayWithObject:initialViewController];
	
	[_pageController setViewControllers:viewControllers
							  direction:UIPageViewControllerNavigationDirectionForward
							   animated:YES
							 completion:nil];
	[[self view] addSubview:[_pageController view]];
	
	// 下载按钮
	UIButton *myButton = [UIButton buttonWithType:UIButtonTypeCustom];
	UIImage *image = [[UIImage imageNamed:@"download"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
	[myButton setImage:image forState:UIControlStateNormal];
	//	[myButton setTitle:NSLocalizedString(@"Save as", nil) forState:UIControlStateNormal];
	//	[myButton setTitle:@"可以松手~" forState:UIControlStateHighlighted];
	[myButton addTarget:self action:@selector(saveAs:) forControlEvents:UIControlEventTouchUpInside];
	myButton.tintColor = [UIColor whiteColor];
	//	myButton.backgroundColor = [UIColor yellowColor];
	myButton.frame = CGRectMake(self.view.frame.size.width - 45, self.view.frame.size.height - 45, 25, 25);
	[self.view addSubview:myButton];
	
	myButton.enabled = YES;
	self.saveBtn = myButton;
//	self.saveBtn.hidden = YES;
	
	[self addLabel];
	[self setIndexLabel];
}

- (void) viewWillAppear:(BOOL)animated
{
	// 必须要加, 不然有闪烁
	// 但通过[self setNeedsStatusBarAppearanceUpdate];这种方式隐藏就不会有问题
	// 但需要改leanote-infol.plist啊
	[Common setTimeout:10 callback:^{
		[[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:animated];
	}];

	[super viewWillAppear:animated];
}

-(void) viewWillDisappear:(BOOL)animated
{
	[[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:animated];
	[super viewWillDisappear:animated];
}

-(void)saveAs:(id)sender
{
	LeaImageViewController *vc = [self viewControllerAtIndex:self.curIndex];
	UIImage *img = vc.image;
	if(img) {
		UIImageWriteToSavedPhotosAlbum(img, nil, nil,nil);
		[Common showSuccessMsg:NSLocalizedString(@"Save image successful", nil)];
	}
	//	[self dismissViewControllerAnimated:YES completion:nil];
}


// 初始化所有数据
- (BOOL) createContentPages {
	self.count = [self.urlArr count];
	self.views = [[NSMutableArray alloc] init];
	for(int i = 0; i < self.count; ++i) {
		[self.views addObject:[NSNull null]];
	}
	
	return YES;
}

// 得到相应的VC对象
- (LeaImageViewController *)viewControllerAtIndex:(NSUInteger)index {
	NSString *url = self.urlArr[index];
	if(!url) {
		return nil;
	}
	LeaImageViewController *vc = self.views[index];
	if(vc && ![Common isNull:vc]) {
		return self.views[index];
	}

	// 创建一个新的控制器类，并且分配给相应的数据
	NSURL *u = [NSURL URLWithString:url];
	NSString *fileId = [Common getFileIdFromUrl:url];
	UIImage *img;
	if(fileId) {
		if(fileId) {
			NSString *absPath = [FileService getFileAbsPathByFileIdOrServerFileId:fileId];
			img = [[UIImage alloc] initWithContentsOfFile:absPath];
		}
	}

	vc = [[LeaImageViewController alloc]  initWithImage:img andURL:u];
	self.views[index] = vc;
//	[self.views setValue:vc forKey:index];
	
	vc.willAppear = ^(void) {
//		[self dismissViewControllerAnimated:YES completion:nil];
		// [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:YES];
	};
	return vc;
}

// 根据数组元素值，得到下标值
- (NSUInteger)indexOfViewController:(LeaImageViewController *)viewController {
	return [self.urlArr indexOfObject:[viewController.url absoluteString]];
}

#pragma mark- UIPageViewControllerDataSource

// 返回上一个ViewController对象
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController{
	NSUInteger index = [self indexOfViewController:(LeaImageViewController *)viewController];
	if ((index == 0) || (index == NSNotFound)) {
		return nil;
	}
	index--;
	// 返回的ViewController，将被添加到相应的UIPageViewController对象上。
	// UIPageViewController对象会根据UIPageViewControllerDataSource协议方法，自动来维护次序。
	// 不用我们去操心每个ViewController的顺序问题。
	return [self viewControllerAtIndex:index];
}

// 返回下一个ViewController对象
- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController{

	NSUInteger index = [self indexOfViewController:(LeaImageViewController *)viewController];

	if (index == NSNotFound) {
		return nil;
	}
	index++;
	if (index == self.count) {
		return nil;
	}
	return [self viewControllerAtIndex:index];
}


- (void)pageViewController:(UIPageViewController *)pageViewController
		didFinishAnimating:(BOOL)finished
   previousViewControllers:(NSArray *)previousViewControllers
	   transitionCompleted:(BOOL)completed
{
	if(completed) {
		NSUInteger index = [self indexOfViewController:(LeaImageViewController *)[pageViewController.viewControllers lastObject]];
		self.curIndex = index;
		[self setIndexLabel];
	}
}

- (void) addLabel {
	_label = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
	_label.font = [UIFont fontWithName:@"Helvetica" size:14.0];
	_label.textAlignment = NSTextAlignmentCenter;
	_label.textColor = [UIColor whiteColor];
	
	[self.view addSubview:_label];
}
-(void)setIndexLabel
{
	_label.text = [NSString stringWithFormat:@"%i/%i", self.curIndex + 1, self.count];
}

@end



