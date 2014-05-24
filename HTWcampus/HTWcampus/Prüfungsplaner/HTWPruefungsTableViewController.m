//
//  HTWPruefungsTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsTableViewController.h"
#import "HTWPruefungsParser.h"
#import "HTWPruefungsDetailTableViewController.h"
#import "HTWNeueStudiengruppe.h"
#import "HTWDozentEingebenTableViewController.h"
#import "HTWAppDelegate.h"
#import "User.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "NSDate+HTW.h"

#define kURL [NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/pr_abfrage.php"]

@interface HTWPruefungsTableViewController () <HTWNeueStudiengruppeDelegate, HTWNeuerDozentDelegate>

@property (nonatomic, strong) NSArray *pruefungsArray;
@property (nonatomic, strong) NSArray *keys;

@property (nonatomic, strong) NSMutableArray *vorher;
@property (nonatomic, strong) NSMutableArray *nachher;

@end

@implementation HTWPruefungsTableViewController

-(NSMutableArray *)vorher
{
    if (!_vorher) {
        _vorher = [NSMutableArray new];
    }
    return _vorher;
}

-(NSMutableArray *)nachher
{
    if (!_nachher) {
        _nachher = [NSMutableArray new];
    }
    return _nachher;
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Prüfungen";
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self loadData];
}

-(void)loadData
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    if(!([defaults objectForKey:@"pruefungJahr"] && [defaults objectForKey:@"pruefungGruppe"] && [defaults objectForKey:@"pruefungTyp"]) && ![self isDozent])
        [self performSegueWithIdentifier:@"modalEingeben" sender:self];
    else if (![defaults objectForKey:@"pruefungDozent"] && [self isDozent]) {
        [self performSegueWithIdentifier:@"modalDozentEingeben" sender:self];
    }
    
    
    HTWPruefungsParser *parser;
    if (![self isDozent])
        parser = [[HTWPruefungsParser alloc] initWithURL:kURL andImmaJahr:[defaults objectForKey:@"pruefungJahr"] andStudienGruppe:[defaults objectForKey:@"pruefungGruppe"] andBDM:[defaults objectForKey:@"pruefungTyp"]];
    else parser = [[HTWPruefungsParser alloc] initWithURL:kURL andDozent:[defaults objectForKey:@"pruefungDozent"]];

    
    
    
    [parser startWithCompletetionHandler:^(NSArray *erg, NSString *errorMessage) {
        if(errorMessage) {
            NSLog(@"ERROR: %@", errorMessage);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                                     message:errorMessage
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
                [errorAlert show];
            });
            return;}
        self.pruefungsArray = [NSArray arrayWithArray:erg];
        [self.vorher removeAllObjects];
        [self.nachher removeAllObjects];
        for (int i = 1; i < _pruefungsArray.count; i++) {
            if([[self getAnfang:i] compare:[NSDate date]] == NSOrderedAscending || ![self getAnfang:i])
               [self.vorher addObject:_pruefungsArray[i]];
            else
                [self.nachher addObject:_pruefungsArray[i]];
            
        }
        [self.tableView reloadData];
    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_pruefungsArray)
    {
        if (section == 0) return _nachher.count;
        else return _vorher.count;
    }
    else return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return @"Zukünftige Prüfungen";
        case 1: return @"Abgeschlossene Prüfungen";
        default:
            break;
    }
    return @"";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if(!_pruefungsArray)
    {
        cell.textLabel.text = @"";
        cell.detailTextLabel.text = @"";
        UIActivityIndicatorView *act = [[UIActivityIndicatorView alloc] init];
        act.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
        act.frame = CGRectMake(0, 0, 50, 50);
        act.center = CGPointMake(cell.frame.size.width/2, cell.frame.size.height/2);
        [act startAnimating];
        [cell addSubview:act];
        return cell;
    }
    if(!_pruefungsArray) return cell;
    
    if (indexPath.section == 0) {
        cell.textLabel.text = _nachher[indexPath.row][@"Modul"];
        if(![_nachher[indexPath.row][@"Tag"] isEqualToString:@" "])
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ Uhr", _nachher[indexPath.row][@"Tag"], _nachher[indexPath.row][@"Zeit"]];
        else cell.detailTextLabel.text = @" ";
    }
    else
    {
        cell.textLabel.text = _vorher[indexPath.row][@"Modul"];
        if(![_vorher[indexPath.row][@"Tag"] isEqualToString:@" "])
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ Uhr", _vorher[indexPath.row][@"Tag"], _vorher[indexPath.row][@"Zeit"]];
        else cell.detailTextLabel.text = @" ";
    }
    
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.detailTextLabel.font = [UIFont HTWMediumFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
    
    cell.textLabel.numberOfLines = 3;
    cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
    cell.detailTextLabel.numberOfLines = 3;
    cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
    
    return cell;
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"pruefungsDetail"]) {
        if ([segue.destinationViewController isKindOfClass:[HTWPruefungsDetailTableViewController class]]) {
            HTWPruefungsDetailTableViewController *pdtvc = (HTWPruefungsDetailTableViewController*)segue.destinationViewController;
            UITableViewCell *senderCell = (UITableViewCell *)sender;
            NSIndexPath *indexPath = [self.tableView indexPathForCell:senderCell];
            if(indexPath.section == 0) pdtvc.pruefung = _nachher[indexPath.row];
            else pdtvc.pruefung = _vorher[indexPath.row];
        }
    }
    else if ([segue.identifier isEqualToString:@"modalEingeben"])
    {
        [(HTWNeueStudiengruppe*)segue.destinationViewController setDelegate:self];
    }
    else if ([segue.identifier isEqualToString:@"modalDozentEingeben"])
    {
        [(HTWDozentEingebenTableViewController*)segue.destinationViewController setDelegate:self];
    }
}

