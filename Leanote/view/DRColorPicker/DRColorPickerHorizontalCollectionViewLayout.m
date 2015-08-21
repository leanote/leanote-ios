//
//  DRColorPickerHorizontalCollectionViewLayout.m
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

#import "DRColorPickerHorizontalCollectionViewLayout.h"
#import "DRColorPickerStore.h"

@implementation DRColorPickerHorizontalCollectionViewLayout
{
    CGSize _itemSize;
    NSInteger _sections;
    NSInteger _cellCount;
    CGFloat _padding;
    CGFloat _borderPadding;
    CGFloat _horizontalPadding;
    CGFloat _verticalPadding;
    CGRect _lastRect;
    NSMutableArray* _allAttributes;
}

- (id) init
{
    if ((self = [super init]) == nil) { return nil; }

    CGFloat size = [DRColorPickerStore thumbnailSizePixels] / UIScreen.mainScreen.scale;
    _itemSize = CGSizeMake(size, size);
    _padding = 4.0f;
    _borderPadding = 4.0f;
    _allAttributes = [NSMutableArray array];

    return self;
}

- (void) prepareLayout
{
    _sections = [self.collectionView numberOfSections];
    _cellCount = 0;
    for (NSInteger i = 0; i < _sections; i++)
    {
        _cellCount += [self.collectionView numberOfItemsInSection:i];
    }
    _lastRect = self.collectionView.bounds;
}

- (CGSize) calculatePages
{
    CGSize baseSize = self.collectionView.bounds.size;
    CGSize adjustedSize = CGSizeMake(baseSize.width - _borderPadding - _borderPadding, baseSize.height - _borderPadding - _borderPadding);
    _rows = floorf(adjustedSize.height / _itemSize.height);
    while (_rows > 0)
    {
        CGFloat rowsHeight = (_rows * _itemSize.height);
        CGFloat rowsHeightWithPadding = rowsHeight + (_padding * _rows - 1);
        if (rowsHeightWithPadding < adjustedSize.height)
        {
            if (self.collectionView.contentMode == UIViewContentModeCenter)
            {
                CGFloat maxSpacing = (adjustedSize.height - rowsHeight) / (CGFloat)(_rows - 1);
                _verticalPadding = MAX(maxSpacing, _padding);
            }
            else
            {
                _verticalPadding = _padding;
            }
            break;
        }
        _rows--;
    }

    _columns = floorf(baseSize.width / _itemSize.width);
    while (_columns > 0)
    {
        CGFloat columnsWidth = (_columns * _itemSize.width);
        CGFloat columnsWidthWithPadding = columnsWidth + (_padding * _columns - 1);
        if (columnsWidthWithPadding < adjustedSize.width)
        {
            CGFloat maxSpacing = (adjustedSize.width - columnsWidth) / (CGFloat)(_columns - 1);
            _horizontalPadding = MAX(maxSpacing, _padding);
            break;
        }
        _columns--;
    }

    _itemsPerPage = _rows * _columns;
    _numberOfPages = ceilf((CGFloat)_cellCount / (CGFloat)_itemsPerPage);

    baseSize.width = _numberOfPages * baseSize.width;

    return baseSize;
}

- (CGSize) collectionViewContentSize
{
    return [self calculatePages];
}

- (NSArray*) layoutAttributesForElementsInRect:(CGRect)rect
{
    if (_allAttributes.count != 0)
    {
        return _allAttributes;
    }

    for (NSUInteger i = 0; i < _sections; i++)
    {
        NSInteger sectionItems = [self.collectionView numberOfItemsInSection:i];
        for (NSUInteger j = 0; j < sectionItems; j++)
        {
            NSIndexPath* indexPath = [NSIndexPath indexPathForRow:j inSection:i];
            UICollectionViewLayoutAttributes *attr = [self internalLayoutForAttributesForCellAtIndexPath:indexPath];
            [_allAttributes addObject:attr];
        }
    }

    return _allAttributes;
}

- (UICollectionViewLayoutAttributes*) layoutAttributesForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [self internalLayoutForAttributesForCellAtIndexPath:indexPath];
}

- (BOOL) shouldInvalidateLayoutForBoundsChange:(CGRect)newBounds
{
    BOOL result = !CGSizeEqualToSize(newBounds.size, _lastRect.size);
    _lastRect = newBounds;

    if (result)
    {
        [_allAttributes removeAllObjects];
    }

    return result;
}

- (UICollectionViewLayoutAttributes*) internalLayoutForAttributesForCellAtIndexPath:(NSIndexPath*)indexPath
{
    UICollectionViewLayoutAttributes *attr = [UICollectionViewLayoutAttributes layoutAttributesForCellWithIndexPath:indexPath];

    if (_rows <= 0 || _columns <= 0)
    {
        return attr;
    }

    NSInteger row = indexPath.row;
    CGRect bounds = self.collectionView.bounds;
    NSInteger columnPosition = row % _columns;
    NSInteger rowPosition = (row / _columns) % _rows;
    NSInteger itemPage = floorf(row / _itemsPerPage);

    CGRect frame;
    frame.origin.x = itemPage * bounds.size.width + (columnPosition * _itemSize.width);
    frame.origin.x += _borderPadding + (columnPosition * _horizontalPadding);
    frame.origin.y = rowPosition * _itemSize.height;
    frame.origin.y += _borderPadding + (rowPosition * _verticalPadding);
    frame.size = _itemSize;

    attr.frame = CGRectIntegral(frame);
    
    return attr;
}

- (void) invalidateLayout
{
    [super invalidateLayout];

    [_allAttributes removeAllObjects];
}

@end
