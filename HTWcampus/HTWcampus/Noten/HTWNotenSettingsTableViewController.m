//
//  HTWNotenSettingsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 07.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWNotenSettingsTableViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWNotenSettingsTableViewController () <UITextFieldDelegate>

@property (nonatomic, strong) UITextField *textfield;

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
    _textfield = [[UITextField alloc] init];
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
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        cell.detailTextLabel.font = [UIFont HTWTableViewCellFont];
        cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
        cell.detailTextLabel.numberOfLines = 3;
        cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        
        switch (indexPath.row) {
            case 0:
                cell.textLabel.text = @"Login";
                cell.detailTextLabel.text = [defaults objectForKey:@"LoginNoten"];
                break;
            case 1:
                cell.textLabel.text = @"Passwort";
                NSMutableString *passwordStern = [[NSMutableString alloc] init];
                for(int i = 0; i < [(NSString*)[defaults objectForKey:@"PasswortNoten"] length]; i++)
                    [passwordStern appendString:@"*"];
                cell.detailTextLabel.text = passwordStern;
                break;
        }
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
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if(indexPath.section == 0)
    {
        if (indexPath.row <= 3) {
            [self.tableView reloadData];
            UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
            CGRect frame = CGRectMake(sender.frame.size.width/4, sender.detailTextLabel.frame.origin.y, sender.frame.size.width/4*3-20, sender.detailTextLabel.frame.size.height);
            _textfield.frame = frame;
            _textfield.hidden = NO;
            _textfield.font = [UIFont HTWTableViewCellFont];
            _textfield.textColor = [UIColor HTWBlueColor];
            _textfield.textAlignment = NSTextAlignmentRight;
            
            switch (indexPath.row) {
                case 0: _textfield.text = [defaults objectForKey:@"LoginNoten"]; _textfield.secureTextEntry = NO; break;
                case 1: _textfield.text = @""; _textfield.secureTextEntry = YES; break;
                default: _textfield.text = @"";
                    break;
            }
            
            _textfield.delegate = self;
            _textfield.tag = indexPath.row;
            sender.detailTextLabel.text = @"";
            [sender addSubview:_textfield];
            [_textfield becomeFirstResponder];
        }
    }
}

#pragma mark - TextField Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    switch (textField.tag) {
        case 0: [defaults setObject:textField.text forKey:@"LoginNoten"]; break;
        case 1: [defaults setObject:textField.text forKey:@"PasswortNoten"]; break;
    }
    
    textField.text = @"";
    [textField resignFirstResponder];
    _textfield.hidden = YES;
    [self.tableView reloadData];
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
        self.textfield.text = @"";
        [self.tableView reloadData];
    }
}

@end
