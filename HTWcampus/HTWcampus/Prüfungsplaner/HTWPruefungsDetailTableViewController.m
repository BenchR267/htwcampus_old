//
//  HTWPruefungsDetailTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsDetailTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "Stunde.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define ALERT_ERROR 0
#define ALERT_SUCCESS 1

@interface HTWPruefungsDetailTableViewController () <UIAlertViewDelegate>

@property (nonatomic, strong) NSArray *keys;

@end

@implementation HTWPruefungsDetailTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    self.title = _pruefung[_keys[5]];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _keys.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 5: return 80;
        default: return 50;
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Informationen";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.text = _keys[indexPath.row];
    cell.detailTextLabel.text = _pruefung[_keys[indexPath.row]];
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.font = [UIFont HTWBaseFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

#pragma mark - IBActions

- (IBAction)addToStundenplanPressed:(id)sender {
    
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
            alert.message = [NSString stringWithFormat:@"Soll die Prüfung zu dem Stundenplan %@ %@ hinzugefügt werden?", [(User*)objects[0] name], [(User*)objects[0] matrnr]];
            [alert addButtonWithTitle:@"Ja"];
            [alert addButtonWithTitle:@"Abbrechen"];
            alert.tag = ALERT_SUCCESS;
            alert.delegate = self;
            [alert show];
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.message = @"Zu welchem Stundenplan soll die Prüfung hinzugefügt werden?";
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
    if(![self getAnfang] || ![self getEnde]) return;
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
        
        Stunde *neu = [[Stunde alloc] initWithEntity:[NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
        neu.titel = _pruefung[_keys[5]];
        neu.kurzel = _pruefung[_keys[6]];
        neu.raum = _pruefung[_keys[9]];
        neu.dozent = _pruefung[_keys[10]];
        neu.anfang = [self getAnfang];
        neu.ende = [self getEnde];
        neu.anzeigen = [NSNumber numberWithBool:YES];
        neu.id = [NSString stringWithFormat:@"%@%d%@", neu.kurzel, [self weekdayFromDate:neu.anfang], [(NSString*)_pruefung[_keys[8]] componentsSeparatedByString:@" "][0]];
        
        [info addStundenObject:neu];
        [context save:nil];
        
        UIAlertView *succcess = [[UIAlertView alloc] init];
        succcess.message = [NSString stringWithFormat:@"Die Prüfung %@ wurde erfolgreich dem Stundenplan %@ hinzugefügt", _pruefung[_keys[5]], [alertView buttonTitleAtIndex:buttonIndex]];
        [succcess show];
        [succcess performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
    }
}

-(NSDate*)getAnfang
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefung[_keys[7]], [self aktuellesJahr], [(NSString*)_pruefung[_keys[8]] componentsSeparatedByString:@" "][0]]];
}

-(NSDate*)getEnde
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefung[_keys[7]], [self aktuellesJahr], [(NSString*)_pruefung[_keys[8]] componentsSeparatedByString:@" "][2]]];
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
