//
//  HTWRaumplanerTableViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 21.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWRaumplanerTableViewController.h"
#import "HTWStundenplanParser.h"
#import "HTWAppDelegate.h"
#import "HTWAlleRaeumeTableViewController.h"
#import "User.h"
#import "Stunde.h"
#import "HTWPortraitViewController.h"
#import "UIColor+HTW.h"

#define IMAGEVIEW_TAG 8

@interface HTWRaumplanerTableViewController() <HTWStundenplanParserDelegate, HTWAlleRaeumeDelegate, UIAlertViewDelegate>
{
    HTWAppDelegate *appdelegate;
    
    int indexForRefresh;
}

@property (weak, nonatomic) IBOutlet UIBarButtonItem *addBarButtonItem;
@property (nonatomic, strong) HTWStundenplanParser *parser;
@property (nonatomic, strong) NSManagedObjectContext *context;
@property (nonatomic, strong) NSArray *zimmer;


@end

@implementation HTWRaumplanerTableViewController

#pragma mark - ViewController Lifecycle

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if(!_zimmer) _zimmer = [[NSArray alloc] init];
    [self updateZimmerArray];
    
    self.clearsSelectionOnViewWillAppear = YES;
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];

    [self.tableView reloadData];
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [_zimmer count];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell" forIndexPath:indexPath];
    
    User *info = _zimmer[indexPath.row];
    
    NSDate *naechsteZeit = [NSDate dateWithTimeIntervalSince1970:0];
    BOOL frei = true;
    
    
    for (Stunde *aktuell in info.stunden)
    {
        if (aktuell.anfang )
        {
            if ([[NSDate date] compare:aktuell.anfang] == NSOrderedDescending &&
                [[NSDate date] compare:aktuell.ende] == NSOrderedAscending)
            {
                frei = false;
                naechsteZeit = aktuell.ende;
                break;
            }
            if ([[NSDate date] compare:aktuell.anfang] == NSOrderedAscending &&
                fabsf([aktuell.anfang timeIntervalSinceDate:[NSDate date]]) < fabsf([naechsteZeit timeIntervalSinceDate:[NSDate date]]))
            {
                naechsteZeit = aktuell.anfang;
            }
        }
    }
    
    NSDateFormatter *uhrzeit = [[NSDateFormatter alloc] init];
    [uhrzeit setDateFormat:@"HH:mm"];
    
    if(frei) cell.detailTextLabel.text = [NSString stringWithFormat:@"frei bis %@", [uhrzeit stringFromDate:naechsteZeit]];
    else cell.detailTextLabel.text = [NSString stringWithFormat:@"besetzt bis %@", [uhrzeit stringFromDate:naechsteZeit]];
    
    if (frei && ![self isSameDayWithDate1:naechsteZeit date2:[NSDate date]]) {
        cell.detailTextLabel.text = @"heute frei";
    }
    
    cell.textLabel.text = info.matrnr;
    cell.textLabel.textColor = [UIColor HTWDarkGrayColor];
    
    if (frei) {
        cell.detailTextLabel.textColor = [UIColor colorWithRed:58/255.f green:121/255.f blue:162/255.f alpha:1];
    }
    else cell.detailTextLabel.textColor = [UIColor colorWithRed:205/255.f green:111/255.f blue:93/255.f alpha:1];
    
    cell.backgroundColor = [UIColor HTWWhiteColor];
    
    return cell;
}



