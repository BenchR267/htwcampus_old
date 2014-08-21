//
//  HTWMatrikelnummernEditTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 08.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMatrikelnummernEditTableViewController.h"
#import "HTWAppdelegate.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWMatrikelnummernEditTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSUserDefaults *defaults;
@property (nonatomic, strong) UITextField *textfield;

@end

@implementation HTWMatrikelnummernEditTableViewController

#pragma mark - ViewController Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.defaults = [[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"];
    self.view.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = _user.name;
    self.textfield = [[UITextField alloc] init];
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 2;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Name";
            cell.detailTextLabel.text = _user.name;
            break;
        case 1:
            if(_user.dozent.boolValue) {
                cell.textLabel.text = @"Kennung";
                NSMutableString *string = [[NSMutableString alloc] init];
                for(int i=0; i<_user.matrnr.length; i++) [string appendString:@"*"];
                cell.detailTextLabel.text = string;
            }
            else {
                cell.textLabel.text = @"Matrikelnummer";
                cell.detailTextLabel.text = _user.matrnr;
            }
        default:
            break;
    }
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.row == 0)
    {
            [self.tableView reloadData];
            UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
            CGRect frame = CGRectMake(sender.frame.size.width/4, sender.detailTextLabel.frame.origin.y, sender.frame.size.width/4*3-20, sender.detailTextLabel.frame.size.height);
            _textfield.frame = frame;
            _textfield.hidden = NO;
            _textfield.font = [UIFont HTWTableViewCellFont];
            _textfield.textColor = [UIColor HTWBlueColor];
            _textfield.textAlignment = NSTextAlignmentRight;
            
            switch (indexPath.row) {
                case 0: _textfield.text = _user.name; break;
                case 1: _textfield.text = _user.matrnr; break;
                default: _textfield.text = @"";
                    break;
            }
            
            _textfield.delegate = self;
            _textfield.tag = indexPath.row;
            sender.detailTextLabel.text = @"";
            [sender addSubview:_textfield];
            [_textfield becomeFirstResponder];
    }
    else if (indexPath.row == 1)
    {
        [_textfield resignFirstResponder];
        _textfield.hidden = YES;
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if (_user.dozent.boolValue && [cell.detailTextLabel.text characterAtIndex:0] == '*') {
            cell.detailTextLabel.text = _user.matrnr;
        }
        else if (_user.dozent.boolValue) {
            NSMutableString *string = [[NSMutableString alloc] init];
            for(int i=0; i<_user.matrnr.length; i++) [string appendString:@"*"];
            cell.detailTextLabel.text = string;
        }
        
    }
}

#pragma mark - TextField Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", _user.matrnr];
    [fetchRequest setPredicate:pred];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    
    for (User *this in objects) {
        switch (textField.tag) {
            case 0:
                this.name = textField.text;
                break;
            case 1:
                this.matrnr = textField.text;
                break;
            default:
                break;
        }
    }
    
    [context save:nil];
    
    textField.text = @"";
    [textField resignFirstResponder];
    _textfield.hidden = YES;
    [textField removeFromSuperview];
    self.title = _user.name;
    [self.tableView reloadData];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

@end
