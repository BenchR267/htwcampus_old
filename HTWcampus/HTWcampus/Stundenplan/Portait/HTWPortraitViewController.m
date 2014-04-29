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
#import "Student.h"
#import "Stunde.h"
#import "HTWStundenplanButtonForLesson.h"
#import "HTWLandscapeViewController.h"
#import "HTWColors.h"

#define PixelPerMin 0.5

@interface HTWPortraitViewController () <HTWStundenplanParserDelegate, UIScrollViewDelegate>
{
    NSString *Matrnr; // Nur für Stundenplan Studenten
    BOOL isPortrait;
    
    HTWAppDelegate *appdelegate;
    
    HTWColors *htwColors;
}
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;
@property (nonatomic, strong) HTWStundenplanParser *parser;
@property (nonatomic, strong) NSArray *angezeigteStunden;

@property (nonatomic, strong) NSManagedObjectContext *context;
@property (strong, nonatomic) IBOutlet UIBarButtonItem *settingsBarButtonItem;

@property (nonatomic, strong) UIView *detailView;


@end

@implementation HTWPortraitViewController

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
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
}

-(void)applicationWillEnterInForeground
{
    [self viewWillAppear:YES];
}

-(void)viewDidLoad
{
    htwColors = [[HTWColors alloc] init];
    
    UIDevice *device = [UIDevice currentDevice];
    
    [device beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
    isPortrait = YES;
    
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"add"] style:UIBarButtonItemStyleBordered target:self action:@selector(addSegue)];
    [self.navigationItem setRightBarButtonItems:@[add, self.navigationItem.rightBarButtonItem]];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];
    
    _settingsBarButtonItem.tintColor = htwColors.darkTextColor;
    
    _scrollView.contentSize = CGSizeMake(80+116*7, 520);
    _scrollView.directionalLockEnabled = YES;
    _scrollView.delegate = self;
    
    _detailView = [[UIView alloc] init];
    _detailView.tag = 1;
    [_scrollView addSubview:_detailView];
    
    self.tabBarController.tabBar.barTintColor = htwColors.darkTabBarTint;
    [self.tabBarController.tabBar setTintColor:htwColors.darkTextColor];
    [self.tabBarController.tabBar setSelectedImageTintColor:htwColors.darkTextColor];
    
    
    self.navigationController.navigationBarHidden = NO;
    
    self.navigationController.navigationBar.barStyle = htwColors.darkNavigationBarStyle;
    self.navigationController.navigationBar.barTintColor = htwColors.darkNavigationBarTint;
    self.navigationController.navigationBar.tintColor = htwColors.darkTextColor;
    self.scrollView.backgroundColor = htwColors.darkViewBackground;
    
    if(!self.raumNummer) Matrnr = [defaults objectForKey:@"Matrikelnummer"];
    else self.title = self.raumNummer;
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    if (!Matrnr && !self.raumNummer) {
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Hallo"
                                                            message:@"Bitte geben Sie Ihre Matrikelnummer oder Studiengruppe ein, damit der Stundenplan geladen werden kann."
                                                           delegate:self
                                                  cancelButtonTitle:[self alertViewCancelButtonTitle]
                                                  otherButtonTitles:[self alertViewOkButtonTitle], nil];
        [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];
        [alertView show];
    }
    else
    {
        
        [self updateAngezeigteStunden];
        
        if ([_angezeigteStunden count] == 0) {
            Matrnr = [defaults objectForKey:@"Matrikelnummer"];
            _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:Matrnr andRaum:NO];
            [_parser setDelegate:self];
            [defaults setObject:Matrnr forKey:@"altMatrikelnummer"];
            [_parser parserStart];
        }
        else
        {
            
            [self setUpInterface];
            
            UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
            [tapRecognizer setNumberOfTapsRequired:2];
            [self.scrollView addGestureRecognizer:tapRecognizer];
        }
    }
    
    [self scrollViewDidScroll:_scrollView];
}

-(void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    isPortrait = YES;
}




#pragma mark - UIScrollView Delegate


