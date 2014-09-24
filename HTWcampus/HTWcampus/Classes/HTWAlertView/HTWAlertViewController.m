//
//  HTWAlertViewController.m
//  test
//
//  Created by Benjamin Herzog on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWAlertViewController.h"
#import "HTWAlertTextField.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define TEXTFIELD_TAG 5

@interface HTWAlertViewController () <UITextFieldDelegate>

@property (nonatomic, strong) NSMutableArray *stringsFromTextField;

@end

@implementation HTWAlertViewController


-(void)viewDidLoad
{
    UIBarButtonItem *abbrechen = [[UIBarButtonItem alloc] initWithTitle:@"Abbrechen" style:UIBarButtonItemStylePlain target:self action:@selector(abbrechenPressed:)];
    self.navigationItem.rightBarButtonItem = abbrechen;
    
    
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
        
        HTWAlertTextField *detailTextField = (HTWAlertTextField*)[cell.contentView viewWithTag:TEXTFIELD_TAG];
        detailTextField.stelle = (int)indexPath.row;
        
        cell.textLabel.text = _mainTitle[indexPath.row];
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        
        if([_numberOfSecureTextField containsObject:[NSNumber numberWithInteger:indexPath.row]])
        {
            detailTextField.secureTextEntry = YES;
        }
        
        detailTextField.text = _stringsFromTextField[indexPath.row];
        detailTextField.font = [UIFont HTWTableViewCellFont];
        detailTextField.textColor = [UIColor HTWBlueColor];
        
        if (indexPath.row == 0) [detailTextField becomeFirstResponder];
    }
    else
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"sec2Cell"];
        if(_commitButtonTitle) cell.textLabel.text = _commitButtonTitle;
        else cell.textLabel.text = @"Bestätigen";
        cell.textLabel.font = [UIFont HTWLargeFont];
        cell.textLabel.textColor = [UIColor HTWWhiteColor];
        cell.backgroundColor = [UIColor HTWBlueColor];
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
        
        UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
        UITextField *detailTextField = (UITextField*)[sender.contentView viewWithTag:TEXTFIELD_TAG];
        detailTextField.text = _stringsFromTextField[indexPath.row];
        
        [detailTextField becomeFirstResponder];
    }
    
    
    
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    HTWAlertTextField *detailTextField = (HTWAlertTextField*)textField;
    _stringsFromTextField[detailTextField.stelle] = textField.text;
    
    [textField resignFirstResponder];
//    [self.tableView reloadData];
}

-(IBAction)abbrechenPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(IBAction)commitPressed:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        gesture.view.backgroundColor = [UIColor HTWGrayColor];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
//        if(_textfield.hidden == NO) _stringsFromTextField[_textfield.tag] = _textfield.text;
        gesture.view.backgroundColor = [UIColor HTWBlueColor];
        
        
        if(_delegate)
        {
            [_delegate gotStringsFromTextFields:_stringsFromTextField];
        }
    }
}

-(void)sendToDelegate
{
    [_delegate gotStringsFromTextFields:_stringsFromTextField];
}

@end
