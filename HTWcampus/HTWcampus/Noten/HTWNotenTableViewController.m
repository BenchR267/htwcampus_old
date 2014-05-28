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

#import "HTWNotenTableViewController.h"
#import "HTWNotenDetailTableViewController.h"
#import "HTWAppDelegate.h"
#import "HTWAlertNavigationController.h"


#import "UIColor+HTW.h"
#import "UIFont+HTW.h"


@interface HTWNotenTableViewController () <NSURLSessionDelegate, HTWAlertViewDelegate>

@end

@implementation HTWNotenTableViewController

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
    self.tableView.backgroundColor = [UIColor HTWSandColor];
    UIBarButtonItem *refresh = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Reload"]
                                                                style:UIBarButtonItemStylePlain
                                                               target:self
                                                               action:@selector(reloadNotenspiegel:)];

    self.navigationItem.rightBarButtonItem = refresh;

    if (self.notenspiegel == nil) {
        isLoading = true;
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
    
    HTWAlertNavigationController *loginModal = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
    loginModal.htwTitle = @"HISQIS Portal";
    loginModal.message = @"Bitte geben Sie Ihre Matrikelnummer und das zugehörige HISQIS-Passwort ein.";
    loginModal.mainTitle = @[@"Login", @"Passwort"];
    loginModal.numberOfSecureTextField = @[@1];
    loginModal.htwDelegate = self;
    loginModal.tag = LOGINMODAL_TAG;
    [self presentViewController:loginModal animated:YES completion:^{}];
}

- (void)loadNoten {
    [self.navigationItem.rightBarButtonItem setEnabled:NO];
    NSURL *hisqisUrl =[NSURL URLWithString:@"https://wwwqis.htw-dresden.de/qisserver/rds?state=user&type=0"];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:hisqisUrl];
    request.timeoutInterval = 10;
    NSOperationQueue *queue = [NSOperationQueue mainQueue];
    [NSURLRequest setAllowsAnyHTTPSCertificate:YES forHost:@"wwwqis.htw-dresden.de"];

    NSLog(@"Noten werden geladen...");
    isLoading = true;
    [self.tableView reloadData];
    
    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request queue:queue completionHandler: ^(NSURLResponse *response, NSData *data, NSError *error) {
        if ([data length]>0 && error == nil)
        {
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
                        HTWNotenStartseiteHTMLParser *startseiteParser = [HTWNotenStartseiteHTMLParser new];
                        NSString *asiToken = [startseiteParser parseAsiTokenFromString:loginHtmlResultAsString];
                        NSLog(@"Login erfolgreich. Asi Token: %@", asiToken);
                        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"NotenLoginNieSpeichern"] &&
                           ![username isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"LoginNoten"]] &&
                           ![password isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"PasswortNoten"]])
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
                        
                        //send notenspiegel request
                        NSURL *notenUrl =[NSURL URLWithString:[NSString stringWithFormat:@"https://wwwqis.htw-dresden.de/qisserver/rds?state=htmlbesch&stg=121&abschl=84&next=list.vm&asi=%@", asiToken]];
                        NSURLRequest *notenRequest = [NSURLRequest requestWithURL:notenUrl];
                        [NSURLConnection sendAsynchronousRequest:notenRequest queue:queue completionHandler:^(NSURLResponse *response, NSData *data, NSError *error) {
                            if ([data length]>0 && error == nil)
                            {
                                NSString *notenspiegelHtmlResultAsString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                                
#warning PDF DOWNLOAD
                                // [self savePDFFromHtml:notenspiegelHtmlResultAsString];
                                
                                
                                
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
                                // NSLog(@"%@", self.notenspiegel);
                                isLoading = false;
                                notendurchschnitt = [self calculateAverageGradeFromNotenspiegel:self.notenspiegel];
                                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                                [self.navigationItem.rightBarButtonItem setEnabled:YES];
                                [self.tableView reloadData];
                            }
                            else if ([data length] == 0 && error == nil)
                            {
                                NSLog(@"No data returned.");
                            }
                            else if (error != nil){
                                NSLog(@"Fehler beim Laden der Notenseite. Error: %@", error);
                                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                                [self.navigationItem.rightBarButtonItem setEnabled:YES];
                            }
                        }];
                    }
                    else {
                        //Login failed
                        UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Nochmal" otherButtonTitles:nil];
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
                    [self.navigationItem.rightBarButtonItem setEnabled:YES];
                }
            }];

            
        }
        else if ([data length] == 0 && error == nil)
        {
            NSLog(@"No data was returned.");
        }
        else if (error != nil){
            NSLog(@"Fehler beim Laden der Noten. Error: %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                                     message:@"Das iPhone hat scheinbar keine Verbindung zum Internet. Bitte stellen Sie sicher, dass das iPhone online ist und versuchen Sie es danach erneut."
                                                                    delegate:nil
                                                           cancelButtonTitle:@"Ok"
                                                           otherButtonTitles:nil];
                [errorAlert show];
            });
            [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
            [self.navigationItem.rightBarButtonItem setEnabled:YES];
        }
    }];
}

