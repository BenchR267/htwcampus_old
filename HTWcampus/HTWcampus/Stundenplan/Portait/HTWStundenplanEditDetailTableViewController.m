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

#define TEXTVIEW_TAG 5

@interface HTWStundenplanEditDetailTableViewController () <UITextViewDelegate, UIAlertViewDelegate>

@property (weak, nonatomic) IBOutlet UITextView *titelTextView;
@property (weak, nonatomic) IBOutlet UITextView *kurzelTextView;
@property (weak, nonatomic) IBOutlet UITextView *raumTextView;
@property (weak, nonatomic) IBOutlet UITextView *dozentTextView;
@property (weak, nonatomic) IBOutlet UITextView *typTextView;
@property (weak, nonatomic) IBOutlet UITextView *semesterTextView;
@property (weak, nonatomic) IBOutlet UITextView *anfangTextView;
@property (weak, nonatomic) IBOutlet UITextView *endeTextView;
@property (weak, nonatomic) IBOutlet UITextView *bemerkungenTextView;

@property (strong, nonatomic) IBOutletCollection(UILabel) NSArray *labels;
@property (strong, nonatomic) IBOutletCollection(UITextView) NSArray *textViews;


@end

@implementation HTWStundenplanEditDetailTableViewController

#pragma mark - ViewController Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"] style:UIBarButtonItemStylePlain target:self action:@selector(shareButtonPressed:)];
    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, shareButton];
    
    
    self.titelTextView.text = _stunde.titel;
    self.kurzelTextView.text = _stunde.kurzel;
    self.raumTextView.text = _stunde.raum;
    self.dozentTextView.text = _stunde.dozent;
	
//	if ([_stunde.kurzel componentsSeparatedByString:@" "].count > 1) {
//		self.typTextView.text = [_stunde.kurzel componentsSeparatedByString:@" "][1];
//	} else {
//		self.typTextView.text = @"";
//	}

	self.typTextView.text = _stunde.type;
	
	self.semesterTextView.text = _stunde.semester;
    self.anfangTextView.text = [NSString stringWithFormat:@"%@ um %@ Uhr", [self wochentagFromDate:_stunde.anfang], [self uhrZeitFromDate:_stunde.anfang]];
    self.endeTextView.text = [NSString stringWithFormat:@"%@ um %@ Uhr", [self wochentagFromDate:_stunde.ende], [self uhrZeitFromDate:_stunde.ende]];
    self.bemerkungenTextView.text = _stunde.bemerkungen;
    
    self.titelTextView.delegate = self;
    self.kurzelTextView.delegate = self;
    self.raumTextView.delegate = self;
    self.dozentTextView.delegate = self;
    self.bemerkungenTextView.delegate = self;
    
    for (UILabel *this in self.labels) {
        this.font = [UIFont HTWTableViewCellFont];
        this.textColor = [UIColor HTWTextColor];
    }
    for (UITextView *this in self.textViews) {
        this.font = [UIFont HTWTableViewCellFont];
        this.textColor = [UIColor HTWBlueColor];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = _stunde.kurzel;
}

#pragma mark - UITableView Delegate

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(indexPath.section < 2)
    {
        UITableViewCell *currentCell = [tableView cellForRowAtIndexPath:indexPath];
        UITextView *currentTextView = (UITextView*)[currentCell.contentView viewWithTag:TEXTVIEW_TAG];
        [currentTextView becomeFirstResponder];
    }
    else
    {
        // LÖSCHEN
        [self stundeLoeschenPressed];
    }
}

#pragma mark - TextField Delegate

-(void)textViewDidEndEditing:(UITextView *)textView
{
    HTWAppDelegate *appdelegate = [[UIApplication sharedApplication] delegate];
    NSManagedObjectContext *context = [appdelegate managedObjectContext];
    if(!_oneLessonOnly)
    {

        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@ && student.matrnr = %@", _stunde.id, _stunde.student.matrnr];
        [fetchRequest setPredicate:pred];

        NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];

        for (Stunde *this in objects) {
            
            this.titel = self.titelTextView.text;
            this.kurzel = self.kurzelTextView.text;
            this.raum = self.raumTextView.text;
            this.dozent = self.dozentTextView.text;
            
        }
    }
    else
    {
        _stunde.titel = self.titelTextView.text;
        _stunde.kurzel = self.kurzelTextView.text;
        _stunde.raum = self.raumTextView.text;
        _stunde.dozent = self.dozentTextView.text;
    }
    
    _stunde.bemerkungen = self.bemerkungenTextView.text;

    [context save:nil];

//	if ([_stunde.kurzel componentsSeparatedByString:@" "].count > 1) {
//		self.typTextView.text = [_stunde.kurzel componentsSeparatedByString:@" "][1];
//	} else {
//		self.typTextView.text = @"";
//	}
	
	self.typTextView.text = _stunde.type;
	
    self.title = _stunde.kurzel;
//    [self.tableView reloadData];
}

-(BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    if ([text isEqualToString:@"\n"]) {
        [textView resignFirstResponder];
    }
    
    return YES;
}

-(void)textViewDidChange:(UITextView *)textView
{
    if (textView.text.length >= 30) {
        textView.text = [textView.text substringToIndex:30];
    }
}

#pragma mark - IBActions

-(IBAction)stundeLoeschenPressed
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    if(!_oneLessonOnly)
        alert.message = [NSString stringWithFormat:@"Sollen wirklich alle Stunden mit dem Kürzel %@ am %@ um %@ Uhr gelöscht werden?",
                         _stunde.kurzel,
                         [self wochentagFromDate:_stunde.anfang ],
                         [self uhrZeitFromDate:_stunde.anfang]];
    else
        alert.message = [NSString stringWithFormat:@"Soll diese Stunde wirklich gelöscht werden? %@", _stunde.kurzel];
    [alert addButtonWithTitle:@"Ja"];
    [alert addButtonWithTitle:@"Nein"];
    alert.tag = ALERT_CONFIRMATION;
    alert.delegate = self;
    [alert show];
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

            if(!_oneLessonOnly)
            {
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
                NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@ && student.matrnr = %@", _stunde.id, _stunde.student.matrnr];
                [fetchRequest setPredicate:pred];

                NSArray *objects = [context executeFetchRequest:fetchRequest error:nil];

                for (Stunde *this in objects) {
                    [context deleteObject:this];
                }
            }
            else [context deleteObject:_stunde];

            
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
            else if ([buttonTitle isEqualToString:@"In Kalender speichern"])
            {
                
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
