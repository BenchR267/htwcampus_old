//
//  mensaViewController.m
//  HTWcampus
//
//  Created by Konstantin on 09.10.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#define MENSAERROR_1 1
#define MENSAERROR_2 2


#import "mensaViewController.h"
#import "MensaXMLParserDelegate.h"
#import "MensaDetailViewController.h"
#import "UIImage+Resize.h"
#import "HTWColors.h"

@interface mensaViewController ()
{
    HTWColors *htwColors;
}
@property (nonatomic, strong) NSXMLParser *xmlParser;
@property (nonatomic, strong) MensaXMLParserDelegate *mensaXMLParserDelegate;
@end

@implementation mensaViewController {
    UIActivityIndicatorView *mensaSpinner;
}

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
    
    htwColors = [[HTWColors alloc] init];
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    //self.navigationItem.leftBarButtonItem = self.editButtonItem;
    mensaMeta = [[NSDictionary alloc] initWithObjectsAndKeys:
                 @"neuemensa.jpg", @"Neue Mensa",
                 @"altemensa.jpg", @"Alte Mensa",
                 @"reichenbachstrasse.jpg", @"Mensa Reichenbachstraße",
                 @"mensologie.jpg", @"Mensologie",
                 @"mensa-siedepunkt.jpg", @"Mensa Siedepunkt",
                 @"johannstadt.jpg", @"Mensa Johannstadt",
                 @"mensa-wueins.jpg", @"Mensa WUeins",
                 @"mensa-bruehl.jpg", @"Mensa Brühl",
                 @"biomensa-uboot.jpg", @"BioMensa U-Boot",
                 @"tellerrandt.jpg", @"Mensa TellerRandt",
                 @"zittau.jpg", @"Mensa Zittau",
                 @"stimmgabel.jpg", @"Mensa Stimm-Gabel",
                 @"palucca.jpg", @"Mensa Palucca Hochschule",
                 @"goerlitz.jpg", @"Mensa Görlitz",
                 @"zittauhausvii.jpg", @"Mensa Haus VII",
                 @"mensasport.jpg", @"Mensa Sport",
                 @"mensa-kreuzgymnasium.jpg", @"Mensa Kreuzgymnasium", nil];
    
    self.feedList = [[NSMutableArray alloc] initWithObjects:
                     @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=heute",
                     @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen", nil];
    isLoading = YES;
    
    [self.mensaDaySwitcher addTarget:self
                            action:@selector(setMensaDay)
                  forControlEvents:UIControlEventValueChanged];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(addMensaData)
                                                 name:@"mensaParsingFinished"
                                               object:nil];
    
//    [[NSNotificationCenter defaultCenter] addObserver:self
//                                             selector:@selector(addTomorrowMensaData)
//                                                 name:@"mensaTomorrowParsingFinished"
//                                               object:nil];
//    
}



