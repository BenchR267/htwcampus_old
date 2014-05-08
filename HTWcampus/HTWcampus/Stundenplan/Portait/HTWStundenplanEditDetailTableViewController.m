//
//  HTWStundenplanEditDetailTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 06.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanEditDetailTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "HTWCSVExport.h"
#import "HTWICSExport.h"
#import "UIFont+HTW.h"
#import "UIColor+HTW.h"

#define ALERT_CONFIRMATION 0
#define ALERT_EXPORT 1

@interface HTWStundenplanEditDetailTableViewController () <UITextFieldDelegate, UIAlertViewDelegate>

@property (nonatomic, strong) UITextField *textfield;

@end

@implementation HTWStundenplanEditDetailTableViewController

#pragma mark - ViewController Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"] style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, shareButton];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = _stunde.kurzel;
    _textfield = [[UITextField alloc] init];
}

#pragma mark - Table View Data Source

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return 7;
    else return 1;
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.row) {
        case 0:
            if(indexPath.section == 0) return 82;
            else return 50;
        default: return 50;
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    
    if(indexPath.section == 0)
    {
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
                cell.detailTextLabel.text = _stunde.titel;
                break;
            case 1:
                cell.textLabel.text = @"Kürzel";
                cell.detailTextLabel.text = _stunde.kurzel;
                break;
            case 2:
                cell.textLabel.text = @"Raum";
                cell.detailTextLabel.text = _stunde.raum;
                break;
            case 3:
                if(!_stunde.student.dozent) cell.textLabel.text = @"Dozent";
                else cell.textLabel.text = @"Studiengang";
                cell.detailTextLabel.text = _stunde.dozent;
                break;
            case 4:
                cell.textLabel.text = @"Typ";
                if([_stunde.kurzel componentsSeparatedByString:@" "].count > 1) cell.detailTextLabel.text = [_stunde.kurzel componentsSeparatedByString:@" "][1];
                break;
            case 5:
                cell.textLabel.text = @"Anfang";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ um %@ Uhr", [self wochentagFromDate:_stunde.anfang], [self uhrZeitFromDate:_stunde.anfang]];
                break;
            case 6:
                cell.textLabel.text = @"Ende";
                cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ um %@ Uhr", [self wochentagFromDate:_stunde.ende], [self uhrZeitFromDate:_stunde.ende]];
                break;
                
            default:
                break;
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"LoeschenCell"];
        cell.textLabel.text = @"Stunde löschen";
        cell.textLabel.font = [UIFont HTWBigBaseFont];
        cell.textLabel.textColor = [UIColor HTWWhiteColor];
        cell.backgroundColor = [UIColor HTWRedColor];
        UILongPressGestureRecognizer *longGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self
                                                                                action:@selector(stundeLoeschenPressed:)];
        longGR.minimumPressDuration = 0.01;
        [cell addGestureRecognizer:longGR];
    }
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section == 0)
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
                case 0: _textfield.text = _stunde.titel; break;
                case 1: _textfield.text = _stunde.kurzel; break;
                case 2: _textfield.text = _stunde.raum; break;
                case 3: _textfield.text = _stunde.dozent; break;
                default: _textfield.text = @"";
                    break;
            }
            
            _textfield.delegate = self;
            _textfield.tag = indexPath.row;
            sender.detailTextLabel.text = @"";
            [sender addSubview:_textfield];
            [_textfield becomeFirstResponder];
        }
    }
}

#pragma mark - TextField Delegate

-(void)textFieldDidEndEditing:(UITextField *)textField
{
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@ && student.matrnr = %@", _stunde.id, _stunde.student.matrnr];
    [fetchRequest setPredicate:pred];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    
    for (Stunde *this in objects) {
        switch (textField.tag) {
            case 0:
                this.titel = textField.text;
                break;
            case 1:
                this.kurzel = textField.text;
                break;
            case 2:
                this.raum = textField.text;
                break;
            case 3:
                this.dozent = textField.text;
                break;
            default:
                break;
        }
    }
    
    [context save:nil];
    
    textField.text = @"";
    [textField resignFirstResponder];
    _textfield.hidden = YES;
    [textField removeFromSuperview];
    self.title = _stunde.kurzel;
    [self.tableView reloadData];
}

