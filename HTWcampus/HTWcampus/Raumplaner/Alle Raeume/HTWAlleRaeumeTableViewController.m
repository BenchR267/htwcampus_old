//
//  TableViewController.m
//  test
//
//  Created by Benjamin Herzog on 13.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWAlleRaeumeTableViewController.h"
#import "HTWAppDelegate.h"
#import "Stunde.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "UIImage+Resize.h"

#define ACCESSORY_VIEW_TAG -6

@interface HTWAlleRaeumeTableViewController () <UISearchBarDelegate>
{
    BOOL stern;
}

@property (nonatomic, strong) NSArray *stundenplanRaeume;
@property (nonatomic, strong) NSArray *arrayRaeume;
@property (nonatomic, strong) NSMutableArray *filteredArrayRaeume;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation HTWAlleRaeumeTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    stern = NO;
    
    self.title = @"Übersicht Räume";
    
    UIBarButtonItem *fertigButton = [[UIBarButtonItem alloc] initWithTitle:@"Fertig" style:UIBarButtonItemStylePlain target:self action:@selector(fertigPressed:)];
    self.navigationItem.rightBarButtonItem = fertigButton;
    
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"alleRaeume"
                                                         ofType:@"txt"];
    _arrayRaeume = [[NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil] componentsSeparatedByString:@"\n"];
    _arrayRaeume = [_arrayRaeume sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [(NSString*)obj1 compare:(NSString*)obj2];
    }];
    
    
    _filteredArrayRaeume = [NSMutableArray arrayWithCapacity:_arrayRaeume.count];
    self.tableView.tableHeaderView = _searchBar;
}

-(void)viewWillAppear:(BOOL)animated
{
    [self aktualisiereStundenPlanRaeume];
    [self.tableView reloadData];
    
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(stern)
    {
        return _stundenplanRaeume.count;
    }
    else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            return [_filteredArrayRaeume count];
        } else {
            return [_arrayRaeume count];
        }
    }
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (stern && section == 0) {
        return @"Es werden nur Räume angezeigt, die im Stundenplan vorkommen.";
    }
    else return @"";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    [[cell.contentView viewWithTag:ACCESSORY_VIEW_TAG] removeFromSuperview];
    
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    NSMutableString *textLabelText;
    if(stern)
    {
        textLabelText = [NSMutableString stringWithString:_stundenplanRaeume[indexPath.row]];
    }
    else {
        if (tableView == self.searchDisplayController.searchResultsTableView) {
            textLabelText = [NSMutableString stringWithString:[_filteredArrayRaeume objectAtIndex:indexPath.row]];
        } else {
            textLabelText = [NSMutableString stringWithString:[_arrayRaeume objectAtIndex:indexPath.row]];
        }
    }
    
    [textLabelText replaceOccurrencesOfString:@"\r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, textLabelText.length)];
    
    cell.textLabel.text = textLabelText;
    
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    
    
    if([_stundenplanRaeume containsObject:textLabelText])
    {
        CGRect rect = CGRectMake(284, 6, 31, 31);
        UIImageView *imageV = [[UIImageView alloc] initWithFrame:rect];
        imageV.image = [[UIImage imageNamed:@"Stern"] resizedImage:rect.size interpolationQuality:kCGInterpolationDefault];
        imageV.tag = ACCESSORY_VIEW_TAG;
        [cell.contentView addSubview:imageV];
        [cell.contentView viewWithTag:ACCESSORY_VIEW_TAG].alpha = 0.6;
    }
    
    cell.textLabel.textColor = [UIColor HTWTextColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!stern)
    {
        if(tableView == self.searchDisplayController.searchResultsTableView) {
            NSIndexPath *indexPath = [self.searchDisplayController.searchResultsTableView indexPathForSelectedRow];
            NSMutableString *destinationTitle = [NSMutableString stringWithString:[_filteredArrayRaeume objectAtIndex:indexPath.row]];
            [destinationTitle replaceOccurrencesOfString:@"\r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, destinationTitle.length)];
            if(_delegate) [_delegate neuerRaumAusgewaehlt:destinationTitle];
        }
        else {
            NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
            NSMutableString *destinationTitle = [NSMutableString stringWithString:[_arrayRaeume objectAtIndex:indexPath.row]];
            [destinationTitle replaceOccurrencesOfString:@"\r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, destinationTitle.length)];
            if(_delegate) [_delegate neuerRaumAusgewaehlt:destinationTitle];
        }
    }
    else
    {
        NSIndexPath *indexPath = [self.tableView indexPathForSelectedRow];
        NSMutableString *destinationTitle = [NSMutableString stringWithString:[_stundenplanRaeume objectAtIndex:indexPath.row]];
        [destinationTitle replaceOccurrencesOfString:@"\r" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, destinationTitle.length)];
        if(_delegate) [_delegate neuerRaumAusgewaehlt:destinationTitle];
    }
    
    
    [self.presentingViewController dismissViewControllerAnimated:YES completion:^{}];
}

#pragma mark Content Filtering

-(void)filterContentForSearchText:(NSString*)searchText scope:(NSString*)scope {
    [self.filteredArrayRaeume removeAllObjects];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF contains[c] %@",searchText];
    _filteredArrayRaeume = [NSMutableArray arrayWithArray:[_arrayRaeume filteredArrayUsingPredicate:predicate]];
}

#pragma mark - UISearchDisplayController Delegate Methods
-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchString:(NSString *)searchString {
    [self filterContentForSearchText:searchString scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:[self.searchDisplayController.searchBar selectedScopeButtonIndex]]];
    return YES;
}

-(BOOL)searchDisplayController:(UISearchDisplayController *)controller shouldReloadTableForSearchScope:(NSInteger)searchOption {
    [self filterContentForSearchText:self.searchDisplayController.searchBar.text scope:
     [[self.searchDisplayController.searchBar scopeButtonTitles] objectAtIndex:searchOption]];
    return YES;
}

-(IBAction)fertigPressed:(id)sender
{
    [self.navigationController dismissViewControllerAnimated:YES completion:^{}];
}

- (IBAction)sternPressed:(id)sender {
    stern = !stern;
    _searchBar.hidden = !_searchBar.hidden;
    [self.tableView reloadData];
}


-(void)aktualisiereStundenPlanRaeume
{
    NSManagedObjectContext *context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Stunde"];
    request.predicate = [NSPredicate predicateWithFormat:@"student.raum = %@", [NSNumber numberWithBool:NO]];
    NSArray *stunden = [context executeFetchRequest:request error:nil];
    if(!stunden) return;
    
    NSMutableSet *set = [[NSMutableSet alloc] init];
    
    for (Stunde *this in stunden) {
        if(this.raum) [set addObject:this.raum];
    }
    
    self.stundenplanRaeume = [set allObjects];
    self.stundenplanRaeume = [self.stundenplanRaeume sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        return [obj1 compare:obj2];
    }];
}

@end
