//
//  mensaViewController.h
//  HTWcampus
//
//  Created by Konstantin on 09.10.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface mensaViewController : UITableViewController  {
    NSInteger mensaDay;
    BOOL isLoading;
    NSDictionary *mensaMeta;
}
- (NSString *)checkWorkingHours:currentMensaName;
- (void)loadMensa;
- (void)addMensaData;
- (void)setMensaDay;
- (void)reloadView;
- (IBAction)refreshMensa:(id)sender;
- (NSString *)getMensaImageNameForName:(NSString *)mensaArray;

@property (strong, nonatomic) IBOutlet UISegmentedControl *mensaDaySwitcher;
@property (weak, nonatomic) IBOutlet UITableView *mensaTableView;
@end