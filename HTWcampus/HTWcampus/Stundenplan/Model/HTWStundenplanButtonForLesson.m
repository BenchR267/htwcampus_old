//
//  StundenplanButtonForLesson.m
//  University
//
//  Created by Benjamin Herzog on 11.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanButtonForLesson.h"
#import <QuartzCore/QuartzCore.h>
#import "HTWColors.h"
#define CornerRadius 5

@interface HTWStundenplanButtonForLesson ()
{
    CGFloat height;
    CGFloat width;
    CGFloat x;
    CGFloat y;
    
    float PixelPerMin;
    
    HTWColors *htwColors;
}

@property (nonatomic, strong) UILabel *kurzel;
@property (nonatomic, strong) UILabel *raum;

@end

@implementation HTWStundenplanButtonForLesson

@synthesize lesson,kurzel,raum;

-(id)initWithLesson:(Stunde *)lessonForButton andPortait:(BOOL)portaitForButton
{
    self = [super init];
    htwColors = [[HTWColors alloc] init];
    
    
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    if ([defaults boolForKey:@"hellesDesign"]) {
        [htwColors setLight];
    } else [htwColors setDark];
    
    [self setPortait:portaitForButton];
    [self setLesson:lessonForButton];
    return self;
}

-(void)setPortait:(BOOL)portait
{
    if (portait) PixelPerMin = 0.5;
    else PixelPerMin = 0.37;
    _portait = portait;
}

-(void)setNow:(BOOL)now
{
    _now = now;
    
    if (lesson.anzeigen) {
        self.backgroundColor = htwColors.darkButtonIsNow;
        if(_portait) self.kurzel.font = [UIFont fontWithName:@"Verdana" size:18];
        else self.kurzel.font = [UIFont fontWithName:@"Verdana" size:14];
        self.kurzel.textColor = htwColors.darkTextColor;
        if(_portait) self.raum.font = [UIFont fontWithName:@"Verdana" size:10];
        else self.raum.font = [UIFont fontWithName:@"Verdana" size:8];
        self.raum.textColor = htwColors.darkTextColor;
        
        [[self layer] setBorderWidth:3.0f];
        [[self layer] setBorderColor:htwColors.darkButtonBorderIsNow.CGColor];
    }
}

