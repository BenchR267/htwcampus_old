//
//  HTWStundeAddTableViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 23.03.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundeAddTableViewController.h"
#import "HTWAppDelegate.h"
#import "Student.h"
#import "Stunde.h"
#import "HTWDatePickViewController.h"
#import "HTWColors.h"

@interface HTWStundeAddTableViewController () <UIAlertViewDelegate, HTWDatePickViewControllerDelegate, UITextFieldDelegate>
{
    HTWAppDelegate *appdelegate;
    
    NSDate *anfang;
    NSDate *ende;
    
    HTWColors *htwColors;
}
@property (weak, nonatomic) IBOutlet UITextField *titelTextField;
@property (weak, nonatomic) IBOutlet UITextField *kurzelTextField;
@property (weak, nonatomic) IBOutlet UITextField *dozentTextField;
@property (weak, nonatomic) IBOutlet UITextField *raumTextField;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (weak, nonatomic) IBOutlet UITableViewCell *anfangCell;
@property (weak, nonatomic) IBOutlet UITableViewCell *endeCell;
@property (weak, nonatomic) IBOutlet UITextField *wiederholungenTextField;
@property (weak, nonatomic) IBOutlet UISegmentedControl *woechentlichSegControl;

@property (nonatomic, strong) Stunde *neueStunde;

@end

@implementation HTWStundeAddTableViewController

#pragma mark - Actions

-(void)viewDidLoad
{
    NSDateFormatter *datum = [[NSDateFormatter alloc] init];
    [datum setDateFormat:@"dd.MM.yyyy HH:mm"];
    
    anfang = [NSDate date];
    ende = [NSDate dateWithTimeIntervalSinceNow:60*90];
    
    _anfangCell.detailTextLabel.text = [datum stringFromDate:anfang];
    
    _endeCell.detailTextLabel.text = [datum stringFromDate:ende];
    
    htwColors = [[HTWColors alloc] init];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    NSDateFormatter *datum = [[NSDateFormatter alloc] init];
    [datum setDateFormat:@"dd.MM.yyyy HH:mm"];

    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];
    
    //    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:23/255.f green:43/255.f blue:54/255.f alpha:1.0];
    self.tabBarController.tabBar.barTintColor = htwColors.darkTabBarTint;
    [self.tabBarController.tabBar setTintColor:htwColors.darkTextColor];
    [self.tabBarController.tabBar setSelectedImageTintColor:htwColors.darkTextColor];
    
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    
    self.view.backgroundColor = htwColors.darkViewBackground;
}

- (IBAction)speichernButtonPressed:(UIBarButtonItem *)sender
{
    if ([_titelTextField.text isEqualToString:@""] || [_kurzelTextField.text isEqualToString:@""] || [_dozentTextField.text isEqualToString:@""] || [_raumTextField.text isEqualToString:@""] || [_wiederholungenTextField.text isEqualToString:@""] || _wiederholungenTextField.text.floatValue == 0 || anfang > ende) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Da ist wohl was schief gegangen"
                                                            message:@"Bitte alle Felder ausfüllen und achten Sie darauf, dass das Anfangsdatum vor dem Enddatum liegen muss."
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok, ich versuchs nochmal!"
                                                  otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    
    [request setEntity:[NSEntityDescription entityForName:@"Student"
                                   inManagedObjectContext:_context]];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", [defaults objectForKey:@"Matrikelnummer"]];
    request.predicate = pred;
    
    NSArray *ret = [_context executeFetchRequest:request error:nil];
    Student *dieserStudent;
    
    if (ret.count > 0) {
        dieserStudent = ret[0];
    }
    else {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Da ist wohl was schief gegangen"
                                                            message:@"Es ist ein Fehler aufgetreten. Der betreffende Student konnte nicht aus der Datenbank geladen werden."
                                                           delegate:self
                                                  cancelButtonTitle:@"Ok, ich versuchs nochmal!"
                                                  otherButtonTitles: nil];
        [alertView show];
        return;
    }
    
    
    NSEntityDescription *entityDesc =[NSEntityDescription entityForName:@"Stunde"
                                                 inManagedObjectContext:_context];
    
    _neueStunde = [[Stunde alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
    [_neueStunde setTitel:_titelTextField.text];
    _neueStunde.kurzel = _kurzelTextField.text;
    _neueStunde.dozent = _dozentTextField.text;
    _neueStunde.raum = _raumTextField.text;
    _neueStunde.bemerkungen = @"";
    _neueStunde.anzeigen = [NSNumber numberWithBool:YES];
    
    _neueStunde.anfang = anfang;
    _neueStunde.ende = ende;
    
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:_neueStunde.anfang] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    NSDateFormatter *vereinfacher = [[NSDateFormatter alloc] init];
    [vereinfacher setDateFormat:@"HH:mm"];
    NSString *anfangZeit = [vereinfacher stringFromDate:_neueStunde.anfang];
    
    _neueStunde.id = [NSString stringWithFormat:@"%@%d%@", _neueStunde.kurzel, weekday, anfangZeit];
    
    [dieserStudent addStundenObject: _neueStunde];
    
    
    if (_wiederholungenTextField.text.floatValue != 1) {
        NSDate *anfangD = _neueStunde.anfang;
        NSDate *endeD = _neueStunde.ende;
        
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        
        if (_woechentlichSegControl.selectedSegmentIndex == 0) dayComponent.day = 7;
        else dayComponent.day = 14;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
        for (int i = 1; i < (int)(_wiederholungenTextField.text.floatValue / 2); i++) {
            Stunde *nochEineStunde = [[Stunde alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
            nochEineStunde.titel = _neueStunde.titel;
            nochEineStunde.kurzel = _neueStunde.kurzel;
            nochEineStunde.dozent = _neueStunde.dozent;
            nochEineStunde.raum = _neueStunde.raum;
            nochEineStunde.bemerkungen = @"";
            nochEineStunde.anzeigen = [NSNumber numberWithBool:YES];
            
            anfangD = [theCalendar dateByAddingComponents:dayComponent toDate:anfangD options:0];
            
            nochEineStunde.anfang = anfangD;
            
            endeD = [theCalendar dateByAddingComponents:dayComponent toDate:endeD options:0];
            
            nochEineStunde.ende = endeD;
            nochEineStunde.id = _neueStunde.id;
            [dieserStudent addStundenObject: nochEineStunde];
            [_context save:nil];
        }
    }
    
//    [_context save:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(void)getNewDate:(NSDate *)newDate andAnfang:(BOOL)ja
{
    if (ja) {
        anfang = newDate;
        ende = [anfang dateByAddingTimeInterval:60*90];
    }
    else ende = newDate;
    
    NSDateFormatter *datum = [[NSDateFormatter alloc] init];
    [datum setDateFormat:@"dd.MM.yyyy HH:mm"];

    _anfangCell.detailTextLabel.text = [datum stringFromDate:anfang];
    
    _endeCell.detailTextLabel.text = [datum stringFromDate:ende];
    
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"anfangEingeben"]) {
        HTWDatePickViewController *HDPVC = segue.destinationViewController;
        HDPVC.delegate = self;
        HDPVC.anfang = YES;
        HDPVC.date = anfang;
        HDPVC.navigationItem.title = @"Anfang eingeben";
    }
    else if ([segue.identifier isEqualToString:@"endeEingeben"])
    {
        HTWDatePickViewController *HDPVC = segue.destinationViewController;
        HDPVC.delegate = self;
        HDPVC.anfang = NO;
        HDPVC.date = ende;
        HDPVC.navigationItem.title = @"Ende eingeben";
    }
}


@end
