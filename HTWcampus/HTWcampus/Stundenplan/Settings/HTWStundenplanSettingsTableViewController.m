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
#import "HTWAppDelegate.h"
#import "User.h"

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
    
    if(![defaults boolForKey:@"Dozent"]) _matrikelnummernCell.detailTextLabel.text = [defaults objectForKey:@"Matrikelnummer"];
    else _matrikelnummernCell.detailTextLabel.text = [self getNameOf:[defaults objectForKey:@"Matrikelnummer"]];
    _markierSlider.value = [defaults floatForKey:@"markierSliderValue"];
    _sliderWert.text = [NSString stringWithFormat:@"%.0f min", self.markierSlider.value];
    
    //    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:23/255.f green:43/255.f blue:54/255.f alpha:1.0];
    self.tabBarController.tabBar.barTintColor = htwColors.darkTabBarTint;
    [self.tabBarController.tabBar setTintColor:htwColors.darkTextColor];
    [self.tabBarController.tabBar setSelectedImageTintColor:htwColors.darkTextColor];
    
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    
    self.tableView.backgroundView.backgroundColor = htwColors.darkViewBackground;
    
    self.matrikelnummernCell.backgroundColor = htwColors.darkCellBackground;
    self.matrikelnummernCell.textLabel.textColor = htwColors.darkCellText;
    self.matrikelnummernCell.detailTextLabel.textColor = htwColors.darkCellText;
    
    self.uebersichtCell.backgroundColor = htwColors.darkCellBackground;
    self.uebersichtCell.textLabel.textColor = htwColors.darkCellText;
    
    self.markierungsCell.backgroundColor = htwColors.darkCellBackground;
    _sliderWert.textColor = htwColors.darkCellText;
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

#pragma mark - Hilfsfunktionen

-(NSString*)getNameOf:(NSString*)matrnr
{
    NSManagedObjectContext *context = [HTWAppDelegate alloc].managedObjectContext;
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:context];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", matrnr];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:entity];
    [request setPredicate:pred];
    
    return [(User*)[context executeFetchRequest:request error:nil][0] name];
}

@end
