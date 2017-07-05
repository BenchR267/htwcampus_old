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
#import "Note.h"


#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "NSURLRequest+IgnoreSSL.h"


@interface HTWNotenTableViewController () <NSURLSessionDelegate, HTWAlertViewDelegate>

@property (nonatomic, strong) NSManagedObjectContext *context;

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
    
    _context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    NSFetchRequest *request = [NSFetchRequest new];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_context];
    [request setEntity:entity];
    [request setSortDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES]]];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    self.notenspiegel = [_context executeFetchRequest:request error:nil].mutableCopy;
    if (self.notenspiegel.count != 0) {
        username = [defaults objectForKey:@"LoginNoten2"];
        password = [defaults objectForKey:@"PasswortNoten2"];
        if (username == nil || password == nil) {
            [self showLoginPopup];
        }
        
        HTWNotenStartseiteHTMLParser *startseiteParser = [HTWNotenStartseiteHTMLParser new];
        self.notenspiegel = [startseiteParser groupSemester:self.notenspiegel].mutableCopy;
        notendurchschnitt = [self calculateAverageGradeFromNotenspiegel:self.notenspiegel];
        self.notenspiegel = [self.notenspiegel sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            NSString *semester = [(Note*)[obj2 objectAtIndex:0] semester];
            NSString *jahr;
            if([semester componentsSeparatedByString:@" "].count > 1)
                jahr = [semester componentsSeparatedByString:@" "][1];
            else jahr = @" ";
            NSComparisonResult result;
            if([[(Note*)obj1[0] semester] componentsSeparatedByString:@" "].count > 1)
                result = [(NSString*)[[(Note*)obj1[0] semester] componentsSeparatedByString:@" "][1] compare:jahr options:NSNumericSearch];
            else result = NSOrderedSame;
            switch(result)
            {
                case NSOrderedAscending: return NSOrderedDescending;
                case NSOrderedDescending: return NSOrderedAscending;
                default: return NSOrderedSame;
            }
        }].mutableCopy;
        [self.tableView reloadData];
    }
    else {
        isLoading = true;
        username = [defaults objectForKey:@"LoginNoten2"];
        password = [defaults objectForKey:@"PasswortNoten2"];
        if (username && password) [self loadNoten];
        else //Ask for user login data
            [self showLoginPopup];
    }
}

- (IBAction)reloadNotenspiegel:(id)sender {
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    username = [defaults objectForKey:@"LoginNoten2"];
    password = [defaults objectForKey:@"PasswortNoten2"];
    notendurchschnitt = 0.0;
    self.notenspiegel = nil;
    [self.tableView reloadData];
    if(!username || !password) [self showLoginPopup];
    else [self loadNoten];
}

- (IBAction)settingsButtonPressed:(id)sender {
    [self showLoginPopup];
}

- (void) showLoginPopup {
    
    HTWAlertNavigationController *loginModal = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
    loginModal.htwTitle = @"Noten abrufen";
    loginModal.message = @"Bitte geben Sie Ihre Daten ein.";
    loginModal.mainTitle = @[@"S-Nummer", @"Passwort"];
    loginModal.numberOfSecureTextField = @[@1];
    loginModal.htwDelegate = self;
    loginModal.tag = LOGINMODAL_TAG;
    [self presentViewController:loginModal animated:YES completion:^{}];
}

