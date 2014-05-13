//
//  TableViewController.m
//  test
//
//  Created by Benjamin Herzog on 13.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWAlleRaeumeTableViewController.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWAlleRaeumeTableViewController () <UISearchBarDelegate>

@property (nonatomic, strong) NSArray *arrayRaeume;
@property (nonatomic, strong) NSMutableArray *filteredArrayRaeume;
@property (weak, nonatomic) IBOutlet UISearchBar *searchBar;

@end

@implementation HTWAlleRaeumeTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    
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
    _searchBar.delegate = self;
    [self.tableView reloadData];
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        return [_filteredArrayRaeume count];
    } else {
        return [_arrayRaeume count];
    }
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if ( cell == nil ) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    if (tableView == self.searchDisplayController.searchResultsTableView) {
        cell.textLabel.text = [_filteredArrayRaeume objectAtIndex:indexPath.row];
    } else {
        cell.textLabel.text = [_arrayRaeume objectAtIndex:indexPath.row];
    }
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWTextColor];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
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
    
    [self dismissViewControllerAnimated:YES completion:^{}];
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

@end
