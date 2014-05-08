//
//  MensaDetailViewController.m
//  HTWcampus
//
//  Created by Konstantin on 19.09.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import "MensaDetailViewController.h"
#import "HTWMensaSpeiseTableViewCell.h"
#import "HTWMensaWebViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface MensaDetailViewController ()

@end

@implementation MensaDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
}

-(void)viewWillAppear:(BOOL)animated {
    if (_availableMeals != nil) {
        self.title = [[_availableMeals objectAtIndex:0] valueForKey:@"mensa"];
    }
    NSLog(@"%lu Essen gefunden", (unsigned long)[_availableMeals count]);
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
    return 112;
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
    NSString *mealName = [[_availableMeals objectAtIndex:indexPath.row] valueForKey:@"desc"];
    NSString *mealPrice = [[_availableMeals objectAtIndex:indexPath.row] valueForKey:@"price"];
    
    
    // Truncate mealName
    NSString *helpString = mealName;
    NSArray *helpArray = [helpString componentsSeparatedByString:@","];
    
    [mealNameLabel setText:[helpArray objectAtIndex:0]];
    [mealPriceLabel setText:mealPrice];
    
    [mealNameLabel sizeToFit];
    [mealNameLabel setNumberOfLines:0];    
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
        HTWMensaWebViewController *dest = segue.destinationViewController;
        dest.detailURL = [NSURL URLWithString:[[_availableMeals objectAtIndex:path.row] valueForKey:@"link"]];
        dest.titleString = [[_availableMeals objectAtIndex:path.row] valueForKey:@"desc"];
    }
}

@end
