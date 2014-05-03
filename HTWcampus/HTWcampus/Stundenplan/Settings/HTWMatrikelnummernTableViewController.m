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
#import "HTWCSVConnection.h"
#import "Student.h"

#import "Stunde.h"
#import "HTWColors.h"

@interface HTWMatrikelnummernTableViewController () <HTWStundenplanParserDelegate, HTWCSVConnectionDelegate, UIAlertViewDelegate>
{
    HTWAppDelegate *appdelegate;
    NSString *Matrnr;
    
    HTWColors *htwColors;
}

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) HTWStundenplanParser *parser;
@property (nonatomic, strong) HTWCSVConnection *dozentParser;
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

#pragma mark - AlertView Delegate

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if([alertView alertViewStyle] == UIAlertViewStyleSecureTextInput && [alertView.title isEqualToString:@"Neuen Stundenplan hinzufügen"])
    {
        if ([buttonTitle isEqualToString:@"Student"]) {
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
        else if ([buttonTitle isEqualToString:@"Dozent"]) {
            if ([alertView alertViewStyle] == UIAlertViewStyleSecureTextInput) {
                NSString *matrNr = [alertView textFieldAtIndex:0].text;
                _dozentParser = nil;
                
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
                    _dozentParser = [[HTWCSVConnection alloc] initWithPassword:matrNr];
                    _dozentParser.delegate = self;
                    [_dozentParser startParser];
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
    }
    else if ([alertView.title isEqualToString:@"Stundenplan wiederherstellen"])
    {
        if([buttonTitle isEqualToString:@"Ok"])
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.frame = CGRectMake(0, 0, 50, 50);
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
            cell.accessoryView = spinner;
            [spinner startAnimating];
            
            if ([self.tableView cellForRowAtIndexPath:path].tag == 0) {
                _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:[(Student*)_nummern[path.row] matrnr] andRaum:NO];
                [_parser setDelegate:self];
                [_parser parserStart];
            }
            else {
                _dozentParser = [[HTWCSVConnection alloc] initWithPassword:[(Student*)_nummern[path.row] matrnr]];
                _dozentParser.delegate = self;
                [_dozentParser startParser];
            }
            
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
    
    if (info.dozent.boolValue == YES) {
        cell.tag = 1;
    }
    else cell.tag = 0;
    
    if(!info.dozent.boolValue) cell.textLabel.text = info.matrnr;
    else cell.textLabel.text = info.name;
    
    cell.textLabel.textColor = htwColors.darkTextColor;
    cell.backgroundColor = htwColors.darkCellBackground;
    
    UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
    imageView.tag = indexPath.row;
    [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
    imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [imageView setTintColor:[UIColor whiteColor]];
    imageView.frame = CGRectMake(0, 0, 50, 50);
    imageView.userInteractionEnabled = YES;
    [imageView addTarget:self action:@selector(didTabReloadButton:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = imageView;
    
    
    return cell;
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
        
        NSString *zuLoeschendeNummer = [(Student*)_nummern[indexPath.row] matrnr];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", zuLoeschendeNummer]];
        
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
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([zuLoeschendeNummer isEqualToString:[defaults objectForKey:@"Matrikelnummer"]])
            [defaults setObject:[(Student*)_nummern[0] matrnr] forKey:@"Matrikelnummer"];
        
        
        
        [self.tableView reloadData];
        
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    Student *info = _nummern[indexPath.row];
    [defaults setBool:info.dozent.boolValue forKey:@"Dozent"];
    [defaults setObject:info.matrnr forKey:@"Matrikelnummer"];
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - IBAction

- (IBAction)addButtonPressed:(id)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Neuen Stundenplan hinzufügen"
                                                    message:@"Bitte geben Sie eine Matrikelnummer oder Studiengruppe bzw. Dozenten-Kennung ein:"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Student", @"Dozent", nil];
    [alert setAlertViewStyle:UIAlertViewStyleSecureTextInput];
    [alert show];
}

-(void)didTabReloadButton:(UIButton *)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Stundenplan wiederherstellen"
                                                    message:@"Wenn Sie auf Ok tippen, werden alle momentanen Stunden incl aller Änderungen in der Datenbank gelöscht und durch das Original auf den HTW-Servern ersetzt. Sind Sie sicher?"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Ok", nil];
    alert.tag = sender.tag;
    [alert show];
}

#pragma mark - StundenplanParser Delegate

-(void)HTWStundenplanParserFinished
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_parser.Matrnr forKey:@"Matrikelnummer"];
    
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
            [imageView addTarget:self action:@selector(didTabReloadButton:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = imageView;
            
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.title = @"Stundenplan erfolgreich heruntergeladen.";
            [alert show];
            [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
            return;
        }
    }
    
}

-(void)HTWCSVConnectionFinished
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_dozentParser.password forKey:@"Matrikelnummer"];
    
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
        if ([aktuell.matrnr isEqualToString:_dozentParser.password]) {
            NSLog(@"und fertig..");
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
            imageView.tag = i;
            [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
            imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:[UIColor whiteColor]];
            imageView.frame = CGRectMake(0, 0, 50, 50);
            imageView.userInteractionEnabled = YES;
            [imageView addTarget:self action:@selector(didTabReloadButton:) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = imageView;
            
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.title = @"Stundenplan erfolgreich heruntergeladen.";
            [alert show];
            [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
            return;
        }
    }
}

-(void)HTWStundenplanParserError:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Fehler";
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Ok"];
    [alert show];
}

-(void)HTWCSVConnectionError:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Fehler";
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Ok"];
    [alert show];
}

@end