- (void)viewDidAppear:(BOOL)animated
{
    
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    _mensaDaySwitcher.tintColor = htwColors.darkTextColor;
    
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

- (IBAction)loadMensa {
    NSURL *RSSUrlToday =[NSURL URLWithString:@"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=heute"];
    NSURL *RSSUrlTomorrow = [NSURL URLWithString:@"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen"];
    NSURLRequest *requestToday = [NSURLRequest requestWithURL:RSSUrlToday];
    NSURLRequest *requestTomorrow = [NSURLRequest requestWithURL:RSSUrlTomorrow];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    
    [NSURLConnection sendAsynchronousRequest:requestToday queue:queue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length]>0 && error == nil)
        {
            //today
            self.mensaXMLParserDelegate = [[MensaXMLParserDelegate alloc] init];
            self.xmlParser = [[NSXMLParser alloc] initWithData:data];
            self.xmlParser.delegate = self.mensaXMLParserDelegate;
            if ([self.xmlParser parse]) {
                [self.feedList removeObjectIdenticalTo:@"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=heute"];
                NSLog(@"Noch übrig: %@", self.feedList);
            }
            
            //tomorrow
            [NSURLConnection sendAsynchronousRequest:requestTomorrow queue:queue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                if ([data length]>0 && error == nil)
                {
                    if (!self.mensaXMLParserDelegate) {
                        self.mensaXMLParserDelegate = [[MensaXMLParserDelegate alloc] init];
                    }
                    self.xmlParser = [[NSXMLParser alloc] initWithData:data];
                    self.xmlParser.delegate = self.mensaXMLParserDelegate;
                    if ([self.xmlParser parse]) {
                        [self.feedList removeObjectIdenticalTo:@"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen"];
                    }
                }
                else if ([data length] == 0 && error == nil)
                {
                    NSLog(@"No Meals found for tomorrow.");
                }
                else if (error != nil){
                    NSLog(@"Fehler beim Parsen der Mensen. Error: %@", error);
                    UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Fehler" message:@"Fehler beim Parsen der Mensa :( Versuch es später nochmal." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
                    alert.tag = MENSAERROR_2;
                    alert.alertViewStyle = UIAlertViewStyleDefault;
                    [alert show];
                }
            }];
            
            //check if both days have been parsed
            if (!self.feedList.count) {
                NSLog(@"Es konnten nicht alle Tage geparst werden: %@", self.feedList);
            }
        }
        else if ([data length] == 0 && error == nil)
        {
            NSLog(@"No Meals found for today.");
        }
        else if (error != nil){
            NSLog(@"Fehler beim Parsen der Mensen. Error: %@", error);
            UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Fehler" message:@"Fehler beim Parsen der Mensa :( Versuche es später nochmal." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
            alert.tag = MENSAERROR_1;
            alert.alertViewStyle = UIAlertViewStyleDefault;
            [alert show];
        }
    }];
}

/*
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex{
    NSLog(@"Entered: %@",[[alertView textFieldAtIndex:0] text]);
}
 */

- (void)addMensaData {
    //Restructure Array according to Mensa
    BOOL todayMensaDone = [[self.feedList objectAtIndex:0] isEqualToString:@"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen"] ? YES : NO;
    if (!self.allMensasOfToday) self.allMensasOfToday = [[NSMutableArray alloc] init];
    if (!self.allMensasOfTomorrow) self.allMensasOfTomorrow = [[NSMutableArray alloc] init];
    id allMealsOfOneMensa = [[NSMutableArray alloc] init];
    int mealCount = 0;
    
    for (NSObject *meal in self.mensaXMLParserDelegate.allMeals) {
        NSDictionary *tmpDict = [self.mensaXMLParserDelegate.allMeals objectAtIndex:mealCount];
		
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
				if (!todayMensaDone) {
                    [self.allMensasOfToday addObject:allMealsOfOneMensa];
                }
                else {
                    [self.allMensasOfTomorrow addObject:allMealsOfOneMensa];
                }
				
				allMealsOfOneMensa = [NSMutableArray new];
				
				[allMealsOfOneMensa addObject:tmpDict];
			}
			
			if((mealCount+1) == [self.mensaXMLParserDelegate.allMeals count])
			{
				if (!todayMensaDone) {
                    [self.allMensasOfToday addObject:allMealsOfOneMensa];
                }
                else {
                    [self.allMensasOfTomorrow addObject:allMealsOfOneMensa];
                }
			}
		}
        mealCount++;
    }
    
    [self reloadView];
}

- (NSString *)getMensaImageNameForName:(NSString *)mensaName {
    for(id mensa in mensaMeta) {
        if ([mensaName isEqualToString:mensa]) {
            return [mensaMeta objectForKey:mensa];
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
    [self.allMensasOfToday removeAllObjects];
    [self.allMensasOfTomorrow removeAllObjects];
    self.feedList = [[NSMutableArray alloc] initWithObjects:
                     @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=heute",
                     @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen", nil];

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
    
    UITableViewCell *cell;
    if (!isLoading) {
        cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
        NSString *currentMensaName;
        
        if (mensaDay == 0) {
            currentMensaName = [[[[self allMensasOfToday] objectAtIndex:indexPath.row] objectAtIndex:0] valueForKey:@"mensa"];
        }
        else {
            currentMensaName = [[[[self allMensasOfTomorrow] objectAtIndex:indexPath.row] objectAtIndex:0] valueForKey:@"mensa"];
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
    
    cell.textLabel.textColor = htwColors.darkCellText;
    cell.detailTextLabel.textColor = htwColors.darkCellText;
    
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
