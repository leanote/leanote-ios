//
//  LeaImageSliderViewController.h
//  Leanote
//
//  Created by life on 15/7/28.
//  Copyright (c) 2015 Leanote.com. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LeaImageSliderViewController : UIViewController<UIPageViewControllerDataSource>{
}

@property (strong, nonatomic) UIPageViewController *pageController;
@property (strong, nonatomic) NSArray *pageContent;

@property (strong, nonatomic) NSArray *urlArr;
@property (strong, nonatomic) NSString *curUrl;
@property NSUInteger curIndex;

-(void)setUrlArr:(NSArray *)urlArr;

@end