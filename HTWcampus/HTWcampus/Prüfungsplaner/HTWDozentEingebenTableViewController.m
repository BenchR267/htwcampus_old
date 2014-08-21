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
    
    _dozentTextField.text = [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] objectForKey:@"pruefungDozent"];
    
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [_dozentTextField becomeFirstResponder];
}

-(IBAction)fertigPressed:(id)sender
{
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] setObject:_dozentTextField.text forKey:@"pruefungDozent"];

    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] setInteger:1 forKey:@"pruefungsPlanTyp"];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] setObject:_dozentTextField.text forKey:@"pruefungDozent"];
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
    return YES;
}

@end
