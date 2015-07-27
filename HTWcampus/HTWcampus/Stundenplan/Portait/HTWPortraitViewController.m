//
//  HTWPortaitViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 15.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWPortraitViewController.h"
#import "HTWStundenplanParser.h"
#import "HTWAppDelegate.h"
#import "User.h"
#import "Stunde.h"
#import "HTWStundenplanButtonForLesson.h"
#import "HTWLandscapeViewController.h"
#import "HTWCSVExport.h"
#import "HTWICSExport.h"
#import "HTWCSVConnection.h"
#import "HTWStundenplanEditDetailTableViewController.h"
#import "HTWAlertNavigationController.h"


#import "UIColor+HTW.h"
#import "UIFont+HTW.h"
#import "UIImage+Resize.h"
#import "NSDate+HTW.h"

#define VERSION_STRING @"1.1.0"
#define UPDATE_CHECK_URL @"http://www.htw-dresden.de/fileadmin/userfiles/htw/img/HTW-App/api/version.json"
//#define UPDATE_CHECK_URL @"http://www.benchr.de/TEST/version.json"
#define UPDATE_URL @"itms-services://?action=download-manifest&url=https://www.htw-dresden.de/fileadmin/userfiles/htw/img/HTW-App/HTWcampus.plist"
#define LAST_CHECK_DATE_KEY @"LASTCHECKDATEKEY"

#define PixelPerMin 0.6
#define ALERT_EINGEBEN 0
#define ALERT_EXPORT 1
#define ALERT_ERROR 2
#define ALERT_NEW 3
#define ALERT_VERSION 4
#define DEPTH_FOR_PARALLAX 10
#define DATEPICKER_TAG 222
#define DATEPICKER_BUTTON_TAG 223
#define KALENDERBUTTON_TAG 333

#define ZEITENVIEW_TAG -2
#define LINEVIEW_TAG -3
#define WOCHENTAGE_TAG -4

@interface HTWPortraitViewController () <HTWStundenplanParserDelegate, HTWCSVConnectionDelegate, UIScrollViewDelegate, HTWAlertViewDelegate>
{
    NSString *Matrnr; // Nur für Stundenplan Studenten
    BOOL isPortrait;
    
    HTWAppDelegate *appdelegate;
    BOOL datePickerIsVisible;
}
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) NSArray *angezeigteStunden;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@property (nonatomic, strong) UIView *detailView;

@property (nonatomic, strong) HTWStundenplanParser *parser;
@property (nonatomic, strong) HTWCSVConnection *csvParser;


@end


@implementation HTWPortraitViewController

#pragma mark - Lazy Getter

-(NSDate *)currentDate
{
    if(!_currentDate) self.currentDate = [NSDate date];
    return _currentDate;
}

#pragma mark - Interface Orientation

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskPortrait;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsLandscape(deviceOrientation) && isPortrait)
    {
        [self performSegueWithIdentifier:@"switchToLandscape" sender:self];
        isPortrait = NO;
    }
    else if (UIDeviceOrientationIsPortrait(deviceOrientation) && !isPortrait)
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        isPortrait = YES;
    }
}

#pragma mark - View Controller Lifecycle

-(void)awakeFromNib
{
    [super awakeFromNib];
}

-(void)applicationWillEnterInForeground
{
    self.currentDate = [NSDate date];
    [self updateAngezeigteStunden];
    [self setUpInterface];
}

-(void)viewDidLoad
{
    [super viewDidLoad];
    isPortrait = YES;
    
    [self checkVersion];

    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];

    _settingsBarButtonItem.tintColor = [UIColor HTWWhiteColor];
    
//    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"]
//                                                            style:UIBarButtonItemStyleBordered
//                                                           target:self
//                                                           action:@selector(addSegue)];
    UIBarButtonItem *changeDate = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender2"]
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(changeDatePressed:)];
    changeDate.tag = KALENDERBUTTON_TAG;
    
//    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"]
//                                                                    style:UIBarButtonItemStyleBordered
//                                                                   target:self
//                                                                   action:@selector(shareTestButtonPressed:)];
    
    [self.navigationItem setRightBarButtonItem:changeDate];
    
    
    
    if(!_raumNummer) Matrnr = [[NSUserDefaults standardUserDefaults] objectForKey:@"Matrikelnummer"];
    if (((!Matrnr && !self.raumNummer) || ([Matrnr isEqualToString:@""] && [_raumNummer isEqualToString:@""]) || ([Matrnr isEqualToString:@""] && !_raumNummer) || (!Matrnr && [_raumNummer isEqualToString:@""]))) {
        
        HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
        alert.htwTitle = @"Neuer Stundenplan";
        alert.message = @"Bitte Matrnr, Studiengruppe oder Dozentenkennung eingeben.";
        alert.mainTitle = @[@"Kennung",@"Name (optional)"];
        alert.htwDelegate = self;
        alert.tag = ALERT_EINGEBEN;
        [self presentViewController:alert animated:NO completion:^{}];
    }
}