-(void)htwAlert:(HTWAlertNavigationController *)alert gotStringsFromTextFields:(NSArray *)strings
{
    if(alert.tag == LOGINMODAL_TAG) {
            NSString *usernameText = strings[0];
            NSString *passwordText = strings[1];
            
            if (usernameText && usernameText.length > 0 &&
                passwordText && passwordText.length > 0) {
//                NSLog(@"%@ %@", strings[0], strings[1]);
                username = usernameText;
                password = passwordText;
                
                [self loadNoten];
            }
            else {
                UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler" message:@"Alle Felder müssen ausgefüllt werden" delegate:self cancelButtonTitle:@"Ok" otherButtonTitles: nil];
                errorPopup.alertViewStyle = UIAlertViewStyleDefault;
                errorPopup.tag = LOGIN_VALIDATION_ERROR_TAG;
                errorPopup.delegate = self;
                [errorPopup show];
            }
    }
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    
    if (alertView.tag == LOGIN_ERROR_TAG) {
        //Try again
        [self showLoginPopup];
    }
 
    else if (alertView.tag == LOGIN_VALIDATION_ERROR_TAG) {
        if(buttonIndex == 0)
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
            if(!([(NSString*)[fach objectForKey:@"note"] isEqualToString:@""] || [(NSString*)[fach objectForKey:@"credits"] isEqualToString:@""]))
            {
                NSMutableString *note = [NSMutableString stringWithString:[fach objectForKey:@"note"]];
                [note replaceOccurrencesOfString:@"," withString:@"." options:NSCaseInsensitiveSearch range:NSMakeRange(0, note.length)];
                
                tempSumme += [note floatValue] * [[fach objectForKey:@"credits"] floatValue];
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
        mensaSpinner.center = CGPointMake((int)cell.frame.size.width/2,
                                          (int)cell.frame.size.height/2);
        [mensaSpinner startAnimating];
        [cell.contentView addSubview:mensaSpinner];
    }
    
    if ([self.notenspiegel count] > 0) {
        if (indexPath.section == 0) {
            cell.textLabel.text = @"Notendurchschnitt";
            cell.detailTextLabel.text = [NSString stringWithFormat:@"%.2f", notendurchschnitt];
            cell.textLabel.font = cell.detailTextLabel.font = [UIFont HTWLargeFont];
            cell.textLabel.textColor = [UIColor HTWTextColor];
            cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
        }
        else {
            cell.textLabel.text = [[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] objectForKey:@"name"];
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

#pragma mark - Hilfsfunktionen

#warning PDF DOWNLOAD UNVOLLSTÄNDIG
-(void)savePDFFromHtml:(NSString*)html
{
    
    NSMutableString *htmlFormed = [NSMutableString stringWithString:html];
    [htmlFormed replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, htmlFormed.length)];
    [htmlFormed replaceOccurrencesOfString:@"\t" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, htmlFormed.length)];
    [htmlFormed replaceOccurrencesOfString:@"  " withString:@" " options:NSCaseInsensitiveSearch range:NSMakeRange(0, htmlFormed.length)];
    NSRange startR = [htmlFormed rangeOfString:@"<a class=\"Konto\" href=\""];
    NSString *urlString = [htmlFormed substringFromIndex:startR.location + @"<a class=\"Konto\" href=\"".length];
    NSRange endR = [urlString rangeOfString:@"\">"];
    urlString = [urlString substringToIndex:endR.location];
    NSMutableString *urlStringFormed = [NSMutableString stringWithString:urlString];
    [urlStringFormed replaceOccurrencesOfString:@"amp;" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, urlStringFormed.length)];
    [urlStringFormed replaceOccurrencesOfString:@"StudentNotenspiegel" withString:@"ProgrammStudentNotenspiegel" options:NSCaseInsensitiveSearch range:NSMakeRange(0, urlStringFormed.length)];
    
    
//    NSLog(@"%@", urlStringFormed);
    
    NSURL *url = [NSURL URLWithString:urlStringFormed];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"GET";
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:[NSOperationQueue mainQueue]];
    NSURLSessionDownloadTask *task = [session downloadTaskWithRequest:request completionHandler:^(NSURL *location, NSURLResponse *response, NSError *error) {
//        NSLog(@"RESPONSE: %@", response);
        if(error)
        {
            NSLog(@"%@", error.localizedDescription);
            return;
        }
//        NSLog(@"%@", location);
        UIActivityViewController *avc = [[UIActivityViewController alloc] initWithActivityItems:@[location, @"Meine Noten als PDF"] applicationActivities:nil];
        [self presentViewController:avc animated:YES completion:^{
            NSLog(@"PDF geteilt.");
        }];
    }];
    [task resume];
}

- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential *credential))completionHandler
{
    completionHandler(NSURLSessionAuthChallengeUseCredential, [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust]);
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([[segue identifier] isEqualToString:@"showFachDetails"]) {
        NSIndexPath *selectedRowIndex = [self.tableView indexPathForSelectedRow];
        HTWNotenDetailTableViewController *notenDetailController = [segue destinationViewController];
            notenDetailController.fach = [[self.notenspiegel objectAtIndex:selectedRowIndex.section-1] objectAtIndex:selectedRowIndex.row];
    }
}


@end
