//
//  HTWPruefungsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsTableViewController.h"
#import "HTWPruefungsParser.h"
#import "HTWPruefungsDetailTableViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWPruefungsTableViewController ()

@property (nonatomic, strong) NSArray *pruefungsArray;

@end

@implementation HTWPruefungsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Prüfungen";
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    
    HTWPruefungsParser *parser = [[HTWPruefungsParser alloc] initWithURL:[NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/pr_abfrage.php"] andImmaJahr:@"12" andStudienGruppe:@"041" andBDM:@"B"];
    [parser startWithCompletetionHandler:^(NSArray *erg, NSString *errorMessage) {
        if(errorMessage) { NSLog(@"ERROR: %@", errorMessage); return;}
        self.pruefungsArray = [NSArray arrayWithArray:erg];
        [self.tableView reloadData];
    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_pruefungsArray) return self.pruefungsArray.count - 2;
    else return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 80;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Prüfungen";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!_pruefungsArray) return cell;
    cell.textLabel.text = _pruefungsArray[indexPath.row+1][@"Modul"];
    cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ Uhr", _pruefungsArray[indexPath.row+1][@"Tag"], _pruefungsArray[indexPath.row+1][@"Zeit"]];
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.font = [UIFont HTWMediumFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pruefungsDetail"]) {
        if ([segue.destinationViewController isKindOfClass:[HTWPruefungsDetailTableViewController class]]) {
            HTWPruefungsDetailTableViewController *pdtvc = (HTWPruefungsDetailTableViewController*)segue.destinationViewController;
            UITableViewCell *senderCell = (UITableViewCell *)sender;
            int row = [self.tableView indexPathForCell:senderCell].row;
            pdtvc.pruefung = _pruefungsArray[row+1];
        }
    }
}

@end
