//
//  DRColorPickerGridView.h
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

#import <UIKit/UIKit.h>
#import "DRColorPickerColor.h"
#import "DRColorPickerHorizontalCollectionViewLayout.h"
#import "DRColorPickerColorView.h"

typedef void (^DRColorPickerGridViewColorSelectedBlock)(DRColorPickerColor* color);
typedef void (^DRColorPickerGridViewColorLongPressBlock)(DRColorPickerColorView* colorView, NSIndexPath* indexPath);
typedef void (^DRColorPickerGridViewScrolledBlock)();

@interface DRColorPickerGridView : UICollectionView

// array of DRColorPickerColor
@property (nonatomic, strong) NSArray* colors;

// optional, highlight an existing color
@property (nonatomic, strong) DRColorPickerColor* highlightColor;

// current page
@property (nonatomic, assign, readonly) NSInteger page;

// fires when a color is selected
@property (nonatomic, copy) DRColorPickerGridViewColorSelectedBlock colorSelectedBlock;

// fires when a color is long pressed
@property (nonatomic, copy) DRColorPickerGridViewColorLongPressBlock colorLongPressBlock;

// fires when the grid is scrolled
@property (nonatomic, copy) DRColorPickerGridViewScrolledBlock scrolledBlock;

// custom layout
@property (nonatomic, strong, readonly) DRColorPickerHorizontalCollectionViewLayout* drCollectionViewLayout;

@end