-(void)setLesson:(Stunde *)lessonForButton
{
    lesson = lessonForButton;
    
    height = (CGFloat)[lesson.ende timeIntervalSinceDate:lesson.anfang] / 60 * PixelPerMin;
    if (_portait) width = 108;
    else width = 90;

    
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    [nurTag setTimeZone:[NSTimeZone defaultTimeZone]];
    
    
    if(_portait){
        NSDate *today = [nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]];
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 1;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
        NSDate *day2 = [theCalendar dateByAddingComponents:dayComponent toDate:today options:0];
        NSDate *day3 = [theCalendar dateByAddingComponents:dayComponent toDate:day2 options:0];
        NSDate *day4 = [theCalendar dateByAddingComponents:dayComponent toDate:day3 options:0];
        NSDate *day5 = [theCalendar dateByAddingComponents:dayComponent toDate:day4 options:0];
        NSDate *day6 = [theCalendar dateByAddingComponents:dayComponent toDate:day5 options:0];
        NSDate *day7 = [theCalendar dateByAddingComponents:dayComponent toDate:day6 options:0];
        
        //Wenn die Stunde heute ist
        if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:today]) {
            x = 78;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[today dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day2])
        {
            x = 194;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day3])
        {
            x = 310;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day3 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day4])
        {
            x = 426;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day4 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day5])
        {
            x = 542;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day5 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day6])
        {
            x = 542+116;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day6 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag dateFromString:[nurTag stringFromDate:lesson.anfang]] isEqual:day7])
        {
            x = 542+116+116;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day7 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
    }
    else {
        
        int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday] - 2;
        if(weekday == -1) weekday=6;
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 7;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
//        dateToBeIncremented = [theCalendar dateByAddingComponents:dayComponent toDate:dateToBeIncremented options:0];
        
        NSDate *montag = [[nurTag dateFromString:[nurTag stringFromDate:[NSDate date]]] dateByAddingTimeInterval:(-60*60*24*weekday) ];
        NSDate *dienstag = [montag dateByAddingTimeInterval:60*60*24];
        NSDate *mittwoch = [dienstag dateByAddingTimeInterval:60*60*24];
        NSDate *donnerstag = [mittwoch dateByAddingTimeInterval:60*60*24];
        NSDate *freitag = [donnerstag dateByAddingTimeInterval:60*60*24];
        
        NSDate *montag2 = [theCalendar dateByAddingComponents:dayComponent toDate:montag options:0];
        NSDate *dienstag2 = [montag2 dateByAddingTimeInterval:60*60*24];
        NSDate *mittwoch2 = [dienstag2 dateByAddingTimeInterval:60*60*24];
        NSDate *donnerstag2 = [mittwoch2 dateByAddingTimeInterval:60*60*24];
        NSDate *freitag2 = [donnerstag2 dateByAddingTimeInterval:60*60*24];
        
        if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:montag]]) {
            x = 1;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[montag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:dienstag]])
        {
            x = 104;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[dienstag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:mittwoch]])
        {
            x = 207;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[mittwoch dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:donnerstag]])
        {
            x = 310;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[donnerstag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:freitag]])
        {
            x = 413;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[freitag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:montag2]])
        {
            x = 577;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[montag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:dienstag2]])
        {
            x = 680;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[dienstag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:mittwoch2]])
        {
            x = 783;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[mittwoch2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:donnerstag2]])
        {
            x = 886;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[donnerstag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([[nurTag stringFromDate:lesson.anfang] isEqualToString:[nurTag stringFromDate:freitag2]])
        {
            x = 989;
            y = 55 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[freitag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
    }
    self.frame = CGRectMake( x, y, width, height);
    
    self.backgroundColor = htwColors.darkZeitenAndButtonBackground;
    self.layer.cornerRadius = CornerRadius;
    
    if (!kurzel) kurzel = [[UILabel alloc] init];
    if (!raum) raum = [[UILabel alloc] init];
    
    kurzel.text = lesson.kurzel;
    if(_portait) kurzel.font = [UIFont systemFontOfSize:20];
    else kurzel.font = [UIFont systemFontOfSize:16];
    kurzel.textAlignment = NSTextAlignmentCenter;
    kurzel.frame = CGRectMake(x, y, width, height*0.6);
    kurzel.textColor = htwColors.darkTextColor;
    
    raum.text = lesson.raum;
    if(_portait) raum.font = [UIFont systemFontOfSize:12];
    else raum.font = [UIFont systemFontOfSize:10];
    raum.textAlignment = NSTextAlignmentCenter;
    raum.frame = CGRectMake(x+3, y+(height*0.6), width-6, height*0.4);
    raum.textColor = htwColors.darkTextColor;
    
    UILabel *anfang = [[UILabel alloc] initWithFrame:raum.frame];
    anfang.textAlignment = NSTextAlignmentLeft;
    anfang.textColor = htwColors.darkTextColor;
    NSDateFormatter *uhrzeit = [[NSDateFormatter alloc] init];
    [uhrzeit setDateFormat:@"HH:mm"];
    anfang.text = [NSString stringWithFormat:@"%@",[uhrzeit stringFromDate:lesson.anfang]];
    if (_portait) anfang.font = [UIFont systemFontOfSize:10];
    else anfang.font = [UIFont systemFontOfSize:8];
    
    UIView *border;
    if (![lesson.bemerkungen isEqualToString:@""] && lesson.bemerkungen != nil) {
        border = [[UIView alloc] initWithFrame:CGRectMake(x+2, y+2, width-4, height-4)];
        [border.layer setBorderColor:[UIColor redColor].CGColor];
        [border.layer setBorderWidth:1.0f];
        border.layer.cornerRadius = 3;
        border.alpha = 0.7;
        border.userInteractionEnabled = NO;
    }
    
    
    UILabel *ende = [[UILabel alloc] initWithFrame:raum.frame];
    ende.textAlignment = NSTextAlignmentRight;
    ende.textColor = htwColors.darkTextColor;
    ende.text = [NSString stringWithFormat:@"%@",[uhrzeit stringFromDate:lesson.ende]];
    if (_portait) ende.font = [UIFont systemFontOfSize:10];
    else ende.font = [UIFont systemFontOfSize:8];
 
    self.bounds = self.frame;
    if(border != nil) [self addSubview:border];
    [self addSubview:anfang];
    [self addSubview:ende];
    [self addSubview:kurzel];
    [self addSubview:raum];
    
    
    
    [[self layer] setBorderWidth:2.0f];
    [[self layer] setBorderColor:htwColors.darkButtonBorder.CGColor];
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"X: %f Y: %f width: %f height: %f", x, y, width, height];
}


@end
