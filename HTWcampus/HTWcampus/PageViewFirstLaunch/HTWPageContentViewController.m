//
//  PageContentViewController.m
//  PageViewDemo
//
//  Created by Simon on 24/11/13.
//  Copyright (c) 2013 Appcoda. All rights reserved.
//

#import "HTWPageContentViewController.h"
#import "HTWAppDelegate.h"

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
    
    if(_pageIndex == 6) _goButton.hidden = NO;
    else _goButton.hidden = YES;

    _goButton.backgroundColor = [UIColor HTWBlueColor];
    _goButton.tintColor = [UIColor HTWWhiteColor];
    [_goButton.titleLabel setFont:[UIFont boldSystemFontOfSize:27]];
    _goButton.layer.cornerRadius = 7;
    _goButton.layer.borderColor = [UIColor HTWWhiteColor].CGColor;
    _goButton.layer.borderWidth = 1;
}
- (IBAction)goButtonClicked:(id)sender {
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"skipTut"];
    HTWAppDelegate *appD = [[UIApplication sharedApplication] delegate];
    UITabBarController *tbc = [[UIStoryboard storyboardWithName:@"main" bundle:nil] instantiateViewControllerWithIdentifier:@"tabBarController"];
    [UIView transitionWithView:appD.window
                      duration:0.5
                       options:UIViewAnimationOptionTransitionFlipFromRight
                    animations:^{

                        [appD.window setRootViewController:tbc];

                    }
                    completion:nil];
}

@end
