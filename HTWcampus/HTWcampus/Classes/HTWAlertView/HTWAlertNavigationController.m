//
//  HTWAlertNavigationController.m
//  test
//
//  Created by Benjamin Herzog on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWAlertNavigationController.h"
#import "HTWAlertViewController.h"

@interface HTWAlertNavigationController () <HTWAlertViewCDelegate>

@end

@implementation HTWAlertNavigationController

-(void)setHtwTitle:(NSString *)htwTitle
{
    [(HTWAlertViewController*)self.viewControllers[0] setHtwTitle:htwTitle];
}

-(void)setMessage:(NSString *)message
{
    [(HTWAlertViewController*)self.viewControllers[0] setMessage:message];
}

-(void)setCommitButtonTitle:(NSString *)commitButtonTitle
{
    [(HTWAlertViewController*)self.viewControllers[0] setCommitButtonTitle:commitButtonTitle];
}

-(void)setMainTitle:(NSMutableArray *)mainTitle
{
    [(HTWAlertViewController*)self.viewControllers[0] setMainTitle:mainTitle];
}

-(void)setHtwDelegate:(id<HTWAlertViewDelegate>)htwDelegate
{
    [(HTWAlertViewController*)self.viewControllers[0] setDelegate:self];
    _htwDelegate = htwDelegate;
}

-(void)setNumberOfSecureTextField:(NSArray *)numberOfSecureTextField
{
    [(HTWAlertViewController*)self.viewControllers[0] setNumberOfSecureTextField:numberOfSecureTextField];
}

-(void)gotStringsFromTextFields:(NSArray *)strings
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{
        if(_htwDelegate)
        {
            [_htwDelegate htwAlert:self gotStringsFromTextFields:strings];
        }
    }];
}

@end
