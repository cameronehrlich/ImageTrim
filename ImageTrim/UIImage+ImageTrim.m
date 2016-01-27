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

static NSUInteger const bytesPerRow = 4;
static NSUInteger const bitsPerComponent = 8;
static NSUInteger const maxColorSpaceValue = 255;

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
    
    size_t width = CGImageGetWidth(cgImage);
    size_t height = CGImageGetHeight(cgImage);
    
    NSUInteger bitmapBytesPerRow = (width * bytesPerRow);
    NSUInteger bitmapByteCount = (bitmapBytesPerRow * height);
    
    
    unsigned char *bitmapData = malloc(bitmapByteCount);
    if (bitmapData == NULL) {
        return CGRectZero;
    }
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    CGContextRef context = CGBitmapContextCreate(bitmapData,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bitmapBytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    if (context == NULL)  {
        free(bitmapData);
        return CGRectZero;
    }
    
    CGRect rect = CGRectMake(0.0f, 0.0f, width, height);
    CGContextDrawImage(context, rect, cgImage);
    CGContextRelease(context);
    
    const CGFloat *components = CGColorGetComponents(borderColor.CGColor);
    const size_t numberOfComponents = CGColorGetNumberOfComponents(borderColor.CGColor);
    
    NSUInteger borderRed, borderGreen, borderBlue, borderAlpha;
    if (numberOfComponents == 2) { // if black or white...see http://stackoverflow.com/questions/9238743/is-there-an-issue-with-cgcolorgetcomponents
        borderRed = borderGreen = borderBlue = components[0] * maxColorSpaceValue;
        borderAlpha = components[1] * maxColorSpaceValue;
    }
    else if (numberOfComponents == 4) {
        borderRed   = components[0] * maxColorSpaceValue;
        borderGreen = components[1] * maxColorSpaceValue;
        borderBlue  = components[2] * maxColorSpaceValue;
        borderAlpha = components[3] * maxColorSpaceValue;
    }
    else {
        NSLog(@"Unknown number of color components");
        free(bitmapData);
        return CGRectZero;
    }
    
    NSInteger imageAlpha, imageRed, imageGreen, imageBlue;
    NSUInteger lowX = width;
    NSUInteger lowY = height;
    NSUInteger highX = 0;
    NSUInteger highY = 0;
    for (NSUInteger y = 0; y < height; y++) {
        for (NSUInteger x = 0; x < width; x++) {
            
            NSUInteger startingIndex = ((width * y) + x) * bytesPerRow; /// * 4 for A, R, G, B
            
            imageAlpha  = bitmapData[startingIndex + 0];
            imageRed    = bitmapData[startingIndex + 1];
            imageGreen  = bitmapData[startingIndex + 2];
            imageBlue   = bitmapData[startingIndex + 3];
            
            CGFloat toleranceThreashold = (tolerance * maxColorSpaceValue);
            
            BOOL isAlphaMatch   = ABS(borderAlpha - imageAlpha)   < toleranceThreashold;
            BOOL isRedMatch     = ABS(borderRed - imageRed)       < toleranceThreashold;
            BOOL isGreenMatch   = ABS(borderGreen - imageGreen)   < toleranceThreashold;
            BOOL isBlueMatch    = ABS(borderBlue - imageBlue)     < toleranceThreashold;
            
            BOOL isColorMatch = isRedMatch & isGreenMatch & isBlueMatch & isAlphaMatch;
            
            if (!isColorMatch) {
                
                if (x < lowX) lowX = x;
                else if (x > highX) highX = x;
                
                if (y < lowY) lowY = y;
                else if (y > highY) highY = y;
            }
        }
    }
    
    free(bitmapData);
    
    return CGRectMake(lowX, lowY, highX-lowX, highY-lowY);
}

@end