-(BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

-(void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        NSLog(@"Zimmer %@ wird gelöscht.", [(User*)_zimmer[indexPath.row] matrnr]);
        appdelegate = [[UIApplication sharedApplication] delegate];
        _context = [appdelegate managedObjectContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
        [fetchRequest setEntity:entity];
        
        [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
        
        
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum = 1) && (matrnr = %@)", [(User*)_zimmer[indexPath.row] matrnr]]];
        
        NSMutableArray *tempArray = [NSMutableArray arrayWithArray:[_context executeFetchRequest:fetchRequest error:nil]];
        for (User *raum in tempArray) {
            [_context deleteObject:raum];
        }
        [_context save:nil];
        [self updateZimmerArray];
        [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return @"Löschen";
}

#pragma mark - HTWStundenplanParser Delegate

-(void)HTWStundenplanParserFinished:(HTWStundenplanParser *)parser
{
    if(parser.tag == 0) {
        [self updateZimmerArray];
        
        [self.tableView reloadData];
    }
    else if (parser.tag == 5) {
        indexForRefresh++;
        if (indexForRefresh >= _zimmer.count) {
            [self updateZimmerArray];
            
            [self.tableView reloadData];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fertig" message:@"Alle Räume wurden ordnungsgemäß aktualisiert." delegate:nil cancelButtonTitle:nil otherButtonTitles:nil];
            [alert show];
            [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:2];
            return;
        }
        User *temp = _zimmer[indexForRefresh];
        _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:temp.matrnr andRaum:YES];
        [_parser setDelegate:self];
        _parser.tag = 5;
        [_parser parserStart];
    }
}

-(void)HTWStundenplanParser:(HTWStundenplanParser *)parser Error:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                    message:errorMessage
                                                   delegate:self
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

#pragma mark - HTWAlleRaeume Delegate

-(void)neuerRaumAusgewaehlt:(NSString *)raumNummer
{
    for (User *this in _zimmer) {
        if ([this.matrnr isEqualToString:raumNummer]) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                            message:@"Dieser Raum ist schon in der Übersicht enthalten."
                                                           delegate:nil
                                                  cancelButtonTitle:@"Ok"
                                                  otherButtonTitles:nil];
            [alert show];
            return;
        }
    }
    
    _parser = nil;
    _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:raumNummer andRaum:YES];
    [_parser setDelegate:self];
    [_parser parserStart];
}

#pragma mark - Hilfsfunktionen

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day] == [comp2 day] && [comp1 month] == [comp2 month] && [comp1 year] == [comp2 year];
}

-(void)updateZimmerArray
{
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"User" inManagedObjectContext:_context];
    [fetchRequest setEntity:entity];
    
    [fetchRequest setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"matrnr" ascending:YES]]];
    
    
    [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"(raum = 1)"]];
    
    _zimmer = [_context executeFetchRequest:fetchRequest error:nil];
    
    if (_zimmer.count == 0) {
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.width)];
        imageView.image = [UIImage imageNamed:@"neuerRaum.png"];
        imageView.tag = IMAGEVIEW_TAG;
        [self.view addSubview:imageView];
    }
    else {
        [[self.view viewWithTag:IMAGEVIEW_TAG] removeFromSuperview];
    }
}

#pragma mark - IBActions

- (IBAction)reloadButtonPressed:(UIBarButtonItem *)sender {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Aktualisierung" message:@"Wenn Sie auf OK tippen, werden alle Pläne der eingetragenen Räume mit denen auf den HTW-Servern aktualisiert. Je nach Anzahl der eingetragenen Räume kann dieser Vorgang etwas dauern." delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Ok", nil];
    [alert show];
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        // OK pressed
        if (_zimmer.count == 0) return;
        indexForRefresh = 0;
        User *temp = _zimmer[indexForRefresh];
        _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:temp.matrnr andRaum:YES];
        [_parser setDelegate:self];
        _parser.tag = 5;
        [_parser parserStart];
    }
}


#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if( [segue.identifier isEqualToString:@"showRaum"])
    {
        HTWPortraitViewController *pvc = segue.destinationViewController;
        UITableViewCell *senderCell = sender;
        pvc.raumNummer = senderCell.textLabel.text;
    }
    else if ([segue.identifier isEqualToString:@"modalNeuerRaum"])
    {
        [(HTWAlleRaeumeTableViewController*)[(UINavigationController*)segue.destinationViewController viewControllers][0] setDelegate:self];
    }
}


@end