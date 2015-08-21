//
//  DRColorPickerWheelViewController.m
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

#import "DRColorPickerWheelViewController.h"
#import "DRColorPickerWheelView.h"
#import "DRColorPickerHomeViewController.h"
#import "DRColorPicker.h"

@interface DRColorPickerWheelViewController ()

@property (nonatomic, strong) DRColorPickerWheelView* wheelView;

@end

@implementation DRColorPickerWheelViewController

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    if (self.wheelView == nil)
    {
        self.wheelView = [[DRColorPickerWheelView alloc] initWithFrame:self.view.bounds];
        if (self.color.rgbColor != nil)
        {
            self.wheelView.color = self.color.rgbColor;
        }
        [self.view addSubview:self.wheelView];
        self.title = DRCPTR(@"ColorWheel");
    }
}

- (void) willMoveToParentViewController:(UIViewController*)parent
{
    [super willMoveToParentViewController:parent];

    if (parent == nil && self.colorSelectedBlock != nil)
    {
        self.drIsBeingDismissed = YES;
        self.color = [[DRColorPickerColor alloc] initWithColor:self.wheelView.color];
        self.colorSelectedBlock(self.color, self);
    }
}

@end