-(void)checkVersion
{
    NSDate *lastCheck = [[NSUserDefaults standardUserDefaults] objectForKey:LAST_CHECK_DATE_KEY];
    if (lastCheck != nil) {
        if ([[NSDate date] timeIntervalSinceDate:lastCheck] <= 60*60*24) {
            return;
        }
    }
    
    NSString *urlString = UPDATE_CHECK_URL; // URL für das PHP, das die aktuelle Version enthält
    NSURL *url = [NSURL URLWithString:urlString];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (data == nil || connectionError ) { return; }
        NSError *error;
        NSDictionary *versionDic = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:&error];
        [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:LAST_CHECK_DATE_KEY];
        if ([(NSString*)[versionDic objectForKey:@"version"] isEqualToString:VERSION_STRING]) {
            // aktuelle Version installiert, alles gut... :)
            return;
        }
        else {
            // es gibt eine aktuellere Version
            NSString *message = [NSString stringWithFormat:@"Eine neue Version (%@) ist verfügbar. Möchtest du die neue Version laden? (Aktuelle Version: %@)", (NSString*)[versionDic objectForKey:@"version"], VERSION_STRING];
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Warnung" message:message delegate:nil cancelButtonTitle:@"Nicht jetzt" otherButtonTitles:@"Laden", nil];
            alert.delegate = self;
            alert.tag = ALERT_VERSION;
            [alert show];
        }
    }];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:)
                                                 name:UIDeviceOrientationDidChangeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if([defaults integerForKey:@"tageInPortrait"] < 2) [defaults setInteger:2 forKey:@"tageInPortrait"];

    
    _scrollView.contentSize = CGSizeMake(60+116*[defaults integerForKey:@"tageInPortrait"], 40+PixelPerMin*(20.5*60-7.5*60));
    _scrollView.directionalLockEnabled = YES;
    _scrollView.delegate = self;
    [self reloadDaysLabelsAndBackground];
    [self reloadZeitenViewAndClockLine];
    
    _detailView = [[UIView alloc] init];
    _detailView.tag = 1;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:_detailView depth:DEPTH_FOR_PARALLAX];
    [_scrollView addSubview:_detailView];
    
    
    self.navigationController.navigationBarHidden = NO;
    self.scrollView.backgroundColor = [UIColor HTWSandColor];
    
    if(!self.raumNummer) Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    else self.title = self.raumNummer;

    
    if (((!Matrnr && !self.raumNummer) || ([Matrnr isEqualToString:@""] && [_raumNummer isEqualToString:@""]) || ([Matrnr isEqualToString:@""] && !_raumNummer) || (!Matrnr && [_raumNummer isEqualToString:@""])) && !_parser && !_csvParser) {
        
        NSLog(@"Keine Kennung eingegeben.");
    }
    else
    {
        
        [self updateAngezeigteStunden];
        
        if ([_angezeigteStunden count] == 0) {
            NSLog(@"Keine Stunden gefunden.");
            [self setUpInterface];
        }
        else
        {
        
            [self setUpInterface];
            
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
            [tapRecognizer setNumberOfTapsRequired:2];
            [self.scrollView addGestureRecognizer:tapRecognizer];
        }
    }
    
    [self orderViewsInScrollView:_scrollView];
}


-(void)viewWillDisappear:(BOOL)animated
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    isPortrait = YES;
}




#pragma mark - UIScrollView Delegate


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self orderViewsInScrollView:scrollView];
}

#pragma mark - Alert View

