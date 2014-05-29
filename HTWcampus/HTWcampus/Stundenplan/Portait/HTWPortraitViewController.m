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

#define PixelPerMin 0.5
#define ALERT_EINGEBEN 0
#define ALERT_EXPORT 1
#define ALERT_ERROR 2
#define ALERT_NEW 3
#define DEPTH_FOR_PARALLAX 10
#define DATEPICKER_TAG 222

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

    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];

    _settingsBarButtonItem.tintColor = [UIColor HTWWhiteColor];
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"]
                                                            style:UIBarButtonItemStyleBordered
                                                           target:self
                                                           action:@selector(addSegue)];
    UIBarButtonItem *changeDate = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender2"]
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(changeDatePressed:)];
    
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"]
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(shareTestButtonPressed:)];
    
    if(!_raumNummer)
    {
        [self.navigationItem setRightBarButtonItems:@[add, shareButton]];
        [self.navigationItem setLeftBarButtonItems:@[self.navigationItem.leftBarButtonItem, changeDate]];
    }
    else
    {
        [self.navigationItem setRightBarButtonItem:changeDate];
    }
    
    
    
    if(!_raumNummer) Matrnr = [[NSUserDefaults standardUserDefaults] objectForKey:@"Matrikelnummer"];
    if (((!Matrnr && !self.raumNummer) || ([Matrnr isEqualToString:@""] && [_raumNummer isEqualToString:@""]) || ([Matrnr isEqualToString:@""] && !_raumNummer) || (!Matrnr && [_raumNummer isEqualToString:@""]))) {
        
        HTWAlertNavigationController *alert = [self.storyboard instantiateViewControllerWithIdentifier:@"HTWAlert"];
        alert.htwTitle = @"Hallo";
        alert.message = @"Bitte geben Sie Ihre Matrikelnummer oder Studiengruppe bzw. Dozenten-Kennung ein, damit der Stundenplan geladen werden kann.";
        alert.mainTitle = @[@"Name (optional)",@"Kennung"];
        alert.htwDelegate = self;
        alert.tag = ALERT_EINGEBEN;
        [self presentViewController:alert animated:NO completion:^{}];
    }
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

    
    _scrollView.contentSize = CGSizeMake(60+116*[defaults integerForKey:@"tageInPortrait"], 459 + [UINavigationBar appearance].frame.size.height);
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
        NSString *eingegeben = strings[1];
        if ([self isMatrikelnummer:eingegeben] || [self isStudiengruppe:eingegeben]) {
            
            Matrnr = strings[1];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:Matrnr forKey:@"Matrikelnummer"];
            
            [self updateAngezeigteStunden];
            
            if ([_angezeigteStunden count] == 0) {
                Matrnr = [defaults objectForKey:@"Matrikelnummer"];
                _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:Matrnr andRaum:NO];
                if(strings[0] && ![strings[0] isEqualToString:@""]) _parser.name = strings[0];
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
            Matrnr = strings[1];
            NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
            [defaults setObject:Matrnr forKey:@"Matrikelnummer"];
            [defaults setBool:YES forKey:@"Dozent"];
            
            _csvParser = [[HTWCSVConnection alloc] initWithPassword:Matrnr];
            if(strings[0] && ![strings[0] isEqualToString:@""]) _csvParser.eName = strings[0];
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
        if ([clickedButtonTitle isEqualToString:@"Nochmal"])
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
}

-(void)HTWCSVConnectionFinished:(HTWCSVConnection *)connection
{
    [self updateAngezeigteStunden];
    
    [self setUpInterface];
}

-(void)HTWStundenplanParser:(HTWStundenplanParser *)parser Error:(NSString *)errorMessage
{
    UIAlertView *alert = [UIAlertView new];
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Nochmal"];
    alert.tag = ALERT_ERROR;
    alert.delegate = self;
    [alert show];
}

