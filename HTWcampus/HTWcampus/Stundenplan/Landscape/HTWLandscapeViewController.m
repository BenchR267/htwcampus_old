//
//  HTWLandscapeViewController.m
//  HTW-App
//
//  Created by Benjamin Herzog on 15.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWLandscapeViewController.h"
#import "HTWAppDelegate.h"
#import "HTWStundenplanButtonForLesson.h"
#import "Stunde.h"
#import "Student.h"
#import "HTWColors.h"
#import "HTWPortaitViewController.h"

#define PixelPerMin 0.37

@interface HTWLandscapeViewController ()
{
    HTWAppDelegate *appdelegate;
    BOOL isPortait;
    
    HTWColors *htwColors;
}
@property (strong, nonatomic) IBOutlet UIView *zeitenView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UIView *detailView;

@property (nonatomic, strong) NSArray *parserStunden;
@property (nonatomic, strong) NSMutableArray *angezeigteStunden;

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation HTWLandscapeViewController

@synthesize Matrnr;

#pragma mark - Support methods for Orientation and Swipe

- (void)orientationChanged:(NSNotification *)notification
{
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (UIDeviceOrientationIsPortrait(deviceOrientation) && !isPortait && (deviceOrientation != UIDeviceOrientationPortraitUpsideDown))
    {
        if(_raum) [self.navigationController popViewControllerAnimated:NO];
        else [self.navigationController popToRootViewControllerAnimated:NO];
        isPortait = YES;
    }
    else if ((UIDeviceOrientationIsLandscape(deviceOrientation) && isPortait) && UIDeviceOrientationIsValidInterfaceOrientation(deviceOrientation))
    {
        [self dismissViewControllerAnimated:YES completion:nil];
        isPortait = NO;
    }
}

-(BOOL)shouldAutorotate
{
    return NO;
}

-(NSUInteger)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscape;
}

-(UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return (UIInterfaceOrientationLandscapeLeft | UIInterfaceOrientationLandscapeRight);
}

-(UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark - View Controller Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    
    
    htwColors = [[HTWColors alloc] init];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationWillEnterInForeground) name:UIApplicationWillEnterForegroundNotification object:nil];
    
    UIDevice *device = [UIDevice currentDevice];
    
    [device beginGeneratingDeviceOrientationNotifications];
    //Get the notification centre for the app
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
    isPortait = NO;
}


-(void)applicationWillEnterInForeground
{
    [self viewWillAppear:YES];
}

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    if (!UIDeviceOrientationIsLandscape(deviceOrientation) && (deviceOrientation != UIDeviceOrientationPortraitUpsideDown))
    {
        if(_raum) [self.navigationController popViewControllerAnimated:NO];
        else [self.navigationController popToRootViewControllerAnimated:NO];
        isPortait = YES;
    }

    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];

    
    self.navigationController.navigationBar.tintColor = htwColors.darkTextColor;
    self.navigationController.navigationBarHidden = YES;
    self.scrollView.contentSize = CGSizeMake(508*2+68, 320);
    
    
    _detailView = [[UIView alloc] init];
    _detailView.tag = 1;
    [_scrollView addSubview:_detailView];
    
    self.scrollView.backgroundColor = htwColors.darkViewBackground;
    self.zeitenView.backgroundColor = htwColors.darkZeitenAndButtonBackground;
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:_context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entityDesc;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"matrnr = %@", Matrnr];
    request.predicate = pred;
    
    NSArray *studenten = [_context executeFetchRequest:request error:nil];
    Student *student = nil;
    if([studenten count])
        student = studenten[0];
    self.parserStunden = [[NSArray alloc] initWithArray:[student.stunden allObjects]];
    self.angezeigteStunden = [[NSMutableArray alloc] init];
    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    NSDate *letzterMontag = [[nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]] dateByAddingTimeInterval:-60*60*24*weekday ];
    NSDate *zweiWochenNachDemMontag = [letzterMontag dateByAddingTimeInterval:60*60*24*13];
    
    for (Stunde *aktuell in _parserStunden) {
        if ([aktuell.anfang timeIntervalSinceDate:letzterMontag] < 0 || [aktuell.anfang timeIntervalSinceDate:zweiWochenNachDemMontag] > 0) {
            continue;
        }
        else [_angezeigteStunden addObject:aktuell];
    }
    
    [self setUpInterface];
    
    
    
    
}