-(void)htwAlert:(HTWAlertNavigationController *)alert gotStringsFromTextFields:(NSArray *)strings
{
    if(alert.tag == ALERT_EINGEBEN)
    {   
        NSString *eingegeben = strings[0];
        if ([self isMatrikelnummer:eingegeben] || [self isStudiengruppe:eingegeben]) {
            
            Matrnr = strings[0];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:Matrnr forKey:@"Matrikelnummer"];
            
            [self updateAngezeigteStunden];
            
            if ([_angezeigteStunden count] == 0) {
                Matrnr = [defaults objectForKey:@"Matrikelnummer"];
                _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:Matrnr andRaum:NO];
                if(strings[1] && ![strings[1] isEqualToString:@""]) _parser.name = strings[1];
                [_parser setDelegate:self];
                [defaults setObject:Matrnr forKey:@"altMatrikelnummer"];
                [_parser parserStart];
            }
            else
            {
                [self setUpInterface];
            }
        }
        else {
            Matrnr = strings[0];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:Matrnr forKey:@"Matrikelnummer"];
            [defaults setBool:YES forKey:@"Dozent"];
            
            _csvParser = [[HTWCSVConnection alloc] initWithPassword:Matrnr];
            if(strings[1] && ![strings[1] isEqualToString:@""]) _csvParser.eName = strings[1];
            _csvParser.delegate = self;
            [_csvParser startParser];
        }
    }
    
}

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *clickedButtonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if(alertView.tag == ALERT_ERROR)
    {
        if ([clickedButtonTitle isEqualToString:@"Wiederholen"])
        {
            HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
            alert.htwTitle = @"Fehler";
            alert.message = alertView.message;
            alert.mainTitle = @[@"Name (optional)",@"Kennung"];
            alert.htwDelegate = self;
            alert.tag = ALERT_EINGEBEN;
            [self presentViewController:alert animated:NO completion:^{}];
        }
    }
    else if (alertView.tag == ALERT_NEW)
    {
        if([clickedButtonTitle isEqualToString:@"Ja"])
        {
            HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
            alert.htwTitle = @"Hallo";
            alert.message = @"Bitte geben Sie ihre Matrikelnummer, Studiengruppe oder Dozenten-Kennung ein, damit der Stundenplan geladen werden kann.";
            alert.mainTitle = @[@"Name (optional)",@"Kennung"];
            alert.htwDelegate = self;
            alert.tag = ALERT_EINGEBEN;
            [self presentViewController:alert animated:NO completion:^{}];
        }
    }
    else if (alertView.tag == ALERT_EXPORT)
    {
        if ([clickedButtonTitle isEqualToString:@"CSV (Google Kalender)"])
        {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:[NSEntityDescription entityForName:@"Stunde"
                                           inManagedObjectContext:_context]];

            [request setPredicate:[NSPredicate predicateWithFormat:@"(student.matrnr = %@)", Matrnr]];
            
            // FetchRequest-Ergebnisse
            NSArray *objects = [_context executeFetchRequest:request error:nil];
            if(objects.count == 0)
            {
                NSLog(@"Es wurde nichts zum CSV-Exportieren gefunden.");
                return;
            }
            
            NSString *dateinamenErweiterung;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults boolForKey:@"Dozent"]) {
                dateinamenErweiterung = [(Stunde*)objects[0] student].name;
            }
            else dateinamenErweiterung = [(Stunde*)objects[0] student].matrnr;
            
            HTWCSVExport *csvExp = [[HTWCSVExport alloc] initWithArray:objects andMatrNr:dateinamenErweiterung];
            
            NSURL *fileURL = [csvExp getFileUrl];
            
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"Mein Stundenplan (%@), erstellt mit der iOS-App der HTW Dresden.",dateinamenErweiterung], fileURL];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeCopyToPasteboard];
            
            [self presentViewController:activityVC animated:YES completion:^{
                [self doubleTap:_scrollView];
            }];
            
            activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                if (completed) {
                    UIAlertView *alert = [[UIAlertView alloc] init];
                    alert.title = @"Stundenplan erfolgreich als CSV-Datei exportiert.";
                    [alert show];
                    
                    NSFileManager *manager = [[NSFileManager alloc] init];
                    
                    [manager removeItemAtPath:[fileURL path] error:nil];
                    
                    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
                }
            };
            
            
            
        }
        else if([clickedButtonTitle isEqualToString:@"ICS (Mac, Windows)"])
        {
            NSFetchRequest *request = [[NSFetchRequest alloc] init];
            [request setEntity:[NSEntityDescription entityForName:@"Stunde"
                                           inManagedObjectContext:_context]];
            
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"(student.matrnr = %@)", Matrnr];
            [request setPredicate:pred];
            
            // FetchRequest-Ergebnisse
            NSArray *objects = [_context executeFetchRequest:request error:nil];
            if(objects.count == 0)
            {
                NSLog(@"Es wurde nichts zum ICS-Exportieren gefunden.");
                return;
            }
            
            
            NSString *dateinamenErweiterung;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults boolForKey:@"Dozent"]) {
                dateinamenErweiterung = [(Stunde*)objects[0] student].name;
            }
            else dateinamenErweiterung = [(Stunde*)objects[0] student].matrnr;
            
            
            HTWICSExport *csvExp = [[HTWICSExport alloc] initWithArray:objects andMatrNr:dateinamenErweiterung];
            
            NSURL *fileURL = [csvExp getFileUrl];
            
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"Mein Stundenplan (%@), erstellt mit der iOS-App der HTW Dresden.",dateinamenErweiterung], fileURL];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypePostToFacebook, UIActivityTypePostToTwitter, UIActivityTypeCopyToPasteboard];
            
            [self presentViewController:activityVC animated:YES completion:^{
                [self doubleTap:_scrollView];
            }];
            
            activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                if (completed) {
                    UIAlertView *alert = [[UIAlertView alloc] init];
                    alert.title = @"Stundenplan erfolgreich als ICS-Datei exportiert.";
                    [alert show];
                    
                    NSFileManager *manager = [[NSFileManager alloc] init];
                    
                    [manager removeItemAtPath:[fileURL path] error:nil];
                    
                    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
                }
            };
        }
        else if ([clickedButtonTitle isEqualToString:@"Bild"])
        {
            UIImage* image = nil;
            
            CGSize sizeForRendering;
            sizeForRendering.width = _scrollView.contentSize.width;
            sizeForRendering.height = self.view.frame.size.height;
            
            UIGraphicsBeginImageContextWithOptions(sizeForRendering, YES, 0.0);
            {
                CGPoint savedContentOffset = _scrollView.contentOffset;
                CGRect savedFrame = _scrollView.frame;
                
                [self.scrollView setContentOffset:CGPointMake(0, -64) animated:NO];
                _scrollView.frame = CGRectMake(0, 0, _scrollView.contentSize.width, sizeForRendering.height);
                
                [_scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                _scrollView.contentOffset = savedContentOffset;
                _scrollView.frame = savedFrame;
            }
            UIGraphicsEndImageContext();
            
            UIImage *sendImage = [image croppedImage:CGRectMake(0, 0, image.size.width, 54+800*PixelPerMin)];
            
            NSString *dateinamenErweiterung;
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            if ([defaults boolForKey:@"Dozent"]) {
                dateinamenErweiterung = [(Stunde*)_angezeigteStunden[0] student].name;
            }
            else dateinamenErweiterung = [(Stunde*)_angezeigteStunden[0] student].matrnr;
            
            NSArray *itemsToShare = @[[NSString stringWithFormat:@"Mein Stundenplan (%@), erstellt mit der iOS-App der HTW Dresden.",dateinamenErweiterung], sendImage];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact];
            
            activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                if ([activityType isEqualToString:UIActivityTypeSaveToCameraRoll] && completed) {
                    UIAlertView *alert = [[UIAlertView alloc] init];
                    alert.title = @"Stundenplan erfolgreich als Bild exportiert.";
                    [alert show];
                    
                    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
                    
                }
            };
            
            [self presentViewController:activityVC animated:YES completion:^{
                [self doubleTap:_scrollView];
            }];
        }
    }
    else if (alertView.tag == ALERT_VERSION) {
        if ([clickedButtonTitle isEqualToString:@"Laden"]) {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:UPDATE_URL]];
        }
    }
}

