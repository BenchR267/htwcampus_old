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
#import "User.h"
#import "HTWPortraitViewController.h"
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define PixelPerMin 0.35
#define ANZAHLTAGE 10
#define DEPTH_FOR_PARALLAX 8

@interface HTWLandscapeViewController () <UIScrollViewDelegate>
{
    HTWAppDelegate *appdelegate;
    BOOL isPortait;
}
@property (strong, nonatomic) IBOutlet UIView *zeitenView;
@property (strong, nonatomic) IBOutlet UIScrollView *scrollView;

@property (nonatomic, strong) UIView *detailView;
@property (nonatomic, strong) NSArray *angezeigteStunden;
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

#pragma mark - View Controller Lifecycle

-(void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationWillEnterInForeground)
                                                 name:UIApplicationWillEnterForegroundNotification
                                               object:nil];
    
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(orientationChanged:)
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
    
    self.navigationController.navigationBarHidden = YES;
    self.scrollView.contentSize = CGSizeMake(508*2+68, 320);
    _scrollView.delegate = self;
    
    
    _detailView = [[UIView alloc] init];
    _detailView.hidden = YES;
    _detailView.tag = 1;
    if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:_detailView depth:DEPTH_FOR_PARALLAX];
    [_scrollView addSubview:_detailView];
    
    self.scrollView.backgroundColor = [UIColor HTWSandColor];
    self.zeitenView.backgroundColor = [UIColor HTWDarkGrayColor];
    
    appdelegate = [[UIApplication sharedApplication] delegate];
    _context = [appdelegate managedObjectContext];
    
    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    
    int weekday = [self weekdayFromDate:[NSDate date]];
    
    NSDate *letzterMontag = [[nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]] dateByAddingTimeInterval:-60*60*24*weekday ];
    NSDate *zweiWochenNachDemMontag = [letzterMontag dateByAddingTimeInterval:60*60*24*13];
    
    NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:_context];
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    request.entity = entityDesc;
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"student.matrnr = %@ && anfang > %@ && ende < %@", Matrnr, letzterMontag, zweiWochenNachDemMontag];
    request.predicate = pred;
    
    _angezeigteStunden = [_context executeFetchRequest:request error:nil];
    
    
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

#pragma mark - UIScrollView Delegate

-(void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    for (UIView *this in _scrollView.subviews) {
        if (this.tag == 1)
            this.hidden = YES;
    }
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
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:clockView depth:DEPTH_FOR_PARALLAX];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:lineView depth:DEPTH_FOR_PARALLAX];
        [self.zeitenView addSubview:clockView];
        [self.zeitenView addSubview:lineView];
        UIView *lineView2 = [[UIView alloc] initWithFrame:CGRectMake(-350, y, self.scrollView.contentSize.width+350-10, 1)];
        lineView2.backgroundColor = linieUndClock;
        lineView2.tag = -1;
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:lineView2 depth:DEPTH_FOR_PARALLAX];
        [self.scrollView addSubview:lineView2];
    }
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    
    for (Stunde *aktuell in self.angezeigteStunden) {
        if(!aktuell.anzeigen.boolValue) continue;
        HTWStundenplanButtonForLesson *button = [[HTWStundenplanButtonForLesson alloc] initWithLesson:aktuell andPortait:NO];
        button.tag = -1;
        
        UILongPressGestureRecognizer *longPressGR = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(buttonIsPressed:)];
        longPressGR.minimumPressDuration = 0.1;
        [button addGestureRecognizer:longPressGR];
        
        if ([[NSDate date] compare:[button.lesson.anfang dateByAddingTimeInterval:-[defaults floatForKey:@"markierSliderValue"]*60]] == NSOrderedDescending &&
            [[NSDate date] compare:button.lesson.ende] == NSOrderedAscending) {
            [button setNow:YES];
        }
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:button depth:DEPTH_FOR_PARALLAX];
        
        UIView *shadow = [[UIView alloc] initWithFrame:button.frame];
        shadow.layer.cornerRadius = button.layer.cornerRadius;
        shadow.backgroundColor = [UIColor HTWGrayColor];
        shadow.alpha = 0.3;
        shadow.tag = -1;
        [self.scrollView addSubview:shadow];
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
//    float xWerteTage[10] = {0.0,103.0,206.0,309.0,412.0,576.0,679.0,782.0,885.0,988.0};
    CGFloat yWertTage = 24;
    NSArray *stringsTage = [NSArray arrayWithObjects:@"Montag", @"Dienstag", @"Mittwoch", @"Donnerstag", @"Freitag", nil];
    
    UIView *heuteMorgenLabelsView = [[UIView alloc] initWithFrame:CGRectMake(-350, 0, _scrollView.contentSize.width+350+350, 24+21)];
    
    UIImage *indicator = [UIImage imageNamed:@"indicator.png"];
    UIImageView *indicatorView = [[UIImageView alloc] initWithImage:indicator];
    indicatorView.frame = CGRectMake([self getScrollX]+350, 24+18, 90, 7);
    [heuteMorgenLabelsView addSubview:indicatorView];
    
    
    
    heuteMorgenLabelsView.backgroundColor = [UIColor HTWDarkGrayColor];
    heuteMorgenLabelsView.tag = -1;
    
    for (int i = 0; i < ANZAHLTAGE; i++) {
        int j = i;
        if (i > 4) j = i-5;
        
        CGFloat x = 1+i*103;
        if(i > 4) x += 61;
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(x+350, yWertTage, 90, 21)];
        label.text = [stringsTage objectAtIndex:j];
        label.textAlignment = NSTextAlignmentCenter;
        label.textColor = [UIColor HTWWhiteColor];
        label.font = [UIFont HTWBaseFont];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:label depth:DEPTH_FOR_PARALLAX];
        [heuteMorgenLabelsView addSubview:label];
    }
    [_scrollView addSubview:heuteMorgenLabelsView];
    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
    
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
        CGFloat y = 54 + [(NSDate*)[stundenZeiten objectAtIndex:i] timeIntervalSinceDate:[today dateByAddingTimeInterval:7*60*60+30*60]] / 60 * PixelPerMin ;
        UIView *vonBisLabel = [[UIView alloc] initWithFrame:CGRectMake(5, y, 30, 90 * PixelPerMin)];
        UILabel *von = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, vonBisLabel.frame.size.width, vonBisLabel.frame.size.height/2)];
        von.text = vonStrings[i];
        von.font = [UIFont HTWVerySmallFont];
        von.textColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:von];
        UILabel *bis = [[UILabel alloc] initWithFrame:CGRectMake(0, vonBisLabel.frame.size.height/2, vonBisLabel.frame.size.width, vonBisLabel.frame.size.height/2)];
        bis.text = bisStrings[i];
        bis.font = [UIFont HTWVerySmallFont];
        bis.textColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:bis];
        
        UIView *strich = [[UIView alloc] initWithFrame:CGRectMake(vonBisLabel.frame.size.width*0.25, von.frame.size.height, vonBisLabel.frame.size.width/2, 1)];
        strich.backgroundColor = [UIColor HTWWhiteColor];
        [vonBisLabel addSubview:strich];
        if([[NSUserDefaults standardUserDefaults] boolForKey:@"parallax"]) [self registerEffectForView:vonBisLabel depth:DEPTH_FOR_PARALLAX];
        
        [_zeitenView addSubview:vonBisLabel];
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


