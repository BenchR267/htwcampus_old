//
//  HTWNeueStudiengruppe.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWNeueStudiengruppe.h"

@interface HTWNeueStudiengruppe () <UIPickerViewDataSource, UIPickerViewDelegate>

@property (weak, nonatomic) IBOutlet UITextField *jahrTextField;
@property (weak, nonatomic) IBOutlet UITextField *gruppeTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *BDMPicker;

@property (nonatomic, strong) NSArray *BDMData;


@end

@implementation HTWNeueStudiengruppe

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    _BDMData = @[@"Bachelor", @"Diplom", @"Master"];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    _jahrTextField.text = [defaults objectForKey:@"pruefungJahr"];
    [_jahrTextField becomeFirstResponder];
    _gruppeTextField.text = [defaults objectForKey:@"pruefungGruppe"];
    
    _BDMPicker.dataSource = self;
    _BDMPicker.delegate = self;
    
    
    [_BDMPicker reloadAllComponents];
    if([[defaults objectForKey:@"pruefungTyp"] isEqualToString:@"B"]) [_BDMPicker selectRow:0 inComponent:0 animated:YES];
    else if([[defaults objectForKey:@"pruefungTyp"] isEqualToString:@"D"]) [_BDMPicker selectRow:1 inComponent:0 animated:YES];
    else if([[defaults objectForKey:@"pruefungTyp"] isEqualToString:@"M"]) [_BDMPicker selectRow:2 inComponent:0 animated:YES];
    
    if(![defaults objectForKey:@"pruefungTyp"]) [defaults setObject:@"B" forKey:@"pruefungTyp"];
    
    
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
}

-(NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component
{
    return _BDMData.count;
}

-(NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView
{
    return 1;
}

-(NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component
{
    return _BDMData[row];
}

-(void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component
{
    [[NSUserDefaults standardUserDefaults] setObject:[_BDMData[row] substringToIndex:1] forKey:@"pruefungTyp"];
}

-(IBAction)fertigPressed:(id)sender
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_jahrTextField.text forKey:@"pruefungJahr"];
    [defaults setObject:_gruppeTextField.text forKey:@"pruefungGruppe"];
    
    
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

@end