-(NSString *)alertViewCancelButtonTitle
{
    return @"Abbrechen";
}
-(NSString*)alertViewOkButtonTitle
{
    return @"Ok";
}

#pragma mark - Stundenplan Parser Delegate

-(void)HTWStundenplanParserFinished:(HTWStundenplanParser *)parser
{
    [self updateAngezeigteStunden];
    
    [self setUpInterface];
    
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Stundenplan erfolgreich heruntergeladen.";
    [alert show];
    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
}

-(void)HTWCSVConnectionFinished:(HTWCSVConnection *)connection
{
    [self updateAngezeigteStunden];
    
    [self setUpInterface];
    
    UIAlertView *alert = [[UIAlertView alloc] init];
    alert.title = @"Stundenplan erfolgreich heruntergeladen.";
    [alert show];
    [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:1];
}

-(void)HTWStundenplanParser:(HTWStundenplanParser *)parser Error:(NSString *)errorMessage
{
    UIAlertView *alert = [UIAlertView new];
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Wiederholen"];
    alert.tag = ALERT_ERROR;
    alert.delegate = self;
    [alert show];
}

-(void)HTWCSVConnection:(HTWCSVConnection *)connection Error:(NSString *)errorMessage
{
    UIAlertView *alert = [UIAlertView new];
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Wiederholen"];
    alert.tag = ALERT_ERROR;
    alert.delegate = self;
    [alert show];
}


#pragma mark - Interface

-(void)setUpInterface
{
    // Daten anzeigen
    
    for (UIView *view in self.scrollView.subviews) {
        if (view.tag < 0) {
            [view removeFromSuperview];
        }
    }
    
    [self reloadDaysLabelsAndBackground];
    
    for (Stunde *aktuell in self.angezeigteStunden) {
        if (!aktuell.anzeigen.boolValue) continue;
        HTWStundenplanButtonForLesson *button = [[HTWStundenplanButtonForLesson alloc] initWithLesson:aktuell andPortait:YES andCurrentDate:self.currentDate];
        button.tag = -1;
        UIView *shadow = [[UIView alloc] initWithFrame:button.frame];
        shadow.backgroundColor = [UIColor HTWGrayColor];
        shadow.alpha = 0.3;
        shadow.layer.cornerRadius = button.layer.cornerRadius;
        shadow.tag = -1;
        [self.scrollView addSubview:shadow];
        [self.scrollView addSubview:button];
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonIsPressed:)];
        longPressGR.minimumPressDuration = 0.1;
        longPressGR.allowableMovement = 0;
        [button addGestureRecognizer:longPressGR];
        if (Matrnr){
            UITapGestureRecognizer *tapGREdit = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(buttonIsPressedForEdit:)];
            tapGREdit.numberOfTapsRequired = 1;
            [button addGestureRecognizer:tapGREdit];
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:button depth:DEPTH_FOR_PARALLAX];
    }
    [self reloadZeitenViewAndClockLine];
    
    
}

