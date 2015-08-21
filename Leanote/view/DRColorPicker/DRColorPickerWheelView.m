//
//  DRColorPickerWheelView.h
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

#import "DRColorPickerWheelView.h"
#import "DRColorPicker+UIColor.h"
#import "DRColorPicker.h"

@interface DRColorPickerWheelGradientView : UIView

@property (nonatomic, assign) CGGradientRef gradient;
@property (nonatomic, strong) UIColor* color1;
@property (nonatomic, strong) UIColor* color2;

@end

@implementation DRColorPickerWheelGradientView

- (void) setColor1:(UIColor*)color
{
    if (_color1 != color)
    {
        _color1 = [color copy];
        [self setupGradient];
        [self setNeedsDisplay];
    }
}

- (void) setColor2:(UIColor*)color
{
    if (_color2 != color)
    {
        _color2 = [color copy];
        [self setupGradient];
        [self setNeedsDisplay];
    }
}

- (void) setupGradient
{
    if (_color1 == nil || _color2 == nil)
    {
        return;
    }

	const CGFloat* c1 = CGColorGetComponents(_color1.CGColor);
	const CGFloat* c2 = CGColorGetComponents(_color2.CGColor);

	CGFloat colors[] = { c1[0], c1[1], c1[2], 1.0f, c2[0], c2[1], c2[2], 1.0f };
	CGColorSpaceRef rgb = CGColorSpaceCreateDeviceRGB();

    if (self.gradient != NULL)
    {
        CGGradientRelease(self.gradient);
    }

	self.gradient = CGGradientCreateWithColorComponents(rgb, colors, NULL, sizeof(colors) / (sizeof(colors[0]) * 4));
	CGColorSpaceRelease(rgb);
}

- (void) drawRect:(CGRect)rect
{
	CGContextRef context = UIGraphicsGetCurrentContext();
	CGRect clippingRect = CGRectMake(0.0f, 0.0f, self.frame.size.width, self.frame.size.height);
	CGPoint endPoints[] = { CGPointMake(0.0f, 0.0f), CGPointMake(self.frame.size.width, 0.0f) };

	CGContextSaveGState(context);
	CGContextClipToRect(context, clippingRect);
	CGContextDrawLinearGradient(context, self.gradient, endPoints[0], endPoints[1], 0.0f);
	CGContextRestoreGState(context);
}

- (void) dealloc
{
    if (self.gradient != NULL)
    {
        CGGradientRelease(self.gradient);
    }
}

@end

CGFloat const DRColorPickerWheelViewGradientViewHeight = 40.0f;
CGFloat const DRColorPickerWheelViewGradientTopMargin = 20.0f;
CGFloat const DRColorPickerWheelViewDefaultMargin = 10.0f;
CGFloat const DRColorPickerWheelLabelWidth = 60.0f;
CGFloat const DRColorPickerWheelLabelHeight = 30.0f;
CGFloat const DRColorPickerWheelTextFieldWidth = 84.0f;
CGFloat const DRColorPickerWheelViewBrightnessIndicatorWidth = 16.0f;
CGFloat const DRColorPickerWheelViewBrightnessIndicatorHeight = 48.0f;
CGFloat const DRColorPickerWheelViewCrossHairshWidthAndHeight = 38.0f;

@interface DRColorPickerWheelView () <UITextFieldDelegate>

@property (nonatomic, strong) DRColorPickerWheelGradientView* brightnessView;
@property (nonatomic, strong) UIImageView* brightnessIndicator;
@property (nonatomic, strong) DRColorPickerWheelGradientView* saturationView;
@property (nonatomic, strong) UIImageView* saturationIndicator;
@property (nonatomic, strong) UIImageView* hueImage;
@property (nonatomic, strong) UIView* colorBubble;
@property (nonatomic, assign) CGFloat brightness;
@property (nonatomic, assign) CGFloat hue;
@property (nonatomic, assign) CGFloat saturation;
@property (nonatomic, strong) UILabel* rgbLabel;
@property (nonatomic, strong) UITextField* rgbTextField;
@property (nonatomic, strong) UIView* colorPreviewView;
@property (nonatomic, weak) UIView* focusView;

