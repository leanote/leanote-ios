//
//  DRColorPickerColor.h
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

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface DRColorPickerColor : NSObject

// init with a rgb color, identifier is created from color rgba
- (instancetype) initWithColor:(UIColor*)color;

// init with an image
- (instancetype) initWithImage:(UIImage*)image;

// init with a dictionary
- (instancetype) initWithDictionary:(NSDictionary*)dictionary;

// init with a color (clone)
- (instancetype) initWithClone:(DRColorPickerColor*)color;

// a dictionary for serialization
- (NSDictionary*) dictionary;

// free up memory from images
- (void) clearImages;

// rgba color
@property (nonatomic, strong) UIColor* rgbColor;

// alpha
@property (nonatomic, assign) CGFloat alpha;

// if rgbColor is nil, this hash represents the MD5 hash of the image bytes
@property (nonatomic, strong) NSString* fullImageHash;

// finally, if this is a new color with an image that needs to be created, populate this property
@property (nonatomic, strong, readonly) UIImage* image;
@property (nonatomic, strong, readonly) UIImage* thumbnailImage;

@end
