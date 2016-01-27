//
//  UIImage+ImageTrim.m
//  ImageTrim
//
//  Created by Cameron Ehrlich on 1/26/16.
//  Copyright © 2016 CIE Digital Labs. All rights reserved.
//

@import QuartzCore;

#import "UIImage+ImageTrim.h"

@implementation UIImage (ImageTrim)

+ (UIImage *)trimmedImageFromImage:(UIImage *)image withBorderColor:(UIColor *)borderColor withTolerance:(CGFloat)tolerance
{
    CGRect newRect = [self cropRectForImage:image withBorderColor:borderColor withTolerance:tolerance];
    CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, newRect);
    UIImage *newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return newImage;
}

+ (CGRect)cropRectForImage:(UIImage *)image withBorderColor:(UIColor *)borderColor withTolerance:(CGFloat)tolerance
{
    CGImageRef cgImage = image.CGImage;
    CGContextRef context = [self createARGBBitmapContextFromImage:cgImage];
    if (context == NULL) {
        NSLog(@"Failed to create valid bitmap context.");
        return CGRectZero;
    }
    
    NSUInteger borderRed, borderGreen, borderBlue, borderAlpha;
    
    const CGFloat *components = CGColorGetComponents(borderColor.CGColor);

    // if black or white... see http://stackoverflow.com/questions/9238743/is-there-an-issue-with-cgcolorgetcomponents
    if (CGColorGetNumberOfComponents(borderColor.CGColor) == 2) {
        borderRed   = (NSUInteger) components[0] * 255;
        borderGreen = (NSUInteger) components[0] * 255;
        borderBlue  = (NSUInteger) components[0] * 255;
        borderAlpha = (NSUInteger) components[1] * 255;
    }
    else if (CGColorGetNumberOfComponents(borderColor.CGColor) == 4) {
        borderRed   = (NSUInteger) components[0] * 255;
        borderGreen = (NSUInteger) components[1] * 255;
        borderBlue  = (NSUInteger) components[2] * 255;
        borderAlpha = (NSUInteger) components[3] * 255;
    }
    else {
        NSLog(@"Unknown number of color components");
        return CGRectZero;
    }
    
    NSLog(@"r=%ld, g=%ld, b=%ld, a=%ld", borderRed, borderGreen, borderBlue, borderAlpha);
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    
    CGContextDrawImage(context, rect, cgImage);
    
    unsigned char *data = CGBitmapContextGetData(context);
    CGContextRelease(context);
    
    
    NSInteger imageAlpha, imageRed, imageGreen, imageBlue;
    
    NSUInteger lowX = width;
    NSUInteger lowY = height;
    NSUInteger highX = 0;
    NSUInteger highY = 0;
    if (data != NULL) {
        for (NSUInteger y = 0; y < height; y++) {
            for (NSUInteger x = 0; x < width; x++) {
                NSUInteger startingIndex = (width * y + x) * 4 /* 4 for A, R, G, B */;
                
                imageAlpha  = data[startingIndex];
                imageRed    = data[startingIndex + 1];
                imageGreen  = data[startingIndex + 2];
                imageBlue   = data[startingIndex + 3];
                
                BOOL isAlphaMatch = ABS(borderAlpha - imageAlpha) < (tolerance * 255);
                BOOL isRedMatch   = ABS(borderRed - imageRed)     < (tolerance * 255);
                BOOL isGreenMatch = ABS(borderGreen - imageGreen) < (tolerance * 255);
                BOOL isBlueMatch = ABS(borderBlue - imageBlue) < (tolerance * 255);
                
                BOOL isColorMatch = isAlphaMatch && isRedMatch && isGreenMatch && isBlueMatch;
                
                if (!isColorMatch) {
                    
//                    NSLog(@"r = %ld : %ld, g = %ld : %ld, b = %ld : %ld, a = %ld : %ld", borderRed, imageRed, borderGreen, imageGreen, borderBlue, imageBlue, borderAlpha, imageAlpha);

                    if (x < lowX)  {
                        lowX = x;
                    }
                    if (x > highX) {
                        highX = x;
                    }
                    if (y < lowY) {
                        lowY = y;
                    }
                    if (y > highY) {
                        highY = y;
                    }
                }
            }
        }
        free(data);
    }
    else {
        NSLog(@"Failed to determine rect for trim.");
        return CGRectZero;
    }
    
    return CGRectMake(lowX, lowY, highX-lowX, highY-lowY);
}

+ (CGContextRef)createARGBBitmapContextFromImage:(CGImageRef)inImage
{
    CGContextRef context = NULL;
    CGColorSpaceRef colorSpace;
    void *bitmapData;
    NSUInteger bitmapByteCount;
    NSUInteger bitmapBytesPerRow;
    
    // Get image width, height. We'll use the entire image.
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    
    // Declare the number of bytes per row. Each pixel in the bitmap in this
    // example is represented by 4 bytes; 8 bits each of red, green, blue, and
    // alpha.
    bitmapBytesPerRow = (width * 4);
    bitmapByteCount = (bitmapBytesPerRow * height);
    
    // Use the generic RGB color space.
    colorSpace = CGColorSpaceCreateDeviceRGB();
    if (colorSpace == NULL) return NULL;
    
    // Allocate memory for image data. This is the destination in memory
    // where any drawing to the bitmap context will be rendered.
    bitmapData = malloc( bitmapByteCount );
    if (bitmapData == NULL)
    {
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }
    
    // Create the bitmap context. We want pre-multiplied ARGB, 8-bits
    // per component. Regardless of what the source image format is
    // (CMYK, Grayscale, and so on) it will be converted over to the format
    // specified here by CGBitmapContextCreate.
    context = CGBitmapContextCreate (bitmapData,
                                     width,
                                     height,
                                     8,      // bits per component
                                     bitmapBytesPerRow,
                                     colorSpace,
                                     kCGImageAlphaPremultipliedFirst);
    if (context == NULL) free (bitmapData);
    
    // Make sure and release colorspace before returning
    CGColorSpaceRelease(colorSpace);
    
    return context;
}

@end