@end

@implementation DRColorPickerWheelView

- (id) initWithFrame:(CGRect)f
{
    if ((self = [super initWithFrame:f]) == nil) { return nil; }

    self.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self createViews];
    self.color = [UIColor redColor];

    return self;
}

- (void) createViews
{
    UIColor* borderColor = [UIColor colorWithWhite:0.0f alpha:0.1f];

    _rgbLabel = [[UILabel alloc] init];
    _rgbLabel.text = @"RGB: #";
    _rgbLabel.textAlignment = NSTextAlignmentCenter;
    _rgbLabel.textColor = UIColor.blackColor;
    _rgbLabel.shadowColor = UIColor.whiteColor;
    _rgbLabel.shadowOffset = CGSizeMake(0.0f, 1.0f);
    _rgbLabel.font = [DRColorPickerFont fontWithSize:16.0f];
    _rgbLabel.backgroundColor = UIColor.whiteColor;
    [self addSubview:_rgbLabel];

    _rgbTextField = [[UITextField alloc] init];
    _rgbTextField.textColor = UIColor.blackColor;
    _rgbTextField.backgroundColor = UIColor.whiteColor;
    _rgbTextField.layer.borderColor = borderColor.CGColor;
    _rgbTextField.layer.borderWidth = 1.0f;
    _rgbTextField.leftView = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 9.0f, 1.0f)];
    _rgbTextField.leftViewMode = UITextFieldViewModeAlways;
    _rgbTextField.font = [UIFont fontWithName:@"Courier" size:18.0f];
    _rgbTextField.returnKeyType = UIReturnKeyDone;
    _rgbTextField.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
    _rgbTextField.delegate = self;
    [_rgbTextField addTarget:self action:@selector(textFieldChanged:) forControlEvents:UIControlEventEditingChanged];
    [self addSubview:_rgbTextField];

    _colorPreviewView = [[UIView alloc] init];
    _colorPreviewView.layer.borderWidth = 1.0f;
    _colorPreviewView.layer.borderColor = DRColorPickerBorderColor.CGColor;
    [self addSubview:_colorPreviewView];

    _hueImage = [[UIImageView alloc] initWithImage:DRColorPickerImage(@"images/common/drcolorpicker-colormap.png")];
    _hueImage.layer.borderWidth = 1.0f;
    _hueImage.layer.borderColor = borderColor.CGColor;
    [self addSubview:_hueImage];

    _brightnessView = [self createBarViewWithBorderColor:borderColor];
    _brightnessIndicator = [self createIndicator];

    if (DRColorPickerShowSaturationBar)
    {
        _saturationView = [self createBarViewWithBorderColor:borderColor];
        _saturationIndicator = [self createIndicator];
    }

    _colorBubble = [[UIView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, DRColorPickerWheelViewCrossHairshWidthAndHeight, DRColorPickerWheelViewCrossHairshWidthAndHeight)];
    UIColor* bubbleBorderColor = [UIColor colorWithWhite:0.9 alpha:0.8];
    _colorBubble.layer.cornerRadius = DRColorPickerWheelViewCrossHairshWidthAndHeight * 0.5f;
    _colorBubble.layer.borderColor = bubbleBorderColor.CGColor;
    _colorBubble.layer.borderWidth = 2;
    _colorBubble.layer.shadowColor = [UIColor blackColor].CGColor;
    _colorBubble.layer.shadowOffset = CGSizeZero;
    _colorBubble.layer.shadowRadius = 1;
    _colorBubble.layer.shadowOpacity = 0.5f;
    _colorBubble.layer.shouldRasterize = YES;
    _colorBubble.layer.rasterizationScale = UIScreen.mainScreen.scale;
    [self addSubview:_colorBubble];
}

