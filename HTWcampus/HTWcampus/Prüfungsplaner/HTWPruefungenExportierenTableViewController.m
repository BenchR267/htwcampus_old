//
//  HTWPruefungenExportierenTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 10.06.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungenExportierenTableViewController.h"
#import "HTWAppDelegate.h"

#import "User.h"
#import "Stunde.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"


#define ALERT_ERROR 0
#define ALERT_SUCCESS 1

@interface HTWPruefungenExportierenTableViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSMutableArray *selected;
@property (nonatomic, strong) NSArray *keys;

@end

@implementation HTWPruefungenExportierenTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    
    UIBarButtonItem *selectBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"selectAll"] style:UIBarButtonItemStylePlain target:self action:@selector(selectAllPressed:)];
    UIBarButtonItem *unSelectBBI = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"unselectAll"] style:UIBarButtonItemStylePlain target:self action:@selector(unSelectAllPressed:)];
    
    self.navigationItem.leftBarButtonItems = @[selectBBI,unSelectBBI];
    
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    _selected = [NSMutableArray new];
    for (int i = 0; i < _pruefungen.count; i++) {
        [_selected addObject:@NO];
    }
}


#pragma mark - Table view data source

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _pruefungen.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 70;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    cell.textLabel.text = _pruefungen[indexPath.row][_keys[5]];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.numberOfLines = 2;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    if([_selected[indexPath.row] isEqual:@YES]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    
    if (selectedCell.accessoryType == UITableViewCellAccessoryNone)
    {
        selectedCell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
        if (selectedCell.accessoryType == UITableViewCellAccessoryCheckmark)
        {
            selectedCell.accessoryType = UITableViewCellAccessoryNone;
        }
    
    if([_selected[indexPath.row] isEqual:@YES]) {
        _selected[indexPath.row] = @NO;
    }
    else {
        _selected[indexPath.row] = @YES;
    }
    
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}
- (IBAction)fertigButtonPressed:(id)sender {
    
    NSManagedObjectContext *context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"(raum = %@)", [NSNumber numberWithBool:NO]];
    fetchRequest.predicate = pred;
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    if(objects.count == 0)
    {
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.message = @"Es wurde noch kein Stundenplan angelegt, deswegen kann auch diese Prüfung keinem Stundenplan hinzugefügt werden.";
        [alert addButtonWithTitle:@"Ok"];
        alert.tag = ALERT_ERROR;
        [alert show];
    }
    else
    {
        if(objects.count == 1)
        {
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.message = [NSString stringWithFormat:@"Soll(en) die Prüfung(en) zu dem Stundenplan %@ %@ hinzugefügt werden?", [(User*)objects[0] name], [(User*)objects[0] matrnr]];
            [alert addButtonWithTitle:@"Ja"];
            [alert addButtonWithTitle:@"Abbrechen"];
            alert.tag = ALERT_SUCCESS;
            alert.delegate = self;
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.message = @"Zu welchem Stundenplan soll(en) die Prüfung(en) hinzugefügt werden?";
            for (User *this in objects) {
                if(!this.name) [alert addButtonWithTitle:this.matrnr];
                else [alert addButtonWithTitle:[NSString stringWithFormat:@"%@ %@", this.name, this.matrnr]];
            }
            [alert addButtonWithTitle:@"Abbrechen"];
            alert.tag = ALERT_SUCCESS;
            alert.delegate = self;
            [alert show];
        }
        
    }
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    
    NSArray *nameUndMatrnr = [[alertView buttonTitleAtIndex:buttonIndex] componentsSeparatedByString:@" "];
    NSString *matrnr = nameUndMatrnr[nameUndMatrnr.count - 1];
    if (![matrnr isEqualToString:@"Abbrechen"]) {
        NSManagedObjectContext *context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        NSPredicate *pred;
        if(![matrnr isEqualToString:@"Ja"]) pred = [NSPredicate predicateWithFormat:@"(raum = %@) && matrnr = %@", [NSNumber numberWithBool:NO], matrnr];
        else pred = [NSPredicate predicateWithFormat:@"raum = %@", [NSNumber numberWithBool:NO]];
        fetchRequest.predicate = pred;
        NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
        User *info = objects[0];
        
        BOOL didAdd = NO;
        for(int i = 0; i < _pruefungen.count; i++) {
            if([_selected[i] isEqual:@NO]) continue;
            if(![self getAnfang:i] || ![self getEnde:i]) continue;
            Stunde *neu = [[Stunde alloc] initWithEntity:[NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
            neu.titel = _pruefungen[i][_keys[5]];
            neu.kurzel = _pruefungen[i][_keys[6]];
            neu.raum = _pruefungen[i][_keys[9]];
            neu.dozent = _pruefungen[i][_keys[10]];
            neu.anfang = [self getAnfang:i];
            neu.ende = [self getEnde:i];
            neu.anzeigen = [NSNumber numberWithBool:YES];
            neu.id = [NSString stringWithFormat:@"%@%d%@", neu.kurzel, [self weekdayFromDate:neu.anfang], [(NSString*)_pruefungen[i][_keys[8]] componentsSeparatedByString:@" "][0]];
            neu.semester = [[NSUserDefaults standardUserDefaults] objectForKey:@"Semester"];
            
            [info addStundenObject:neu];
            didAdd = YES;
        }
        
        [context save:nil];
        
        if(didAdd) {
            UIAlertView *succcess = [[UIAlertView alloc] init];
            succcess.message = @"Die Prüfungen wurden erfolgreich hinzugefügt. (Eventuell haben einige Prüfungen keine auswertbaren Zeitangaben, diese konnten leider nicht hinzugefügt werden.)";
            [succcess show];
            [succcess performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
        }
        [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
    }
}

-(IBAction)selectAllPressed:(id)sender {
    for(int i = 0; i < _selected.count; i++) {
        _selected[i] = @YES;
    }
    [self.tableView reloadData];
}

-(IBAction)unSelectAllPressed:(id)sender {
    for(int i = 0; i < _selected.count; i++) {
        _selected[i] = @NO;
    }
    [self.tableView reloadData];
}

#pragma mark - Hilfsfunktionen

-(NSDate*)getAnfang:(int)index
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefungen[index][_keys[7]], [self aktuellesJahr], [(NSString*)_pruefungen[index][_keys[8]] componentsSeparatedByString:@" "][0]]];
}

-(NSDate*)getEnde:(int)index
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefungen[index][_keys[7]], [self aktuellesJahr], [(NSString*)_pruefungen[index][_keys[8]] componentsSeparatedByString:@" "][2]]];
}

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSString*)aktuellesJahr
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"yyyy"];
    return [dateF stringFromDate:[NSDate date]];
}

@end
