//
//  DRColorPickerHueView.m
//
//  Created by Jeff on 8/10/14.
//  Copyright (c) 2014 Digital Ruby, LLC. All rights reserved.
//
/*
 The MIT License (MIT)

 Copyright (c) 2014 Digital Ruby, LLC

 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:

 The above copyright notice and this permission notice shall be included in
 all copies or substantial portions of the Software.

 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 THE SOFTWARE.
 */

#import "DRColorPickerHueView.h"
#import "DRColorPicker.h"

#define DR_COLOR_PICKER_HUE_VIEW_PAGE_COUNT 12

@interface DRColorPickerHueView ()

@property (nonatomic, strong) UIImageView* hueBar;
@property (nonatomic, strong) UIImageView* hueIndicator;
@property (nonatomic, strong) NSMutableArray* hueColors;
@property (nonatomic, assign) NSInteger lastPage;

@end

@implementation DRColorPickerHueView

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]) == nil) { return nil; }

    self.hueGrid = [[DRColorPickerGridView alloc] init];
    __weak DRColorPickerHueView* weakSelf = self;
    self.hueGrid.scrolledBlock = ^
    {
        [weakSelf updatePage];
    };
    [self addSubview:self.hueGrid];

    UIImage* hueBarImage = DRColorPickerImage(@"images/common/drcolorpicker-color-bar.png");
    self.hueBar = [[UIImageView alloc] initWithImage:hueBarImage];
    self.hueBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    self.hueBar.userInteractionEnabled = YES;
    UITapGestureRecognizer* tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hueBarTapped:)];
    [self.hueBar addGestureRecognizer:tapGesture];
    UIPanGestureRecognizer* panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(hueBarPanned:)];
    [self.hueBar addGestureRecognizer:panGesture];
    [self addSubview:self.hueBar];

    self.hueIndicator = [[UIImageView alloc] initWithImage:DRColorPickerImage(@"images/common/drcolorpicker-brightnessguide.png")];
    self.hueIndicator.layer.shadowColor = [UIColor blackColor].CGColor;
    self.hueIndicator.layer.shadowOffset = CGSizeZero;
    self.hueIndicator.layer.shadowRadius = 1;
    self.hueIndicator.layer.shadowOpacity = 0.8f;
    self.hueIndicator.layer.shouldRasterize = YES;
    self.hueIndicator.layer.rasterizationScale = UIScreen.mainScreen.scale;
    [self addSubview:self.hueIndicator];

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self handleFrameChange];

    return self;
}

- (void) setFrame:(CGRect)f
{
    self.lastPage = self.hueGrid.page;

    super.frame = f;

    [self handleFrameChange];
}

- (void) updatePage
{
    if (self.hueGrid.contentSize.width <= 0.0f || self.hueGrid.contentSize.height <= 0.0f)
    {
        return;
    }

    CGFloat hueSize = self.hueBar.bounds.size.width / DR_COLOR_PICKER_HUE_VIEW_PAGE_COUNT;
    CGFloat pages = (self.hueGrid.contentSize.width - self.hueGrid.bounds.size.width);
    if (pages < 1.0f)
    {
        return;
    }
    CGFloat percent = self.hueGrid.contentOffset.x / pages;
    CGFloat trackWidth = self.hueBar.bounds.size.width - hueSize;
    CGPoint center = CGPointMake(self.hueBar.frame.origin.x + (hueSize * 0.5f) + (trackWidth * percent), self.hueBar.center.y);
    self.hueIndicator.center = center;
}

- (void) handleFrameChange
{
    if (self.hueGrid == nil)
    {
        return;
    }

    NSInteger page = self.lastPage;
    CGFloat hueBarPadding = 10.0f;
    CGFloat hueBarHeight = 44.0f;
    self.hueBar.frame = CGRectMake(hueBarPadding, self.bounds.size.height - hueBarPadding - hueBarHeight, self.bounds.size.width - hueBarPadding - hueBarPadding, hueBarHeight);
    self.hueGrid.frame = CGRectMake(0.0f, 0.0f, self.bounds.size.width, self.bounds.size.height - hueBarPadding - hueBarHeight - hueBarPadding);
    [self.hueGrid.drCollectionViewLayout calculatePages];
    [self createDataSource];

    // restore the page
    CGFloat newX = page * self.hueGrid.bounds.size.width;
    [self.hueGrid setContentOffset:CGPointMake(newX, 0.0f) animated:NO];

    // do this after the next run loop to allow the hueGrid to lay itself out and get it's content offset sorted out
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^
    {
        [self updatePage];
    });
}

- (void) createDataSource
{
    if (self.hueGrid.collectionViewLayout == nil)
    {
        return;
    }

    self.hueColors = [NSMutableArray array];

    CGFloat luminosityMultiplier = 1.0f / (CGFloat)(self.hueGrid.drCollectionViewLayout.rows * 2);
    CGFloat saturationMultiplier = 1.0f / (CGFloat)(self.hueGrid.drCollectionViewLayout.columns * 2);

    for (NSInteger i = 0 ; i < DR_COLOR_PICKER_HUE_VIEW_PAGE_COUNT; i++)
    {
        CGFloat hue = i * 30 / 360.0;
        for (NSInteger x = 0; x < self.hueGrid.drCollectionViewLayout.itemsPerPage; x++)
        {
            NSInteger row = x / self.hueGrid.drCollectionViewLayout.columns;
            NSInteger column = x % self.hueGrid.drCollectionViewLayout.columns;

            CGFloat saturation = (column * saturationMultiplier) + 0.25f;
            CGFloat luminosity = 1.0f - (row * luminosityMultiplier);
            UIColor* color = [UIColor colorWithHue:hue saturation:saturation brightness:luminosity alpha:1.0];
            [self.hueColors addObject:[[DRColorPickerColor alloc] initWithColor:color]];
        }
    }

    [self.hueGrid setColors:self.hueColors];
    [self updatePage];
}

- (void) scrollFromColorBarPoint:(CGPoint)p
{
    NSInteger page = p.x / (self.hueBar.bounds.size.width / DR_COLOR_PICKER_HUE_VIEW_PAGE_COUNT);
    [self.hueGrid scrollRectToVisible:CGRectMake(page * self.hueGrid.bounds.size.width, 0, self.hueGrid.bounds.size.width, self.hueGrid.bounds.size.height) animated:YES];
}

- (void) hueBarTapped:(UITapGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:self.hueBar];
    [self scrollFromColorBarPoint:point];
}

- (void) hueBarPanned:(UIPanGestureRecognizer*)gesture
{
    CGPoint point = [gesture locationInView:self.hueBar];
    [self scrollFromColorBarPoint:point];
}

@end