-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (UIView *this in _scrollView.subviews) {
        CGPoint origin;
        switch (this.tag) {
            case 1: this.hidden = YES; break;
            case -4:
                this.frame = CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 50);
                [_scrollView bringSubviewToFront:this];
                break;
            case -2:
                origin.x = _scrollView.contentOffset.x;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                [_scrollView bringSubviewToFront:this];
                break;
            case -3:
                origin.x = _scrollView.contentOffset.x+15;
                origin.y = this.frame.origin.y;
                this.frame = CGRectMake(origin.x, origin.y, this.frame.size.width, this.frame.size.height);
                break;
            default:
                break;
        }
    }
    
    for (UIView *this in _scrollView.subviews) {
        if(this.tag == -3) {
            [_scrollView bringSubviewToFront:this];
            break;
        }
    }
}

#pragma mark - Alert View

-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *clickedButtonTitle = [alertView buttonTitleAtIndex:buttonIndex];
    
    if([alertView.title isEqualToString:@"Hallo"] || [alertView.title isEqualToString:@"Fehler"])
    {
        if ([clickedButtonTitle isEqualToString:[self alertViewOkButtonTitle]])
        {
            if ([alertView alertViewStyle] == UIAlertViewStylePlainTextInput) {
                Matrnr = [alertView textFieldAtIndex:0].text;
                NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
                [defaults setObject:Matrnr forKey:@"Matrikelnummer"];
                
                
                _parser = nil;
                
                [self updateAngezeigteStunden];
                
                if ([_angezeigteStunden count] == 0) {
                    Matrnr = [defaults objectForKey:@"Matrikelnummer"];
                    _parser = [[HTWStundenplanParser alloc] initWithMatrikelNummer:Matrnr andRaum:NO];
                    [_parser setDelegate:self];
                    [defaults setObject:Matrnr forKey:@"altMatrikelnummer"];
                    [_parser parserStart];
                }
                else
                {                
                    [self setUpInterface];
                }
            }
        }
        else if ([clickedButtonTitle isEqualToString:[self alertViewCancelButtonTitle]])
        {
            NSLog(@"AlertView wurde abgebrochen.");
        }
    }
    else if ([alertView.title isEqualToString:@"Exportieren"])
    {
        if ([clickedButtonTitle isEqualToString:@"CSV"])
        {
#warning CSV-Export einbinden
            UIAlertView *alert = [[UIAlertView alloc] init];
            alert.title = @"CSV-Exportierung befindet sich gerade noch im Aufbau..";
            [alert show];
            
            [alert performSelector:@selector(dismissWithClickedButtonIndex:animated:) withObject:nil afterDelay:3];
        }
        else if ([clickedButtonTitle isEqualToString:@"Bild"])
        {
            UIImage* image = nil;
            
            UIGraphicsBeginImageContext(_scrollView.contentSize);
            {
                CGPoint savedContentOffset = _scrollView.contentOffset;
                CGRect savedFrame = _scrollView.frame;
                
                [self.scrollView setContentOffset:CGPointMake(0, -64) animated:NO];
                _scrollView.frame = CGRectMake(0, 0, _scrollView.contentSize.width, _scrollView.contentSize.height);
                
                [_scrollView.layer renderInContext: UIGraphicsGetCurrentContext()];
                image = UIGraphicsGetImageFromCurrentImageContext();
                
                _scrollView.contentOffset = savedContentOffset;
                _scrollView.frame = savedFrame;
            }
            UIGraphicsEndImageContext();
            
            CGImageRef imgRef = CGImageCreateWithImageInRect([image CGImage], CGRectMake(0, 0, image.size.width, 54 + 803 * PixelPerMin));
            
            image = [UIImage imageWithCGImage:imgRef];
            
            NSArray *itemsToShare = @[@"Stundenplan erstellt mit der iOS-App der HTW Dresden.", image];
            UIActivityViewController *activityVC = [[UIActivityViewController alloc] initWithActivityItems:itemsToShare applicationActivities:nil];
            activityVC.excludedActivityTypes = @[UIActivityTypeAssignToContact];
            activityVC.title = @"Stundenplan teilen.";
            
            activityVC.completionHandler = ^(NSString *activityType, BOOL completed) {
                if ([activityType isEqualToString:UIActivityTypeSaveToCameraRoll] && completed) {
                    UIAlertView *alert = [[UIAlertView alloc] init];
                    alert.title = @"Stundenplan erfolgreich exportiert.";
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

-(void)HTWStundenplanParserFinished
{
    [self updateAngezeigteStunden];
    
    [self setUpInterface];
}

-(void)HTWStundenplanParserError:(NSString *)errorMessage
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                        message:errorMessage
                                                       delegate:self
                                              cancelButtonTitle:[self alertViewCancelButtonTitle]
                                              otherButtonTitles:[self alertViewOkButtonTitle], nil];
    [alertView setAlertViewStyle:UIAlertViewStylePlainTextInput];    
    [alertView show];
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
    
    [self reloadCellLabels];
    
    for (Stunde *aktuell in self.angezeigteStunden) {
        if (!aktuell.anzeigen.boolValue) continue;
        HTWStundenplanButtonForLesson *button = [[HTWStundenplanButtonForLesson alloc] initWithLesson:aktuell andPortait:YES];
        button.tag = -1;
        [self.scrollView addSubview:button];
        if (Matrnr){
            UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonIsPressed:)];
            longPressGR.minimumPressDuration = 0.1;
            longPressGR.allowableMovement = 0;
            [button addGestureRecognizer:longPressGR];
        }
    }
    [self setUpZeitenView];
    
    
}

