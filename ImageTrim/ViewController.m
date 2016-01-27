//
//  ViewController.m
//  ImageTrim
//
//  Created by Cameron Ehrlich on 1/26/16.
//  Copyright © 2016 CIE Digital Labs. All rights reserved.
//

#import "ViewController.h"
#import "UIImage+ImageTrim.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:0.5f];
    
    UIImage *image = [UIImage imageNamed:@"Screen Shot 2016-01-26 at 4.28.12 PM"];
    
    self.imageView.image = [UIImage trimmedImageFromImage:image withBorderColor:[UIColor whiteColor] withTolerance:0.1f];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
