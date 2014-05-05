//
//  HTWStundenplanSettingsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanSettingsTableViewController.h"
#import "HTWStundenplanSettingsUebersichtTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWStundenplanSettingsTableViewController ()

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
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(![defaults boolForKey:@"Dozent"]) _matrikelnummernCell.detailTextLabel.text = [defaults objectForKey:@"Matrikelnummer"];
    else _matrikelnummernCell.detailTextLabel.text = [self getNameOf:[defaults objectForKey:@"Matrikelnummer"]];
    _markierSlider.value = [defaults floatForKey:@"markierSliderValue"];
    _sliderWert.text = [NSString stringWithFormat:@"%.0f min", self.markierSlider.value];
    
    self.navigationController.navigationBarHidden = NO;
    
    self.tableView.backgroundView.backgroundColor = [UIColor HTWSandColor];
    
    _matrikelnummernCell.backgroundColor = [UIColor HTWWhiteColor];
    _matrikelnummernCell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    _matrikelnummernCell.textLabel.font = [UIFont HTWBaseFont];
    _matrikelnummernCell.detailTextLabel.textColor = [UIColor HTWDarkGrayColor];
    _matrikelnummernCell.detailTextLabel.font = [UIFont HTWBaseFont];
    
    _uebersichtCell.backgroundColor = [UIColor HTWWhiteColor];
    _uebersichtCell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    _uebersichtCell.textLabel.font = [UIFont HTWBaseFont];
    
    _markierungsCell.backgroundColor = [UIColor HTWWhiteColor];
    _sliderWert.textColor = [UIColor HTWDarkGrayColor];
    _sliderWert.font = [UIFont HTWBaseFont];
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