-(void)dealloc
{
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(orientationChanged:)
               name:UIDeviceOrientationDidChangeNotification
             object:nil];
    [nc removeObserver:self name:UIDeviceOrientationDidChangeNotification object:nil];
    isPortait = YES;
}

#pragma mark - Interface

-(void)setUpInterface
{
    [self loadLabels];
    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
    
    if ([[NSDate date] compare:[today dateByAddingTimeInterval:7*60*60+30*60]] == NSOrderedDescending &&
        [[NSDate date] compare:[today dateByAddingTimeInterval:20*60*60]] == NSOrderedAscending)
    {
        UIColor *linieUndClock = [UIColor colorWithRed:255/255.f green:72/255.f blue:68/255.f alpha:1];
        
        UIImage *clock = [UIImage imageNamed:@"Clock"];
        UIImageView *clockView = [[UIImageView alloc] initWithImage:clock];
        
        clockView.image = [clockView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        [clockView setTintColor:linieUndClock];
        
        CGFloat y = 55 + [[NSDate date] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin;
        
        clockView.frame = CGRectMake(0, y-7.5, 15, 15);
        clockView.tag = -1;
        
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(15, y, self.zeitenView.bounds.size.width, 1)];
        lineView.backgroundColor = linieUndClock;
        lineView.tag = -1;
        [self.zeitenView addSubview:clockView];
        [self.zeitenView addSubview:lineView];
        UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(-350, y, self.scrollView.contentSize.width+350-10, 1)];
        lineView2.backgroundColor = linieUndClock;
        lineView2.tag = -1;
        [self.scrollView addSubview:lineView2];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (Stunde *aktuell in self.angezeigteStunden) {
        if(!aktuell.anzeigen.boolValue) continue;
        HTWStundenplanButtonForLesson *button = [[HTWStundenplanButtonForLesson alloc] initWithLesson:aktuell andPortait:NO];
        button.tag = -1;
        
        if (!_raum){
            [button addTarget:self
                       action:@selector(buttonPressed:)
             forControlEvents:UIControlEventTouchDown];
            [button addTarget:self
                       action:@selector(buttonReleased:)
             forControlEvents:UIControlEventTouchUpOutside|UIControlEventTouchUpInside];
        }
        
        if ([[NSDate date] compare:[button.lesson.anfang dateByAddingTimeInterval:-[defaults floatForKey:@"markierSliderValue"]*60]] == NSOrderedDescending &&
            [[NSDate date] compare:button.lesson.ende] == NSOrderedAscending) {
            [button setNow:YES];
        }
        
        [self.scrollView addSubview:button];
    }
//    self.scrollView.bounds = self.scrollView.frame;
    
    [self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
    
    UITapGestureRecognizer *tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)];
    [tapRecognizer setNumberOfTapsRequired:2];
    [self.scrollView addGestureRecognizer:tapRecognizer];
}

