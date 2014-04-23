//
//  HTWDatePickViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 23.03.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWDatePickViewController.h"



@interface HTWDatePickViewController ()
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@end

@implementation HTWDatePickViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    [_datePicker setTimeZone:[NSTimeZone localTimeZone]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    _datePicker.date = _date;
}

- (IBAction)dateChanged:(UIDatePicker *)sender
{
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [_delegate getNewDate:_datePicker.date andAnfang:_anfang];
}

@end