- (DRColorPickerWheelGradientView*) createBarViewWithBorderColor:(UIColor*)borderColor
{
    DRColorPickerWheelGradientView* v = [[DRColorPickerWheelGradientView alloc] init];
    v.layer.borderWidth = 1.0f;
    v.layer.borderColor = borderColor.CGColor;
    [self addSubview:v];

    return v;
}

- (UIImageView*) createIndicator
{
    UIImageView* indicator = [[UIImageView alloc] initWithFrame:CGRectMake(DRColorPickerWheelViewDefaultMargin, self.brightnessView.center.y,
                                                                         DRColorPickerWheelViewBrightnessIndicatorWidth, DRColorPickerWheelViewBrightnessIndicatorHeight)];
    indicator.image = DRColorPickerImage(@"images/common/drcolorpicker-brightnessguide.png");
    indicator.layer.shadowColor = [UIColor blackColor].CGColor;
    indicator.layer.shadowOffset = CGSizeZero;
    indicator.layer.shadowRadius = 1;
    indicator.layer.shadowOpacity = 0.8f;
    indicator.layer.shouldRasterize = YES;
    indicator.layer.rasterizationScale = UIScreen.mainScreen.scale;
    [self addSubview:indicator];

    return indicator;
}

- (void) layoutSubviews
{
    [super layoutSubviews];

    self.rgbLabel.frame = CGRectMake(DRColorPickerWheelViewDefaultMargin, DRColorPickerWheelViewDefaultMargin, DRColorPickerWheelLabelWidth, DRColorPickerWheelLabelHeight);

    self.rgbTextField.frame = CGRectMake(DRColorPickerWheelViewDefaultMargin + DRColorPickerWheelLabelWidth,
                                         DRColorPickerWheelViewDefaultMargin,
                                         DRColorPickerWheelTextFieldWidth,
                                         DRColorPickerWheelLabelHeight);

    CGFloat previewX = DRColorPickerWheelViewDefaultMargin + DRColorPickerWheelLabelWidth + DRColorPickerWheelViewDefaultMargin + DRColorPickerWheelTextFieldWidth;
    self.colorPreviewView.frame = CGRectMake(previewX, DRColorPickerWheelViewDefaultMargin, self.frame.size.width - DRColorPickerWheelViewDefaultMargin - previewX, DRColorPickerWheelLabelHeight);

    CGFloat hueHeight;
    if (self.saturationView == nil)
    {
        hueHeight = CGRectGetHeight(self.frame) - DRColorPickerWheelViewGradientViewHeight - DRColorPickerWheelViewGradientTopMargin - DRColorPickerWheelViewDefaultMargin - DRColorPickerWheelViewDefaultMargin - DRColorPickerWheelLabelHeight;
    }
    else
    {
        hueHeight = CGRectGetHeight(self.frame) - DRColorPickerWheelViewGradientViewHeight - DRColorPickerWheelViewGradientViewHeight - DRColorPickerWheelViewDefaultMargin - DRColorPickerWheelViewDefaultMargin - DRColorPickerWheelViewGradientTopMargin - DRColorPickerWheelViewDefaultMargin - DRColorPickerWheelLabelHeight;
    }

    self.hueImage.frame = CGRectMake(DRColorPickerWheelViewDefaultMargin,
                                               DRColorPickerWheelViewDefaultMargin + DRColorPickerWheelViewDefaultMargin + DRColorPickerWheelLabelHeight,
                                               CGRectGetWidth(self.frame) - (DRColorPickerWheelViewDefaultMargin * 2),
                                               hueHeight);
    
    self.saturationView.frame = CGRectMake(DRColorPickerWheelViewDefaultMargin,
                                         CGRectGetMaxY(self.hueImage.frame) + DRColorPickerWheelViewDefaultMargin,
                                         CGRectGetWidth(self.frame) - (DRColorPickerWheelViewDefaultMargin * 2),
                                         DRColorPickerWheelViewGradientViewHeight);

    CGFloat brightnessY = (self.saturationView == nil ? CGRectGetMaxY(self.hueImage.frame) + DRColorPickerWheelViewDefaultMargin : CGRectGetMaxY(self.saturationView.frame) + DRColorPickerWheelViewDefaultMargin);
    self.brightnessView.frame = CGRectMake(DRColorPickerWheelViewDefaultMargin,
                                           brightnessY,
                                           CGRectGetWidth(self.frame) - (DRColorPickerWheelViewDefaultMargin * 2),
                                           DRColorPickerWheelViewGradientViewHeight);

    [self updateIndicatorsPosition];
    [self updateColorBubblePosition];
}