-(void)reloadCellLabels
{
    UIColor *schriftfarbe = htwColors.darkTextColor;
    
    NSArray *wochentage = @[@"Montag",@"Dienstag",@"Mittwoch",@"Donnerstag",@"Freitag",@"Samstag",@"Sonntag"];
    
    int weekday = [self weekdayFromDate:[NSDate date]];
    
    int wochentagePointer = weekday;
    
    NSMutableArray *labels = [[NSMutableArray alloc] init];
    
    for (int i=0; i < 7; i++) {
        UILabel *this = [[UILabel alloc] initWithFrame:CGRectMake(i*116+78+_scrollView.contentSize.width, 20, 108, 26)];
        this.textAlignment = NSTextAlignmentCenter;
        this.font = [UIFont fontWithName:@"Helvetica" size:20];
        this.tag = -1;
        this.textColor = schriftfarbe;
        
        this.text = wochentage[wochentagePointer];
        
        wochentagePointer++;
        if (wochentagePointer > wochentage.count-1) {
            wochentagePointer = 0;
        }
        
        
        [labels addObject:this];
    }
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-_scrollView.contentSize.width, _scrollView.contentOffset.y+64, _scrollView.contentSize.width*3, 50)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake(78+_scrollView.contentSize.width, 47, 108, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    heuteMorgenLabelsView.tag = -4;
    
    
    
    heuteMorgenLabelsView.backgroundColor = htwColors.darkZeitenAndButtonBackground;
    
    for (UILabel *this in labels) {
        [heuteMorgenLabelsView addSubview:this];
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    ;
    
    BOOL abwechselnd = YES;
    CGFloat yStreifen = 54 + 30 * PixelPerMin;
    for (int i=0; i<20; i++) {
        if (abwechselnd) {
            UIView *strich1 = [[UIView alloc] initWithFrame:CGRectMake(-_scrollView.contentSize.width, yStreifen, self.scrollView.contentSize.width*3, 60*PixelPerMin)];
            strich1.backgroundColor = htwColors.darkStricheStundenplan;
            strich1.tag = -1;
            
            [self.scrollView addSubview:strich1];
        }
        yStreifen += 60 * PixelPerMin;
        abwechselnd = !abwechselnd;
    }
    
    
}

-(void)setUpZeitenView
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
    
    NSMutableArray *stundenZeiten = [[NSMutableArray alloc] init];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:60*60*7]];
    for (int i=0; i<17; i++) {
        [stundenZeiten addObject:[(NSDate*)stundenZeiten[i] dateByAddingTimeInterval:60*60]];
    }
        
    UIView *zeitenView = [[UIView alloc] initWithFrame:CGRectMake(_scrollView.contentOffset.x, -350, 63, _scrollView.contentSize.height+700)];
    zeitenView.backgroundColor = htwColors.darkZeitenAndButtonBackground;
    zeitenView.tag = -2;
    
    NSDateFormatter *uhrzeit = [[NSDateFormatter alloc] init];
    [uhrzeit setDateFormat:@"HH:mm"];
    for (int i = 0; i < [stundenZeiten count]; i++) {
        CGFloat y = 54 + [(NSDate*)[stundenZeiten objectAtIndex:i] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin + 350;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(25, y, 108, 20)];
        label.text = [uhrzeit stringFromDate:stundenZeiten[i]];
        label.textAlignment = NSTextAlignmentLeft;
        label.textColor = htwColors.darkTextColor;
        label.font = [UIFont fontWithName:@"Helvetica" size:12];
        
        
        [zeitenView addSubview:label];
    }
    [self.scrollView addSubview:zeitenView];
    
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
    if (gesture.state == UIGestureRecognizerStateBegan) {
        HTWStundenplanButtonForLesson *buttonPressed = (HTWStundenplanButtonForLesson*)gesture.view;
        
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
        _detailView.backgroundColor = htwColors.darkButtonBorder;
        _detailView.alpha = 0.85;
        
        for (UIView *this in _detailView.subviews) {
            [this removeFromSuperview];
        }
        
        UILabel *titel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _detailView.frame.size.width, _detailView.frame.size.height*4/5)];
        titel.text = buttonPressed.lesson.titel;
        titel.textAlignment = NSTextAlignmentCenter;
        titel.font = [UIFont systemFontOfSize:17];
        titel.lineBreakMode = NSLineBreakByWordWrapping;
        titel.numberOfLines = 3;
        titel.textColor = htwColors.darkTextColor;
        [_detailView addSubview:titel];
        
        UILabel *dozent = [[UILabel alloc] initWithFrame:CGRectMake(0, _detailView.frame.size.height*4/5-9, _detailView.frame.size.width, _detailView.frame.size.height*2/5)];
        if(buttonPressed.lesson.dozent) dozent.text = [NSString stringWithFormat:@"Dozent: %@", buttonPressed.lesson.dozent];
        dozent.textAlignment = NSTextAlignmentCenter;
        dozent.font = [UIFont systemFontOfSize:15];
        dozent.textColor = htwColors.darkTextColor;
        [_detailView addSubview:dozent];
        
        [_scrollView bringSubviewToFront:_detailView];
        
        _detailView.hidden = NO;
    }
    if (gesture.state == UIGestureRecognizerStateEnded) {
        _detailView.hidden = YES;
    }
}


