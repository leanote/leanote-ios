//
//  DRColorPickerStore.h
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
#import "DRColorPicker+UIColor.h"
#import "DRColorPickerColor.h"

#define DR_COLOR_PICKER_FULL_SIZE (1024.0f)
#define DR_COLOR_PICKER_SETTINGS_FILE_NAME @"drcolorpicker.settings.json"

typedef void (^DRColorPickerStoreThumbnailCompletionBlock)(UIImage* thumbnailImage);

typedef NS_ENUM(NSInteger, DRColorPickerStoreList)
{
    DRColorPickerStoreListRecent,
    DRColorPickerStoreListFavorites
};

@interface DRColorPickerStore : NSObject

+ (instancetype) sharedInstance;
+ (CGFloat) thumbnailSizePixels;
+ (CGFloat) thumbnailSizePoints;

// get colors for a list
- (NSArray*) colorsForList:(DRColorPickerStoreList)list;

// add or update a color in a list
- (void) upsertColor:(DRColorPickerColor*)color list:(DRColorPickerStoreList)list moveToFront:(BOOL)moveToFront;

// remove an instance of a color, this may cleanup underlying files if no more colors reference this rgb or texture
- (void) deleteColor:(DRColorPickerColor*)color fromList:(DRColorPickerStoreList)list;

// save all changes to file
- (void) saveColorSettings;

// get a thumbnail image for a color - color must be saved first. completion is called back on the main thread. color must have been made from an image, not rgb values.
// if no completion, image is returned
- (UIImage*) thumbnailImageForColor:(DRColorPickerColor*)color completion:(DRColorPickerStoreThumbnailCompletionBlock)completion;

// get full path to the thumbnail image for this color, nil if none
- (NSString*) thumbnailPathForColor:(DRColorPickerColor*)color;

// get full path to the full image for this color, nil if none
- (NSString*) fullPathForColor:(DRColorPickerColor*)color;

// array of DRColorPickerColor
@property (nonatomic, strong, readonly) NSArray* recentColors;

// array of DRColorPickerColor
@property (nonatomic, strong, readonly) NSArray* favoriteColors;

@end
