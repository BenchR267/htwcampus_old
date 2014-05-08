//
//  notenViewController.m
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#define LOGINMODAL_TAG 1
#define LOGIN_ERROR_TAG 2
#define LOGIN_VALIDATION_ERROR_TAG 3
#define ALERT_SAVE_LOGIN 4

#define HISQIS_LOGGEDIN_STARTPAGE @"https://wwwqis.htw-dresden.de/qisserver/rds?state=user&type=0&category=menu.browse&breadCrumbSource=&startpage=portal.vm"

#import "notenViewController.h"
#import "notenDetailViewController.h"
#import "HTWAppDelegate.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "NSArray+HTWSemester.h"

@implementation notenViewController

- (id)initWithStyle:(UITableViewStyle)style
{
    self = [super initWithStyle:style];
    if (self) {
        // Custom initialization
        isLoading = false;
        notendurchschnitt = 0.0;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if (self.notenspiegel == nil) {
        isLoading = true;
        //[self loadNoten];
    }

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    self.tableView.backgroundColor = [UIColor HTWSandColor];
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Reload"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(reloadNotenspiegel:)];
    
    self.navigationItem.rightBarButtonItem = refresh;
    
    if (self.notenspiegel == nil) {
        NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
        username = [defaults objectForKey:@"LoginNoten"];
        password = [defaults objectForKey:@"PasswortNoten"];
        if (username && password) [self loadNoten];
        else //Ask for user login data
            [self showLoginPopup];
    }
}

- (IBAction)reloadNotenspiegel:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    username = [defaults objectForKey:@"LoginNoten"];
    password = [defaults objectForKey:@"PasswortNoten"];
    notendurchschnitt = 0.0;
    self.notenspiegel = nil;
    [self.tableView reloadData];
    if(!username || !password) [self showLoginPopup];
    else [self loadNoten];
}

- (void) showLoginPopup {
    UIAlertView *loginModal = [[UIAlertView alloc] initWithTitle:@"HISQIS Portal" message:nil delegate:self cancelButtonTitle:@"Abbrechen" otherButtonTitles:@"Anmelden", nil];
    loginModal.alertViewStyle = UIAlertViewStyleLoginAndPasswordInput;
    loginModal.tag = LOGINMODAL_TAG;
    [loginModal dismissWithClickedButtonIndex:0 animated:YES];
    [loginModal show];
}

