//
//  DRColorPickerHomeViewController.h
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
#import "DRColorPickerBaseViewController.h"

@class DRColorPickerViewController;
@class DRColorPickerHomeViewController;

typedef void (^DRColorPickerImportBlock)(UINavigationController* navVC, DRColorPickerHomeViewController* rootVC, NSString* title);
typedef void (^DRColorPickerDismissBlock)(BOOL cancel);

@interface DRColorPickerHomeViewController : DRColorPickerBaseViewController

- (void) finishImport:(UIImage*)image;

// default is nil, this can be set to a block that will present import UI for custom image selection. The block should call importImage:image when done.
@property (nonatomic, copy) DRColorPickerImportBlock importBlock;

// called when the view controller should be dismissed
@property (nonatomic, copy) DRColorPickerDismissBlock dismissBlock;

// default YES, means that if this view deallocated without the cancel or done button being tapped (i.e. tapping outside a popover), to treat that as tapping the done button
@property (nonatomic, assign) BOOL callDoneTappedInDealloc;

// allow the user to change the alpha value of the selected color, default is YES
@property (nonatomic, assign) BOOL showAlphaSlider;

@property (nonatomic, strong) UIImage* addToFavoritesImage;
@property (nonatomic, strong) UIImage* favoritesImage;
@property (nonatomic, strong) UIImage* hueImage;
@property (nonatomic, strong) UIImage* wheelImage;
@property (nonatomic, strong) UIImage* importImage;

@end