-(void)reloadDaysLabelsAndBackground
{
    
    NSArray *wochentage = @[@"Montag",@"Dienstag",@"Mittwoch",@"Donnerstag",@"Freitag",@"Samstag",@"Sonntag"];
    
    NSDate *cDate = self.currentDate.copy;
    int weekday = [self.currentDate getWeekDay];
    
    int wochentagePointer = weekday;
    
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (int i=0; i < [defaults integerForKey:@"tageInPortrait"]; i++) {
        UILabel *this = [[UILabel alloc] initWithFrame:CGRectMake(i*116+50+_scrollView.contentSize.width, 13, 108, 26)];
        this.textAlignment = NSTextAlignmentCenter;
        this.font = [UIFont HTWLargeFont];
        this.tag = -1;
        this.textColor = [UIColor HTWGrayColor];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:this depth:DEPTH_FOR_PARALLAX];
//        this.text = [wochentage[wochentagePointer] uppercaseString];
        this.text = wochentage[wochentagePointer];
        
        UILabel *thisDate = [[UILabel alloc] initWithFrame:CGRectMake(this.frame.origin.x+this.frame.size.width/4, this.frame.origin.y-9, this.frame.size.width/2, 15)];
        thisDate.textAlignment = NSTextAlignmentCenter;
        thisDate.font = [UIFont HTWVerySmallFont];
        thisDate.tag = -1;
        thisDate.textColor = [UIColor HTWGrayColor];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:thisDate depth:DEPTH_FOR_PARALLAX];
        thisDate.text = [cDate getAsStringWithFormat:@"dd.MM."];
        
        wochentagePointer++;
        if (wochentagePointer > wochentage.count-1) {
            wochentagePointer = 0;
        }
        
        cDate = [cDate addDays:1 months:0 years:0];
//        cDate = [cDate dateByAddingTimeInterval:60*60*24];
        
        //set active Day
        if (i == 0) {
            this.textColor = thisDate.textColor = [UIColor HTWWhiteColor];
        }
        
        [labels addObject:this];
        [labels addObject:thisDate];
    }
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 40)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator-gray@2x.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake(50+_scrollView.contentSize.width, 37, 108, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    heuteMorgenLabelsView.tag = WOCHENTAGE_TAG;
    
    
    
    heuteMorgenLabelsView.backgroundColor = [UIColor HTWDarkGrayColor];
    
    for (UILabel *this in labels) {
        [heuteMorgenLabelsView addSubview:this];
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    
}

-(void)reloadZeitenViewAndClockLine
{
    NSDate *today = self.currentDate.getDayOnly;
    
    
    UIView *zeitenView = [[UIView alloc] initWithFrame:CGRectMake(_scrollView.contentOffset.x, -350, 40, _scrollView.contentSize.height+700)];
    zeitenView.backgroundColor = [UIColor HTWDarkGrayColor];
    zeitenView.tag = ZEITENVIEW_TAG;
    
    NSArray *vonStrings = @[@"07:30", @"09:20", @"11:10", @"13:10", @"15:00", @"16:50", @"18:30"];
    NSArray *bisStrings = @[@"09:00", @"10:50", @"12:40", @"14:40", @"16:30", @"18:20", @"20:00"];
    NSArray *stundenZeiten = @[[today dateByAddingTimeInterval:60*60*7+60*30],
                               [today dateByAddingTimeInterval:60*60*9+60*20],
                               [today dateByAddingTimeInterval:60*60*11+60*10],
                               [today dateByAddingTimeInterval:60*60*13+60*10],
                               [today dateByAddingTimeInterval:60*60*15+60*00],
                               [today dateByAddingTimeInterval:60*60*16+60*50],
                               [today dateByAddingTimeInterval:60*60*18+60*30] ];
    
    for (int i = 0; i < stundenZeiten.count; i++) {
        CGFloat y = 54 + [(NSDate*)[stundenZeiten objectAtIndex:i] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin + 350;
        UIView *vonBisView = [[UIView alloc] initWithFrame:CGRectMake(5, y, 30, 90 * PixelPerMin)];
        UILabel *von = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, vonBisView.frame.size.width, vonBisView.frame.size.height/2)];
        von.text = vonStrings[i];
        von.font = [UIFont HTWVerySmallFont];
        von.textColor = [UIColor HTWWhiteColor];
        [vonBisView addSubview:von];
        UILabel *bis = [[UILabel alloc] initWithFrame:CGRectMake(0, vonBisView.frame.size.height/2, vonBisView.frame.size.width, vonBisView.frame.size.height/2)];
        bis.text = bisStrings[i];
        bis.font = [UIFont HTWVerySmallFont];
        bis.textColor = [UIColor HTWWhiteColor];
        [vonBisView addSubview:bis];
        
        UIView *strich = [[UIView alloc] initWithFrame:CGRectMake(vonBisView.frame.size.width*0.25, von.frame.size.height, vonBisView.frame.size.width/2, 1)];
        strich.backgroundColor = [UIColor HTWWhiteColor];
        [vonBisView addSubview:strich];
        
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:vonBisView depth:DEPTH_FOR_PARALLAX];
        
        [zeitenView addSubview:vonBisView];
    }
    
    
    [self.scrollView addSubview:zeitenView];
    
    today = [NSDate date].getDayOnly;
    if ([[NSDate date] compare:[today dateByAddingTimeInterval:7*60*60+00*60]] == NSOrderedDescending &&
        [[NSDate date] compare:[today dateByAddingTimeInterval:22*60*60]] == NSOrderedAscending)
    {
        UIColor *linieUndClock = [UIColor colorWithRed:221/255.f green:72/255.f blue:68/255.f alpha:1];
        
        CGFloat y = 54 + [[NSDate date] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin;
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.scrollView.contentSize.width, 1.5)];
        lineView.backgroundColor = linieUndClock;
        lineView.alpha = 0.6;
        lineView.tag = LINEVIEW_TAG;
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:lineView depth:DEPTH_FOR_PARALLAX];
        [self.scrollView addSubview:lineView];
        [_scrollView bringSubviewToFront:lineView];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    for (UIView *view in self.scrollView.subviews) {
        if([view isKindOfClass:[HTWStundenplanButtonForLesson class]])
        {
            HTWStundenplanButtonForLesson *button = (HTWStundenplanButtonForLesson*)view;
            float einstellungMarkierung = [defaults floatForKey:@"markierSliderValue"]*60;
            if(_raumNummer) einstellungMarkierung = 0;
            if ([[NSDate date] compare:[button.lesson.anfang dateByAddingTimeInterval:-einstellungMarkierung]] == NSOrderedDescending &&
                [[NSDate date] compare:button.lesson.ende] == NSOrderedAscending) {
                [button setNow:YES];
            }
        }
    }
    
}

