//
//  HTWDozentEingebenTableViewController.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWNeuerDozentDelegate <NSObject>

@optional
-(void)neuerDozentEingegeben;

@end

@interface HTWDozentEingebenTableViewController : UITableViewController

@property (nonatomic, strong) id <HTWNeuerDozentDelegate> delegate;

@end
