//
//  mensaViewController.m
//  HTWcampus
//
//  Created by Konstantin on 09.10.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#define MENSAERROR_1 1
#define MENSAERROR_2 2

#define mensaTodayUrl @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss"
#define mensaTomorrowUrl @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen"

#import "mensaViewController.h"
#import "MensaDetailViewController.h"
#import "HTWAppDelegate.h"
#import "UIImage+Resize.h"
#import "UIColor+HTW.h"
#import "HTWMensaSpeiseTableViewCell.h"
#import "HTWMensaXMLParser.h"

@interface mensaViewController () {
    UIActivityIndicatorView *mensaSpinner;
}
@property (strong, nonatomic) NSMutableArray *allMensasOfToday;
@property (strong, nonatomic) NSMutableArray *allMensasOfTomorrow;
@property (strong, nonatomic) NSArray *mensaMeta;
@end

@implementation mensaViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
       [self setMensaDay];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    
    NSError *error;
    _mensaMeta = [NSJSONSerialization
                                JSONObjectWithData: [NSData dataWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"mensen" ofType:@"json"]]
                                options: NSJSONReadingMutableContainers
                                error:&error];
    
    isLoading = YES;
    
    [self.mensaDaySwitcher addTarget:self
                            action:@selector(setMensaDay)
                  forControlEvents:UIControlEventValueChanged];
}

- (void)viewDidAppear:(BOOL)animated
{
    
    
    //self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.tableView.backgroundColor = [UIColor HTWSandColor];
    self.navigationController.navigationBar.barTintColor = [UIColor HTWBlueColor];
    _mensaDaySwitcher.tintColor = [UIColor HTWWhiteColor];
    
//    self.mensaLoadingIndicator.hidden = NO;
//    self.mensaLoadingIndicator.hidesWhenStopped = YES;
    if (![self allMensasOfToday]) {
        [self loadMensa];
    }
    else {
        [self.tableView reloadData];
    }
}


- (void)setMensaDay {
    mensaDay = self.mensaDaySwitcher.selectedSegmentIndex;
    [self.tableView reloadData];
}

- (void)loadMensa {
    NSURL *RSSUrlToday =[NSURL URLWithString:mensaTodayUrl];
    NSURL *RSSUrlTomorrow = [NSURL URLWithString:mensaTomorrowUrl];
    
    NSURLSession *sessionForTodaysMensa = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[sessionForTodaysMensa dataTaskWithURL:RSSUrlToday completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        HTWMensaXMLParser *parser = [[HTWMensaXMLParser alloc] init];
        _allMensasOfToday = [[NSMutableArray alloc] initWithArray: [self groupMealsAccordingToMensa:[parser getAllMealsFromHTML:data]]];
        dispatch_async(dispatch_get_main_queue(), ^
       {
           isLoading = false;
           [self.tableView reloadData];
       });
        
    }] resume];
    
    NSURLSession *sessionForTomorrowsMensa = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration]];
    [[sessionForTomorrowsMensa dataTaskWithURL:RSSUrlTomorrow completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        HTWMensaXMLParser *parser = [HTWMensaXMLParser new];
        _allMensasOfTomorrow = [[NSMutableArray alloc] initWithArray:[self groupMealsAccordingToMensa:[parser getAllMealsFromHTML:data]]];
        dispatch_async(dispatch_get_main_queue(), ^
           {
               isLoading = false;
               [self.tableView reloadData];
           });
    }] resume];
    
    
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
}
 */

