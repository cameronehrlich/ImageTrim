//
//  UIImage+ImageTrim.h
//  ImageTrim
//
//  Created by Cameron Ehrlich on 1/26/16.
//  Copyright © 2016 CIE Digital Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface UIImage (ImageTrim)

+ (UIImage *)trimmedImageFromImage:(UIImage *)image withBorderColor:(UIColor *)borderColor withTolerance:(CGFloat)tolerance;

@end
