//
//  HTWNotenSettingsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 07.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWNotenSettingsTableViewController.h"
#import "HTWAlertTextField.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWNotenSettingsTableViewController () <UITextFieldDelegate>



@end

@implementation HTWNotenSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
}

-(IBAction)fertigPressed:(id)sender
{
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = @"Einstellungen Noten";
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section==0) return 2;
    else return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section==0) return 60;
    else return 50;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
        HTWAlertTextField *detailTextField = (HTWAlertTextField*)[cell.contentView viewWithTag:5];
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        detailTextField.font = [UIFont HTWTableViewCellFont];
        detailTextField.textColor = [UIColor HTWBlueColor];
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Login";
                cell.detailTextLabel.text = [defaults objectForKey:@"LoginNoten"];
                break;
            case 1:
                cell.textLabel.text = @"Passwort";
                detailTextField.text = [defaults objectForKey:@"PasswortNoten"];
                detailTextField.secureTextEntry = YES;
                break;
        }
        detailTextField.stelle = (int)indexPath.row;
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoeschenCell"];
        cell.textLabel.text = @"Login löschen";
        cell.backgroundColor = [UIColor HTWRedColor];
        cell.textLabel.textColor = [UIColor HTWWhiteColor];
        cell.textLabel.font = [UIFont HTWLargeFont];
        UILongPressGestureRecognizer *longGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(loeschenCellPressed:)];
        longGR.minimumPressDuration = 0.01;
        [cell addGestureRecognizer:longGR];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(indexPath.section == 0)
    {
        
        UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
        HTWAlertTextField *detailTextField = (HTWAlertTextField*)[sender.contentView viewWithTag:5];
//        if (detailTextField.stel)
//        detailTextField.text = _stringsFromTextField[indexPath.row];
        
        [detailTextField becomeFirstResponder];
    }
}

#pragma mark - TextField Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    HTWAlertTextField *detaiLTextField = (HTWAlertTextField*)textField;
    switch (detaiLTextField.stelle) {
        case 0: [defaults setObject:textField.text forKey:@"LoginNoten"]; break;
        case 1: [defaults setObject:textField.text forKey:@"PasswortNoten"]; break;
    }
    [textField resignFirstResponder];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - LöschenCell Pressed

-(IBAction)loeschenCellPressed:(UILongPressGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        gesture.view.backgroundColor = [UIColor HTWGrayColor];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        [defaults setObject:nil forKey:@"LoginNoten"];
        [defaults setObject:nil forKey:@"PasswortNoten"];
        [self.tableView reloadData];
    }
}

@end
