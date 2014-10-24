//
//  HTWAlertNavigationController.h
//  test
//
//  Created by Benjamin Herzog on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HTWAlertNavigationController;

@protocol HTWAlertViewDelegate <NSObject>

@optional
-(void)htwAlert:(HTWAlertNavigationController*)alert gotStringsFromTextFields:(NSArray*)strings;

@end

@interface HTWAlertNavigationController : UINavigationController

@property (nonatomic, strong) NSString *htwTitle;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *commitButtonTitle;

@property int tag;

@property (nonatomic, strong) NSArray *mainTitle;
@property (nonatomic, strong) NSArray *numberOfSecureTextField;

@property (nonatomic, strong) id <HTWAlertViewDelegate> htwDelegate;

@end

