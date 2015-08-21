//
//  LeaImagePagerViewController.m
//  Leanote
//
//  Created by life on 15/7/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import "LeaImagePagerViewController.h"

static CGFloat SCREEN_WIDTH;
static CGFloat SCREEN_HEIGHT;
static CGFloat const MaximumZoomScale = 4.0;
static CGFloat const MinimumZoomScale = 0.1;

#define IMAGEVIEW_COUNT 3

@interface LeaImagePagerViewController ()<UIScrollViewDelegate>{
	UIScrollView *_scrollView;
	UIImageView *_leftImageView;
	UIImageView *_centerImageView;
	UIImageView *_rightImageView;
	UIPageControl *_pageControl;
	UILabel *_label;
	NSMutableDictionary *_imageData;//图片数据
	int _currentImageIndex;//当前图片索引
	int _imageCount;//图片总数
}

@end

@implementation LeaImagePagerViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	
	SCREEN_WIDTH = self.view.frame.size.width;
	SCREEN_HEIGHT = self.view.frame.size.height;
	
	//加载数据
	[self loadImageData];
	//添加滚动控件
	[self addScrollView];
	//添加图片控件
	[self addImageViews];
	//添加分页控件
	[self addPageControl];
	//添加图片信息描述控件
	[self addLabel];
	//加载默认图片
	[self setDefaultImage];
}

- (UIImage *)getImage:(int)i
{
	NSArray *arr = @[@"download", @"bold", @"italic"];
	i = i % 3;
	return [UIImage imageNamed:arr[i]];
}

-(NSString *)getTitle:(int)i
{
	return [NSString stringWithFormat:@"HEHE %i", i];
}

#pragma mark 加载图片数据
-(void)loadImageData {
	_imageCount = 3;
}

#pragma mark 添加控件
-(void)addScrollView {
	_scrollView=[[UIScrollView alloc]initWithFrame:[UIScreen mainScreen].bounds];
	
	[self.view addSubview:_scrollView];
	_scrollView.maximumZoomScale = MaximumZoomScale;
	_scrollView.minimumZoomScale = MinimumZoomScale;
	
	// 设置代理
	_scrollView.delegate=self;
	// 设置contentSize
	_scrollView.contentSize=CGSizeMake(IMAGEVIEW_COUNT*SCREEN_WIDTH, SCREEN_HEIGHT) ;
	// 设置当前显示的位置为中间图片
	[_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:NO];
	// 设置分页
	_scrollView.pagingEnabled=YES;
	//去掉滚动条
	_scrollView.showsHorizontalScrollIndicator=NO;

}