- (IBAction)shareTestButtonPressed:(id)sender {
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Exportieren"
                                                    message:@"In welcher Form wollen Sie den Stundenplan exportieren oder teilen?"
                                                   delegate:self
                                          cancelButtonTitle:@"Abbrechen"
                                          otherButtonTitles:@"Bild", @"CSV", nil];
    
    [alert show];
    
}

#pragma mark - Hilfsfunktionen

-(void)updateAngezeigteStunden
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    
    NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
    dayComponent.day = 7;
    
    NSCalendar *theCalendar = [NSCalendar currentCalendar];
    
    NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
    NSDate *theDayAfterTomorrow = [theCalendar dateByAddingComponents:dayComponent toDate:today options:0];
    
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"Stunde"
                                   inManagedObjectContext:_context]];
    NSPredicate *pred;
    
    if(Matrnr) pred = [NSPredicate predicateWithFormat:@"(student.matrnr = %@) && anfang > %@ && ende < %@", Matrnr, today, theDayAfterTomorrow];
    else pred = [NSPredicate predicateWithFormat:@"(student.matrnr = %@) && anfang > %@ && ende < %@", _raumNummer, today, theDayAfterTomorrow];
    [request setPredicate:pred];
    
    // FetchRequest-Ergebnisse
    _angezeigteStunden = [NSMutableArray arrayWithArray:[_context executeFetchRequest:request
                                                                                error:nil]];
}

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
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
    }
}

-(void)addSegue
{
    [self performSegueWithIdentifier:@"add" sender:self];
}
@end
