//
//  HTWStundenplanAddTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 06.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanAddTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "Stunde.h"
#import "HTWDatePickViewController.h"
#import "UIFont+HTW.h"
#import "UIColor+HTW.h"

@interface HTWStundenplanAddTableViewController () <UITextFieldDelegate, HTWDatePickViewControllerDelegate>

@property (nonatomic, strong) UITextField *textfield;

@property (nonatomic, strong) NSString *titel;
@property (nonatomic, strong) NSString *kurzel;
@property (nonatomic, strong) NSString *raum;
@property (nonatomic, strong) NSString *dozent;
@property (nonatomic, strong) NSDate *anfang;
@property (nonatomic, strong) NSDate *ende;

@end

@implementation HTWStundenplanAddTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    _anfang = [NSDate date];
    _ende = [_anfang dateByAddingTimeInterval:60*60+30*60];
    _titel = @"";
    _kurzel = @"";
    _raum = @"";
    _dozent = @"";
    self.title = @"Neue Stunde hinzufügen";
    
    self.navigationItem.backBarButtonItem.title = @"Bestätigen";
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.backgroundColor = [UIColor HTWBackgroundColor];
    if(!_textfield) _textfield = [[UITextField alloc] init];
    
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 7;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0: return 82;
        default: return 50;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    switch (indexPath.row) {
        case 0:
            cell.textLabel.text = @"Titel";
            cell.detailTextLabel.text = _titel;
            break;
        case 1:
            cell.textLabel.text = @"Kürzel";
            cell.detailTextLabel.text = _kurzel;
            break;
        case 2:
            cell.textLabel.text = @"Raum";
            cell.detailTextLabel.text = _raum;
            break;
        case 3:
            if(![defaults boolForKey:@"Dozent"]) cell.textLabel.text = @"Dozent";
            else cell.textLabel.text = @"Studiengang";
            cell.detailTextLabel.text = _dozent;
            break;
        case 4:
            cell.textLabel.text = @"Typ";
            if([_kurzel componentsSeparatedByString:@" "].count > 1) cell.detailTextLabel.text = [_kurzel componentsSeparatedByString:@" "][1];
            else cell.detailTextLabel.text = @"";
            break;
        case 5:
            cell.textLabel.text = @"Anfang";
            cell.detailTextLabel.text = [self stringFromDate:_anfang];
            break;
        case 6:
            cell.textLabel.text = @"Ende";
            cell.detailTextLabel.text = [self stringFromDate:_ende];
            break;
            
        default:
            break;
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
        if (indexPath.row <= 3) {
            [self.tableView reloadData];
            
            
            UITableViewCell *sender = [tableView cellForRowAtIndexPath:indexPath];
            CGRect frame = CGRectMake(sender.frame.size.width/4, sender.detailTextLabel.frame.origin.y, sender.frame.size.width/4*3-20, sender.detailTextLabel.frame.size.height);
            _textfield.frame = frame;
            _textfield.hidden = NO;
            _textfield.font = [UIFont HTWTableViewCellFont];
            _textfield.textColor = [UIColor HTWBlueColor];
            _textfield.textAlignment = NSTextAlignmentRight;
            
            switch (indexPath.row) {
                case 0: _textfield.text = _titel; break;
                case 1: _textfield.text = _kurzel; break;
                case 2: _textfield.text = _raum; break;
                case 3: _textfield.text = _dozent; break;
                default: _textfield.text = @"";
                    break;
            }
            
            _textfield.delegate = self;
            _textfield.tag = indexPath.row;
            sender.detailTextLabel.text = @"";
            [sender addSubview:_textfield];
            [_textfield becomeFirstResponder];
        }
    else if (indexPath.row == 5) // Anfang
        [self performSegueWithIdentifier:@"anfangEingeben" sender:[tableView cellForRowAtIndexPath:indexPath]];
    else if (indexPath.row == 6) // Ende
        [self performSegueWithIdentifier:@"endeEingeben" sender:[tableView cellForRowAtIndexPath:indexPath]];
}

#pragma mark - TextField Delegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    switch (textField.tag) {
        case 0:
            _titel = textField.text;
            break;
        case 1:
            _kurzel = textField.text;
            break;
        case 2:
            _raum = textField.text;
            break;
        case 3:
            _dozent = textField.text;
            break;
        default:
            break;
    }
    
    textField.text = @"";
    [textField resignFirstResponder];
    _textfield.hidden = YES;
    [textField removeFromSuperview];
    self.title = _kurzel;
    [self.tableView reloadData];
}

#pragma mark - HTWDatePick Delegate

-(void)getNewDate:(NSDate *)newDate andAnfang:(BOOL)ja
{
    if (ja) {
        _anfang = newDate;
        _ende = [_anfang dateByAddingTimeInterval:60*90];
    }
    else _ende = newDate;
    
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:5 inSection:0], [NSIndexPath indexPathForRow:6 inSection:0]] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - IBActions

- (IBAction)speichernButtonPressed:(id)sender {
    if ([_titel isEqualToString:@""] || [_kurzel isEqualToString:@""] || [_raum isEqualToString:@""] || [_dozent isEqualToString:@""] || [_ende compare:_anfang] == NSOrderedAscending) {
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.message = @"Bitte alle Felder ausfüllen und darauf achten, dass der Anfang der Stunde vor dem Ende sein muss.";
        [alert addButtonWithTitle:@"Nochmal probieren"];
        [alert show];
        return;
    }
    
    
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    
    Stunde *newStunde = [[Stunde alloc] initWithEntity:[NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:context] insertIntoManagedObjectContext:context];
    newStunde.titel = _titel;
    newStunde.kurzel = _kurzel;
    newStunde.raum = _raum;
    newStunde.dozent = _dozent;
    newStunde.anfang = _anfang;
    newStunde.ende = _ende;
    newStunde.semester = [defaults objectForKey:@"Semester"];
    newStunde.anzeigen = [NSNumber numberWithBool:YES];
    newStunde.id = [NSString stringWithFormat:@"%@%d%@", _kurzel, [self wochentagFromDate:_anfang], [self uhrZeitFromDate:_anfang]];
    
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", [defaults objectForKey:@"Matrikelnummer"]];
    [fetchRequest setPredicate:pred];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    if (objects.count > 0) {
        User *this = objects[0];
        [this addStundenObject:newStunde];
    }
    
    [context save:nil];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"anfangEingeben"]) {
        HTWDatePickViewController *HDPVC = segue.destinationViewController;
        HDPVC.delegate = self;
        HDPVC.anfang = YES;
        HDPVC.date = _anfang;
        HDPVC.navigationItem.title = @"Anfang eingeben";
    }
    else if ([segue.identifier isEqualToString:@"endeEingeben"])
    {
        HTWDatePickViewController *HDPVC = segue.destinationViewController;
        HDPVC.delegate = self;
        HDPVC.anfang = NO;
        HDPVC.date = _ende;
        HDPVC.navigationItem.title = @"Ende eingeben";
    }
}


#pragma mark - Hilfsfunktionen

-(NSString *)stringFromDate:(NSDate*)date
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    return [dateF stringFromDate:date];
}

-(NSString*)uhrZeitFromDate:(NSDate*)date
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"HH:mm"];
    return [dateF stringFromDate:date];
}

-(int)wochentagFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    return weekday;
}

@end
