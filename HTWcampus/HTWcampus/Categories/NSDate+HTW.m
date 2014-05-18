//
//  NSDate+HTW.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 18.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "NSDate+HTW.h"

@implementation NSDate (HTW)


#pragma mark - Class Methods
+(int)getWeekDay
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:[NSDate date]] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

+(NSDate*)getFromString:(NSString*)dateAsString withFormat:(NSString*)format
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:format];
    return [dateF dateFromString:dateAsString];
}


#pragma mark - Instance Methods
-(int)getWeekDay
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSString*)getWeekDayString
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:self] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    switch (weekday) {
        case 0: return @"Montag";
        case 1: return @"Dienstag";
        case 2: return @"Mittwoch";
        case 3: return @"Donnerstag";
        case 4: return @"Freitag";
        case 5: return @"Samstag";
        case 6: return @"Sonntag";
    }
    return @"";
}

-(NSString*)getAsStringWithFormat:(NSString*)formatString
{
    NSDateFormatter *dateF = [[NSDateFormatter alloc] init];
    [dateF setDateFormat:formatString];
    return [dateF stringFromDate:self];
}

-(NSDate*)getDayOnly
{
    NSDateFormatter *dateF = [NSDateFormatter new];
    [dateF setDateFormat:@"dd.MM.yyyy"];
    return [dateF dateFromString:[dateF stringFromDate:self]];
}

@end
