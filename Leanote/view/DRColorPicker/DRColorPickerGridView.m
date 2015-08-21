//
//  DRColorPickerGridView.m
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

#import "DRColorPickerGridView.h"
#import "DRColorPickerGridViewCell.h"
#import "DRColorPickerStore.h"

@interface DRColorPickerGridView () <UICollectionViewDelegate, UICollectionViewDataSource, UIScrollViewDelegate>

@property (nonatomic, strong) UILongPressGestureRecognizer* longPressGesture;

@end

@implementation DRColorPickerGridView

- (id) initWithFrame:(CGRect)frame
{
    UICollectionViewLayout* layout = [[DRColorPickerHorizontalCollectionViewLayout alloc] init];
    return [self initWithFrame:frame collectionViewLayout:layout];
}

- (id) initWithFrame:(CGRect)frame collectionViewLayout:(UICollectionViewLayout *)layout
{
    if ((self = [super initWithFrame:frame collectionViewLayout:layout]) == nil) { return nil; }

    self.contentMode = UIViewContentModeCenter;
    self.delegate = self;
    self.dataSource = self;
    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.backgroundColor = [UIColor clearColor];
    self.showsHorizontalScrollIndicator = self.showsVerticalScrollIndicator = NO;
    self.pagingEnabled = YES;
    self.clipsToBounds = NO;
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressed:)];
    self.longPressGesture.delaysTouchesBegan = YES;
    [self addGestureRecognizer:self.longPressGesture];
    [self registerClass:[DRColorPickerGridViewCell class] forCellWithReuseIdentifier:@"DRColorPickerGridViewCell"];

    return self;
}

- (NSInteger) itemsInSize:(CGFloat)size itemSize:(CGFloat)itemSize padding:(CGFloat)padding totalSize:(CGFloat*)totalSize
{
    NSInteger count = 0;

    while (YES)
    {
        CGFloat _totalSize = (padding * count) + (itemSize * (count + 1));
        if (_totalSize > size)
        {
            break;
        }
        if (totalSize != NULL)
        {
            *totalSize = _totalSize;
        }
        count++;
    }

    return count;
}

- (void) setColors:(NSArray *)colors
{
    _colors = colors;

    if (self.highlightColor.rgbColor != nil)
    {
        NSInteger index = 0;
        for (DRColorPickerColor* color in colors)
        {
            if ([self.highlightColor.rgbColor isEqual:color.rgbColor])
            {
                self.highlightColor = color;
                // scroll to the highlighted cell
                dispatch_async(dispatch_get_main_queue(), ^
                {
                    NSInteger page = index / self.drCollectionViewLayout.itemsPerPage;
                    [self setContentOffset:CGPointMake(self.bounds.size.width * page, 0.0f) animated:NO];
                });
                break;
            }
            index++;
        }
    }

    [self reloadData];
}

- (NSInteger) numberOfSectionsInCollectionView:(UICollectionView*)collectionView
{
    [self.collectionViewLayout invalidateLayout];

    return 1;
}

- (NSInteger) collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.colors.count;
}

- (UICollectionViewCell*) collectionView:(UICollectionView*)collectionView cellForItemAtIndexPath:(NSIndexPath*)indexPath
{
    DRColorPickerColor* color = nil;

    if (self.colors.count != 0)
    {
        if (indexPath.row >= 0 && indexPath.row < self.colors.count)
        {
            color = (DRColorPickerColor*)self.colors[indexPath.row];
        }

        if (color != nil)
        {
            @try
            {
                DRColorPickerGridViewCell* cell = [self dequeueReusableCellWithReuseIdentifier:@"DRColorPickerGridViewCell" forIndexPath:indexPath];
                cell.colorView.color = color;
                cell.colorView.highlighted = (self.highlightColor != nil && color == self.highlightColor);
                return cell;
            }
            @catch (...)
            {
                
            }
        }
    }

    return [[UICollectionViewCell alloc] init];
}

- (void) collectionView:(UICollectionView*)collectionView didSelectItemAtIndexPath:(NSIndexPath*)indexPath
{
    if (self.colorSelectedBlock != nil && indexPath.row >= 0 && indexPath.row < self.colors.count)
    {
        DRColorPickerColor* color = (DRColorPickerColor*)self.colors[indexPath.row];
        self.colorSelectedBlock(color);
    }
}

- (void) scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    _page = self.contentOffset.x / self.bounds.size.width;
    if (self.scrolledBlock != nil)
    {
        self.scrolledBlock();
    }
}

- (void) scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    _page = self.contentOffset.x / self.bounds.size.width;
    if (self.scrolledBlock != nil)
    {
        self.scrolledBlock();
    }
}

- (void) scrollViewDidScroll:(UIScrollView *)scrollView
{
    _page = self.contentOffset.x / self.bounds.size.width;
    if (self.scrolledBlock != nil)
    {
        self.scrolledBlock();
    }
}

- (DRColorPickerHorizontalCollectionViewLayout*) drCollectionViewLayout
{
    return (DRColorPickerHorizontalCollectionViewLayout*)self.collectionViewLayout;
}

- (void) longPressed:(id)sender
{
    if (self.longPressGesture.state != UIGestureRecognizerStateBegan || self.colorLongPressBlock == nil)
    {
        return;
    }

    CGPoint p = [self.longPressGesture locationInView:self];
    NSIndexPath* indexPath = [self indexPathForItemAtPoint:p];
    if (indexPath != nil)
    {
        DRColorPickerGridViewCell* cell = (DRColorPickerGridViewCell*)[self cellForItemAtIndexPath:indexPath];
        self.colorLongPressBlock(cell.colorView, indexPath);
    }
}

@end
