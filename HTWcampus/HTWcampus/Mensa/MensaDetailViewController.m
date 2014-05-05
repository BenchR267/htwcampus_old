//
//  MensaDetailViewController.m
//  HTWcampus
//
//  Created by Konstantin on 19.09.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import "MensaDetailViewController.h"
#import "HTWMensaSpeiseTableViewCell.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface MensaDetailViewController ()

@end

@implementation MensaDetailViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
 
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

-(void)viewWillAppear:(BOOL)animated {
    if (_availableMeals != nil) {
        self.title = [[_availableMeals objectAtIndex:0] valueForKey:@"mensa"];
    }
    NSLog(@"%i Essen gefunden", [_availableMeals count]);
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

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }   
    else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
{
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Navigation logic may go here. Create and push another view controller.
    /*
     <#DetailViewController#> *detailViewController = [[<#DetailViewController#> alloc] initWithNibName:@"<#Nib name#>" bundle:nil];
     // ...
     // Pass the selected object to the new view controller.
     [self.navigationController pushViewController:detailViewController animated:YES];
     */
}

@end
