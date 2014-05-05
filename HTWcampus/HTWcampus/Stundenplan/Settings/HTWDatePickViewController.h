//
//  HTWDatePickViewController.h
//  HTW-App
//
//  Created by Benjamin Herzog on 23.03.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWDatePickViewControllerDelegate <NSObject>

@required
-(void)getNewDate:(NSDate*)newDate andAnfang:(BOOL)ja;

@end

@interface HTWDatePickViewController : UIViewController

@property (nonatomic, assign) id <HTWDatePickViewControllerDelegate> delegate;
@property BOOL anfang;
@property (nonatomic, strong) NSDate *date;

@end
