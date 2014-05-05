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

#define HISQIS_LOGGEDIN_STARTPAGE @"https://wwwqis.htw-dresden.de/qisserver/rds?state=user&type=0&category=menu.browse&breadCrumbSource=&startpage=portal.vm"

#import "notenViewController.h"
#import "notenDetailViewController.h"
#import "HTWColors.h"

@interface notenViewController ()
{
    HTWColors *htwColors;
}
@end

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
    htwColors = [[HTWColors alloc] init];
}

- (void)viewDidAppear:(BOOL)animated {
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBarHidden = NO;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    
    [self.tableView reloadData];
    
    if (self.notenspiegel == nil) {
        //Ask for user login data
        [self showLoginPopup];
    }
}

- (IBAction)reloadNotenspiegel:(id)sender {
    username = password = nil;
    notendurchschnitt = 0.0;
    self.notenspiegel = nil;
    [self.tableView reloadData];
    [self showLoginPopup];
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
                                self.notenspiegel = [startseiteParser parseNotenspiegelFromString:notenspiegelHtmlResultAsString];
                                isLoading = false;
                                notendurchschnitt = [self calculateAverageGradeFromNotenspiegel:self.notenspiegel];
                                [self.tableView reloadData];
                            }
                            else if ([data length] == 0 && error == nil)
                            {
                                NSLog(@"No data returned.");
                            }
                            else if (error != nil){
                                NSLog(@"Fehler beim Laden der Notenseite. Error: %@", error);
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
                }
            }];

            
        }
        else if ([data length] == 0 && error == nil)
        {
            NSLog(@"No data was returned.");
        }
        else if (error != nil){
            NSLog(@"Fehler beim Laden der Noten. Error: %@", error);
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
    
    if (alertView.tag == LOGIN_ERROR_TAG) {
        //Try again
        [self showLoginPopup];
    }
    
    if (alertView.tag == LOGIN_VALIDATION_ERROR_TAG) {
        [self showLoginPopup];
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
    return 44;
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
            cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%.2f", notendurchschnitt];
            cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica" size:35];
        }
        else {
            cell.textLabel.text = [[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] objectForKey:@"name"];
            cell.detailTextLabel.text = [[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] objectForKey:@"note"];
            cell.detailTextLabel.textColor = [[UIColor alloc] initWithRed:255/255.0 green:137/255.0 blue:44/255.0 alpha:1.0];
        }
        cell.textLabel.textColor = htwColors.darkCellText;
        cell.detailTextLabel.textColor = htwColors.darkCellText;
        
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