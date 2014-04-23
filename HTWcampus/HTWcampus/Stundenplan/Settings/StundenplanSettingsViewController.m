//
//  StundenplanSettingsViewController.m
//  University
//
//  Created by Benjamin Herzog on 21.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "StundenplanSettingsViewController.h"
#import "StundenplanSettingsTableViewController.h"
#import "HTWColors.h"



#define CornerRadius 5

@interface StundenplanSettingsViewController () <UITextFieldDelegate>
{
    HTWColors *htwColors;
}

@property (weak, nonatomic) IBOutlet UIButton *uebersichtButton;
@property (strong, nonatomic) IBOutlet UISlider *markierSlider;
@property (strong, nonatomic) IBOutlet UILabel *sliderWert;
@property (strong, nonatomic) IBOutlet UISegmentedControl *designSegControl;
@property (weak, nonatomic) IBOutlet UIButton *matrikelnummernButton;
@property (weak, nonatomic) IBOutlet UILabel *aktuelleMatrikelNummerLabel;


@end

@implementation StundenplanSettingsViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    htwColors = [[HTWColors alloc] init];
    
    
	// Do any additional setup after loading the view.
    
    self.uebersichtButton.layer.cornerRadius = CornerRadius;
    self.matrikelnummernButton.layer.cornerRadius = CornerRadius;
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];
    
    _aktuelleMatrikelNummerLabel.text = [defaults objectForKey:@"Matrikelnummer"];
    
//    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:23/255.f green:43/255.f blue:54/255.f alpha:1.0];
    self.tabBarController.tabBar.barTintColor = htwColors.darkTabBarTint;
    [self.tabBarController.tabBar setSelectedImageTintColor:htwColors.darkTextColor];
    [self.tabBarController.tabBar setTintColor:htwColors.darkTextColor];
    
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    
    
    for (UIView *aktuell in self.view.subviews) {
        if ([aktuell isKindOfClass:[UILabel class]]) {
            [(UILabel*)aktuell setTextColor : htwColors.darkTextColor];
        }
        if ([aktuell isKindOfClass:[UIButton class]]) {
            [(UIButton*)aktuell setBackgroundColor:htwColors.darkZeitenAndButtonBackground];
        }
    }
    
    
    self.navigationController.navigationBarHidden = NO;
    
    self.view.backgroundColor = htwColors.darkViewBackground;
    
    self.markierSlider.value = [defaults floatForKey:@"markierSliderValue"];
    self.sliderWert.text = [NSString stringWithFormat:@"%.0f min", self.markierSlider.value];
    if ([defaults boolForKey:@"hellesDesign"]) self.designSegControl.selectedSegmentIndex = 0;
    else self.designSegControl.selectedSegmentIndex = 1;
    _designSegControl.tintColor = htwColors.darkZeitenAndButtonBackground;
    
    
}

-(void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
}


#pragma mark - Actions and Segues

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"stundenOverview"]) {
        if ([segue.destinationViewController isKindOfClass:[StundenplanSettingsTableViewController class]]) {
            StundenplanSettingsTableViewController *sstvc = segue.destinationViewController;
            sstvc.fetchedResultsController = nil;
        }
    }
}
- (IBAction)sliderValueChanged:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:self.markierSlider.value forKey:@"markierSliderValue"];
    self.sliderWert.text = [NSString stringWithFormat:@"%.0f min", self.markierSlider.value];
    [UIApplication sharedApplication].scheduledLocalNotifications = nil;
}
- (IBAction)designSegControlChanged:(UISegmentedControl *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if (sender.selectedSegmentIndex == 0) {
        [defaults setBool:YES forKey:@"hellesDesign"];
    }
    else if (sender.selectedSegmentIndex == 1) [defaults setBool:NO forKey:@"hellesDesign"];
    [self viewDidLoad];
    [self viewWillAppear:YES];
    sender.tintColor = htwColors.darkTextColor;
}

@end
