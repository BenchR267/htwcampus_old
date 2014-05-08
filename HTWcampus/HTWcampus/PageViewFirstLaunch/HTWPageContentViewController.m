//
//  PageContentViewController.m
//  PageViewDemo
//
//  Created by Simon on 24/11/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "HTWPageContentViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWPageContentViewController ()

@end

@implementation HTWPageContentViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    self.backgroundImageView.image = [UIImage imageNamed:self.imageFile];
    self.titleLabel.text = self.titleText;
    self.titleLabel.font = [UIFont HTWBaseFont];
    self.titleLabel.textColor = [UIColor HTWDarkGrayColor];
    

}

@end
