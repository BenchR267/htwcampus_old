//
//  HTWAlertViewController.m
//  test
//
//  Created by Benjamin Herzog on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWAlertViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWAlertViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textfield;
@property (nonatomic, strong) NSMutableArray *stringsFromTextField;

@end

@implementation HTWAlertViewController


-(void)viewDidLoad
{
    UIBarButtonItem *abbrechen = [[UIBarButtonItem alloc] initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(abbrechenPressed:)];
    self.navigationItem.rightBarButtonItem = abbrechen;
    
    if(!_textfield) _textfield = [[UITextField alloc] init];
    if(!_stringsFromTextField) _stringsFromTextField = [[NSMutableArray alloc] init];
    for (int i = 0; i < _mainTitle.count; i++) {
        [_stringsFromTextField addObject:@""];
    }
    
    self.title = _htwTitle;
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    NSIndexPath *ip = [NSIndexPath indexPathForItem:0 inSection:0];
    [self tableView:self.tableView didSelectRowAtIndexPath:ip];
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0)
    {
        if(_message) return _message;
        else return @"Bitte eingeben";
    }
    else return @"";
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return _mainTitle.count;
    else return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if(indexPath.section == 0)
    {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
        
        cell.textLabel.text = _mainTitle[indexPath.row];
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        
        cell.detailTextLabel.text = _stringsFromTextField[indexPath.row];
        cell.detailTextLabel.font = [UIFont HTWTableViewCellFont];
        cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"sec2Cell"];
        if(_commitButtonTitle) cell.textLabel.text = _commitButtonTitle;
        else cell.textLabel.text = @"Bestätigen";
        cell.textLabel.font = [UIFont HTWLargeFont];
        cell.textLabel.textColor = [UIColor HTWWhiteColor];
        cell.backgroundColor = [UIColor HTWGreenColor];
        UILongPressGestureRecognizer *longGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                             action:@selector(commitPressed:)];
        longGR.minimumPressDuration = 0.01;
        [cell addGestureRecognizer:longGR];
    }
    
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
    {
        [self.tableView reloadData];
        
        UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
        CGRect frame = CGRectMake(sender.frame.size.width/4, sender.detailTextLabel.frame.origin.y, sender.frame.size.width/4*3-20, sender.detailTextLabel.frame.size.height);
        _textfield.frame = frame;
        _textfield.hidden = NO;
        _textfield.font = [UIFont HTWTableViewCellFont];
        _textfield.textColor = [UIColor HTWBlueColor];
        _textfield.textAlignment = NSTextAlignmentRight;
        _textfield.text = _stringsFromTextField[indexPath.row];
        
        _textfield.delegate = self;
        _textfield.tag = indexPath.row;
        if([_numberOfSecureTextField containsObject:[NSNumber numberWithInteger:_textfield.tag]]) _textfield.secureTextEntry = YES;
        else _textfield.secureTextEntry = NO;
        sender.detailTextLabel.text = @"";
        [sender addSubview:_textfield];
        [_textfield becomeFirstResponder];
    }
    
    
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    _stringsFromTextField[_textfield.tag] = _textfield.text;
    
    textField.text = @"";
    [textField resignFirstResponder];
    _textfield.hidden = YES;
    [textField removeFromSuperview];
    [self.tableView reloadData];
}

-(IBAction)abbrechenPressed:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:^{}];
}

-(IBAction)commitPressed:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        gesture.view.backgroundColor = [UIColor HTWGrayColor];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        _stringsFromTextField[_textfield.tag] = _textfield.text;
        gesture.view.backgroundColor = [UIColor HTWRedColor];
        
        
        if(_delegate)
        {
            //[self performSelector:@selector(sendToDelegate) withObject:nil afterDelay:1];
            [_delegate gotStringsFromTextFields:_stringsFromTextField];
        }
    }
}

-(void)sendToDelegate
{
    [_delegate gotStringsFromTextFields:_stringsFromTextField];
}

@end
