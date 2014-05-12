//
//  HTWNeueStudiengruppe.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWNeueStudiengruppeDelegate <NSObject>

@optional
-(void)neueStudienGruppeEingegeben;

@end

@interface HTWNeueStudiengruppe : UITableViewController

@property (nonatomic, strong) id <HTWNeueStudiengruppeDelegate> delegate;

@end
