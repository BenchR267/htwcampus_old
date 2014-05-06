//
//  HTWStundenplanEditDetailTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 06.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanEditDetailTableViewController.h"
#import "UIFont+HTW.h"
#import "UIColor+HTW.h"

@implementation HTWStundenplanEditDetailTableViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = _stunde.kurzel;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: return 82;
        default: return 50;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Titel";
            cell.detailTextLabel.text = _stunde.titel;
            break;
        case 1:
            cell.textLabel.text = @"Kürzel";
            cell.detailTextLabel.text = _stunde.kurzel;
            break;
        case 2:
            cell.textLabel.text = @"Raum";
            cell.detailTextLabel.text = _stunde.raum;
            break;
        case 3:
            cell.textLabel.text = @"Dozent";
            cell.detailTextLabel.text = _stunde.dozent;
            break;
        case 4:
            cell.textLabel.text = @"Typ";
            if([_stunde.kurzel componentsSeparatedByString:@" "].count > 1) cell.detailTextLabel.text = [_stunde.kurzel componentsSeparatedByString:@" "][1];
            break;
        case 5:
            cell.textLabel.text = @"Anfang";
            cell.detailTextLabel.text = [self stringFromDate:_stunde.anfang];
            break;
        case 6:
            cell.textLabel.text = @"Ende";
            cell.detailTextLabel.text = [self stringFromDate:_stunde.ende];
            break;
            
        default:
            break;
    }
    
    return cell;
}

-(NSString *)stringFromDate:(NSDate*)date
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF stringFromDate:date];
}

@end
