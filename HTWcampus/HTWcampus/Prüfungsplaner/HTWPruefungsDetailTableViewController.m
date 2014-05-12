//
//  HTWPruefungsDetailTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsDetailTableViewController.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWPruefungsDetailTableViewController ()

@property (nonatomic, strong) NSArray *keys;

@end

@implementation HTWPruefungsDetailTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    self.title = _pruefung[_keys[5]];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _keys.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 5: return 80;
        default: return 50;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Informationen";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.text = _keys[indexPath.row];
    cell.detailTextLabel.text = _pruefung[_keys[indexPath.row]];
    
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

@end
