//
//  StundenplanButtonForLesson.m
//  University
//
//  Created by Benjamin Herzog on 11.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanButtonForLesson.h"
#import <QuartzCore/QuartzCore.h>
#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define CornerRadius 5

@interface HTWStundenplanButtonForLesson ()
{
    CGFloat height;
    CGFloat width;
    CGFloat x;
    CGFloat y;
    
    float PixelPerMin;
}

@property (nonatomic, strong) UILabel *kurzel;
@property (nonatomic, strong) UILabel *raum;
@property (nonatomic, strong) UILabel *typ;

@end

@implementation HTWStundenplanButtonForLesson

@synthesize lesson,kurzel,raum,typ;

#pragma mark - INIT

-(id)initWithLesson:(Stunde *)lessonForButton andPortait:(BOOL)portaitForButton
{
    self = [super init];
    
    [self setPortait:portaitForButton];
    [self setLesson:lessonForButton];
    return self;
}

#pragma mark - Setter

-(void)setPortait:(BOOL)portait
{
    if (portait) PixelPerMin = 0.5;
    else PixelPerMin = 0.35;
    _portait = portait;
}

-(void)setNow:(BOOL)now
{
    _now = now;
    
    if (lesson.anzeigen) {
        self.backgroundColor = [UIColor HTWBlueColor];
        kurzel.textColor = [UIColor HTWWhiteColor];
        raum.textColor = [UIColor HTWWhiteColor];
        typ.textColor = [UIColor HTWWhiteColor];
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
        if ([self isSameDayWithDate1:lesson.anfang date2:today]) {
            x = 60;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[today dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day2])
        {
            x = 176;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day3])
        {
            x = 292;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day3 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day4])
        {
            x = 408;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day4 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day5])
        {
            x = 524;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day5 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day6])
        {
            x = 641;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day6 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:day7])
        {
            x = 756;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[day7 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
    }
    else {
        
        int weekday = [self weekdayFromDate:[NSDate date]];
        
        NSDateComponents *dayComponent = [[NSDateComponents alloc] init];
        dayComponent.day = 7;
        
        NSCalendar *theCalendar = [NSCalendar currentCalendar];
        
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
        
        if ([self isSameDayWithDate1:lesson.anfang date2:montag]) {
            x = 1;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[montag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:dienstag])
        {
            x = 104;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[dienstag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:mittwoch])
        {
            x = 207;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[mittwoch dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:donnerstag])
        {
            x = 310;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[donnerstag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:freitag])
        {
            x = 413;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[freitag dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:montag2])
        {
            x = 577;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[montag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:dienstag2])
        {
            x = 680;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[dienstag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else if ([self isSameDayWithDate1:lesson.anfang date2:mittwoch2])
        {
            x = 783;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[mittwoch2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:donnerstag2])
        {
            x = 886;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[donnerstag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
        else  if ([self isSameDayWithDate1:lesson.anfang date2:freitag2])
        {
            x = 989;
            y = 54 + (CGFloat)[lesson.anfang timeIntervalSinceDate:[freitag2 dateByAddingTimeInterval:60*60*7+60*30]] / 60 * PixelPerMin;
        }
    }
    self.frame = CGRectMake( x, y, width, height);
    
    self.backgroundColor = [UIColor HTWWhiteColor];
    self.layer.cornerRadius = CornerRadius;
    
    if (!kurzel) kurzel = [[UILabel alloc] init];
    if (!raum) raum = [[UILabel alloc] init];
    if (!typ) typ = [[UILabel alloc] init];
    
    kurzel.text = [lesson.kurzel componentsSeparatedByString:@" "][0];
    if(_portait) kurzel.font = [UIFont HTWBigBaseFont];
    else kurzel.font = [UIFont HTWBaseFont];
    kurzel.textAlignment = NSTextAlignmentLeft;
    kurzel.frame = CGRectMake(x+width*0.02f, y, width*0.98f, height*0.6);
    kurzel.textColor = [UIColor HTWDarkGrayColor];
    
    raum.text = lesson.raum;
    if(_portait) raum.font = [UIFont HTWVerySmallFont];
    else raum.font = [UIFont HTWSmallestFont];
    raum.textAlignment = NSTextAlignmentLeft;
    raum.frame = CGRectMake(x+3, y+(height*0.6), width-6, height*0.4);
    raum.textColor = [UIColor HTWDarkGrayColor];
    
    if([lesson.kurzel componentsSeparatedByString:@" "][1]) {
        typ.text = [lesson.kurzel componentsSeparatedByString:@" "][1];
        if(_portait) typ.font = [UIFont HTWBigBaseFont];
        else typ.font = [UIFont HTWSmallFont];
        typ.textAlignment = NSTextAlignmentRight;
        typ.frame = CGRectMake(x+3, y+(height*0.5), width-6, height*0.4);
        typ.textColor = [UIColor HTWDarkGrayColor];
        [self addSubview:typ];
    }
 
    self.bounds = self.frame;
    [self addSubview:kurzel];
    [self addSubview:raum];
}

#pragma mark - Hilfsfunktionen

- (BOOL)isSameDayWithDate1:(NSDate*)date1 date2:(NSDate*)date2 {
    NSCalendar* calendar = [NSCalendar currentCalendar];
    
    unsigned unitFlags = NSYearCalendarUnit | NSMonthCalendarUnit |  NSDayCalendarUnit;
    NSDateComponents* comp1 = [calendar components:unitFlags fromDate:date1];
    NSDateComponents* comp2 = [calendar components:unitFlags fromDate:date2];
    
    return [comp1 day]   == [comp2 day] &&
    [comp1 month] == [comp2 month] &&
    [comp1 year]  == [comp2 year];
}

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSString *)description
{
    return [NSString stringWithFormat:@"X: %f Y: %f width: %f height: %f stunde: %@", x, y, width, height, lesson.kurzel];
}


@end