-(IBAction)buttonIsPressed:(UILongPressGestureRecognizer*)gesture
{
    HTWStundenplanButtonForLesson *buttonPressed = (HTWStundenplanButtonForLesson*)gesture.view;
    if (gesture.state == UIGestureRecognizerStateBegan) {
        buttonPressed.backgroundColor = [UIColor HTWBlueColor];
        for (UIView *this in buttonPressed.subviews) {
            if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWWhiteColor]];
        }
        
        CGFloat x = buttonPressed.frame.origin.x-buttonPressed.frame.size.width/2;
        CGFloat y = buttonPressed.frame.origin.y-220*PixelPerMin;
        CGFloat width = buttonPressed.frame.size.width*2;
        CGFloat height = 220*PixelPerMin;
        
        if (x + width > _scrollView.contentOffset.x + [UIScreen mainScreen].bounds.size.height - _zeitenView.frame.size.width)
            x -= ((x + width) - ([UIScreen mainScreen].bounds.size.height - _zeitenView.frame.size.width + _scrollView.contentOffset.x));
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
        titel.font = [UIFont HTWSmallFont];
        titel.lineBreakMode = NSLineBreakByWordWrapping;
        titel.numberOfLines = 3;
        titel.textColor = [UIColor HTWWhiteColor];
        [_detailView addSubview:titel];
        
        UILabel *dozent = [[UILabel alloc] initWithFrame:CGRectMake(0, _detailView.frame.size.height*4/5-9, _detailView.frame.size.width, _detailView.frame.size.height*2/5)];
        if(buttonPressed.lesson.dozent) dozent.text = [NSString stringWithFormat:@"Dozent: %@", buttonPressed.lesson.dozent];
        dozent.textAlignment = NSTextAlignmentCenter;
        dozent.font = [UIFont HTWVerySmallFont];
        dozent.textColor = [UIColor HTWWhiteColor];
        [_detailView addSubview:dozent];
        
        
        [_scrollView bringSubviewToFront:_detailView];
        
        _detailView.hidden = NO;
    }
    else if (gesture.state == UIGestureRecognizerStateEnded){
        _detailView.hidden = YES;
        buttonPressed.backgroundColor = [UIColor HTWWhiteColor];
        for (UIView *this in buttonPressed.subviews) {
            if([this isKindOfClass:[UILabel class]]) [(UILabel*)this setTextColor:[UIColor HTWDarkGrayColor]];
        }
    }
}

#pragma mark - Hilfsfunktionen

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
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

@end