- (void) textFieldChanged:(id)sender
{
    NSString* text = [self.rgbTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (text.length == 6)
    {
        UIColor* color = [UIColor colorWithHexString:text];
        if (color != nil)
        {
            [self setColor:color];
        }
    }
}

- (BOOL) textField:(UITextField*)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString*)string
{
    return ([textField.text stringByReplacingCharactersInRange:range withString:string].length <= 6);
}

- (BOOL) textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    
    return NO;
}

- (void) setColor:(UIColor*)newColor
{
    if (![_color isEqual:newColor])
    {
        [newColor getHue:&_hue saturation:&_saturation brightness:&_brightness alpha:NULL];
        CGColorSpaceModel colorSpaceModel = newColor.colorSpaceModel;
        if (colorSpaceModel == kCGColorSpaceModelMonochrome && newColor != nil)
        {
            const CGFloat* c = CGColorGetComponents(newColor.CGColor);
            _color = [UIColor colorWithHue:0 saturation:0 brightness:c[0] alpha:1.0];
        }
        else
        {
            _color = [newColor copy];
        }
        
        if (self.colorChangedBlock != nil)
        {
            self.colorChangedBlock(self.color);
        }

        self.colorPreviewView.backgroundColor = newColor;
        NSString* hex = newColor.hexStringFromColorNoAlpha;
        if ([hex caseInsensitiveCompare:self.rgbTextField.text] != NSOrderedSame)
        {
            self.rgbTextField.text = hex;
        }

        [self updateIndicatorsColor];
        [self updateIndicatorsPosition];
        [self updateColorBubblePosition];
    }
}

- (void) updateIndicatorsPosition
{
    [self.color getHue:nil saturation:&_saturation brightness:&_brightness alpha:nil];
    
    CGPoint brightnessPosition;
    brightnessPosition.x = (1.0f - self.brightness) * self.brightnessView.frame.size.width + self.brightnessView.frame.origin.x;
    brightnessPosition.y = self.brightnessView.center.y;
    
    self.brightnessIndicator.center = brightnessPosition;

    CGPoint saturationPosition;
    saturationPosition.x = (1.0f - self.saturation) * self.saturationView.frame.size.width + self.saturationView.frame.origin.x;
    saturationPosition.y = self.saturationView.center.y;

    self.saturationIndicator.center = saturationPosition;
}

- (void) setColorBubblePosition:(CGPoint)p
{
    self.colorBubble.center = p;
}

- (void) updateColorBubblePosition
{
    CGPoint hueSatPosition;
    
    hueSatPosition.x = (self.hue * self.hueImage.frame.size.width) + self.hueImage.frame.origin.x;
    hueSatPosition.y = (1.0f - self.saturation) * self.hueImage.frame.size.height + self.hueImage.frame.origin.y;
    [self setColorBubblePosition:hueSatPosition];
    [self updateIndicatorsColor];
}

- (void) updateIndicatorsColor
{
    UIColor* brightnessColor1 = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:1.0f alpha:1.0f];
    UIColor* brightnessColor2 = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:0.0f alpha:1.0f];
    self.colorBubble.backgroundColor = brightnessColor1;
	[self.brightnessView setColor1:brightnessColor1];
	[self.brightnessView setColor2:brightnessColor2];

    UIColor* saturationColor1 = [UIColor colorWithHue:self.hue saturation:0.0f brightness:1.0f alpha:1.0f];
    UIColor* saturationColor2 = [UIColor colorWithHue:self.hue saturation:1.0f brightness:1.0f alpha:1.0f];
    [self.saturationView setColor1:saturationColor2];
    [self.saturationView setColor2:saturationColor1];
}

