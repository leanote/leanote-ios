//
//  DRColorPickerHomeView.m
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

#import "DRColorPickerHomeView.h"
#import "DRColorPickerHomeViewController.h"
#import "DRColorPickerGridViewCell.h"
#import "DRColorPicker.h"

@interface DRColorPickerHomeView ()

@property (nonatomic, strong) UILabel* alphaLabel;
@property (nonatomic, strong) UILabel* currentColorLabel;
@property (nonatomic, strong) UISlider* alphaSlider;
@property (nonatomic, strong) DRColorPickerColorView* currentColorView;
@property (nonatomic, strong) UIButton* addToFavoritesButton;
@property (nonatomic, strong) UIView* topDivider;
@property (nonatomic, strong) DRColorPickerColorView* animateView;

@end

@implementation DRColorPickerHomeView

- (id) initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]) == nil) { return nil; }

    _showAlphaSlider = YES;

    self.standardColors = [[DRColorPickerGridView alloc] init];
    [self addSubview:self.standardColors];

    self.alphaLabel = [[UILabel alloc] init];
    self.alphaLabel.text = DRCPTR(@"Opacity", 1.0f);
    self.alphaLabel.textAlignment = NSTextAlignmentLeft;
    self.alphaLabel.font = [DRColorPickerFont fontWithSize:14.0f];
    self.alphaLabel.minimumScaleFactor = 0.5f;
    self.alphaLabel.adjustsFontSizeToFitWidth = YES;
    self.alphaLabel.textColor = DRColorPickerLabelColor ?: UIColor.blackColor;
    [self addSubview:self.alphaLabel];

    self.currentColorLabel = [[UILabel alloc] init];
    self.currentColorLabel.text = DRCPTR(@"CurrentColor");
    self.currentColorLabel.textAlignment = NSTextAlignmentRight;
    self.currentColorLabel.font = [DRColorPickerFont fontWithSize:14.0f];
    self.currentColorLabel.adjustsFontSizeToFitWidth = YES;
    self.currentColorLabel.textColor = DRColorPickerLabelColor ?: UIColor.blackColor;
    self.currentColorLabel.backgroundColor = [UIColor clearColor];
    [self addSubview:self.currentColorLabel];

    self.alphaSlider = [[UISlider alloc] init];
    self.alphaSlider.minimumValue = 0.0f;
    self.alphaSlider.maximumValue = 1.0f;
    self.alphaSlider.value = 1.0f;
    [self alphaSliderValueChanged:self.alphaSlider];
    [self.alphaSlider addTarget:self action:@selector(alphaSliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.alphaSlider];

    self.currentColorView = [[DRColorPickerColorView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    [self addSubview:self.currentColorView];

    self.addToFavoritesButton = [[UIButton alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 44.0f, 44.0f)];
    self.addToFavoritesButton.contentScaleFactor = UIScreen.mainScreen.scale;
    self.addToFavoritesButton.showsTouchWhenHighlighted = YES;
    [self.addToFavoritesButton addTarget:self action:@selector(addToFavoritesButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
	// life
//    [self addSubview:self.addToFavoritesButton];

    self.topDivider = [[UIView alloc] init];
    self.topDivider.backgroundColor = [UIColor.lightGrayColor colorWithAlphaComponent:0.3f];
    [self addSubview:self.topDivider];

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;

    [self doLayout];

    return self;
}

- (void) setFrame:(CGRect)f
{
    super.frame = f;

    [self doLayout];
}

- (void) doLayout
{
    if (self.standardColors == nil)
    {
        return;
    }

    // top part is the current color
    // [Alpha Label - Left] [Current Color Label - Right]
    // [Alpha Slider] [Current Color] [Add To Favorites]
    // [Standard Color Grid]

    BOOL isIPAD = (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
    CGFloat padding = (isIPAD ? 10.0f : 4.0f);

    if (self.showAlphaSlider)
    {
        self.alphaLabel.hidden = NO;
        self.alphaSlider.hidden = NO;

        self.alphaLabel.frame = CGRectMake(padding + padding, padding, 120.0f, 24.0f);
        self.currentColorLabel.frame = CGRectMake(self.bounds.size.width - padding - padding - 150.0f, padding, 150.0f, 24.0f);
		// life, 因为addToFavoritesButton没了
		self.currentColorView.center = CGPointMake(
												   self.bounds.size.width - padding - /*self.addToFavoritesButton.bounds.size.width*/ + 15 - padding - (self.currentColorView.bounds.size.width * 0.5f),
                                                   CGRectGetMaxY(self.currentColorLabel.frame) + padding + (self.currentColorView.bounds.size.height * 0.5f));
//        self.addToFavoritesButton.center = CGPointMake(self.bounds.size.width - padding - (self.addToFavoritesButton.bounds.size.width * 0.5f), self.currentColorView.center.y);
        self.alphaSlider.frame = CGRectMake(padding, self.currentColorView.center.y - 22.0f, CGRectGetMinX(self.currentColorView.frame) - 30.0f, 44.0f);
        self.topDivider.frame = CGRectMake(0.0f, CGRectGetMaxY(self.alphaSlider.frame) + padding, self.bounds.size.width, 1.0f);
    }
    else
    {
        self.alphaLabel.hidden = YES;
        self.alphaSlider.hidden = YES;

        self.currentColorLabel.frame = CGRectMake((self.bounds.size.width * 0.5f) - 150.0f - padding, padding, 150.0f, 24.0f);
        self.currentColorView.center = CGPointMake((self.bounds.size.width * 0.5f) + (self.currentColorView.bounds.size.width * 0.5f) + padding, (padding + (self.currentColorView.bounds.size.height * 0.5f)));
        self.currentColorLabel.center = CGPointMake(self.currentColorLabel.center.x, self.currentColorView.center.y);
        self.addToFavoritesButton.center = CGPointMake(self.currentColorView.center.x + (self.currentColorView.bounds.size.width * 0.5f) + padding + (self.addToFavoritesButton.bounds.size.width * 0.5f), self.currentColorView.center.y);
        self.topDivider.frame = CGRectMake(0.0f, CGRectGetMaxY(self.currentColorView.frame) + padding, self.bounds.size.width, 1.0f);
    }

    CGFloat standardColorsY = CGRectGetMaxY(self.topDivider.frame);
    self.standardColors.frame = CGRectMake(0.0f, standardColorsY, self.bounds.size.width, self.bounds.size.height - standardColorsY);

    [self createStandardColors];
}

// 标准颜色, 缺少一个白色
- (void) createStandardColors
{
    NSMutableArray* colors = [NSMutableArray array];
    [self.standardColors.drCollectionViewLayout calculatePages];
    NSInteger colorCount = self.standardColors.drCollectionViewLayout.itemsPerPage;
    NSInteger hueCount = (colorCount / 3) * 2;
    NSInteger grayCount = colorCount - hueCount - 1; // -1 for transparency at the end
    for (NSInteger i = 0; i < hueCount; i++)
    {
        UIColor* color = [UIColor colorWithHue:(CGFloat)i / (CGFloat)hueCount saturation:1.0 brightness:1.0 alpha:1.0];
        [colors addObject:[[DRColorPickerColor alloc] initWithColor:color]];
    }
	
    for (NSInteger i = 0; i <= grayCount; i++)
    {
		// 黑色太多了, 分不清
		if(i == 1) {
			continue;
		}
        UIColor* color = [UIColor colorWithWhite:(CGFloat)i / (CGFloat)grayCount alpha:1.0];
        [colors addObject:[[DRColorPickerColor alloc] initWithColor:color]];
    }
	
	// 最后是clearColor
    [colors addObject:[[DRColorPickerColor alloc] initWithColor:[UIColor clearColor]]];
    self.standardColors.colors = colors;
}

- (void) animationDidStop:(CAAnimation*)anim finished:(BOOL)flag
{
    [UIView animateWithDuration:0.33f animations:^
    {
        self.animateView.transform = CGAffineTransformMakeScale(0.1f, 0.1f);
    } completion:^(BOOL finished)
    {
        [self.animateView removeFromSuperview];
    }];
}

- (void) animateAddToFavorites
{
    if (self.favoritesView == nil)
    {
        return;
    }

    [self.animateView removeFromSuperview];
    self.animateView = [[DRColorPickerColorView alloc] initWithFrame:self.currentColorView.frame];
    self.animateView.color = self.color;
    [self.favoritesView.superview addSubview:self.animateView];

    CAKeyframeAnimation* pathAnimation = [CAKeyframeAnimation animationWithKeyPath:@"position"];
    pathAnimation.fillMode = kCAFillModeForwards;
    pathAnimation.removedOnCompletion = NO;
    pathAnimation.delegate = self;
    pathAnimation.duration = 0.7f;
    
    CGPoint startPoint = [self.currentColorView.superview convertPoint:self.currentColorView.center toView:self.favoritesView.superview];
    CGPoint endPoint = self.favoritesView.center;
    CGPoint curvePoint = CGPointMake(startPoint.x - 50.0f, startPoint.y - 50.0f);
    CGPoint controlPoint = CGPointMake(startPoint.x - 5.0f, startPoint.y - 50.0f);
    UIBezierPath* path = [UIBezierPath bezierPath];
    [path moveToPoint:startPoint];
    [path addQuadCurveToPoint:curvePoint controlPoint:controlPoint];
    [path addLineToPoint:endPoint];
    pathAnimation.path = path.CGPath;

    [self.animateView.layer addAnimation:pathAnimation forKey:@"pathAnimation"];
}

- (void) addToFavoritesButtonTapped:(id)sender
{
    [[DRColorPickerStore sharedInstance] upsertColor:self.color list:DRColorPickerStoreListFavorites moveToFront:YES];
    [self animateAddToFavorites];
}

- (void) alphaSliderValueChanged:(id)sender
{
    CGFloat alpha = self.alphaSlider.value;
    self.alphaLabel.text = DRCPTR(@"Opacity", alpha);
    self.color.alpha = alpha;
    self.currentColorView.color = self.color;
}

- (void) setColor:(DRColorPickerColor*)color
{
    _color = color;
    self.alphaSlider.value = color.alpha;
    self.currentColorView.color = color;
    [self alphaSliderValueChanged:self.alphaSlider];
}

- (void) setAddToFavoritesImage:(UIImage *)addToFavoritesImage
{
    [self.addToFavoritesButton setBackgroundImage:addToFavoritesImage forState:UIControlStateNormal];
}

- (UIImage*) addToFavoritesImage
{
    return [self.addToFavoritesButton backgroundImageForState:UIControlStateNormal];
}

- (void) setShowAlphaSlider:(BOOL)showAlphaSlider
{
    _showAlphaSlider = showAlphaSlider;

    [self doLayout];
}

@end
