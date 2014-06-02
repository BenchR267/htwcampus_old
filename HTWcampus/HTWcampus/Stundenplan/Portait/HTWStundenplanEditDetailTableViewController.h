//
//  HTWStundenplanEditDetailTableViewController.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 06.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stunde.h"

@interface HTWStundenplanEditDetailTableViewController : UITableViewController

@property BOOL oneLessonOnly;
@property (nonatomic, strong) Stunde *stunde;

@end
