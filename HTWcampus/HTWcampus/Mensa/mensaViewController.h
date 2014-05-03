//
//  mensaViewController.h
//  HTWcampus
//
//  Created by Konstantin on 09.10.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MensaXMLParserDelegate.h"

@interface mensaViewController : UITableViewController <CustomMensaManagerDelegate> {
    NSInteger mensaDay;
    BOOL isLoading;
    NSDictionary *mensaMeta;
}
- (NSString *)checkWorkingHours:currentMensaName;
- (IBAction)loadMensa;
- (void)addMensaData;
- (void)setMensaDay;
- (void)reloadView;
- (IBAction)refreshMensa:(id)sender;
- (NSString *)getMensaImageNameForName:(NSString *)mensaArray;

@property (strong, nonatomic) IBOutlet UISegmentedControl *mensaDaySwitcher;
@property (weak, nonatomic) IBOutlet UITableView *mensaTableView;
@property (strong, nonatomic) IBOutlet NSMutableArray *allMensasOfToday;
@property (strong, nonatomic) IBOutlet NSMutableArray *allMensasOfTomorrow;
@property (strong, nonatomic) NSMutableArray *feedList;
@end