#pragma mark 添加图片三个控件
-(void)addImageViews{
	_leftImageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
	_leftImageView.contentMode = UIViewContentModeScaleAspectFit;
	_leftImageView.userInteractionEnabled = YES;
	[_scrollView addSubview:_leftImageView];
	
	// 位置变了
	_centerImageView = [[UIImageView alloc]initWithFrame:CGRectMake(SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
	_centerImageView.contentMode = UIViewContentModeScaleAspectFit;
	_centerImageView.userInteractionEnabled = YES;
	[_scrollView addSubview:_centerImageView];
	
	_rightImageView = [[UIImageView alloc]initWithFrame:CGRectMake(2 * SCREEN_WIDTH, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
	_rightImageView.contentMode = UIViewContentModeScaleAspectFit;
	[_scrollView addSubview:_rightImageView];
	
	// 双击
	UITapGestureRecognizer *tgr2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleImageDoubleTapped:)];
	[tgr2 setNumberOfTapsRequired:2];
	[_centerImageView addGestureRecognizer:tgr2];
	
//	[_leftImageView sizeToFit];
//	_scrollView.zoomScale = _scrollView.minimumZoomScale;
//	_scrollView.contentSize = _leftImageView.image.size;
//	[self centerImage];
}

- (void)centerImage
{
	CGFloat scaleWidth = CGRectGetWidth(_scrollView.frame) / _leftImageView.image.size.width;
	CGFloat scaleHeight = CGRectGetHeight(_scrollView.frame) / _leftImageView.image.size.height;
	
	_scrollView.minimumZoomScale = MIN(scaleWidth, scaleHeight);
	_scrollView.zoomScale = _scrollView.minimumZoomScale;
	
	[self scrollViewDidZoom:_scrollView];
}

- (void)scrollViewDidZoom:(UIScrollView *)scrollView
{
	CGSize size = scrollView.frame.size;
	CGRect frame = _leftImageView.frame;
	
	if (frame.size.width < size.width) {
		frame.origin.x = (size.width - frame.size.width) / 2;
	} else {
		frame.origin.x = 0;
	}
	
	if (frame.size.height < size.height) {
		frame.origin.y = (size.height - frame.size.height) / 2;
	} else {
		frame.origin.y = 0;
	}
	
	_leftImageView.frame = frame;
}

// 双击缩放
- (void)handleImageDoubleTapped:(UITapGestureRecognizer *)tgr
{
	if (_scrollView.zoomScale > _scrollView.minimumZoomScale) {
		//[_scrollView setZoomScale:_scrollView.minimumZoomScale animated:YES];
		//return;
	}
	
	CGPoint point = [tgr locationInView:_centerImageView];
	CGSize size = _scrollView.frame.size;
	
	CGFloat w = size.width / _scrollView.maximumZoomScale;
	CGFloat h = size.height / _scrollView.maximumZoomScale;
	CGFloat x = point.x - (w / 2.0f);
	CGFloat y = point.y - (h / 2.0f);
	
	CGRect rect = CGRectMake(x, y, w, h);
	[_scrollView zoomToRect:rect animated:YES];
}

#pragma mark 设置默认显示图片
-(void)setDefaultImage {
	// 加载默认图片
	_leftImageView.image = [self getImage:_imageCount-1]; // [UIImage imageNamed:[NSString stringWithFormat:@"%i.jpg",_imageCount-1]];
	_centerImageView.image = [self getImage:0];
	_rightImageView.image = [self getImage:1];
	
	_currentImageIndex = 0;
	
	// 设置当前页
	_pageControl.currentPage = _currentImageIndex;
	_label.text = [self getTitle:_currentImageIndex];
}

#pragma mark 添加分页控件
-(void)addPageControl{
	_pageControl = [[UIPageControl alloc]init];
	//注意此方法可以根据页数返回UIPageControl合适的大小
	CGSize size = [_pageControl sizeForNumberOfPages:_imageCount];
	_pageControl.bounds=CGRectMake(0, 0, size.width, size.height);
	_pageControl.center=CGPointMake(SCREEN_WIDTH/2, SCREEN_HEIGHT-100);
	//设置颜色
	_pageControl.pageIndicatorTintColor = [UIColor colorWithRed:193/255.0 green:219/255.0 blue:249/255.0 alpha:1];
	//设置当前页颜色
	_pageControl.currentPageIndicatorTintColor = [UIColor colorWithRed:0 green:150/255.0 blue:1 alpha:1];
	//设置总页数
	_pageControl.numberOfPages=_imageCount;
	
	[self.view addSubview:_pageControl];
}

#pragma mark 添加信息描述控件
-(void)addLabel{
	
	_label=[[UILabel alloc]initWithFrame:CGRectMake(0, 10, SCREEN_WIDTH,30)];
	_label.textAlignment=NSTextAlignmentCenter;
	_label.textColor=[UIColor colorWithRed:0 green:150/255.0 blue:1 alpha:1];
	
	[self.view addSubview:_label];
}

#pragma mark 滚动停止事件
-(void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView{
	//重新加载图片
	[self reloadImage];
	//移动到中间
	[_scrollView setContentOffset:CGPointMake(SCREEN_WIDTH, 0) animated:NO];
	//设置分页
	_pageControl.currentPage=_currentImageIndex;
	//设置描述
	_label.text = [self getTitle:_currentImageIndex];
}

#pragma mark 重新加载图片
-(void)reloadImage
{
	int leftImageIndex, rightImageIndex;
	CGPoint offset = [_scrollView contentOffset];
	if (offset.x > SCREEN_WIDTH) { // 向右滑动
		_currentImageIndex = (_currentImageIndex+1)%_imageCount;
	}
	else if(offset.x <SCREEN_WIDTH){ // 向左滑动
		_currentImageIndex = (_currentImageIndex+_imageCount-1)%_imageCount;
	}
	
	// UIImageView *centerImageView=(UIImageView *)[_scrollView viewWithTag:2];
	_centerImageView.image = [self getImage:_currentImageIndex];
	
	// 重新设置左右图片
	leftImageIndex = (_currentImageIndex + _imageCount - 1) % _imageCount;
	rightImageIndex = (_currentImageIndex + 1) % _imageCount;
	_leftImageView.image = [self getImage:leftImageIndex];
	_rightImageView.image = [self getImage:rightImageIndex];
}

@end