-(BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - IBActions

-(IBAction)stundeLoeschenPressed:(UITapGestureRecognizer*)gesture
{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        gesture.view.backgroundColor = [UIColor HTWGrayColor];
    }
    else if (gesture.state == UIGestureRecognizerStateEnded)
    {
        gesture.view.backgroundColor = [UIColor HTWRedColor];// Stunde löschen
        UIAlertView *alert = [[UIAlertView alloc] init];
        alert.message = [NSString stringWithFormat:@"Sollen wirklich alle Stunden mit dem Kürzel %@ am %@ um %@ Uhr gelöscht werden?",
                         _stunde.kurzel,
                         [self wochentagFromDate:_stunde.anfang ],
                         [self uhrZeitFromDate:_stunde.anfang]];
        [alert addButtonWithTitle:@"Ja"];
        [alert addButtonWithTitle:@"Nein"];
        alert.tag = ALERT_CONFIRMATION;
        alert.delegate = self;
        [alert show];
    }
}

- (IBAction)stundeAusblendenPressed:(id)sender {
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@ && student.matrnr = %@", _stunde.id, _stunde.student.matrnr];
    [fetchRequest setPredicate:pred];
    
    NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
    
    for (Stunde *this in objects) {
        this.anzeigen = [NSNumber numberWithBool:NO];
    }
    
    [context save:nil];
    
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)shareButtonPressed:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exportieren"
                                                    message:@"In welcher Form wollen Sie die Stunde exportieren oder teilen?"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"CSV (Google Kalender)", @"ICS (Mac, Windows, iPhone)", nil];
    alert.tag = ALERT_EXPORT;
    [alert show];
}


#pragma mark - UIAlertView Delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if (alertView.tag == ALERT_CONFIRMATION) {
        if ([buttonTitle isEqualToString:@"Ja"]) {
            HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
            NSManagedObjectContext *context = [appdelegate managedObjectContext];
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@ && student.matrnr = %@", _stunde.id, _stunde.student.matrnr];
            [fetchRequest setPredicate:pred];
            
            NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];
            
            for (Stunde *this in objects) {
                [context deleteObject:this];
            }
            
            [context save:nil];
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    else if (alertView.tag == ALERT_EXPORT)
    {
            if ([buttonTitle isEqualToString:@"CSV (Google Kalender)"])
            {
                NSString *dateiNamenErweiterung;
                if(_stunde.student.dozent.boolValue) dateiNamenErweiterung = _stunde.student.name;
                else dateiNamenErweiterung = _stunde.student.matrnr;
                
                HTWCSVExport *csvExp = [[HTWCSVExport alloc] initWithArray:@[_stunde] andMatrNr:dateiNamenErweiterung];
                
                NSURL *fileURL = [csvExp getFileUrl];
                
                NSArray *itemsToShare = @[[NSString stringWithFormat:@"Lehrveranstaltung %@, erstellt mit der iOS-App der HTW Dresden.",_stunde.titel], fileURL];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
                activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeCopyToPasteboard];
                
                [self presentViewController:activityVC animated:YES completion:^{}];
                
                activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                    if (completed) {
                        UIAlertView *alert = [[UIAlertView alloc] init];
                        alert.title = @"Stunde erfolgreich als CSV-Datei exportiert.";
                        [alert show];
                        
                        NSFileManager *manager = [[NSFileManager alloc] init];
                        
                        [manager removeItemAtPath:[fileURL path] error:nil];
                        
                        [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
                    }
                };
                
                
                
            }
            else if([buttonTitle isEqualToString:@"ICS (Mac, Windows, iPhone)"])
            {
                NSString *dateiNamenErweiterung;
                if(_stunde.student.dozent.boolValue) dateiNamenErweiterung = _stunde.student.name;
                else dateiNamenErweiterung = _stunde.student.matrnr;
                
                HTWICSExport *csvExp = [[HTWICSExport alloc] initWithArray:@[_stunde] andMatrNr:dateiNamenErweiterung];
                
                NSURL *fileURL = [csvExp getFileUrl];
                
                NSArray *itemsToShare = @[[NSString stringWithFormat:@"Lehrveranstaltung %@, erstellt mit der iOS-App der HTW Dresden.",_stunde.titel], fileURL];
                UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
                activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeCopyToPasteboard];
                
                [self presentViewController:activityVC animated:YES completion:^{}];
                
                activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                    if (completed) {
                        UIAlertView *alert = [[UIAlertView alloc] init];
                        alert.title = @"Stundenplan erfolgreich als ICS-Datei exportiert.";
                        [alert show];
                        
                        NSFileManager *manager = [[NSFileManager alloc] init];
                        
                        [manager removeItemAtPath:[fileURL path] error:nil];
                        
                        [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
                    }
                };
            }
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

-(NSString*)wochentagFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    switch (weekday) {
        case 0: return @"Montag";
        case 1: return @"Dienstag";
        case 2: return @"Mittwoch";
        case 3: return @"Donnerstag";
        case 4: return @"Freitag";
        case 5: return @"Samstag";
        case 6: return @"Sonntag";
            
        default: return @"";
    }
}

@end