-(void)loadLabels
{
    float xWerteTage[10] = {0.0,103.0,206.0,309.0,412.0,576.0,679.0,782.0,885.0,988.0};
    CGFloat yWertTage = 24;
    NSArray *stringsTage = [NSArray arrayWithObjects:@"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", nil];
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-350, 0, _scrollView.contentSize.width+350+350, 24+21)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake([self getScrollX]+350, 24+18, 90, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    
    
    
    heuteMorgenLabelsView.backgroundColor = htwColors.darkZeitenAndButtonBackground;
    heuteMorgenLabelsView.tag = -1;
    
    for (int i = 0; i < 10; i++) {
        int j = i;
        if (i > 4) j = i-5;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(xWerteTage[i]+350, yWertTage, 90, 21)];
        label.text = [stringsTage objectAtIndex:j];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = htwColors.darkTextColor;
        label.font = [UIFont fontWithName:@"Helvetica" size:16];
        [heuteMorgenLabelsView addSubview:label];
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
    
    NSMutableArray *stundenZeiten = [[NSMutableArray alloc] init];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:7*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:8*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:9*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:10*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:11*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:12*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:13*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:14*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:15*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:16*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:17*60*60]];
    [stundenZeiten addObject:[today dateByAddingTimeInterval:18*60*60]];
    NSMutableArray *stundenTexte = [[NSMutableArray alloc] init];
    [stundenTexte addObject:@"07:00"];
    [stundenTexte addObject:@"08:00"];
    [stundenTexte addObject:@"09:00"];
    [stundenTexte addObject:@"10:00"];
    [stundenTexte addObject:@"11:00"];
    [stundenTexte addObject:@"12:00"];
    [stundenTexte addObject:@"13:00"];
    [stundenTexte addObject:@"14:00"];
    [stundenTexte addObject:@"15:00"];
    [stundenTexte addObject:@"16:00"];
    [stundenTexte addObject:@"17:00"];
    [stundenTexte addObject:@"18:00"];
    
    for (int i = 0; i < [stundenZeiten count]; i++) {
        CGFloat y = 54 + [(NSDate*)[stundenZeiten objectAtIndex:i] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(22, y, 108, 20)];
        //        UIView *strich1 = [[UIView alloc] initWithFrame:CGRectMake(5, y-3, self.zeitenView.bounds.size.width, 2)];
        //        strich1.backgroundColor = [UIColor lightGrayColor];
        //        strich1.tag = -1;
        //        UIView *strich2 = [[UIView alloc] initWithFrame:CGRectMake(-350, y-3, self.scrollView.contentSize.width+350-10, 2)];
        //        strich2.backgroundColor = [UIColor lightGrayColor];
        //        strich2.tag = -1;
        label.text = [stundenTexte objectAtIndex:i];
        label.textAlignment = NSTextAlignmentLeft;
        label.font = [UIFont fontWithName:@"Helvetica" size:12];
        label.textColor = htwColors.darkTextColor;
        [self.zeitenView addSubview:label];
        //        [self.zeitenView addSubview:strich1];
        //        [self.scrollView addSubview:strich2];
    }
    
    BOOL abwechselnd = YES;
    CGFloat yStreifen = 54 + 30 * PixelPerMin;
    for (int i=0; i<20; i++) {
        if (abwechselnd) {
            UIView *strich1 = [[UIView alloc] initWithFrame:CGRectMake(-350, yStreifen, self.scrollView.contentSize.width+350+350, 60*PixelPerMin)];
            strich1.backgroundColor = htwColors.darkStricheStundenplan;
            strich1.tag = -1;
            
            [self.scrollView addSubview:strich1];
        }
        yStreifen += 60 * PixelPerMin;
        abwechselnd = !abwechselnd;
    }
}

#pragma mark - IBActions

-(IBAction)doubleTap:(id)sender
{
    [self.scrollView setContentOffset:CGPointMake([self getScrollX], 0) animated:YES];
}