- (void) updateHueWithMovement:(CGPoint)position
{
	self.hue = (position.x - self.hueImage.frame.origin.x) / self.hueImage.frame.size.width;
	self.saturation = 1.0f -  (position.y - self.hueImage.frame.origin.y) / self.hueImage.frame.size.height;
    
	UIColor* topColor = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:1.0f];
    UIColor* gradientColor = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:1.0f alpha:1.0f];
    self.colorBubble.backgroundColor = gradientColor;
    [self updateIndicatorsColor];
    [self setColor:topColor];
}

- (void) updateBrightnessWithMovement:(CGPoint)position
{
	self.brightness = 1.0f - ((position.x - self.brightnessView.frame.origin.x) / self.brightnessView.frame.size.width);
	
	UIColor* topColor = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:1.0f];
    [self setColor:topColor];
}

- (void) updateSaturationWithMovement:(CGPoint)position
{
    self.saturation = 1.0f - ((position.x - self.saturationView.frame.origin.x) / self.saturationView.frame.size.width);

    UIColor* topColor = [UIColor colorWithHue:self.hue saturation:self.saturation brightness:self.brightness alpha:1.0f];
    [self setColor:topColor];
}

- (void) touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesBegan:touches withEvent:event];

	for (UITouch* touch in touches)
    {
		[self handleTouchEvent:[touch locationInView:self]];
    }
}

- (void) touchesMoved:(NSSet*)touches withEvent:(UIEvent*)event
{
    [super touchesMoved:touches withEvent:event];

	for (UITouch* touch in touches)
    {
		[self handleTouchEvent:[touch locationInView:self]];
	}
}

- (void) touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesEnded:touches withEvent:event];
	
	self.focusView = nil;
}

- (void) touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    [super touchesCancelled:touches withEvent:event];

    self.focusView = nil;
}

- (void) handleTouchEvent:(CGPoint)position
{
	if (self.focusView == self.hueImage || (self.focusView == nil && CGRectContainsPoint(self.hueImage.frame,position)))
    {
		position.x = MIN(MAX(CGRectGetMinX(self.hueImage.frame), position.x), CGRectGetMaxX(self.hueImage.frame) - 1);
		position.y = MIN(MAX(CGRectGetMinY(self.hueImage.frame), position.y), CGRectGetMaxY(self.hueImage.frame) - 1);
		self.focusView = self.hueImage;
		[self setColorBubblePosition:position];
		[self updateHueWithMovement:position];
	}
    else if (self.focusView == self.brightnessView || (self.focusView == nil && CGRectContainsPoint(self.brightnessView.frame, position)))
    {
        position.x = MIN(MAX(CGRectGetMinX(self.brightnessView.frame), position.x), CGRectGetMaxX(self.brightnessView.frame) - 1);
        position.y = MIN(MAX(CGRectGetMinY(self.brightnessView.frame), position.y), CGRectGetMaxY(self.brightnessView.frame) - 1);
		self.focusView = self.brightnessView;
        self.brightnessIndicator.center = CGPointMake(position.x, self.brightnessView.center.y);
		[self updateBrightnessWithMovement:position];
	}
    else if (self.saturationView != nil && (self.focusView == self.saturationView || (self.focusView == nil && CGRectContainsPoint(self.saturationView.frame, position))))
    {
        position.x = MIN(MAX(CGRectGetMinX(self.saturationView.frame), position.x), CGRectGetMaxX(self.saturationView.frame) - 1);
        position.y = MIN(MAX(CGRectGetMinY(self.saturationView.frame), position.y), CGRectGetMaxY(self.saturationView.frame) - 1);
		self.focusView = self.saturationView;
        self.saturationIndicator.center = CGPointMake(position.x, self.saturationView.center.y);
        [self updateSaturationWithMovement:position];
    }
}

@end

