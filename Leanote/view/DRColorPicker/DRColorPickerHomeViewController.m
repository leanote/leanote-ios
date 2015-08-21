//
//  DRColorPickerHomeViewController.m
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

#import "DRColorPickerHomeViewController.h"
#import "DRColorPickerWheelViewController.h"
#import "DRColorPickerHueViewController.h"
#import "DRColorPickerGridView.h"
#import "DRColorPickerGridViewCell.h"
#import "DRColorPickerStore.h"
#import "DRColorPickerGridViewController.h"
#import "DRColorPickerHomeView.h"
#import "DRColorPicker.h"

@interface DRColorPickerHomeViewController ()

@property (nonatomic, assign) BOOL cancel;
@property (nonatomic, strong) DRColorPickerHomeView* homeView;
@property (nonatomic, strong) UIBarButtonItem* favoritesButton;
@property (nonatomic, strong) DRColorPickerColorView* recentColorView;
@property (nonatomic, strong) UIBarButtonItem* cancelButton;
@property (nonatomic, strong) UIBarButtonItem* doneButton;

@end

@implementation DRColorPickerHomeViewController

- (void) dealloc
{
    // if we are in a popover, we can dealloc without done or cancel being called, in which case we pretend they tapped done - in
    // this way the behavior of tapping outside the popover acts as tapping the done button
    if (self.cancelButton.enabled && self.doneButton.enabled && self.callDoneTappedInDealloc && self.dismissBlock != nil && !self.cancel)
    {
        [[DRColorPickerStore sharedInstance] upsertColor:self.homeView.color list:DRColorPickerStoreListRecent moveToFront:YES];
        [self callDismissBlock:NO];
    }
    else
    {
        [[DRColorPickerStore sharedInstance] saveColorSettings];
    }
}

- (id) init
{
    if ((self = [super init]) == nil) { return nil; }

    __weak DRColorPickerHomeViewController* weakSelf = self;
    self.homeView = [[DRColorPickerHomeView alloc] init];
    self.homeView.standardColors.colorSelectedBlock = ^(DRColorPickerColor* color)
    {
        DRColorPickerHomeViewController* strongSelf = weakSelf;
        strongSelf.color = color;
    };
    self.callDoneTappedInDealloc = YES;
    self.showAlphaSlider = YES;

    return self;
}

- (void) viewDidLoad
{
    [super viewDidLoad];

    [self loadDefaultImages];
    [self createToolbar];
    self.navigationItem.leftBarButtonItem = self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelTapped:)];
    self.navigationItem.rightBarButtonItem = self.doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    self.navigationItem.title = DRCPTR(@"Colors");
    self.homeView.frame = self.view.bounds;
    [self.view addSubview:self.homeView];
}

- (void) loadDefaultImages
{
    if (self.addToFavoritesImage == nil)
    {
//        self.addToFavoritesImage = DRColorPickerImage(@"images/default/drcolorpicker-addtofavorites.png");
    }
    if (self.favoritesImage == nil)
    {
        self.favoritesImage = DRColorPickerImage(@"images/default/drcolorpicker-favorites.png");
    }
    if (self.hueImage == nil)
    {
        self.hueImage = DRColorPickerImage(@"images/default/drcolorpicker-hue.png");
    }
    if (self.wheelImage == nil)
    {
        self.wheelImage = DRColorPickerImage(@"images/default/drcolorpicker-wheel.png");
    }
    if (self.importImage == nil)
    {
        self.importImage = DRColorPickerImage(@"images/default/drcolorpicker-import.png");
    }
}

- (UIBarButtonItem*) barItemWithImage:(UIImage*)image view:(UIView*)view action:(SEL)action
{
    UIButton* button = [UIButton buttonWithType:UIButtonTypeCustom];
    button.bounds = CGRectMake(0, 0, 44.0f, 44.0f);
    button.showsTouchWhenHighlighted = YES;
    button.contentScaleFactor = UIScreen.mainScreen.scale;

    if (image == nil)
    {
        view.userInteractionEnabled = NO;
        [button addSubview:view];
        [button sendSubviewToBack:view];
    }
    else
    {
        [button setBackgroundImage:image forState:UIControlStateNormal];
    }

    [button addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];
    UIBarButtonItem* barButtonItem = [[UIBarButtonItem alloc] initWithCustomView:button];

    return barButtonItem;
}

- (void) createToolbar
{
    UIBarButtonItem* fs1 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fs2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    UIBarButtonItem* fs3 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
    fs3.width = 4.0f;
    UIBarButtonItem* favorites = [self barItemWithImage:self.favoritesImage view:nil action:@selector(favoritesTapped:)];
	// life
//    self.recentColorView = [[DRColorPickerColorView alloc] initWithFrame:CGRectMake(7.0f, 7.0f, 30.0f, 30.0f)];
//    self.recentColorView.color = self.homeView.color;
//    UIBarButtonItem* recent = [self barItemWithImage:nil view:self.recentColorView action:@selector(recentTapped:)];
    UIBarButtonItem* hue = [self barItemWithImage:self.hueImage view:nil action:@selector(hueTapped:)];
    UIBarButtonItem* wheel = [self barItemWithImage:self.wheelImage view:nil action:@selector(wheelTapped:)];
    self.favoritesButton = favorites;

    if (self.importBlock == nil)
    {
        self.toolbarItems = @[ fs1, /*favorites, fs3,recent, */ fs3, hue, fs3, wheel, fs2 ];
    }
    else
    {
        UIBarButtonItem* import = [self barItemWithImage:self.importImage view:nil action:@selector(importTapped:)];
        self.toolbarItems = @[ fs1, favorites, fs3, /*recent, */ fs3, hue, fs3, wheel, fs3, import, fs2 ];
    }
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [self.navigationController setToolbarHidden:NO animated:animated];
}

