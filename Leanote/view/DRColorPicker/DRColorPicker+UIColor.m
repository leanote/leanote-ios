//
//  DRColorPicker+UIColor.m
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

#import "DRColorPicker+UIColor.h"

@implementation UIColor (DRColorPicker)

- (NSString*) hexStringFromColor
{
	return [NSString stringWithFormat:@"%0.8X", (unsigned int)self.rgbaHex];
}

- (NSString*) hexStringFromColorAlphaOne
{
    return [NSString stringWithFormat:@"%0.6XFF", (unsigned int)self.rgbHex];
}

- (NSString*) hexStringFromColorNoAlpha
{
    return [NSString stringWithFormat:@"%0.6X", (unsigned int)self.rgbHex];    
}

+ (UIColor*) colorWithRGBHex:(UInt32)hex
{
	CGFloat r = (hex >> 16) & 0xFF;
	CGFloat g = (hex >> 8) & 0xFF;
	CGFloat b = (hex) & 0xFF;

	return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:1.0f];
}

- (NSString *)stringFromColor
{
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -stringFromColor");
	NSString *result;
	switch (self.colorSpaceModel)
    {
		case kCGColorSpaceModelRGB:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f, %0.3f, %0.3f}", self.red, self.green, self.blue, self.alpha];
			break;
		case kCGColorSpaceModelMonochrome:
			result = [NSString stringWithFormat:@"{%0.3f, %0.3f}", self.white, self.alpha];
			break;
		default:
			result = nil;
	}
	return result;
}

+ (UIColor*) colorWithString:(NSString *)stringToConvert
{
	NSScanner *scanner = [NSScanner scannerWithString:stringToConvert];
	if (![scanner scanString:@"{" intoString:NULL])
    {
        return nil;
    }
	const NSUInteger kMaxComponents = 4;
	float c[kMaxComponents];
	NSUInteger i = 0;
	if (![scanner scanFloat:&c[i++]])
    {
        return nil;
    }

	while (1) {
		if ([scanner scanString:@"}" intoString:NULL])
        {
            break;
        }
		else if (i >= kMaxComponents)
        {
            return nil;
        }
		else if ([scanner scanString:@"," intoString:NULL])
        {
			if (![scanner scanFloat:&c[i++]]) return nil;
		}
        else
        {
			return nil;
		}
	}
	if (![scanner isAtEnd])
    {
        return nil;
    }

	UIColor *color;
	switch (i)
    {
		case 2: // monochrome
			color = [UIColor colorWithWhite:c[0] alpha:c[1]];
			break;
		case 4: // RGB
			color = [UIColor colorWithRed:c[0] green:c[1] blue:c[2] alpha:c[3]];
			break;
		default:
			color = nil;
	}
	return color;
}

+ (UIColor*) colorWithRGBAHex:(UInt32)hex
{
	CGFloat r = (hex >> 24) & 0xFF;
	CGFloat g = (hex >> 16) & 0xFF;
	CGFloat b = (hex >> 8) & 0xFF;
    CGFloat a = (hex) & 0xFF;

	return [UIColor colorWithRed:r / 255.0f green:g / 255.0f blue:b / 255.0f alpha:a / 255.0f];
}

// Returns a UIColor by scanning the string for a hex number and passing that to +[UIColor colorWithRGBHex:]
// Skips any leading whitespace and ignores any trailing characters
+ (UIColor*) colorWithHexString:(NSString*)stringToConvert
{
	NSScanner* scanner = [NSScanner scannerWithString:stringToConvert];
	unsigned hexNum;
	if (![scanner scanHexInt:&hexNum])
    {
        return nil;
    }

	return (stringToConvert.length == 6 ? [UIColor colorWithRGBHex:hexNum] : [UIColor colorWithRGBAHex:hexNum]);
}

- (CGFloat) alpha
{
	return CGColorGetAlpha(self.CGColor);
}

- (UInt32) rgbHex
{
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use rgbHex");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a])
    {
        return 0;
    }

	r = MIN(MAX(self.red, 0.0f), 1.0f);
	g = MIN(MAX(self.green, 0.0f), 1.0f);
	b = MIN(MAX(self.blue, 0.0f), 1.0f);

	return (((UInt32)roundf(r * 255)) << 16) | (((UInt32)roundf(g * 255)) << 8) | (((UInt32)roundf(b * 255)));
}

- (UInt32) rgbaHex
{
	NSAssert(self.canProvideRGBComponents, @"Must be a RGB color to use rgbaHex");

	CGFloat r,g,b,a;
	if (![self red:&r green:&g blue:&b alpha:&a])
    {
        return 0;
    }

	r = MIN(MAX(self.red, 0.0f), 1.0f);
	g = MIN(MAX(self.green, 0.0f), 1.0f);
	b = MIN(MAX(self.blue, 0.0f), 1.0f);
    a = MIN(MAX(self.alpha, 0.0f), 1.0f);

	return (((UInt32)roundf(r * 255)) << 24) | (((UInt32)roundf(g * 255)) << 16) | (((UInt32)roundf(b * 255)) << 8) | (((UInt32)roundf(a * 255)));
}

- (BOOL) red:(CGFloat *)red green:(CGFloat *)green blue:(CGFloat *)blue alpha:(CGFloat *)alpha
{
	const CGFloat* components = CGColorGetComponents(self.CGColor);

	CGFloat r,g,b,a;

	switch (self.colorSpaceModel)
    {
		case kCGColorSpaceModelMonochrome:
			r = g = b = components[0];
			a = components[1];
			break;
		case kCGColorSpaceModelRGB:
			r = components[0];
			g = components[1];
			b = components[2];
			a = components[3];
			break;
		default:	// We don't know how to handle this model
			return NO;
	}

	if (red) *red = r;
	if (green) *green = g;
	if (blue) *blue = b;
	if (alpha) *alpha = a;

	return YES;
}

- (CGFloat) red
{
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -red");
	const CGFloat* c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (CGFloat) green
{
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -green");
	const CGFloat* c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[1];
}

- (CGFloat) blue
{
	NSAssert(self.canProvideRGBComponents, @"Must be an RGB color to use -blue");
	const CGFloat* c = CGColorGetComponents(self.CGColor);
	if (self.colorSpaceModel == kCGColorSpaceModelMonochrome) return c[0];
	return c[2];
}

- (CGFloat) white
{
	NSAssert(self.colorSpaceModel == kCGColorSpaceModelMonochrome, @"Must be a Monochrome color to use -white");
	const CGFloat* c = CGColorGetComponents(self.CGColor);
	return c[0];
}

- (BOOL) canProvideRGBComponents
{
	switch (self.colorSpaceModel)
    {
		case kCGColorSpaceModelRGB:
		case kCGColorSpaceModelMonochrome:
			return YES;
		default:
			return NO;
	}
}

- (CGColorSpaceModel) colorSpaceModel
{
	return CGColorSpaceGetModel(CGColorGetColorSpace(self.CGColor));
}

@end