#pragma mark - IB Actions

-(IBAction)doubleTap:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake(0, -64) animated:YES];
}

-(IBAction)buttonIsPressed:(UILongPressGestureRecognizer*)gesture
{
    HTWStundenplanButtonForLesson *buttonPressed = (HTWStundenplanButtonForLesson*)gesture.view;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [buttonPressed markLesson];
        
        CGFloat x = buttonPressed.frame.origin.x-buttonPressed.frame.size.width/2;
        CGFloat y = buttonPressed.frame.origin.y-180*PixelPerMin;
        CGFloat width = buttonPressed.frame.size.width*2;
        CGFloat height = 180*PixelPerMin;
        
        if (x + width > _scrollView.contentOffset.x + [UIScreen mainScreen].bounds.size.width)
            x -= ((x + width) - ([UIScreen mainScreen].bounds.size.width + _scrollView.contentOffset.x));
        else if (x < _scrollView.contentOffset.x) x = _scrollView.contentOffset.x;
        if (y < 0) {
            y = buttonPressed.frame.origin.y + buttonPressed.frame.size.height;
        }
        
        
        _detailView.frame = CGRectMake(x, y, width,height);
        _detailView.layer.cornerRadius = 10;
        _detailView.backgroundColor = [UIColor HTWBlueColor];
        _detailView.alpha = 0.9;
        
        for (UIView *this in _detailView.subviews) {
            [this removeFromSuperview];
        }
        
        UILabel *titel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _detailView.frame.size.width, _detailView.frame.size.height*4/5)];
        titel.text = buttonPressed.lesson.titel;
        titel.textAlignment = NSTextAlignmentCenter;
        titel.font = [UIFont HTWBaseFont];
        titel.lineBreakMode = NSLineBreakByWordWrapping;
        titel.numberOfLines = 3;
        titel.textColor = [UIColor HTWWhiteColor];
        [_detailView addSubview:titel];
        
        UILabel *dozent = [[UILabel alloc] initWithFrame:CGRectMake(0, _detailView.frame.size.height*4/5-9, _detailView.frame.size.width, _detailView.frame.size.height*2/5)];
        if(buttonPressed.lesson.dozent && buttonPressed.lesson.student.dozent.boolValue == NO)
            dozent.text = [NSString stringWithFormat:@"Dozent: %@", buttonPressed.lesson.dozent];
        else if (buttonPressed.lesson.dozent && buttonPressed.lesson.student.dozent.boolValue)
            dozent.text = [NSString stringWithFormat:@"Studiengang: %@", buttonPressed.lesson.dozent];
        dozent.textAlignment = NSTextAlignmentCenter;
        dozent.font = [UIFont HTWSmallFont];
        dozent.textColor = [UIColor HTWWhiteColor];
        
        
        
        [_detailView addSubview:dozent];
        
        [_scrollView bringSubviewToFront:_detailView];
        
        _detailView.hidden = NO;
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        _detailView.hidden = YES;
        
        if ([[NSDate date] compare:[buttonPressed.lesson.anfang dateByAddingTimeInterval:-([[NSUserDefaults standardUserDefaults] floatForKey:@"markierSliderValue"]*60)]] == NSOrderedDescending &&
            [[NSDate date] compare:buttonPressed.lesson.ende] == NSOrderedAscending) {
            [buttonPressed setNow:YES];
        }
        else {
            [buttonPressed unmarkLesson];
        }
    }
}

-(IBAction)buttonIsPressedForEdit:(UILongPressGestureRecognizer*)sender
{
    [self performSegueWithIdentifier:@"showEditDetail" sender:sender.view];
}

- (IBAction)shareTestButtonPressed:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exportieren"
                                                    message:@"In welcher Form wollen Sie den Stundenplan exportieren oder teilen?"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Bild", @"CSV (Google Kalender)", @"ICS (Mac, Windows)", nil];
    alert.tag = ALERT_EXPORT;
    [alert show];
}

-(IBAction)changeDatePressed:(id)sender
{
//    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"]
//                                                            style:UIBarButtonItemStyleBordered
//                                                           target:self
//                                                           action:@selector(addSegue)];
    UIBarButtonItem *changeDate = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender2"]
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(changeDatePressed:)];
    changeDate.tag = KALENDERBUTTON_TAG;
    UIBarButtonItem *changeDateDone = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender3"]
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(changeDatePressed:)];
    changeDateDone.tag = KALENDERBUTTON_TAG;
