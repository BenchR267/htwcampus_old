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
#import "User.h"
#import "HTWMatrikelnummernEditTableViewController.h"
#import "HTWAlertNavigationController.h"

#import "Stunde.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define ALERT_EINGEBEN 110
#define ALERT_FEHLER 111
#define ALERT_WARNUNG 112

@interface HTWMatrikelnummernTableViewController () <HTWStundenplanParserDelegate, HTWCSVConnectionDelegate, HTWAlertViewDelegate, UIAlertViewDelegate>
{
    HTWAppDelegate *appdelegate;
    NSString *Matrnr;
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
    
    self.title = @"Stundenpläne";
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
    
    _nummern = [_context executeFetchRequest:fetchRequest error:nil];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
//    self.navigationItem.rightBarButtonItems = @[self.navigationItem.rightBarButtonItem, self.editButtonItem];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.tableView.backgroundView.backgroundColor = [UIColor HTWSandColor];

    [self.tableView reloadData];
}

#pragma mark - AlertView Delegate

-(void)htwAlert:(HTWAlertNavigationController *)alert gotStringsFromTextFields:(NSArray *)strings
{
    if(alert.tag == ALERT_EINGEBEN)
    {
        NSString *eingegeben = strings[1];
        if (eingegeben.length == 0) return;
            if ([self isMatrikelnummer:eingegeben] || [self isStudiengruppe:eingegeben]) {
                
                _parser = nil;
                
                NSString *matrNr = [eingegeben copy];
                
                appdelegate = [[UIApplication sharedApplication] delegate];
                _context = [appdelegate managedObjectContext];
                
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
                [fetchRequest setEntity:entity];
                
                [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
                
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", matrNr]];
                
                NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
                
                if(tempArray.count == 0)
                {
                    _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:matrNr andRaum:NO];
                    if(strings[0] && ![strings[0] isEqualToString:@""]) _parser.name = strings[0];
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
            else {
                NSString *matrNr = strings[1];
                _dozentParser = nil;
                
                appdelegate = [[UIApplication sharedApplication] delegate];
                _context = [appdelegate managedObjectContext];
                
                NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
                NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
                [fetchRequest setEntity:entity];
                
                [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
                
                [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", matrNr]];
                
                NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
                
                if(tempArray.count == 0)
                {
                    _dozentParser = [[HTWCSVConnection alloc] initWithPassword:matrNr];
                    if(strings[0] && ![strings[0] isEqualToString:@""]) _dozentParser.eName = strings[0];
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

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    if ([alertView.title isEqualToString:@"Stundenplan wiederherstellen"])
    {
        if([buttonTitle isEqualToString:@"Ok"])
        {
            NSIndexPath *path = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
            
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
            spinner.frame = CGRectMake(0, 0, 50, 50);
            spinner.color = [UIColor HTWDarkGrayColor];
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:path];
            cell.accessoryView = spinner;
            [spinner startAnimating];
            
            if ([self.tableView cellForRowAtIndexPath:path].tag == 0) {
                _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:[(User*)_nummern[path.row] matrnr] andRaum:NO];
                [_parser setDelegate:self];
                [_parser parserStart];
            }
            else {
                _dozentParser = [[HTWCSVConnection alloc] initWithPassword:[(User*)_nummern[path.row] matrnr]];
                _dozentParser.delegate = self;
                [_dozentParser startParser];
            }
            
        }
    }
    else if (alertView.tag == ALERT_FEHLER)
    {
        HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
        [alert setHtwTitle:@"Neuer Stundenplan"];
        alert.message = @"Bitte geben Sie eine Matrikelnummer oder Studiengruppe bzw. Dozenten-Kennung ein:";
        alert.mainTitle = @[@"Name (optional)",@"Kennung"];
        alert.htwDelegate = self;
        alert.tag = ALERT_EINGEBEN;
        [self presentViewController:alert animated:YES completion:^{}];
    }
}

#pragma mark - UIGestureRecognizer

-(IBAction)cellPressedForPop:(UITapGestureRecognizer*)gesture
{
    UITableViewCell *senderCell = (UITableViewCell*)gesture.view;
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    User *info = _nummern[[self.tableView indexPathForCell:senderCell].row];
    [defaults setBool:info.dozent.boolValue forKey:@"Dozent"];
    [defaults setObject:info.matrnr forKey:@"Matrikelnummer"];
    [self.navigationController popViewControllerAnimated:YES];
}

-(IBAction)cellPressedForEdit:(UILongPressGestureRecognizer*)gesture
{
    UITableViewCell *senderCell = (UITableViewCell*)gesture.view;
    [self performSegueWithIdentifier:@"editUser" sender:senderCell];
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
    
    User *info = _nummern[indexPath.row];
    
    if (info.dozent.boolValue == YES) {
        cell.tag = 1;
    }
    else cell.tag = 0;
    
    if(!info.name) cell.textLabel.text = info.matrnr;
    else cell.textLabel.text = info.name;
    
    cell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    cell.textLabel.font = [UIFont HTWBaseFont];
    cell.backgroundColor = [UIColor HTWWhiteColor];
    
    UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
    imageView.tag = indexPath.row;
    [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
    imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [imageView setTintColor:[UIColor HTWDarkGrayColor]];
    imageView.frame = CGRectMake(0, 0, 50, 50);
    imageView.userInteractionEnabled = YES;
    [imageView addTarget:self action:@selector(didTabReloadButton:) forControlEvents:UIControlEventTouchUpInside];
    cell.accessoryView = imageView;
    
    UISwipeGestureRecognizer *longGR = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(cellPressedForEdit:)];
    longGR.direction = UISwipeGestureRecognizerDirectionRight;
    
    [cell addGestureRecognizer:longGR];
    
    UITapGestureRecognizer *tapGR = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(cellPressedForPop:)];
    tapGR.numberOfTapsRequired = 1;
    
    [cell addGestureRecognizer:tapGR];
    
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
-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"want to delete object at row %ld (%@)", (long)indexPath.row, [(User*)_nummern[indexPath.row] matrnr]);
        appdelegate = [[UIApplication sharedApplication] delegate];
        _context = [appdelegate managedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
        
        NSString *zuLoeschendeNummer = [(User*)_nummern[indexPath.row] matrnr];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0) && (matrnr = %@)", zuLoeschendeNummer]];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
        for (User *aktuell in tempArray) {
            [_context deleteObject:aktuell];
        }
        [_context save:nil];
        
        fetchRequest = [[NSFetchRequest alloc] init];
        entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
        
        _nummern = [_context executeFetchRequest:fetchRequest error:nil];
        
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        if ([zuLoeschendeNummer isEqualToString:[defaults objectForKey:@"Matrikelnummer"]]) {
            if(_nummern.count)
                [defaults setObject:[(User*)_nummern[0] matrnr] forKey:@"Matrikelnummer"];
            else
                [defaults setObject:nil forKey:@"Matrikelnummer"];
        }
        
        
        
        [UIView transitionWithView:self.tableView
                          duration:0.3f
                           options:UIViewAnimationOptionTransitionCrossDissolve
                        animations:^(void) {
                            [self.tableView reloadData];
                        } completion:NULL];
        
    }
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark - IBAction

- (IBAction)addButtonPressed:(id)sender {
//    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Neuer Stundenplan"
//                                                    message:@"Bitte geben Sie eine Matrikelnummer oder Studiengruppe bzw. Dozenten-Kennung ein:"
//                                                   delegate:self
//                                          cancelButtonTitle:@"Abbrechen"
//                                          otherButtonTitles:@"Ok", nil];
//    [alert setAlertViewStyle:UIAlertViewStylePlainTextInput];
//    alert.tag = ALERT_EINGEBEN;
//    [alert show];
    
    HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
    [alert setHtwTitle:@"Neuer Stundenplan"];
    alert.message = @"Bitte geben Sie eine Matrikelnummer oder Studiengruppe bzw. Dozenten-Kennung ein:";
    alert.mainTitle = @[@"Name (optional)",@"Kennung"];
    alert.htwDelegate = self;
    alert.tag = ALERT_EINGEBEN;
    [self presentViewController:alert animated:YES completion:^{}];
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

-(void)HTWStundenplanParserFinished:(HTWStundenplanParser *)parser
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_parser.Matrnr forKey:@"Matrikelnummer"];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
    
    _nummern = [_context executeFetchRequest:fetchRequest error:nil];
    
    [self.tableView reloadData];
    for (int i=0; i<_nummern.count; i++) {
        User *aktuell = _nummern[i];
        if ([aktuell.matrnr isEqualToString:_parser.Matrnr]) {
            NSLog(@"und fertig..");
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
            imageView.tag = i;
            [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
            imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:[UIColor HTWDarkGrayColor]];
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

-(void)HTWCSVConnectionFinished:(HTWCSVConnection *)connection
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:_dozentParser.password forKey:@"Matrikelnummer"];
    [defaults setBool:YES forKey:@"Dozent"];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum == 0)"]];
    
    _nummern = [_context executeFetchRequest:fetchRequest error:nil];
    
    [self.tableView reloadData];
    for (int i=0; i<_nummern.count; i++) {
        User *aktuell = _nummern[i];
        if ([aktuell.matrnr isEqualToString:_dozentParser.password]) {
            NSLog(@"und fertig..");
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            UIButton *imageView = [UIButton buttonWithType:UIButtonTypeSystem];
            imageView.tag = i;
            [imageView setImage:[UIImage imageNamed:@"Reload"] forState:UIControlStateNormal];
            imageView.imageView.image = [imageView.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            [imageView setTintColor:[UIColor HTWDarkGrayColor]];
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

-(void)HTWStundenplanParser:(HTWStundenplanParser *)parser Error:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Fehler";
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Ok"];
    alert.tag = ALERT_FEHLER;
    alert.delegate = self;
    [alert show];
}

-(void)HTWCSVConnection:(HTWCSVConnection *)connection Error:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Fehler";
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Ok"];
    alert.tag = ALERT_FEHLER;
    alert.delegate = self;
    [alert show];
}

#pragma mark - Hilfsfunktionen

-(BOOL)isMatrikelnummer:(NSString*)string
{
    if (string.length != 5) return NO;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{5}" options:0 error:nil];
    NSTextCheckingResult *result = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (result) {
        return YES;
    }
    else return NO;
}

-(BOOL)isStudiengruppe:(NSString*)string
{
    NSArray *array = [string componentsSeparatedByString:@"/"];
    if (array.count != 3) return NO;
    else
    {
        for (NSString *this in array) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{2,}" options:0 error:nil];
            NSTextCheckingResult *result = [regex firstMatchInString:this options:0 range:NSMakeRange(0, this.length)];
            if (result) {
                return YES;
            }
            else return NO;
        }
    }
    return NO;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"editUser"]) {
        UITableViewCell *senderCell = (UITableViewCell*)sender;
        User *info = _nummern[[self.tableView indexPathForCell:senderCell].row];
        HTWMatrikelnummernEditTableViewController *dest = segue.destinationViewController;
        dest.user = info;
    }
}

@end