- (void) viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];

    self.homeView.favoritesView = (UIView*)[self.favoritesButton valueForKey:@"view"];
}

- (void) callDismissBlock:(BOOL)cancel
{
    self.cancel = cancel;

    NSAssert(self.dismissBlock != nil, @"Should have had a dismiss block setup");

    if (!cancel)
    {
        if (self.colorSelectedBlock != nil)
        {
            DRColorPickerColor* cloneColor = [[DRColorPickerColor alloc] initWithClone:self.color];
            self.colorSelectedBlock(cloneColor, self);
            self.colorSelectedBlock = nil;
        }
    }

    DRColorPickerDismissBlock block = [self.dismissBlock copy];
    self.dismissBlock = nil;
    [[DRColorPickerStore sharedInstance] saveColorSettings];
    block(cancel);
}

- (void) cancelTapped:(id)sender
{
    [self callDismissBlock:YES];
}

- (void) doneTapped:(id)sender
{
    self.cancelButton.enabled = self.doneButton.enabled = NO;

    __weak DRColorPickerHomeViewController* weakSelf = self;
    __block UIActivityIndicatorView* p = [[UIActivityIndicatorView alloc] initWithFrame:self.navigationController.view.bounds];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15f * NSEC_PER_SEC)), dispatch_get_main_queue(),
    ^{
        DRColorPickerHomeViewController* strongSelf = weakSelf;
        if (strongSelf == nil || p == nil)
        {
            return;
        }
        [p setActivityIndicatorViewStyle:UIActivityIndicatorViewStyleWhiteLarge];
        p.backgroundColor = [UIColor colorWithWhite:0.0f alpha:0.5f];
        p.color = UIColor.whiteColor;
        p.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        p.userInteractionEnabled = YES;
        [p startAnimating];
        [strongSelf.navigationController.view addSubview:p];
        p.alpha = 0.0f;
        [UIView animateWithDuration:0.25f animations:^
        {
            p.alpha = 1.0f;
        }];
    });

    dispatch_async(dispatch_get_global_queue(0, 0),
    ^{
		// 如果选择了
		// life
		if(self.homeView.color) {
			[[DRColorPickerStore sharedInstance] upsertColor:self.homeView.color list:DRColorPickerStoreListRecent moveToFront:YES];
		}
		dispatch_async(dispatch_get_main_queue(),
					   ^{
						   [p removeFromSuperview];
						   p = nil;
						   [self callDismissBlock:NO];
					   });
	});
}

- (void) pushViewController:(DRColorPickerBaseViewController*)vc
{
    __weak DRColorPickerHomeViewController* weakSelf = self;
    [self.navigationController pushViewController:vc animated:YES];
    vc.colorSelectedBlock = ^(DRColorPickerColor* color, DRColorPickerBaseViewController* _vc)
    {
        DRColorPickerHomeViewController* strongSelf = weakSelf;
        strongSelf.color = color;
        if (!_vc.drIsBeingDismissed)
        {
            [strongSelf.navigationController popViewControllerAnimated:YES];
        }
    };
}

- (void) favoritesTapped:(id)sender
{
    DRColorPickerGridViewController* favs = [[DRColorPickerGridViewController alloc] init];
    favs.title = DRCPTR(@"Favorites");
    favs.list = DRColorPickerStoreListFavorites;
    favs.gridView.contentMode = UIViewContentModeTop;
    [self pushViewController:favs];
}

- (void) recentTapped:(id)sender
{
    DRColorPickerGridViewController* recents = [[DRColorPickerGridViewController alloc] init];
    recents.title = DRCPTR(@"Recent");
    recents.list = DRColorPickerStoreListRecent;
    recents.gridView.contentMode = UIViewContentModeTop;
    [self pushViewController:recents];
}

- (void) hueTapped:(id)sender
{
    DRColorPickerHueViewController* hues = [[DRColorPickerHueViewController alloc] init];
    hues.color = self.color;
    [self pushViewController:hues];
}

- (void) wheelTapped:(id)sender
{
    DRColorPickerWheelViewController* wheel = [[DRColorPickerWheelViewController alloc] init];
    wheel.color = self.color;
    [self pushViewController:wheel];
}

- (void) importTapped:(id)sender
{
    if (self.importBlock != nil)
    {
        self.importBlock(self.navigationController, self, DRCPTR(@"LoadTexture"));
    }
}

- (void) setColor:(DRColorPickerColor*)color
{
    self.homeView.color = color;
}

- (DRColorPickerColor*) color
{
    return self.homeView.color;
}

- (void) setImage:(UIImage *)image
{
    DRColorPickerColor* color = [[DRColorPickerColor alloc] initWithImage:image];
    self.homeView.color = color;
}

- (UIImage*) image
{
    return self.homeView.color.image;
}

- (void) finishImport:(UIImage*)image
{
    if (image != nil)
    {
        self.image = image;
    }
}

- (void) setAddToFavoritesImage:(UIImage *)addToFavoritesImage
{
    self.homeView.addToFavoritesImage = addToFavoritesImage;
}

- (UIImage*) addToFavoritesImage
{
    return self.homeView.addToFavoritesImage;
}

- (void) setShowAlphaSlider:(BOOL)showAlphaSlider
{
    self.homeView.showAlphaSlider = showAlphaSlider;
}

- (BOOL) showAlphaSlider
{
    return self.homeView.showAlphaSlider;
}

@end
