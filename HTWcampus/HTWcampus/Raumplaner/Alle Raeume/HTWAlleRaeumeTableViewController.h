//
//  TableViewController.h
//  test
//
//  Created by Benjamin Herzog on 13.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWAlleRaeumeDelegate <NSObject>

@optional
-(void)neuerRaumAusgewaehlt:(NSString*)raumNummer;

@end

@interface HTWAlleRaeumeTableViewController : UITableViewController

@property (nonatomic, strong) id <HTWAlleRaeumeDelegate> delegate;

@end