-(void)neueStudienGruppeEingegeben
{
    [self loadData];
}

-(void)neuerDozentEingegeben
{
    [self loadData];
}

- (IBAction)refreshButtonPressed:(id)sender {
    [self loadData];
}

- (IBAction)settingsButtonPressed:(id)sender {
    if(![self isDozent])
        [self performSegueWithIdentifier:@"modalEingeben" sender:self];
    else [self performSegueWithIdentifier:@"modalDozentEingeben" sender:self];
}

#pragma mark - Hilfsfunktionen

-(BOOL)isDozent
{
    NSManagedObjectContext *context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", [[NSUserDefaults standardUserDefaults] objectForKey:@"Matrikelnummer"]];
    request.predicate = pred;
    NSArray *objects = [context executeFetchRequest:request error:nil];
    if(objects.count > 0)
    {
        User *info = objects[0];
        if(info.dozent.boolValue) return YES;
        else return NO;
    }
    return NO;
}

-(NSDate*)getAnfang:(int)index
{
    if(![NSMutableString stringWithString:[(NSString*)_pruefungsArray[index][_keys[8]] componentsSeparatedByString:@" "][0]])
        return nil;
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    NSMutableString *anfang = [NSMutableString stringWithString:[(NSString*)_pruefungsArray[index][_keys[8]] componentsSeparatedByString:@" "][0]];
    [anfang replaceOccurrencesOfString:@"." withString:@":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, anfang.length)];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefungsArray[index][_keys[7]], [self aktuellesJahr], anfang]];
}

-(NSDate*)getEnde:(int)index
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"dd.MM.yyyy HH:mm"];
    NSMutableString *ende = [NSMutableString stringWithString:[(NSString*)_pruefungsArray[index][_keys[8]] componentsSeparatedByString:@" "][2]];
    [ende replaceOccurrencesOfString:@"." withString:@":" options:NSCaseInsensitiveSearch range:NSMakeRange(0, ende.length)];
    return [dateF dateFromString:[NSString stringWithFormat:@"%@%@ %@", _pruefungsArray[index][_keys[7]], [self aktuellesJahr], ende]];
}

-(NSString*)aktuellesJahr
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:@"yyyy"];
    return [dateF stringFromDate:[NSDate date]];
}

@end
