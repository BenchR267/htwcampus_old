//
//  notenDetailViewController.m
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#import "HTWNotenDetailTableViewController.h"
#import "UIColor+HTW.h"

@interface HTWNotenDetailTableViewController ()

@end

@implementation HTWNotenDetailTableViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.fach.name;
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    return 7;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"fachDetailZelle";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    NSString *text;
    NSString *detailedText;
    
    switch (indexPath.row) {
        case 0:
            text = @"Fach";
            detailedText = self.fach.name;
            break;
        case 1:
            text = @"Note";
            detailedText = [NSString stringWithFormat:@"%.1f",self.fach.note.floatValue];
            break;
        case 2:
            text = @"Status";
            detailedText = self.fach.status;
            break;
        case 3:
            text = @"Credits";
            detailedText = [NSString stringWithFormat:@"%.1f",self.fach.credits.floatValue];
            break;
        case 4:
            text = @"Versuch";
            detailedText = [NSString stringWithFormat:@"%d",self.fach.versuch.intValue];
            break;
        case 5:
            text = @"Semester";
            detailedText = self.fach.semester;
            break;
        case 6:
            text = @"Prüfungsnummer";
            detailedText = [NSString stringWithFormat:@"%d",self.fach.nr.intValue];
            break;
            
        default:
            break;
    }
    cell.textLabel.text = text;
    cell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    cell.detailTextLabel.text = detailedText;
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

@end