//    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"]
//                                                                    style:UIBarButtonItemStyleBordered
//                                                                   target:self
//                                                                   action:@selector(shareTestButtonPressed:)];
    if(!datePickerIsVisible)
    {
        datePickerIsVisible = YES;
        UIDatePicker* picker = [[UIDatePicker alloc] init];
        picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        picker.datePickerMode = UIDatePickerModeDate;
        picker.tag = DATEPICKER_TAG;
        picker.backgroundColor = [UIColor HTWBackgroundColor];
        
        [picker addTarget:self action:@selector(dueDateChanged:) forControlEvents:UIControlEventValueChanged];
        picker.frame = CGRectMake(0.0, 0.0, self.view.frame.size.width, 460);
        
        picker.date = self.currentDate;
        
#define BUTTONSHEIGHT 40
        
        UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0, picker.frame.origin.y+picker.frame.size.height, self.view.frame.size.width, BUTTONSHEIGHT)];
        buttonsView.tag = DATEPICKER_BUTTON_TAG;
        buttonsView.backgroundColor = [UIColor HTWDarkGrayColor];
        
        UIButton *heuteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width/2, BUTTONSHEIGHT)];
        [heuteButton setTitle:@"Heute" forState:UIControlStateNormal];
        [heuteButton addTarget:self action:@selector(setToday) forControlEvents:UIControlEventTouchUpInside];
        [buttonsView addSubview:heuteButton];
        
        UIButton *fertigButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2, 0, self.view.frame.size.width/2, BUTTONSHEIGHT)];
        [fertigButton setTitle:@"Fertig" forState:UIControlStateNormal];
        [fertigButton addTarget:self action:@selector(changeDatePressed:) forControlEvents:UIControlEventTouchUpInside];
        [buttonsView addSubview:fertigButton];
        
//        UIButton *buttonForDisablingPicker = [[UIButton alloc] initWithFrame:CGRectMake(0, picker.frame.size.height, self.view.frame.size.width, 500)];
//        buttonForDisablingPicker.tag = DATEPICKER_BUTTON_TAG;
//        [buttonForDisablingPicker addTarget:self action:@selector(changeDatePressed:) forControlEvents:UIControlEventTouchUpInside];
        
        [self.view addSubview:picker];
        [self.view addSubview:buttonsView];
//        [self.view addSubview:buttonForDisablingPicker];
        [self.view bringSubviewToFront:picker];
        self.scrollView.userInteractionEnabled = NO;
//        UIBarButtonItem *heute = [[UIBarButtonItem alloc] initWithTitle:@"Heute" style:UIBarButtonItemStyleBordered target:self action:@selector(setToday)];
//        if(!_raumNummer) {
//            [self.navigationItem setRightBarButtonItems:@[heute] animated:YES];
//            for (UIView *temp in self.navigationItem.rightBarButtonItems) {
//                if (temp.tag == KALENDERBUTTON_TAG) {
//                    [(UIBarButtonItem*)temp setImage:[UIImage imageNamed:@"Kalender3"]];
//                }
//            }
//            for (UIView *temp in self.navigationItem.leftBarButtonItems) {
//                if (temp.tag == KALENDERBUTTON_TAG) {
//                    [(UIBarButtonItem*)temp setImage:[UIImage imageNamed:@"Kalender3"]];
//                }
//            }
//        }
//        else
            [self.navigationItem setRightBarButtonItems:@[] animated:YES];
    }
    else
    {
        for (UIView *temp in self.navigationItem.rightBarButtonItems) {
            if (temp.tag == KALENDERBUTTON_TAG) {
                [(UIBarButtonItem*)temp setImage:[UIImage imageNamed:@"Kalender2"]];
            }
        }
        for (UIView *temp in self.navigationItem.leftBarButtonItems) {
            if (temp.tag == KALENDERBUTTON_TAG) {
                [(UIBarButtonItem*)temp setImage:[UIImage imageNamed:@"Kalender2"]];
            }
        }
//        [(UIBarButtonItem*)[self.view viewWithTag:KALENDERBUTTON_TAG] setImage:[UIImage imageNamed:@"Kalender2"]];
        for (UIView *temp in self.view.subviews) {
            if (temp.tag == DATEPICKER_TAG || temp.tag == DATEPICKER_BUTTON_TAG) {
                [temp removeFromSuperview];
            }
        }
        
//        [[self.view viewWithTag:DATEPICKER_TAG] removeFromSuperview];
        self.scrollView.userInteractionEnabled = YES;
        datePickerIsVisible = NO;
        
        
        [self.navigationItem setRightBarButtonItems:@[changeDate] animated:YES];
    }
}

-(void)setToday
{
    self.currentDate = [NSDate date];
    [(UIDatePicker*)[self.view viewWithTag:DATEPICKER_TAG] setDate:[NSDate date]];
    [self dueDateChanged:(UIDatePicker*)[self.view viewWithTag:DATEPICKER_TAG]];
////    if(!_raumNummer) [self changeDatePressed:(UIBarButtonItem*)self.navigationItem.leftBarButtonItems[1]];
////    else
//        [self changeDatePressed:(UIBarButtonItem*)self.navigationItem.rightBarButtonItem];
}