-(CGFloat)getScrollX
{
    NSDateFormatter *vereinfacher = [[NSDateFormatter alloc] init];
    [vereinfacher setDateFormat:@"dd.MM.yyyy"];
    [vereinfacher setTimeZone:[NSTimeZone timeZoneWithName:@"CET"]];
    
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday] - 2;
    if(weekday == -1) weekday=6;
    NSDate *today = [vereinfacher dateFromString:[vereinfacher stringFromDate:[NSDate date]]];
    
    NSDate *montag = [[vereinfacher dateFromString:[vereinfacher stringFromDate:[NSDate date]]] dateByAddingTimeInterval:(-60*60*24*weekday) ];
    NSDate *dienstag = [montag dateByAddingTimeInterval:60*60*24];
    NSDate *mittwoch = [dienstag dateByAddingTimeInterval:60*60*24];
    NSDate *donnerstag = [mittwoch dateByAddingTimeInterval:60*60*24];
    NSDate *freitag = [donnerstag dateByAddingTimeInterval:60*60*24];
    NSDate *montag2 = [[vereinfacher dateFromString:[vereinfacher stringFromDate:[NSDate date]]] dateByAddingTimeInterval:((-60*60*24*weekday)+60*60*24*7) ];
    NSDate *dienstag2 = [montag2 dateByAddingTimeInterval:60*60*24];
    NSDate *mittwoch2 = [dienstag2 dateByAddingTimeInterval:60*60*24];
    NSDate *donnerstag2 = [mittwoch2 dateByAddingTimeInterval:60*60*24];
    NSDate *freitag2 = [donnerstag2 dateByAddingTimeInterval:60*60*24];
    
    if ([today isEqualToDate:montag]) return 0;
    else if ([today isEqualToDate:dienstag]) return 103;
    else if ([today isEqualToDate:mittwoch]) return 206;
    else if ([today isEqualToDate:donnerstag]) return 309;
    else if ([today isEqualToDate:freitag]) return 412;
    else if ([today isEqualToDate:montag2]) return 576;
    else if ([today isEqualToDate:dienstag2]) return 679;
    else if ([today isEqualToDate:mittwoch2]) return 782;
    else if ([today isEqualToDate:donnerstag2]) return 885;
    else if ([today isEqualToDate:freitag2]) return 988;
    else return 576;
}


-(IBAction)buttonPressed:(id)sender
{
    HTWStundenplanButtonForLesson *buttonPressed = (HTWStundenplanButtonForLesson*)sender;
    _detailView.frame = CGRectMake(buttonPressed.frame.origin.x-buttonPressed.frame.size.width/2, buttonPressed.frame.origin.y-180*PixelPerMin, buttonPressed.frame.size.width*2,180*PixelPerMin);
    _detailView.layer.cornerRadius = 10;
    _detailView.backgroundColor = [UIColor redColor];
    _detailView.alpha = 0.8;
    UILabel *titel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, _detailView.frame.size.width, _detailView.frame.size.height*4/5)];
    titel.text = buttonPressed.lesson.titel;
    titel.textAlignment = NSTextAlignmentCenter;
    titel.font = [UIFont systemFontOfSize:15];
    titel.lineBreakMode = NSLineBreakByWordWrapping;
    titel.numberOfLines = 2;
    [_detailView addSubview:titel];
    
    UILabel *dozent = [[UILabel alloc] initWithFrame:CGRectMake(0, _detailView.frame.size.height*4/5-9, _detailView.frame.size.width, _detailView.frame.size.height*2/5)];
    dozent.text = buttonPressed.lesson.dozent;
    dozent.textAlignment = NSTextAlignmentCenter;
    dozent.font = [UIFont systemFontOfSize:15];
    [_detailView addSubview:dozent];
    
    for (UIView *aktuell in _scrollView.subviews) {
        if (aktuell.tag == 1) {
            [_scrollView bringSubviewToFront:aktuell];
            aktuell.hidden = NO;
            break;
        }
    }
}

-(IBAction)buttonReleased:(id)sender
{
    for (UIView *aktuell in _scrollView.subviews) {
        if (aktuell.tag == 1) {
            for (UIView *this in aktuell.subviews) {
                [this removeFromSuperview];
            }
            aktuell.hidden = YES;
            break;
        }
    }
}

#pragma mark - Navigation

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    
}

@end