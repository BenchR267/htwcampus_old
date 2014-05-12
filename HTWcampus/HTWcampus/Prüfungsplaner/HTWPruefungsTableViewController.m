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

#define kURL [NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/pr_abfrage.php"]

@interface HTWPruefungsTableViewController () <HTWNeueStudiengruppeDelegate, HTWNeuerDozentDelegate>

@property (nonatomic, strong) NSArray *pruefungsArray;

@end

@implementation HTWPruefungsTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = @"Prüfungen";
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
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
        if(errorMessage) { NSLog(@"ERROR: %@", errorMessage); return;}
        self.pruefungsArray = [NSArray arrayWithArray:erg];
        [self.tableView reloadData];
    }];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(_pruefungsArray) return self.pruefungsArray.count - 1;
    else return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 90;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return @"Prüfungen";
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
    cell.textLabel.text = _pruefungsArray[indexPath.row+1][@"Modul"];
    if(![_pruefungsArray[indexPath.row+1][@"Tag"] isEqualToString:@" "])
        cell.detailTextLabel.text = [NSString stringWithFormat:@"%@ %@ Uhr", _pruefungsArray[indexPath.row+1][@"Tag"], _pruefungsArray[indexPath.row+1][@"Zeit"]];
    else cell.detailTextLabel.text = @" ";
    
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
            long row = [self.tableView indexPathForCell:senderCell].row;
            pdtvc.pruefung = _pruefungsArray[row+1];
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

@end
