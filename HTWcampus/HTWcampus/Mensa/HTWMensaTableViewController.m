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

#import "HTWMensaTableViewController.h"
#import "HTWMensaSingleTableViewController.h"
#import "HTWAppDelegate.h"
#import "UIImage+Resize.h"
#import "UIFont+HTW.h"
#import "UIColor+HTW.h"
#import "HTWMensaSpeiseTableViewCell.h"
#import "HTWMensaXMLParser.h"

@interface HTWMensaTableViewController () {
    UIActivityIndicatorView *mensaSpinner;
}
@property (strong, nonatomic) NSMutableArray *allMensasOfToday;
@property (strong, nonatomic) NSMutableArray *allMensasOfTomorrow;
@property (strong, nonatomic) NSArray *mensaMeta;
@end

@implementation HTWMensaTableViewController

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
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 10;
    NSURLSession *sessionForTodaysMensa = [NSURLSession sessionWithConfiguration:config];
    [[sessionForTodaysMensa dataTaskWithURL:RSSUrlToday completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error)
        {
            [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                                 message:@"Es scheint keine Verbindung zum Internet zu bestehen. Bitte stellen Sie sicher, dass das iPhone online ist und versuchen sie es danach erneut."
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles:nil];
            dispatch_async(dispatch_get_main_queue(), ^
                           {
                               [errorAlert show];
                           });
            isLoading = false;
            return;
        }
        HTWMensaXMLParser *parser = [[HTWMensaXMLParser alloc] init];
        _allMensasOfToday = [[NSMutableArray alloc] initWithArray: [self groupMealsAccordingToMensa:[parser getAllMealsFromHTML:data]]];
        dispatch_async(dispatch_get_main_queue(), ^
       {
           isLoading = false;
           [self.tableView reloadData];
       });
        
    }] resume];
    
    [UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
    NSURLSession *sessionForTomorrowsMensa = [NSURLSession sessionWithConfiguration:config];
    [[sessionForTomorrowsMensa dataTaskWithURL:RSSUrlTomorrow completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if(error)
        {
            return;
        }
        HTWMensaXMLParser *parser = [HTWMensaXMLParser new];
        _allMensasOfTomorrow = [[NSMutableArray alloc] initWithArray:[self groupMealsAccordingToMensa:[parser getAllMealsFromHTML:data]]];
        dispatch_async(dispatch_get_main_queue(), ^
           {
               isLoading = false;
               [UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
               [self.tableView reloadData];
           });
    }] resume];
    
    
}

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

- (NSString *)checkWorkingHours:(NSString*)currentMensa4sq {
    if([currentMensa4sq isEqualToString:@""] || [currentMensa4sq isEqualToString:@"na"])
        return @"Keine Öffnungszeiten verfügbar";

    NSURL *requestURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://api.foursquare.com/v2/venues/%@?client_id=41JI0EUVFDHKEUXTB1DHBXP5W2GAUNHUQNMZP5XXAQWZE1BN&client_secret=QG1XL1SLIH2IFH5AT1ZFPBVNSZRAMKUG5BEWYJBALTXYRBUO&v=20140526", currentMensa4sq]];
    NSData *data = [NSData dataWithContentsOfURL:requestURL];
    if(!data) return @"Data leer";
    NSDictionary *erg = [NSJSONSerialization JSONObjectWithData:data
                                                   options:NSJSONReadingMutableContainers
                                                     error:nil];

    if(mensaDay == 1)
    {
        NSString* ret = erg[@"response"][@"venue"][@"popular"][@"timeframes"][1][@"open"][0][@"renderedTime"];
        if(!ret) return @"Keine Öffnungszeiten verfügbar";
        return ret;
    }

    if(!erg[@"response"][@"venue"][@"popular"])
        return @"Keine Öffnungszeiten verfügbar";
    if (erg[@"response"][@"venue"][@"popular"][@"isOpen"]) {
        return @"Momentan geöffnet";
    }
    return @"Nicht geöffnet";
}

-(NSString*)get4sqForMensaName:(NSString*)name
{
    if(!name) return @"";
    for (NSDictionary *mensa in _mensaMeta) {
        if([mensa[@"name"] isEqualToString:name])
            return mensa[@"4sq"];
    }
    return @"";
}

-(void)reloadView {
    isLoading = NO;
    [mensaSpinner stopAnimating];
//    NSLog(@"reloadView called");
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

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(!isLoading && mensaDay == 0 && self.allMensasOfToday.count == 0) return 120;
    else if(!isLoading && mensaDay == 1 && self.allMensasOfTomorrow.count == 0) return 120;
    return 64.0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
//    NSLog(@"%lu Mensen gefunden.", (unsigned long)[[self allMensasOfToday] count]);
//    return [[self allMensas] count];
    return 1;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (!isLoading) {
        if (mensaDay == 0) {
//            NSLog(@"Zeige HEUTIGEN Speiseplan");
            if(self.allMensasOfToday.count == 0) return 1;
            return [[self allMensasOfToday] count];
        }
        else {
//            NSLog(@"Zeige MORGIGEN Speiseplan");
            if(self.allMensasOfTomorrow.count == 0) return 1;
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
    
    if(!isLoading && mensaDay == 0 && self.allMensasOfToday.count == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        cell.textLabel.text = @"Leider haben heute keine Mensen offen..";
    }
    else if(!isLoading && mensaDay == 1 && self.allMensasOfTomorrow.count == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:LoadingCellIdentifier forIndexPath:indexPath];
        cell.textLabel.numberOfLines = 3;
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        cell.textLabel.text = @"Leider haben morgen keine Mensen offen..";
    }
    
    else if (!isLoading && ((mensaDay == 0 && self.allMensasOfToday.count) || (mensaDay == 1 && self.allMensasOfTomorrow.count))) {
        cell = (HTWMensaSpeiseTableViewCell*)[tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSString *currentMensaName;
        
        if (mensaDay == 0)
            currentMensaName = _allMensasOfToday[indexPath.row][0][@"mensa"];
        else
            currentMensaName = _allMensasOfTomorrow[indexPath.row][0][@"mensa"];
        
    
        [cell.textLabel setText:currentMensaName];
        [cell.detailTextLabel setText:[self checkWorkingHours:[self get4sqForMensaName:currentMensaName]]];

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
        HTWMensaSingleTableViewController *mensaDetailController = [segue destinationViewController];
        if (mensaDay == 0) {
            mensaDetailController.availableMeals = [[self allMensasOfToday] objectAtIndex:selectedRowIndex.row];
        }
        else {
            mensaDetailController.availableMeals = [[self allMensasOfTomorrow] objectAtIndex:selectedRowIndex.row];
        }
    }
}

@end
