//
//  HTWDozentEingebenTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWDozentEingebenTableViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWDozentEingebenTableViewController () <UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UILabel *dozentLabel;
@property (weak, nonatomic) IBOutlet UITextField *dozentTextField;


@end

@implementation HTWDozentEingebenTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = @"Prüfenden eingeben";
    
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    _dozentLabel.font = [UIFont HTWTableViewCellFont];
    _dozentLabel.textColor = [UIColor HTWTextColor];
    _dozentTextField.font = [UIFont HTWTableViewCellFont];
    _dozentTextField.textColor = [UIColor HTWBlueColor];
    _dozentTextField.delegate = self;
    [_dozentTextField becomeFirstResponder];
    
    _dozentTextField.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"pruefungDozent"];
    
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
}

-(IBAction)fertigPressed:(id)sender
{
    [[NSUserDefaults standardUserDefaults] setObject:_dozentTextField.text forKey:@"pruefungDozent"];
    
    if(_delegate) [_delegate neuerDozentEingegeben];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [[NSUserDefaults standardUserDefaults] setObject:_dozentTextField.text forKey:@"pruefungDozent"];
    
    if(_delegate) [_delegate neuerDozentEingegeben];
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
    return YES;
}

@end