-(void) dueDateChanged:(UIDatePicker *)sender {
    self.currentDate = sender.date;
    [self viewWillAppear:YES];
}

#pragma mark - Hilfsfunktionen

-(void)updateAngezeigteStunden
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = [defaults integerForKey:@"tageInPortrait"];
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    
    NSDate *today = self.currentDate.getDayOnly;
    NSDate *theLastShownDate = [theCalendar dateByAddingComponents:dayComponent toDate:today options:0];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Stunde"
                                   inManagedObjectContext:_context]];
    NSPredicate *pred;
    
    if(Matrnr) pred = [NSPredicate predicateWithFormat:@"(student.matrnr = %@) && anfang > %@ && ende < %@", Matrnr, today, theLastShownDate];
    else pred = [NSPredicate predicateWithFormat:@"(student.matrnr = %@) && anfang > %@ && ende < %@", _raumNummer, today, theLastShownDate];
    [request setPredicate:pred];
    
    // FetchRequest-Ergebnisse
    _angezeigteStunden = [_context executeFetchRequest:request
                                                 error:nil];
}

-(void)orderViewsInScrollView:(UIScrollView*)scrollView
{
    for (UIView *this in scrollView.subviews) {
        CGPoint origin;
        switch (this.tag) {
            case 1: this.hidden = YES; break;
            case WOCHENTAGE_TAG:
                this.frame = CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 40);
                [scrollView bringSubviewToFront:this];
                break;
            case ZEITENVIEW_TAG:
                origin.x = scrollView.contentOffset.x;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                [scrollView bringSubviewToFront:this];
                break;
            case LINEVIEW_TAG:
                origin.x = scrollView.contentOffset.x+15;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                break;
            default:
                break;
        }
    }
    
    for (UIView *this in scrollView.subviews) {
        if(this.tag == ZEITENVIEW_TAG) {
            [scrollView bringSubviewToFront:this];
            break;
        }
    }
    
    for (UIView *this in scrollView.subviews) {
        if(this.tag == WOCHENTAGE_TAG) {
            [scrollView bringSubviewToFront:this];
            break;
        }
    }
}

- (void)registerEffectForView:(UIView *)aView depth:(CGFloat)depth;
{
    if(![[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) return;
	UIInterpolatingMotionEffect *effectX;
	UIInterpolatingMotionEffect *effectY;
    effectX = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.x"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongHorizontalAxis];
    effectY = [[UIInterpolatingMotionEffect alloc] initWithKeyPath:@"center.y"
                                                              type:UIInterpolatingMotionEffectTypeTiltAlongVerticalAxis];
	
	
	effectX.maximumRelativeValue = @(depth);
	effectX.minimumRelativeValue = @(-depth);
	effectY.maximumRelativeValue = @(depth);
	effectY.minimumRelativeValue = @(-depth);
	
	[aView addMotionEffect:effectX];
	[aView addMotionEffect:effectY];
}

-(BOOL)isMatrikelnummer:(NSString*)string
{
    if([string isEqualToString:@""]) return NO;
    if (string.length != 5) return NO;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{5}" options:0 error:nil];
    NSTextCheckingResult *result = [regex firstMatchInString:string options:0 range:NSMakeRange(0, string.length)];
    if (result) {
        return YES;
    }
    else return NO;
}

-(BOOL)isStudiengruppe:(NSString*)string
{
    if([string isEqualToString:@""]) return NO;
    NSArray *array = [string componentsSeparatedByString:@"/"];
    if (array.count != 3) return NO;
    else
    {
//        for (NSString *this in array) {
//            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{2,}" options:0 error:nil];
//            NSTextCheckingResult *result = [regex firstMatchInString:this options:0 range:NSMakeRange(0, this.length)];
//            if (result) {
//                return YES;
//            }
//            else return NO;
//        }
        return YES;
    }
    return NO;
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"switchToLandscape"])
    {
        [segue.destinationViewController setHidesBottomBarWhenPushed:YES];
        if(Matrnr) {
            [segue.destinationViewController setMatrnr:Matrnr];
            [(HTWLandscapeViewController*)segue.destinationViewController setRaum:NO];
        }
        else {
            [segue.destinationViewController setMatrnr:self.raumNummer];
            [(HTWLandscapeViewController*)segue.destinationViewController setRaum:YES];
        }
        [(HTWLandscapeViewController*)segue.destinationViewController setCurrentDate:self.currentDate];
    }
    else if ([segue.identifier isEqualToString:@"showEditDetail"])
    {
        HTWStundenplanEditDetailTableViewController *dest = (HTWStundenplanEditDetailTableViewController*)segue.destinationViewController;
        HTWStundenplanButtonForLesson *button = (HTWStundenplanButtonForLesson*)sender;
        dest.stunde = button.lesson;
        dest.oneLessonOnly = YES;
    }
}

-(void)addSegue
{
    [self performSegueWithIdentifier:@"add" sender:self];
}
@end