-(void)HTWCSVConnection:(HTWCSVConnection *)connection Error:(NSString *)errorMessage
{
    UIAlertView *alert = [UIAlertView new];
    alert.message = errorMessage;
    [alert addButtonWithTitle:@"Nochmal"];
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
        UILabel *this = [[UILabel alloc] initWithFrame:CGRectMake(i*116+60+_scrollView.contentSize.width, 20, 108, 26)];
        this.textAlignment = NSTextAlignmentCenter;
        this.font = [UIFont HTWLargeFont];
        this.tag = -1;
        this.textColor = [UIColor HTWWhiteColor];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:this depth:DEPTH_FOR_PARALLAX];
        this.text = wochentage[wochentagePointer];
        
        UILabel *thisDate = [[UILabel alloc] initWithFrame:CGRectMake(this.frame.origin.x+this.frame.size.width/4, this.frame.origin.y-10, this.frame.size.width/2, 15)];
        thisDate.textAlignment = NSTextAlignmentCenter;
        thisDate.font = [UIFont HTWVerySmallFont];
        thisDate.tag = -1;
        thisDate.textColor = [UIColor HTWWhiteColor];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:thisDate depth:DEPTH_FOR_PARALLAX];
        thisDate.text = [cDate getAsStringWithFormat:@"dd.MM."];
        
        wochentagePointer++;
        if (wochentagePointer > wochentage.count-1) {
            wochentagePointer = 0;
        }
        cDate = [cDate dateByAddingTimeInterval:60*60*24];
        
        
        [labels addObject:this];
        [labels addObject:thisDate];
    }
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 50)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake(60+_scrollView.contentSize.width, 47, 108, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    heuteMorgenLabelsView.tag = -4;
    
    
    
    heuteMorgenLabelsView.backgroundColor = [UIColor HTWDarkGrayColor];
    
    for (UILabel *this in labels) {
        [heuteMorgenLabelsView addSubview:this];
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    
}

-(void)reloadZeitenViewAndClockLine
{
    NSDate *today = self.currentDate.getDayOnly;
    
    
    UIView *zeitenView = [[UIView alloc] initWithFrame:CGRectMake(_scrollView.contentOffset.x, -350, 45, _scrollView.contentSize.height+700)];
    zeitenView.backgroundColor = [UIColor HTWDarkGrayColor];
    zeitenView.tag = -2;
    
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
    if ([[NSDate date] compare:[today dateByAddingTimeInterval:7*60*60+30*60]] == NSOrderedDescending &&
        [[NSDate date] compare:[today dateByAddingTimeInterval:22*60*60]] == NSOrderedAscending)
    {
        UIColor *linieUndClock = [UIColor colorWithRed:221/255.f green:72/255.f blue:68/255.f alpha:1];
        
        
        
        UIImage *clock = [UIImage imageNamed:@"Clock"];
        UIImageView *clockView = [[UIImageView alloc] initWithImage:clock];
        
        clockView.image = [clockView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [clockView setTintColor:linieUndClock];
        
        CGFloat y = 54 + [[NSDate date] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin;
        clockView.frame = CGRectMake(0, y-7.5, 15, 15);
        clockView.alpha = 0.6;
        clockView.tag = -2;
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.scrollView.contentSize.width, 1)];
        lineView.backgroundColor = linieUndClock;
        lineView.alpha = 0.6;
        lineView.tag = -3;
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:lineView depth:DEPTH_FOR_PARALLAX];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:clockView depth:DEPTH_FOR_PARALLAX];
        [self.scrollView addSubview:lineView];
        [self.scrollView addSubview:clockView];
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
        buttonPressed.backgroundColor = [UIColor HTWBlueColor];
        for (UIView *this in buttonPressed.subviews) {
            if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWWhiteColor]];
            else if (this.tag == -9) this.backgroundColor = [UIColor whiteColor];
        }
        
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
            buttonPressed.backgroundColor = [UIColor HTWWhiteColor];
        
            for (UIView *this in buttonPressed.subviews) {
                if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWDarkGrayColor]];
                else if (this.tag == -9) this.backgroundColor = [UIColor HTWTextColor];
            }
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
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"]
                                                            style:UIBarButtonItemStyleBordered
                                                           target:self
                                                           action:@selector(addSegue)];
    UIBarButtonItem *changeDate = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender2"]
                                                                   style:UIBarButtonItemStyleBordered
                                                                  target:self
                                                                  action:@selector(changeDatePressed:)];
    UIBarButtonItem *changeDateDone = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Kalender3"]
                                                                       style:UIBarButtonItemStyleBordered
                                                                      target:self
                                                                      action:@selector(changeDatePressed:)];
    UIBarButtonItem *shareButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"Share"]
                                                                    style:UIBarButtonItemStyleBordered
                                                                   target:self
                                                                   action:@selector(shareTestButtonPressed:)];
    if(!datePickerIsVisible)
    {
        datePickerIsVisible = YES;
        UIDatePicker* picker = [[UIDatePicker alloc] init];
        picker.autoresizingMask = UIViewAutoresizingFlexibleWidth;
        picker.datePickerMode = UIDatePickerModeDate;
        picker.tag = DATEPICKER_TAG;
        picker.backgroundColor = [UIColor HTWBackgroundColor];
        
        [picker addTarget:self action:@selector(dueDateChanged:) forControlEvents:UIControlEventValueChanged];
        picker.frame = CGRectMake(0.0, self.view.frame.size.height - 460, self.view.frame.size.width, 460);
        
        picker.date = self.currentDate;
        
        [self.view addSubview:picker];
        [self.view bringSubviewToFront:picker];
        self.scrollView.userInteractionEnabled = NO;
        UIBarButtonItem *heute = [[UIBarButtonItem alloc] initWithTitle:@"Heute" style:UIBarButtonItemStyleBordered target:self action:@selector(setToday)];
        if(!_raumNummer) {
            [self.navigationItem setRightBarButtonItems:@[heute] animated:YES];
            [(UIBarButtonItem*)sender setImage:[UIImage imageNamed:@"Kalender3"]];
        }
        else [self.navigationItem setRightBarButtonItems:@[changeDateDone, heute] animated:YES];
    }
    else
    {
        [(UIBarButtonItem*)sender setImage:[UIImage imageNamed:@"Kalender2"]];
        [[self.view viewWithTag:DATEPICKER_TAG] removeFromSuperview];
        self.scrollView.userInteractionEnabled = YES;
        datePickerIsVisible = NO;
        
        
        if(!_raumNummer)
        {
            [self.navigationItem setRightBarButtonItems:@[add, shareButton] animated:YES];
        }
        else
        {
            [self.navigationItem setRightBarButtonItems:@[changeDate] animated:YES];
        }
    }
}

