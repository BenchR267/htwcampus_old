//
//  MensaDetailViewController.m
//  HTWcampus
//
//  Created by Konstantin on 19.09.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import "HTWMensaSingleTableViewController.h"
#import "HTWMensaSpeiseTableViewCell.h"
#import "HTWMensaDetailTableViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWMensaSingleTableViewController ()

@end

@implementation HTWMensaSingleTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    
    _availableMeals = [_availableMeals sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        switch([obj1[@"price"] compare:obj2[@"price"]])
        {
            case NSOrderedAscending: return NSOrderedDescending;
            case NSOrderedDescending: return NSOrderedAscending;
            default: return NSOrderedSame;
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated {
    if (_availableMeals != nil) {
        self.title = [[_availableMeals objectAtIndex:0] valueForKey:@"mensa"];
    }
//    NSLog(@"%lu Essen gefunden", (unsigned long)[_availableMeals count]);
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    return 1;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!_availableMeals[indexPath.row][@"price"] || [_availableMeals[indexPath.row][@"price"] isEqualToString:@""]) return 100;
    return 120;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    //NSLog(@"%i Essen gefunden.", [_availableMeals count]);
    return [_availableMeals count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Meal";
    HTWMensaSpeiseTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    UILabel *mealNameLabel = (UILabel *)[cell viewWithTag:1];
    UILabel *mealPriceLabel = (UILabel *)[cell viewWithTag:2];
    
    // Configure the cell...
    NSString *mealName = [[_availableMeals objectAtIndex:indexPath.row] valueForKey:@"title"];
    NSString *mealPrice = [[_availableMeals objectAtIndex:indexPath.row] valueForKey:@"price"];
    
    
    // Truncate mealName
    NSString *helpString = mealName;
    NSArray *helpArray = [helpString componentsSeparatedByString:@","];

    if(helpArray.count >= 2)
        [mealNameLabel setText:[NSString stringWithFormat:@"%@,%@", helpArray[0], helpArray[1]]];
    else
        [mealNameLabel setText:helpArray[0]];

    [mealNameLabel sizeToFit];
    [mealPriceLabel setText:mealPrice];
    
    [mealNameLabel sizeToFit];
    [mealNameLabel setNumberOfLines:3];
    mealNameLabel.lineBreakMode = NSLineBreakByWordWrapping;
    [mealNameLabel sizeToFit];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self performSegueWithIdentifier:@"showLink" sender:indexPath];
}

#pragma mark - Navigation


-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"showLink"]) {
        NSIndexPath *path = (NSIndexPath*)sender;
        HTWMensaDetailTableViewController *dest = segue.destinationViewController;
        dest.speise = [_availableMeals objectAtIndex:path.row];
    }
}

@end
