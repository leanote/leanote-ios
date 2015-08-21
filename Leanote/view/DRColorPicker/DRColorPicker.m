//
//  DRColorPicker.m
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

#import "DRColorPicker.h"

CGFloat DRColorPickerThumbnailSizeInPointsPhone = 42.0f;
CGFloat DRColorPickerThumbnailSizeInPointsPad = 54.0f;
UIFont* DRColorPickerFont;
UIColor* DRColorPickerLabelColor;
UIColor* DRColorPickerBackgroundColor;
UIColor* DRColorPickerBorderColor;
NSInteger DRColorPickerStoreMaxColors = 200;
BOOL DRColorPickerShowSaturationBar = NO;
BOOL DRColorPickerHighlightLastHue = NO;
BOOL DRColorPickerUsePNG = NO;
CGFloat DRColorPickerJPEG2000Quality = 0.9f;
NSString* DRColorPickerSharedAppGroup = nil;

NSString* DRCPTR(NSString* key, ...)
{
    NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
    NSString* result = NSLocalizedStringFromTableInBundle(key, @"DRColorPickerLocalizable", [NSBundle bundleWithPath:[resourcePath stringByAppendingPathComponent:@"DRColorPicker.bundle"]], nil);
    if (result.length == 0)
    {
        NSString* fullPath = [resourcePath stringByAppendingPathComponent:@"../../DRColorPicker.bundle"];
        NSBundle* bundle = [NSBundle bundleWithPath:fullPath];
        result = NSLocalizedStringFromTableInBundle(key, @"DRColorPickerLocalizable", bundle, nil);
    }

    va_list ap;
    va_start(ap, key);

    result = [[NSString alloc] initWithFormat:result arguments:ap];

    va_end(ap);

    return result;
}

UIImage* DRColorPickerImage(NSString* subPath)
{
    if (subPath.length == 0)
    {
        return nil;
    }

    static NSCache* imageWithContentsOfFileCache;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken,
    ^{
        imageWithContentsOfFileCache = [[NSCache alloc] init];
    });

    NSString* fullPath = [@"DRColorPicker.bundle/" stringByAppendingString:subPath];
    UIImage* img = [UIImage imageNamed:fullPath];
    if (img == nil)
    {
        fullPath = [@"../../DRColorPicker.bundle/" stringByAppendingString:subPath];
        img = [UIImage imageNamed:fullPath];
        if (img == nil)
        {
            NSString* resourcePath = [[NSBundle mainBundle] resourcePath];
            fullPath = [resourcePath stringByAppendingPathComponent:[@"DRColorPicker.bundle/" stringByAppendingString:subPath]];
            img = [UIImage imageNamed:fullPath];
            if (img == nil)
            {
                fullPath = [resourcePath stringByAppendingPathComponent:[@"../../DRColorPicker.bundle/" stringByAppendingString:subPath]];
                img = [UIImage imageNamed:fullPath];
                if (img == nil)
                {
                    NSString* lastPath = subPath.lastPathComponent;
                    img = [UIImage imageNamed:lastPath];
                    if (img == nil)
                    {
                        img = [UIImage imageNamed:[@"../../" stringByAppendingPathComponent:lastPath]];
                        if (img == nil)
                        {
                            img = (UIImage*)[imageWithContentsOfFileCache objectForKey:subPath];
                            if (img == nil)
                            {
                                img = [UIImage imageWithContentsOfFile:fullPath];
                                if (img != nil)
                                {
                                    [imageWithContentsOfFileCache setObject:img forKey:subPath];
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    return img;
}