- (void)loadNoten {
    
    
#define getPos @"https://wwwqis.htw-dresden.de/appservice/getcourses"
#define getGrade @"https://wwwqis.htw-dresden.de/appservice/getgrades"
//#define getPos @"https://wwwqis.htw-dresden.de/qisserver/api/student/getcourses"
//#define getGrade @"https://wwwqis.htw-dresden.de/qisserver/api/student/getgrades"

//    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@?sNummer=%@&RZLogin=%@", getPos, username, password]];
    
    NSString *post = [NSString stringWithFormat:@"sNummer=%@&RZLogin=%@",username, password];
    NSData *postData = [post dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
    
//    [NSURLRequest allowsAnyHTTPSCertificateForHost:[[NSURL URLWithString:getPos] host]];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:getPos]];
    
    [request setHTTPMethod:@"POST"];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    [request setHTTPBody:postData];
    [request setTimeoutInterval:10];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        
        // Fehler in der Übertragung
        if (data == nil || connectionError != nil) {
            NSLog(@"%@", connectionError.localizedDescription);
            return;
        }
        
        // HTTP Status Code ausgeben
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
        
        if (httpResponse.statusCode == 401) {
            // sNummer/RZLogin sind falsch
            UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Wiederholen" otherButtonTitles:nil];
            errorPopup.alertViewStyle = UIAlertViewStyleDefault;
            errorPopup.tag = LOGIN_ERROR_TAG;
            [errorPopup show];
            isLoading = false;
            return;
        }
        else if (httpResponse.statusCode == 400) {
            // sNummer/RZLogin fehlt
            UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Wiederholen" otherButtonTitles:nil];
            errorPopup.alertViewStyle = UIAlertViewStyleDefault;
            errorPopup.tag = LOGIN_ERROR_TAG;
            [errorPopup show];
            isLoading = false;
            return;
        }
        else {
            // Angaben stimmen -> JSON-Array befindet sich in data
            NSError *error;
            NSArray *pos = (NSArray*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
            if (error != nil) return;
            for (NSDictionary *dic in pos) {
                // Jeder Studiengang, für den Noten vorhanden sind
                NSString *AbschlNr = dic[@"AbschlNr"];
                NSString *StgNr = dic[@"StgNr"];
                NSString *POVersion = dic[@"POVersion"];
                
                NSString *post2 = [NSString stringWithFormat:@"sNummer=%@&RZLogin=%@&AbschlNr=%@&StgNr=%@&POVersion=%@",username, password, AbschlNr, StgNr, POVersion];
                NSData *postData2 = [post2 dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
                NSString *postLength2 = [NSString stringWithFormat:@"%lu", (unsigned long)[post length]];
                
                NSMutableURLRequest *request2 = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:getGrade]];
                
                [request2 setHTTPMethod:@"POST"];
                [request2 setValue:postLength2 forHTTPHeaderField:@"Content-Length"];
                [request2 setHTTPBody:postData2];
                [request2 setTimeoutInterval:10];
                
                
                
                [NSURLConnection sendAsynchronousRequest:request2 queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                    // Fehler in der Übertragung
                    if (data == nil || connectionError != nil) {
                        NSLog(@"%@", connectionError.localizedDescription);
                        return;
                    }
                    
                    // HTTP Status Code ausgeben
                    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
                    
                    if (httpResponse.statusCode == 401) {
                        // sNummer/RZLogin sind falsch
                        UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Wiederholen" otherButtonTitles:nil];
                        errorPopup.alertViewStyle = UIAlertViewStyleDefault;
                        errorPopup.tag = LOGIN_ERROR_TAG;
                        [errorPopup show];
                        isLoading = false;
                        return;
                    }
                    else if (httpResponse.statusCode == 400) {
                        // sNummer/RZLogin fehlt
                        UIAlertView *errorPopup = [[UIAlertView alloc] initWithTitle:@"Fehler beim Login" message:@"Login fehlgeschlagen." delegate:self cancelButtonTitle:@"Wiederholen" otherButtonTitles:nil];
                        errorPopup.alertViewStyle = UIAlertViewStyleDefault;
                        errorPopup.tag = LOGIN_ERROR_TAG;
                        [errorPopup show];
                        isLoading = false;
                        return;
                    }
                    else {
                        // Angaben stimmen JSON-Array befindet sich in data
                        
                        if(![[NSUserDefaults standardUserDefaults] boolForKey:@"NotenLoginNieSpeichern"] &&
                           ![username isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"LoginNoten2"]] &&
                           ![password isEqualToString:[[NSUserDefaults standardUserDefaults] objectForKey:@"PasswortNoten2"]])
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
                        
                        [self deleteAllNoten];
                        NSError *error;
                        NSArray *grades = (NSArray*)[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
                        for (NSDictionary *fach in grades) {
                            // Durch alle Noten durchgehen
                            Note *neueNote = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:self.context];
                            neueNote.credits = [NSNumber numberWithDouble:((NSString*)fach[@"EctsCredits"]).doubleValue];
                            neueNote.name = fach[@"PrTxt"];
                            neueNote.note = [NSNumber numberWithDouble:((NSString*)fach[@"PrNote"]).doubleValue/100];
                            neueNote.nr = [NSNumber numberWithDouble:((NSString*)fach[@"PrNr"]).doubleValue];
                            neueNote.semester = [self ausformuliertesSemesterVon:fach[@"Semester"]];
                            neueNote.status = fach[@"Status"];
                            neueNote.versuch = [NSNumber numberWithDouble:((NSString*)fach[@"Versuch"]).doubleValue];
                            [self.context save:nil];
                        }
                        
                        // Noten aus der DB laden und anzeigen
                        NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
                        NSMutableArray *allenoten = (NSMutableArray*)[self.context executeFetchRequest:request error:nil];
                        
                        self.notenspiegel = [[self groupNotenBySemester:allenoten] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                            NSString *semester = [(Note*)[obj2 objectAtIndex:0] semester];
                            NSString *jahr;
                            if([semester componentsSeparatedByString:@" "].count > 1)
                                jahr = [semester componentsSeparatedByString:@" "][1];
                            else jahr = @" ";
                            NSComparisonResult result;
                            if([[(Note*)obj1[0] semester] componentsSeparatedByString:@" "].count > 1)
                                result = [(NSString*)[[(Note*)obj1[0] semester] componentsSeparatedByString:@" "][1] compare:jahr options:NSNumericSearch];
                            else result = NSOrderedSame;
                            switch(result)
                            {
                                case NSOrderedAscending: return NSOrderedDescending;
                                case NSOrderedDescending: return NSOrderedAscending;
                                default: return NSOrderedSame;
                            }
                        }].mutableCopy;
                        // NSLog(@"%@", self.notenspiegel);
                        isLoading = false;
                        notendurchschnitt = [self calculateAverageGradeFromNotenspiegel:self.notenspiegel];
                        [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                        [self.navigationItem.rightBarButtonItem setEnabled:YES];
                        [self.tableView reloadData];
                    }
                }];
            }
        }
        
    }];
    
}