- (void)loadNoten {
    
    NSURL *hisqisUrl =[NSURL URLWithString:@"https://wwwqis.htw-dresden.de/qisserver/rds?state=user&type=0"];
    NSURLRequest *request = [NSURLRequest requestWithURL:hisqisUrl];
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"wwwqis.htw-dresden.de"];

    NSLog(@"Noten werden geladen...");
    isLoading = true;
    [self.tableView reloadData];
    
    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length]>0 && error == nil)
        {
            NSDictionary* headers = [(NSHTTPURLResponse *)response allHeaderFields];
            NSString *cookies = [headers objectForKey:@"Set-Cookie"];
            NSArray *cookieArray = [cookies componentsSeparatedByString:@";"];
            NSString *jsessionid = [cookieArray objectAtIndex:0];
            NSLog(@"%@", jsessionid);
            
            //send login post request
            NSMutableURLRequest *loginRequest = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://wwwqis.htw-dresden.de/qisserver/rds?state=user&type=1&category=auth.login&startpage=portal.vm"]];
            [loginRequest setValue:@"gzip" forHTTPHeaderField:@"Accept-Encoding"];
            [loginRequest setHTTPBody:[[NSString stringWithFormat:@"username=%@&submit=Ok&password=%@", username, password] dataUsingEncoding:NSUTF8StringEncoding]];
            [loginRequest setHTTPMethod:@"POST"];
            
            [NSURLConnection sendAsynchronousRequest:loginRequest queue:queue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
                if ([data length]>0 && error == nil)
                {
                    NSString *loginHtmlResultAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    
                    //Check if login was successful
                    if ([[response.URL absoluteString] isEqualToString:HISQIS_LOGGEDIN_STARTPAGE]) {
                        //parse asi token
                        notenStartseiteHTMLParser *startseiteParser = [notenStartseiteHTMLParser new];
                        NSString *asiToken = [startseiteParser parseAsiTokenFromString:loginHtmlResultAsString];
                        NSLog(@"Login erfolgreich. Asi Token: %@", asiToken);
                        
                        //send notenspiegel request
                        NSURL *notenUrl =[NSURL URLWithString:[NSString stringWithFormat:@"https://wwwqis.htw-dresden.de/qisserver/rds?state=htmlbesch&stg=121&abschl=84&next=list.vm&asi=%@", asiToken]];
                        NSURLRequest *notenRequest = [NSURLRequest requestWithURL:notenUrl];
                        [NSURLConnection sendAsynchronousRequest:notenRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                            if ([data length]>0 && error == nil)
                            {
                                NSString *notenspiegelHtmlResultAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                self.notenspiegel = [[NSArray alloc] init];
                                NSMutableArray *sortedNotenspiegel = [NSMutableArray arrayWithArray:[startseiteParser parseNotenspiegelFromString:notenspiegelHtmlResultAsString]];
                                self.notenspiegel = [sortedNotenspiegel sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                                    NSString *semester = [[obj2 objectAtIndex:0] objectForKey:@"semester"];
                                    NSString *jahr;
                                    if([semester componentsSeparatedByString:@" "].count > 1)
                                        jahr = [semester componentsSeparatedByString:@" "][1];
                                    else jahr = @" ";
                                    NSComparisonResult result;
                                    if([(NSString*)[obj1[0] objectForKey:@"semester"] componentsSeparatedByString:@" "].count > 1)
                                        result = [(NSString*)[(NSString*)[obj1[0] objectForKey:@"semester"] componentsSeparatedByString:@" "][1] compare:jahr options:NSNumericSearch];
                                    else result = NSOrderedSame;
                                    switch(result)
                                    {
                                        case NSOrderedAscending: return NSOrderedDescending;
                                        case NSOrderedDescending: return NSOrderedAscending;
                                        default: return NSOrderedSame;
                                    }
                                }];
                                isLoading = false;
                                notendurchschnitt = [self calculateAverageGradeFromNotenspiegel:self.notenspiegel];
                                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                                [self.tableView reloadData];
                            }
                            else if ([data length] == 0 && error == nil)
                            {
                                NSLog(@"No data returned.");
                            }
                            else if (error != nil){
                                NSLog(@"Fehler beim Laden der Notenseite. Error: %@", error);
                                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                            }
                        }];
                    }
                    else {
                        //Login failed
                        UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:@"Nochmal", nil];
                        errorPopup.alertViewStyle = UIAlertViewStyleDefault;
                        errorPopup.tag = LOGIN_ERROR_TAG;
                        [errorPopup show];
                    }
                }
                else if ([data length] == 0 && error == nil)
                {
                    NSLog(@"No data returned.");
                }
                else if (error != nil){
                    NSLog(@"HISQIS Login Request Page nicht erreichbar. Error: %@", error);
                    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                }
            }];

            
        }
        else if ([data length] == 0 && error == nil)
        {
            NSLog(@"No data was returned.");
        }
        else if (error != nil){
            NSLog(@"Fehler beim Laden der Noten. Error: %@", error);
            [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        }
    }];
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if(alertView.tag == LOGINMODAL_TAG) {
        if (buttonIndex == 1) {
            UITextField *usernameTextfield = [alertView textFieldAtIndex:0];
            UITextField *passwordTextfield = [alertView textFieldAtIndex:1];
            
            if (usernameTextfield && usernameTextfield.text.length > 0 &&
                passwordTextfield && passwordTextfield.text.length > 0) {
                NSLog(@"%@ %@", [[alertView textFieldAtIndex:0] text], [[alertView textFieldAtIndex:0] text]);
                username = [[alertView textFieldAtIndex:0] text];
                password = [[alertView textFieldAtIndex:1] text];
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                if(![defaults boolForKey:@"NotenLoginNieSpeichern"])
                {
                    UIAlertView *saveAlert = [[UIAlertView alloc] init];
                    saveAlert.message = @"Soll der Login gespeichert werden?";
                    [saveAlert addButtonWithTitle:@"Ja"];
                    [saveAlert addButtonWithTitle:@"Nein"];
                    [saveAlert addButtonWithTitle:@"Nein, nicht mehr fragen"];
                    saveAlert.tag = ALERT_SAVE_LOGIN;
                    saveAlert.delegate = self;
                    [saveAlert show];
                }
                [self loadNoten];
            }
            else {
                [alertView dismissWithClickedButtonIndex:-1 animated:YES];
                UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler" message:@"Alle Felder müssen ausgefüllt werden" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                errorPopup.alertViewStyle = UIAlertViewStyleDefault;
                errorPopup.tag = LOGIN_VALIDATION_ERROR_TAG;
                [errorPopup show];
            }
        }
    }
    
    else if (alertView.tag == LOGIN_ERROR_TAG) {
        //Try again
        [self showLoginPopup];
    }
    
    else if (alertView.tag == LOGIN_VALIDATION_ERROR_TAG) {
        [self showLoginPopup];
    }
    
    else if (alertView.tag == ALERT_SAVE_LOGIN)
    {
        NSString *buttonTitle = [alertView buttonTitleAtIndex:buttonIndex];
        if ([buttonTitle isEqualToString:@"Ja"]) {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:username forKey:@"LoginNoten"];
            [defaults setObject:password forKey:@"PasswortNoten"];
        }
        else if ([buttonTitle isEqualToString:@"Nein, nicht mehr fragen"])
        {
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setBool:YES forKey:@"NotenLoginNieSpeichern"];
        }
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (float)calculateAverageGradeFromNotenspiegel: (NSArray *)notenspiegel {
    float tempSumme = 0.0;
    float creditsSum = 0.0;
    
    for (NSArray *semester in notenspiegel) {
        for (NSDictionary *fach in semester) {
            if (!([[fach objectForKey:@"note"] isEqualToString:@""] || [[fach objectForKey:@"credits"] isEqualToString:@""])) {
                tempSumme += [[fach objectForKey:@"note"] floatValue] * [[fach objectForKey:@"credits"] floatValue];
                creditsSum += [[fach objectForKey:@"credits"] floatValue];
            }
        }
    }
    return creditsSum == 0 ? 0.0 : tempSumme/creditsSum;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    // Return the number of sections.
    if ([self.notenspiegel count] > 0) {
        //Notencount + average grade
        return [self.notenspiegel count] + 1;
    }
    if (!self.notenspiegel || [self.notenspiegel count] == 0) {
        return 1;
    }
    return 0;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    // Return the number of rows in the section.
    if ([self.notenspiegel count] > 0) {
        if (section == 0) {
            return 1;
        }
        else {
            return [[self.notenspiegel objectAtIndex:section-1] count];
        }
    }
    if (!self.notenspiegel || [self.notenspiegel count] == 0) {
        return 1;
    }
    return 0;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
    if ([self.notenspiegel count] > 0 && section>0) {
        return [[[self.notenspiegel objectAtIndex:section-1] objectAtIndex:0] objectForKey:@"semester"];
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (indexPath.section == 0 && [self.notenspiegel count]>0) {
        return 88;
    }
    return 50;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"pruefungsfachZelle";
    NSString *reuseIdentifierLoading = @"spinnerZelle";
    NSString *reuseIdentifierAverageGrade = @"notendurchschnittZelle";
    
    UITableViewCell *cell;
    if (!isLoading) {
        if (indexPath.section > 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
        }
        else {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifierAverageGrade forIndexPath:indexPath];
        }
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifierLoading forIndexPath:indexPath];
        UIActivityIndicatorView *mensaSpinner;
        mensaSpinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        mensaSpinner.center = CGPointMake(160,22);
        [mensaSpinner startAnimating];
        [cell.contentView addSubview:mensaSpinner];
    }
    
    if ([self.notenspiegel count] > 0) {
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Notendurchschnitt";
            cell.textLabel.font = [UIFont HTWBigBaseFont];
            cell.textLabel.textColor = [UIColor HTWTextColor];
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", notendurchschnitt];
            cell.detailTextLabel.font = [UIFont HTWBigBaseFont];
            cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
        }
        else {
            cell.textLabel.text = [[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] objectForKey:@"name"];
            cell.textLabel.font = [UIFont HTWTableViewCellFont];
            cell.textLabel.textColor = [UIColor HTWTextColor];
            cell.detailTextLabel.font = [UIFont HTWMediumFont];
            cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
            cell.detailTextLabel.text = [[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] objectForKey:@"note"];
            
        }
    }
    
    if (!self.notenspiegel) {
        
    }
    
    if (self.notenspiegel && [self.notenspiegel count] == 0) {
        cell.textLabel.text = @"Keine Noten verfügbar :(";
        [cell.textLabel center];
    }
    
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
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
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

#pragma mark - Hilfsfunktionen



#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showFachDetails"]) {
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        notenDetailViewController *notenDetailController = [segue destinationViewController];
            notenDetailController.fach = [[self.notenspiegel objectAtIndex:selectedRowIndex.section-1] objectAtIndex:selectedRowIndex.row];
    }
}


@end