-(void)setToday
{
    self.currentDate = [NSDate date];
    [(UIDatePicker*)[self.view viewWithTag:DATEPICKER_TAG] setDate:[NSDate date]];
    [self dueDateChanged:(UIDatePicker*)[self.view viewWithTag:DATEPICKER_TAG]];
    [self changeDatePressed:nil];
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
            case -4:
                this.frame = CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 50);
                [scrollView bringSubviewToFront:this];
                break;
            case -2:
                origin.x = scrollView.contentOffset.x;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                [scrollView bringSubviewToFront:this];
                break;
            case -3:
                origin.x = scrollView.contentOffset.x+15;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                break;
            default:
                break;
        }
    }
    
    for (UIView *this in scrollView.subviews) {
        if(this.tag == -3) {
            [scrollView bringSubviewToFront:this];
            break;
        }
    }
    
    for (UIView *this in scrollView.subviews) {
        if(this.tag == -4) {
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
        for (NSString *this in array) {
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\d{2,}" options:0 error:nil];
            NSTextCheckingResult *result = [regex firstMatchInString:this options:0 range:NSMakeRange(0, this.length)];
            if (result) {
                return YES;
            }
            else return NO;
        }
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
    }
}

-(void)addSegue
{
    [self performSegueWithIdentifier:@"add" sender:self];
}
@end
