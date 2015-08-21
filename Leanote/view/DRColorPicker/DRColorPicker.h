//
//  DRColorPicker.h
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
#import "DRColorPickerViewController.h"

// stands for Digital Ruby Color Picker Translation
NSString* DRCPTR(NSString* key, ...);

UIImage* DRColorPickerImage(NSString* subPath);

// size of each individual color in points on iPhone, default is 42
extern CGFloat DRColorPickerThumbnailSizeInPointsPhone;

// size of each individual color in points on iPad, default is 54
extern CGFloat DRColorPickerThumbnailSizeInPointsPad;

// font to use for the color picker
extern UIFont* DRColorPickerFont;

// color of labels text in the color picker views
extern UIColor* DRColorPickerLabelColor;

// background color of the view controllers
extern UIColor* DRColorPickerBackgroundColor;

// border color of the colors - pick something that is different than the background color to help your colors stand out
extern UIColor* DRColorPickerBorderColor;

// maximum colors in the favorites, recent and standard color list - default 200
extern NSInteger DRColorPickerStoreMaxColors;

// should a saturation bar be shown on the color wheel view? Default is NO
extern BOOL DRColorPickerShowSaturationBar;

// highlight the last hue picked in the hue view, default is NO
extern BOOL DRColorPickerHighlightLastHue;

// if you are allowing textures, they default to JPEG2000 to save disk space. This is slower to save and may have a tiny loss of quality,
// so if performance is a concern, set this to YES.
// ***** once you have set this once for your app, do not ever change it as it will invalidate the hashes for all your textures (this would be bad) *****
extern BOOL DRColorPickerUsePNG;

// default is 0.9f, value of 0.0f to 1.0f, 1.0f is lossless but biggest file size and hence more disk space used - ignored if using PNG for texture
// ***** once you have set this once for your app, do not ever change it as it will invalidate the hashes for all your textures (this would be bad) *****
extern CGFloat DRColorPickerJPEG2000Quality;

// new in iOS 8 is the concept of shared folders - if you want the color picker to use a shared folder accessible by apps
// with the same group id, set this to your group id, otherwise leave nil to use the documents folder. Default is nil
extern NSString* DRColorPickerSharedAppGroup;
