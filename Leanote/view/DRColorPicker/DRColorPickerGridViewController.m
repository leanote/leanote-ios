//
//  DRColorPickerGridViewController.m
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

#import "DRColorPickerGridViewController.h"
#import "DRColorPickerStore.h"
#import "DRColorPickerHomeViewController.h"
#import "DRColorPicker.h"

@interface DRColorPickerGridViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) DRColorPickerGridView* gridView;
@property (nonatomic, strong) DRColorPickerColorView* colorViewLongPressed;
@property (nonatomic, strong) NSIndexPath* colorViewIndexPath;

@end

@implementation DRColorPickerGridViewController

- (id) init
{
    if ((self = [super init]) == nil) { return nil; }

    self.gridView = [[DRColorPickerGridView alloc] init];

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    self.gridView.frame = self.view.bounds;
    [self.view addSubview:self.gridView];

    __weak DRColorPickerGridViewController* weakSelf = self;
    self.gridView.colorSelectedBlock = ^(DRColorPickerColor* color)
    {
        DRColorPickerGridViewController* strongSelf = weakSelf;
        if (strongSelf.colorSelectedBlock != nil)
        {
            strongSelf.colorSelectedBlock(color, strongSelf);
        }
    };
    self.gridView.colorLongPressBlock = ^(DRColorPickerColorView* colorView, NSIndexPath* indexPath)
    {
        DRColorPickerGridViewController* strongSelf = weakSelf;
        if (strongSelf.list == DRColorPickerStoreListFavorites)
        {
            [strongSelf handleLongTap:colorView indexPath:indexPath];
        }
    };
}

- (void) handleLongTap:(DRColorPickerColorView*)colorView indexPath:(NSIndexPath*)indexPath
{
    self.colorViewLongPressed = colorView;
    self.colorViewIndexPath = indexPath;
    UIActionSheet* actionSheet = [[UIActionSheet alloc] init];
    NSInteger offset = 0;
    if (indexPath.row != 0)
    {
        [actionSheet addButtonWithTitle:DRCPTR(@"MoveToFront")];
        offset = 1;
    }
    [actionSheet addButtonWithTitle:DRCPTR(@"Delete")];
    [actionSheet addButtonWithTitle:DRCPTR(@"Cancel")];
    actionSheet.destructiveButtonIndex = offset;
    actionSheet.cancelButtonIndex = offset + 1;
    actionSheet.delegate = self;
    CGRect rect = [self.view convertRect:colorView.bounds fromView:colorView];
    [actionSheet showFromRect:rect inView:self.view animated:YES];
}

- (void) updateColorsFromList
{
    NSArray* colors = [[DRColorPickerStore sharedInstance] colorsForList:self.list];
    [self.gridView setColors:colors];
}

- (void) setList:(DRColorPickerStoreList)list
{
    _list = list;

    [self updateColorsFromList];
}

- (void) deleteColor
{
    [[DRColorPickerStore sharedInstance] deleteColor:self.colorViewLongPressed.color fromList:self.list];
    @try
    {
        [self.gridView deleteItemsAtIndexPaths:@[ self.colorViewIndexPath]];
    }
    @catch (...)
    {
        [self.gridView reloadData];
    }
}

- (void) moveColorToFront
{
    [[DRColorPickerStore sharedInstance] upsertColor:self.colorViewLongPressed.color list:self.list moveToFront:YES];
    [self.gridView moveItemAtIndexPath:self.colorViewIndexPath toIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
}

- (void) actionSheet:(UIActionSheet*)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.destructiveButtonIndex)
    {
        [self deleteColor];
    }
    else if ([[actionSheet buttonTitleAtIndex:buttonIndex] isEqualToString:DRCPTR(@"MoveToFront")])
    {
        [self moveColorToFront];
    }
    self.colorViewLongPressed = nil;
    self.colorViewIndexPath = nil;
}

@end
