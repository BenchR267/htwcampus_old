//
//  StundenplanSettingsTableViewController.m
//  University
//
//  Created by Benjamin Herzog on 05.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWAppDelegate.h"
#import "User.h"

#import "HTWStundenplanSettingsUebersichtTableViewController.h"
#import "HTWStundenplanSettingsUebersichtTableViewCell.h"
#import "Stunde.h"
#import "HTWSwitchInStundenplanSettingsUebersichtTableViewCell.h"
#import "HTWStundenplanEditDetailTableViewController.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWStundenplanSettingsUebersichtTableViewController ()
{
    HTWAppDelegate *appdelegate;
    NSString *Matrnr;
}

@property (nonatomic, strong) NSArray *array;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation HTWStundenplanSettingsUebersichtTableViewController

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    
    [self updateArray];
    
    if([self getNameOf:Matrnr] && ![[self getNameOf:Matrnr] isEqualToString:@""]) self.title = [self getNameOf:Matrnr];
    else self.title = Matrnr;
    
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        
        HTWStundenplanSettingsUebersichtTableViewCell *cell = (HTWStundenplanSettingsUebersichtTableViewCell*)[self.tableView cellForRowAtIndexPath:indexPath];
        NSLog(@"%@ wurde gelöscht.",cell.ID);
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Stunde"
                                                  inManagedObjectContext:self.context];
        [request setEntity:entity];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@", cell.ID];
        request.predicate = pred;
        
        NSArray *empArray=[self.context executeFetchRequest:request error:nil];
        
        for (Stunde *aktuell in empArray) {
            [_context deleteObject:aktuell];
        }
        
        [_context save:nil];
        [self updateArray];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    self.navigationController.navigationBarHidden = NO;

    
    Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    [self updateArray];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Löschen";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return _array.count;
}

- (void)configureCell:(HTWStundenplanSettingsUebersichtTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Stunde *info = _array[indexPath.row];
    
    NSString *typ;
    if ([info.kurzel componentsSeparatedByString:@" "].count > 1) 
        typ = [info.kurzel componentsSeparatedByString:@" "][1];
    else typ = @" ";
    
    cell.titelLabel.text = [NSString stringWithFormat:@"%@ %@", typ, info.titel];
    [cell.titelLabel setFont:[UIFont HTWBaseFont]];
    cell.titelLabel.textColor = [UIColor HTWDarkGrayColor];
    cell.titelLabel.numberOfLines = 2;
    cell.titelLabel.lineBreakMode = NSLineBreakByCharWrapping;
    
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"HH:mm"];
    
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:info.anfang] weekday] - 2;
    if(weekday == -1) weekday=6;
    NSString *wochentag;
    switch (weekday) {
        case 0: wochentag = [NSString stringWithFormat:@"Montag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 1: wochentag = [NSString stringWithFormat:@"Dienstag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 2: wochentag = [NSString stringWithFormat:@"Mittwoch, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 3: wochentag = [NSString stringWithFormat:@"Donnerstag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 4: wochentag = [NSString stringWithFormat:@"Freitag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 5: wochentag = [NSString stringWithFormat:@"Samstag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
        case 6: wochentag = [NSString stringWithFormat:@"Sonntag, %@ - %@ Uhr",
                             [dateFormatter stringFromDate:info.anfang],
                             [dateFormatter stringFromDate:info.ende]]; break;
            
        default: wochentag = [[NSString alloc] init];
            break;
    }
    
    cell.subtitleLabel.text = wochentag;
    cell.subtitleLabel.textColor = [UIColor HTWDarkGrayColor];
    cell.subtitleLabel.font = [UIFont HTWSmallestFont];
    
    [cell.cellSwitch setOn:info.anzeigen.boolValue];
    
    [cell.cellSwitch addTarget:self action:@selector(flip:) forControlEvents:UIControlEventValueChanged];
    [cell.cellSwitch setID:info.id];
    cell.ID = info.id;
    
    cell.backgroundColor = [UIColor HTWWhiteColor];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    HTWStundenplanSettingsUebersichtTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 82;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"editStunde" sender:indexPath];
}

-(void)updateArray
{
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"student.matrnr = %@ && semester = %@", [defaults objectForKey:@"Matrikelnummer"], [defaults objectForKey:@"Semester"]];
    fetchRequest.predicate=pred;
    
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"titel" ascending:YES]]];
    
    
    NSArray *objects = [_context executeFetchRequest:fetchRequest error:nil];
    NSMutableArray *objectsFormed = [[NSMutableArray alloc] init];
    
    BOOL gefunden = NO;
    for (Stunde *this1 in objects) {
        gefunden = NO;
        for (Stunde *this2 in objectsFormed) {
            if([this1.id isEqualToString:this2.id]) {
                gefunden = YES;
            }
        }
        if(!gefunden) [objectsFormed addObject:this1];
    }
    
    _array = objectsFormed;
//    [self.tableView reloadData];
}

#pragma mark - Switch Action

- (IBAction)flip:(id)sender
{
    HTWSwitchInStundenplanSettingsUebersichtTableViewCell *onoff = (HTWSwitchInStundenplanSettingsUebersichtTableViewCell *) sender;
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Stunde"
                                              inManagedObjectContext:self.context];
    [request setEntity:entity];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"id = %@", onoff.ID];
    request.predicate = pred;
    
    NSArray *empArray=[self.context executeFetchRequest:request error:nil];
    
    [empArray setValue:[NSNumber numberWithBool:onoff.on] forKey:@"anzeigen"];
    
    NSError *saveError;
    [_context save:&saveError];
    if(saveError) NSLog(@"Saving changes to %@ failed: %@", onoff.ID, saveError);
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

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if([segue.identifier isEqualToString:@"editStunde"])
    {
        if ([sender isKindOfClass:[NSIndexPath class]]) {
            NSIndexPath *indexPath = sender;
            HTWStundenplanEditDetailTableViewController *destVC = segue.destinationViewController;
            destVC.stunde = _array[indexPath.row];
            destVC.oneLessonOnly = NO;
        }
    }
}

@end