- (NSArray *)groupMealsAccordingToMensa:(NSArray *)meals {
    if (meals == nil) return nil;
    
    
    NSMutableArray *allMealsOfOneMensa = [[NSMutableArray alloc] init];
    int mealCount = 0;
    NSMutableArray *allMensas = [[NSMutableArray alloc] init];
    
    for (int i = 0; i < [meals count]; i++) {
        NSDictionary *tmpDict = [meals objectAtIndex:mealCount];
		
		if ([allMealsOfOneMensa count] == 0)
			[allMealsOfOneMensa addObject:tmpDict];
		
		else if ([allMealsOfOneMensa count] >  0)
		{
			NSString *str1 = [tmpDict objectForKey:@"mensa"];
			NSString *str2 = [[allMealsOfOneMensa objectAtIndex:0] objectForKey:@"mensa"];
			if ([str1 isEqualToString:str2])
				[allMealsOfOneMensa addObject:tmpDict];
			else
			{
				[allMensas addObject:allMealsOfOneMensa];
				allMealsOfOneMensa = [NSMutableArray new];
				[allMealsOfOneMensa addObject:tmpDict];
			}
			
			if((mealCount+1) == [meals count])
			{
				[allMensas addObject:allMealsOfOneMensa];
			}
		}
        mealCount++;
    }

    return allMensas;
}


- (NSString *)getMensaImageNameForName:(NSString *)mensaName {
    for (NSDictionary *mensa in _mensaMeta) {
        if ([mensaName isEqualToString:mensa[@"name"]]) {
            return [mensa objectForKey:@"bild"];
        }
    }
    return @"noavailablemensaimage.jpg";
}

- (NSString *)checkWorkingHours:currentMensaName {
    if ([currentMensaName isEqualToString:@"Mensa Reichenbachstraße"]) {
        return @"Geöffnet";
    }
    
    return @"Keine Öffnungszeiten verfügbar";
}

-(void)reloadView {
    isLoading = NO;
    [mensaSpinner stopAnimating];
    NSLog(@"reloadView called");
    [self.mensaTableView reloadData];
}

- (IBAction)refreshMensa:(id)sender {
    [_allMensasOfToday removeAllObjects];
    [_allMensasOfTomorrow removeAllObjects];
    isLoading = YES;
    [self.mensaTableView reloadData];
    [self loadMensa];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Table view data source

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 64.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    NSLog(@"%lu Mensen gefunden.", (unsigned long)[[self allMensasOfToday] count]);
//    return [[self allMensas] count];
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!isLoading) {
        if (mensaDay == 0) {
            NSLog(@"Zeige HEUTIGEN Speiseplan");
            return [[self allMensasOfToday] count];
        }
        else {
            NSLog(@"Zeige MORGIGEN Speiseplan");
            return [[self allMensasOfTomorrow] count];
        }
    }
    else
        return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Mensa";
    static NSString *LoadingCellIdentifier = @"MensaLoading";
    
    HTWMensaSpeiseTableViewCell *cell;
    if (!isLoading) {
        cell = (HTWMensaSpeiseTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSString *currentMensaName;
        
        if (mensaDay == 0) {
            currentMensaName = _allMensasOfToday[indexPath.row][0][@"mensa"];
        }
        else {
            currentMensaName = _allMensasOfTomorrow[indexPath.row][0][@"mensa"];
        }
    
        [cell.textLabel setText:currentMensaName];
        [cell.detailTextLabel setText:[self checkWorkingHours:currentMensaName]];
    
        //Add mensa image
        UIImage *currentMensaImage = [UIImage imageNamed:[self getMensaImageNameForName:currentMensaName]];
        cell.imageView.image = [currentMensaImage thumbnailImage:128 transparentBorder:0 cornerRadius:0 interpolationQuality:kCGInterpolationDefault];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
        mensaSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        mensaSpinner.center = CGPointMake(160,32);
		[mensaSpinner startAnimating];
        [cell.contentView addSubview:mensaSpinner];
    }
    
    return cell;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([[segue identifier] isEqualToString:@"mensaMeals"]) {
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        MensaDetailViewController *mensaDetailController = [segue destinationViewController];
        if (mensaDay == 0) {
            mensaDetailController.availableMeals = [[self allMensasOfToday] objectAtIndex:selectedRowIndex.row];
        }
        else {
            mensaDetailController.availableMeals = [[self allMensasOfTomorrow] objectAtIndex:selectedRowIndex.row];
        }
    }
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

/*
#pragma mark - Navigation

// In a story board-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}

 */

@end
