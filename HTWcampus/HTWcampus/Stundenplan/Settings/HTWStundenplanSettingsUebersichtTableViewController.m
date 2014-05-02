//
//  StundenplanSettingsTableViewController.m
//  University
//
//  Created by Benjamin Herzog on 05.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWAppDelegate.h"
#import "Student.h"

#import "HTWStundenplanSettingsUebersichtTableViewController.h"
#import "HTWStundenplanSettingsUebersichtTableViewCell.h"
#import "Stunde.h"
#import "HTWSwitchInStundenplanSettingsUebersichtTableViewCell.h"
#import "HTWColors.h"

@interface HTWStundenplanSettingsUebersichtTableViewController () <NSFetchedResultsControllerDelegate>
{
    HTWAppDelegate *appdelegate;
    NSString *Matrnr;
    
    HTWColors *htwColors;
}

@property (nonatomic, strong) NSArray *array;
@property (nonatomic, strong) NSMutableArray *angezeigteStunden;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation HTWStundenplanSettingsUebersichtTableViewController

@synthesize fetchedResultsController;

#pragma mark - Lazy loading

- (NSFetchedResultsController *)fetchedResultsController {
    
    if (fetchedResultsController != nil) {
        return fetchedResultsController;
    }
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"student.matrnr = %@", [defaults objectForKey:@"Matrikelnummer"]];
    fetchRequest.predicate=pred;
    
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"id" ascending:YES],[NSSortDescriptor sortDescriptorWithKey:@"titel" ascending:YES]]];
    
    [fetchRequest setFetchBatchSize:20];
    
    
    
    [fetchRequest setReturnsDistinctResults:YES];
//    [fetchRequest setResultType:NSDictionaryResultType];
    [fetchRequest setPropertiesToFetch:[NSArray arrayWithObject:@"id"]];
    
    NSFetchedResultsController *theFetchedResultsController = [[NSFetchedResultsController alloc] initWithFetchRequest:fetchRequest
                                                                                                  managedObjectContext:_context
                                                                                                    sectionNameKeyPath:@"id"
                                                                                                             cacheName:nil];
    self.fetchedResultsController = theFetchedResultsController;
    fetchedResultsController.delegate = self;
    
    return fetchedResultsController;
    
}

#pragma mark - View Controller Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    htwColors = [[HTWColors alloc] init];
    
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    
    NSError *error;
	if (![[self fetchedResultsController] performFetch:&error]) {
		// Update to handle the error appropriately.
		NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
		exit(-1);  // Fail
	}
    
    self.title = Matrnr;
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
    } 
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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
    
    Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    
    fetchedResultsController = nil;
    [[self fetchedResultsController] performFetch:nil];
    [self.tableView reloadData];
}

- (void)viewDidUnload {
    self.fetchedResultsController = nil;
}

#pragma mark - Table view data source

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Löschen";
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [[fetchedResultsController sections] count];
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (void)configureCell:(HTWStundenplanSettingsUebersichtTableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
    Stunde *info = [fetchedResultsController objectAtIndexPath:indexPath];
    
    NSString *typ = [info.kurzel substringWithRange:NSMakeRange([info.kurzel length]-1, 1)];
    
    cell.titelLabel.text = [NSString stringWithFormat:@"%@ %@", typ, info.titel];
    [cell.titelLabel setFont:[UIFont systemFontOfSize:12]];
    cell.titelLabel.textColor = htwColors.darkTextColor;
    
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
    cell.subtitleLabel.textColor = htwColors.darkTextColor;
    
    [cell.cellSwitch setOn:info.anzeigen.boolValue];
    
    [cell.cellSwitch addTarget:self action:@selector(flip:) forControlEvents:UIControlEventValueChanged];
    [cell.cellSwitch setID:info.id];
    cell.ID = info.id;
    
    cell.backgroundColor = htwColors.darkCellBackground;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    HTWStundenplanSettingsUebersichtTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    [self configureCell:cell atIndexPath:indexPath];
    
    return cell;
}

- (void)controllerWillChangeContent:(NSFetchedResultsController *)controller {
    // The fetch controller is about to start sending change notifications, so prepare the table view for updates.
    [self.tableView beginUpdates];
}

- (void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath {
    
    UITableView *tableView = self.tableView;
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [tableView insertRowsAtIndexPaths:[NSArray arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeUpdate:
            [self configureCell:(HTWStundenplanSettingsUebersichtTableViewCell*)[tableView cellForRowAtIndexPath:indexPath] atIndexPath:indexPath];
            break;
            
        case NSFetchedResultsChangeMove:
            [tableView deleteRowsAtIndexPaths:[NSArray
                                               arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
            [tableView insertRowsAtIndexPaths:[NSArray
                                               arrayWithObject:newIndexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controller:(NSFetchedResultsController *)controller didChangeSection:(id )sectionInfo atIndex:(NSUInteger)sectionIndex forChangeType:(NSFetchedResultsChangeType)type {
    
    switch(type) {
            
        case NSFetchedResultsChangeInsert:
            [self.tableView insertSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
            
        case NSFetchedResultsChangeDelete:
            [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:sectionIndex] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}


- (void)controllerDidChangeContent:(NSFetchedResultsController *)controller
{
    [self.tableView endUpdates];
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

@end