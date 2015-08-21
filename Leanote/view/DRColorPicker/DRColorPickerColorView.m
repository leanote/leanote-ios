//
//  DRColorPickerColorView.m
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

#import "DRColorPickerColorView.h"
#import "DRColorPickerStore.h"
#import "DRColorPicker.h"

static UIColor* s_borderColor;
static UIImage* s_transparencyImage;

@interface DRColorPickerColorView ()

@property (nonatomic, strong) UIImageView* thumbnailView;
@property (nonatomic, strong) UIImageView* transparencyView;

@end

@implementation DRColorPickerColorView

+ (void) initialize
{
    if (self == [DRColorPickerColorView class])
    {
        s_borderColor = (DRColorPickerBorderColor ?: [UIColor colorWithWhite:0.85f alpha:1.0f]);
        s_transparencyImage = DRColorPickerImage(@"images/common/drcolorpicker-checkerboard.png");
    }
}

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]) == nil) { return nil; }

    self.transparencyView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.transparencyView.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.transparencyView.clipsToBounds = YES;
    [self addSubview:self.transparencyView];

    self.thumbnailView = [[UIImageView alloc] initWithFrame:self.bounds];
    self.thumbnailView.contentScaleFactor = [[UIScreen mainScreen] scale];
    self.thumbnailView.layer.cornerRadius = self.thumbnailView.bounds.size.width * 0.5f;
    self.thumbnailView.layer.borderWidth = 1.0f;
    self.thumbnailView.layer.borderColor = s_borderColor.CGColor;
    [self addSubview:self.thumbnailView];

    return self;
}

- (void) setColor:(DRColorPickerColor*)color
{
    _color = color;
    self.highlighted = NO;

    if (color == nil)
    {
        self.hidden = YES;
        self.thumbnailView.image = nil;
        return;
    }

    self.hidden = NO;

    self.thumbnailView.image = nil;
    if (self.color.rgbColor == nil)
    {
        self.thumbnailView.alpha = self.color.alpha;
        self.thumbnailView.backgroundColor = [UIColor clearColor];

        [[DRColorPickerStore sharedInstance] thumbnailImageForColor:self.color completion:^(UIImage* image)
        {
            // if we are still the same color, set the image
            if (self.color.rgbColor == nil)
            {
                self.thumbnailView.image = image;
            }
        }];
    }
    else
    {
        self.thumbnailView.alpha = 1.0f;
        self.thumbnailView.backgroundColor = self.color.rgbColor;
    }

    self.transparencyView.hidden = (self.color.alpha == 1.0f);

    if (self.transparencyView.hidden)
    {
        self.transparencyView.image = nil;
        self.transparencyView.layer.cornerRadius = 0.0f;
    }
    else
    {
        self.transparencyView.image = s_transparencyImage;
        self.transparencyView.layer.cornerRadius = self.transparencyView.bounds.size.width * 0.5f;
    }
}

- (void) setHighlighted:(BOOL)highlighted
{
    if (_highlighted != highlighted)
    {
        _highlighted = highlighted;

        if (highlighted)
        {
			self.thumbnailView.layer.cornerRadius = 0.0f;
            self.thumbnailView.layer.shadowColor = self.thumbnailView.layer.borderColor;
            self.thumbnailView.layer.shadowOffset = CGSizeZero;
            self.thumbnailView.layer.shadowRadius = 6.0f;
            self.thumbnailView.layer.shadowOpacity = 0.9f;
            self.thumbnailView.layer.borderWidth = 2.0f;
        }
        else
        {
			self.thumbnailView.layer.cornerRadius = self.thumbnailView.bounds.size.width * 0.5f;
            self.thumbnailView.layer.shadowColor = [UIColor clearColor].CGColor;
            self.thumbnailView.layer.shadowOffset = CGSizeZero;
            self.thumbnailView.layer.shadowRadius = 0.0f;
            self.thumbnailView.layer.shadowOpacity = 0.0f;
            self.thumbnailView.layer.borderWidth = 1.0f;
        }
    }
}

@end

