//
//  HTWMatrikelnummernTableViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 27.02.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMatrikelnummernTableViewController.h"

#import "HTWAppDelegate.h"
#import "HTWStundenplanParser.h"
#import "Student.h"

#import "Stunde.h"
#import "HTWColors.h"

@interface HTWMatrikelnummernTableViewController () <NSFetchedResultsControllerDelegate, HTWStundenplanParserDelegate, UIAlertViewDelegate>
{
    HTWAppDelegate *appdelegate;
    NSString *Matrnr;
    
    HTWColors *htwColors;
}

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) HTWStundenplanParser *parser;
@property (nonatomic, strong) NSArray *nummern;

@end

@implementation HTWMatrikelnummernTableViewController


#pragma mark - Lazy Loading



- (void)viewDidLoad
{
    [super viewDidLoad];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
    
    _nummern = [_context executeFetchRequest:fetchRequest error:nil];
    
    htwColors = [[HTWColors alloc] init];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, self.editButtonItem];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.view.backgroundColor = htwColors.darkViewBackground;
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)addButtonPressed:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Neuen Stundenplan hinzufügen"
                                                    message:@"Bitte geben Sie eine Matrikelnummer oder Studiengruppe ein:"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Ok", nil];
    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if([alertView alertViewStyle] == UIAlertViewStylePlainTextInput && [alertView.title isEqualToString:@"Neuen Stundenplan hinzufügen"])
    {
        if ([buttonTitle isEqualToString:@"Ok"]) {
            NSString *matrNr = [alertView textFieldAtIndex:0].text;
            _parser = nil;
            
            
            appdelegate = [[UIApplication sharedApplication] delegate];
            _context = [appdelegate managedObjectContext];
            
            NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
            NSEntityDescription *entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
            [fetchRequest setEntity:entity];
            
            [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
            
            [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", matrNr]];
            
            NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
            
            if(tempArray.count == 0)
            {
                _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:matrNr andRaum:NO];
                [_parser setDelegate:self];
                [_parser parserStart];
            }
            else
            {
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Nummer schon vorhanden"
                                                                message:@"Die Nummer ist in der Datenbank schon vorhanden, bitte tippen Sie stattdessen auf das Aktualisieren-Symbol."
                                                               delegate:nil
                                                      cancelButtonTitle:@"Ok"
                                                      otherButtonTitles:nil];
                [alert show];
            }

        }
    }
    else if ([alertView.title isEqualToString:@"Stundenplan wiederherstellen"])
    {
        if([buttonTitle isEqualToString:@"Ok"])
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
            //    NSLog(@"Button gedrückt!!! %@", [(Student*)[fetchedResultsController objectAtIndexPath:path] matrnr]);
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.frame = CGRectMake(0, 0, 50, 50);
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
            cell.accessoryView = spinner;
            [spinner startAnimating];
            
            _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:[(Student*)_nummern[path.row] matrnr] andRaum:NO];
            [_parser setDelegate:self];
            [_parser parserStart];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return _nummern.count;
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    Student *info = _nummern[indexPath.row];
    
//    NSLog(@"Raum: %@", info.raum);
    
    cell.textLabel.text = info.matrnr;
    cell.textLabel.textColor = htwColors.darkTextColor;
    cell.backgroundColor = htwColors.darkCellBackground;
    
//    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Reload"]];
//    imageView.image = [imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
//    [imageView setTintColor:[UIColor redColor]];
    
    UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
    imageView.tag = indexPath.row;
    [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
    imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [imageView setTintColor:[UIColor whiteColor]];
    imageView.frame = CGRectMake(0, 0, 50, 50);
    imageView.userInteractionEnabled = YES;
    [imageView addTarget:self action:@selector(didTapStar:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = imageView;
    
    
    return cell;
}

-(void)didTapStar:(UIButton *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stundenplan wiederherstellen"
                                                    message:@"Wenn Sie auf Ok tippen, werden alle momentanen Stunden incl aller Änderungen in der Datenbank gelöscht und durch das Original auf den HTW-Servern ersetzt. Sind Sie sicher?"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = sender.tag;
    [alert show];
    
    
}

-(void)HTWStundenplanParserFinished
{
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
    
    _nummern = [_context executeFetchRequest:fetchRequest error:nil];
    
    [self.tableView reloadData];
    for (int i=0; i<_nummern.count; i++) {
        Student *aktuell = _nummern[i];
        if ([aktuell.matrnr isEqualToString:_parser.Matrnr]) {
            NSLog(@"und fertig..");
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
            imageView.tag = i;
            [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
            imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:[UIColor whiteColor]];
            imageView.frame = CGRectMake(0, 0, 50, 50);
            imageView.userInteractionEnabled = YES;
            [imageView addTarget:self action:@selector(didTapStar:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = imageView;
            return;
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Löschen";
}


// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}


//// Override to support editing the table view.
//- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    if (editingStyle == UITableViewCellEditingStyleDelete) {
//        // Delete the row from the data source
//        [_context deleteObject:_nummern[indexPath.row]];
//        //[tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
//    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
//        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
//        NSLog(@"Etwas hinzugefügt");
//    }   
//}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"want to delete object at row %ld", (long)indexPath.row);
        appdelegate = [[UIApplication sharedApplication] delegate];
        _context = [appdelegate managedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", [(Student*)_nummern[indexPath.row] matrnr]]];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
        for (Student *aktuell in tempArray) {
            [_context deleteObject:aktuell];
        }
        [_context save:nil];
        
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
        
        _nummern = [_context executeFetchRequest:fetchRequest error:nil];
        
        [self.tableView reloadData];
        
    }
}

-(void)controller:(NSFetchedResultsController *)controller didChangeObject:(id)anObject atIndexPath:(NSIndexPath *)indexPath forChangeType:(NSFetchedResultsChangeType)type newIndexPath:(NSIndexPath *)newIndexPath
{
    UITableView *tableV = [self tableView];
    switch(type) {
        case NSFetchedResultsChangeDelete:
            [tableV deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
            break;
    }
}

- (void)controllerDidChangeContent:(NSFetchedResultsController*)controller
{
    [[self tableView] endUpdates];
}

- (void)controllerWillChangeContent:(NSFetchedResultsController*)controller
{
    [[self tableView] beginUpdates];
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    NSLog(@"%@", [(Student*)_nummern[indexPath.row] matrnr]);
}






-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Student *info = _nummern[indexPath.row];
    [defaults setObject:info.matrnr forKey:@"Matrikelnummer"];
    [self.navigationController popViewControllerAnimated:YES];
}

@end
