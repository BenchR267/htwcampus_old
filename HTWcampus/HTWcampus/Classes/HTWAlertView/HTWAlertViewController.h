//
//  HTWAlertViewController.h
//  test
//
//  Created by Benjamin Herzog on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWAlertViewCDelegate <NSObject>

@optional
-(void)gotStringsFromTextFields:(NSArray*)strings;

@end

@interface HTWAlertViewController : UITableViewController

@property (nonatomic, strong) NSString *htwTitle;
@property (nonatomic, strong) NSString *message;
@property (nonatomic, strong) NSString *commitButtonTitle;

@property (nonatomic, strong) NSArray *mainTitle;

@property (nonatomic, strong) id <HTWAlertViewCDelegate> delegate;



@end
