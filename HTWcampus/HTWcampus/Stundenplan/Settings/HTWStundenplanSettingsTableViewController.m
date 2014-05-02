//
//  HTWStundenplanSettingsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanSettingsTableViewController.h"
#import "HTWColors.h"
#import "HTWStundenplanSettingsUebersichtTableViewController.h"

@interface HTWStundenplanSettingsTableViewController ()
{
    HTWColors *htwColors;
}

@property (weak, nonatomic) IBOutlet UITableViewCell *matrikelnummernCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *uebersichtCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *markierungsCell;
@property (weak, nonatomic) IBOutlet UISlider *markierSlider;
@property (weak, nonatomic) IBOutlet UILabel *sliderWert;

@end

@implementation HTWStundenplanSettingsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    htwColors = [[HTWColors alloc] init];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];
    
    _matrikelnummernCell.detailTextLabel.text = [defaults objectForKey:@"Matrikelnummer"];
    _markierSlider.value = [defaults floatForKey:@"markierSliderValue"];
    _sliderWert.text = [NSString stringWithFormat:@"%.0f min", self.markierSlider.value];
    
    //    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:23/255.f green:43/255.f blue:54/255.f alpha:1.0];
    self.tabBarController.tabBar.barTintColor = htwColors.darkTabBarTint;
    [self.tabBarController.tabBar setTintColor:htwColors.darkTextColor];
    [self.tabBarController.tabBar setSelectedImageTintColor:htwColors.darkTextColor];
    
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    
    self.view.backgroundColor = htwColors.darkViewBackground;
    
    self.matrikelnummernCell.backgroundColor = htwColors.darkCellBackground;
    self.matrikelnummernCell.textLabel.textColor = htwColors.darkTextColor;
    self.matrikelnummernCell.detailTextLabel.textColor = htwColors.darkTextColor;
    
    self.uebersichtCell.backgroundColor = htwColors.darkCellBackground;
    self.uebersichtCell.textLabel.textColor = htwColors.darkTextColor;
    
    self.markierungsCell.backgroundColor = htwColors.darkCellBackground;
    _sliderWert.textColor = htwColors.darkTextColor;
}

#pragma mark - IBActions

- (IBAction)sliderValueChanged:(UISlider *)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setFloat:_markierSlider.value forKey:@"markierSliderValue"];
    _sliderWert.text = [NSString stringWithFormat:@"%.0f min", _markierSlider.value];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"stundenOverview"]) {
        if ([segue.destinationViewController isKindOfClass:[HTWStundenplanSettingsUebersichtTableViewController class]]) {
            HTWStundenplanSettingsUebersichtTableViewController *sstvc = segue.destinationViewController;
            sstvc.fetchedResultsController = nil;
        }
    }
}

@end