-(void)deleteAllNoten
{
    NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:@"Note"];
    NSMutableArray *alleNoten = (NSMutableArray*)[self.context executeFetchRequest:request error:nil];
    for (Note *temp in alleNoten) {
        [self.context deleteObject:temp];
    }
    [self.context save:nil];
}

-(NSString*)ausformuliertesSemesterVon:(NSString*)semester
{
    NSString *jahr = [semester substringToIndex:4];
    NSString *typ = [semester substringFromIndex:4];
    
    switch (typ.intValue) {
        case 1:
            return [NSString stringWithFormat:@"Sommersemester %@", jahr];
            break;
        case 2:
            return [NSString stringWithFormat:@"Wintersemester %@/%d", jahr, jahr.intValue - 2000 + 1];
            break;
        default:
            break;
    }
    
    return @"";
}

-(NSMutableArray*)groupNotenBySemester:(NSMutableArray*)alleNoten
{
    NSMutableArray *newNotenspiegel = [[NSMutableArray alloc] init];
    int tempIndex = 0;
    int indexCount = 0;
    NSMutableDictionary *semesterIndex = [[NSMutableDictionary alloc] init];
    
    for (Note *fach in alleNoten) {
        if (!([semesterIndex count] == 0)) {
            if ([[semesterIndex objectForKey:[NSNumber numberWithInt:tempIndex]] isEqualToString:fach.semester]) {
                [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            }
            else {
                //check if semester alread exists or not
                bool foundSemester = false;
                for (NSString* key in semesterIndex) {
                    NSString *value = [semesterIndex objectForKey:key];
                    
                    if ([value isEqualToString:fach.semester]) {
                        foundSemester = true;
                        tempIndex = [key intValue];
                        break;
                    }
                }
                if (!foundSemester) {
                    [semesterIndex setObject:fach.semester forKey:[@(indexCount) stringValue]];
                    [newNotenspiegel addObject:[[NSMutableArray alloc] init]];
                    tempIndex = indexCount;
                    indexCount++;
                }
                
                [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            }
        }
        else {
            tempIndex = indexCount;
            [newNotenspiegel addObject:[[NSMutableArray alloc] init]];
            [semesterIndex setObject:fach.semester forKey:[@(tempIndex) stringValue]];
            [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            indexCount++;
        }
    }
    return newNotenspiegel;
}

-(void)htwAlert:(HTWAlertNavigationController *)alert gotStringsFromTextFields:(NSArray *)strings
{
    if(alert.tag == LOGINMODAL_TAG) {
        NSString *usernameText = strings[0];
        
        if (![usernameText hasPrefix:@"s"]) {
            usernameText = [NSString stringWithFormat:@"s%@", usernameText];
        }
        
            NSString *passwordText = strings[1];
        
            if (usernameText && usernameText.length > 0 &&
                passwordText && passwordText.length > 0) {
//                NSLog(@"%@ %@", strings[0], strings[1]);
                username = usernameText;
                password = passwordText;
                
                [[NSUserDefaults standardUserDefaults] setObject:username forKey:@"LoginNoten2"];
                [[NSUserDefaults standardUserDefaults] setObject:password forKey:@"PasswortNoten2"];
                
                [self reloadNotenspiegel:self.navigationItem.rightBarButtonItem];
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
            [defaults setObject:username forKey:@"LoginNoten2"];
            [defaults setObject:password forKey:@"PasswortNoten2"];
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
        for (Note *fach in semester) {
            if(!([fach.note.stringValue isEqualToString:@""] || [fach.credits.stringValue isEqualToString:@""]))
            {
                NSNumber *note = fach.note;
//                [note replaceOccurrencesOfString:@"," withString:@"." options:NSCaseInsensitiveSearch range:NSMakeRange(0, note.length)];
                if (note.doubleValue == 0)
                    continue;
                
                tempSumme += note.floatValue * fach.credits.floatValue;
                creditsSum += fach.credits.floatValue;
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
        return [(Note*)[[self.notenspiegel objectAtIndex:section-1] objectAtIndex:0] semester];
    }
    return nil;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    if (!self.notenspiegel && !isLoading) return 80;
    if (indexPath.section == 0 && [self.notenspiegel count]>0) {
        return 25;
    }
    return UITableViewAutomaticDimension;
}

//-(void)tableView:(UITableView *)tableView willDisplayHeaderView:(UIView *)view forSection:(NSInteger)section {
//    UITableViewHeaderFooterView *header = (UITableViewHeaderFooterView *)view;
//    header.textLabel.textColor = [UIColor HTWGrayColor];
//    header.textLabel.font = [UIFont HTWSmallBoldFont];
//}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *reuseIdentifier = @"pruefungsfachZelle";
    NSString *reuseIdentifierLoading = @"spinnerZelle";
    NSString *reuseIdentifierAverageGrade = @"notendurchschnittZelle";
    
    UITableViewCell *cell;
    if (!isLoading) {
        if (indexPath.section > 0) {
            cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifier forIndexPath:indexPath];
//            cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue2 reuseIdentifier:reuseIdentifier];
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
        //Remove default separators
        tableView.separatorColor = [UIColor HTWBackgroundColor];
        
        if (indexPath.section == 0) {
            cell.textLabel.textAlignment = NSTextAlignmentCenter;
            cell.textLabel.text = [NSString stringWithFormat:@"Gesamt: ∅ %.2f", notendurchschnitt];
            cell.textLabel.font = [UIFont HTWExtraLargeFont];
            cell.textLabel.textColor = [UIColor HTWGrayColor];
            cell.backgroundColor = [UIColor clearColor];
        }
        else {
            cell.textLabel.text = [(Note*)[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] name];
            NSString *detailTemp = [NSString stringWithFormat:@"%.1f",[(Note*)[[self.notenspiegel objectAtIndex:indexPath.section-1] objectAtIndex:indexPath.row] note].floatValue];
            if (![detailTemp isEqualToString:@"0.0"]) {
                cell.detailTextLabel.text = detailTemp;
            }
            else {
                cell.detailTextLabel.text = @"";
            }
            cell.textLabel.textColor = [UIColor HTWDarkGrayColor];
            cell.detailTextLabel.textColor = [UIColor HTWBlueColor];
            cell.detailTextLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }
    
    if (self.notenspiegel.count == 0 && !isLoading) {
        cell.textLabel.text = @"Leider konnte keine Verbindung aufgebaut werden...";
        cell.textLabel.font = [UIFont HTWTableViewCellFont];
        cell.textLabel.textColor = [UIColor HTWTextColor];
        cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        cell.textLabel.numberOfLines = 2;
        cell.textLabel.textAlignment = NSTextAlignmentCenter;
    }
    
    if (self.notenspiegel && [self.notenspiegel count] == 0) {
        cell.textLabel.text = @"Keine Noten verfügbar :(";
    }
    
    return cell;
}

#pragma mark - Hilfsfunktionen

//#warning PDF DOWNLOAD UNVOLLSTÄNDIG
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
