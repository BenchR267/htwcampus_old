//
//  HTWRaumParser.m
//  test
//
//  Created by Benjamin Herzog on 27.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWRaumParser.h"
#import "HTWTabParser.h"

#define kURL @"http://www2.htw-dresden.de/~rawa/cgi-bin/plan/plan_quelle_app.txt"

@interface HTWRaumParser () <HTWTabParserDelegate>
{
    int stelle;
}

@property (nonatomic, strong) NSMutableDictionary *raum;


@end

@implementation HTWRaumParser

#pragma mark - API

-(void)startParser
{
    [self dateFromStringsWoche:@"wö" andTag:@"2" andZeit:@""];
    
    NSString *string = [NSString stringWithContentsOfURL:[NSURL URLWithString:kURL] encoding:NSASCIIStringEncoding error:nil];
    HTWTabParser *parser = [[HTWTabParser alloc] initWithContent:string];
    parser.delegate = self;
    _raeume = [[NSMutableArray alloc] init];
    _raeumeHeute = [[NSMutableArray alloc] init];
    [parser startParser];
}

#pragma mark - HTWTabParser Delegate

-(void)HTWnewLineFound
{
    _raum = [[NSMutableDictionary alloc] init];
    stelle=0;
}

-(void)HTWfoundCharacters:(NSString *)characters
{
    switch (stelle) {
        case 0: [_raum setObject:characters forKey:@"kuerzel"]; break;
        case 1: [_raum setObject:characters forKey:@"titel"]; break;
        case 2: [_raum setObject:[self getDayNameFrom:characters] forKey:@"tag"];
            [_raum setObject:[NSString stringWithFormat:@"%d",[self getDayNumFromDayName:_raum[@"tag"]]] forKey:@"tagNum"];
            break;
        case 3: [_raum setObject:[self getWeekNameFrom:characters] forKey:@"woche"]; break;
        case 4: [_raum setObject:characters forKey:@"anfang"]; break;
        case 5: [_raum setObject:characters forKey:@"ende"]; break;
        case 6: [_raum setObject:characters forKey:@"raum"]; break;
        case 7: [_raum setObject:characters forKey:@"studiengruppe"];
            
            [_raum setObject:[self dateFromStringsWoche:_raum[@"woche"] andTag:_raum[@"tagNum"] andZeit:_raum[@"anfang"]] forKey:@"anfangDatum"];
            [_raum setObject:[self dateFromStringsWoche:_raum[@"woche"] andTag:_raum[@"tagNum"] andZeit:_raum[@"ende"]] forKey:@"endeDatum"];
//            NSLog(@"raum: %@\tanfang: %@\tende: %@", _raum[@"raum"], _raum[@"anfangDatum"], _raum[@"endeDatum"]);
            
            if ((![self isBetweenDate:[NSDate date] earlyDate:_raum[@"anfangDatum"] andLateDate:_raum[@"endeDatum"]]) && [self isDate1:[NSDate date] onSameDayAsDate2:_raum[@"anfangDatum"]])
                 [_raeumeHeute addObject:_raum];
            
            [_raeume addObject:_raum];
            _raum = nil;
            break;
        default:
            break;
    }
    stelle++;
    if(stelle > 7) stelle = 0;
}

-(void)HTWerrorOccured:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"titel"
                                                    message:errorMessage
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    
    [alert show];
}

-(void)HTWdocumentEnd
{
    NSLog(@"HTWRaumParser finished..");
    [_delegate finished];
}

#pragma mark - Hilfsfunktionen

- (BOOL)isBetweenDate:(NSDate*)date earlyDate:(NSDate *)earlierDate andLateDate:(NSDate *)laterDate
{
    if ([date compare:earlierDate] == NSOrderedDescending && [date compare:laterDate] == NSOrderedAscending)
        return YES;
    return NO;
}

-(NSString*)getDayNameFrom:(NSString*)tag
{
    NSArray *teile = [tag componentsSeparatedByString:@")"];
    return teile[teile.count-1];
}

-(NSString*)getWeekNameFrom:(NSString*)week
{
    NSArray *teile = [week componentsSeparatedByString:@"("];
    teile = [teile[0] componentsSeparatedByString:@" "];
    return teile[0];
}

-(int)getDayNumFromDayName:(NSString*)tag
{
    if ([tag isEqualToString:@"Montag"]) return 0;
    else if ([tag isEqualToString:@"Dienstag"]) return 1;
    else if ([tag isEqualToString:@"Mittwoch"]) return 2;
    else if ([tag isEqualToString:@"Donnerstag"]) return 3;
    else if ([tag isEqualToString:@"Freitag"]) return 4;
    else if ([tag isEqualToString:@"Samstag"]) return 5;
    else if ([tag isEqualToString:@"Sonntag"]) return 6;
    return -1;
}

-(NSDate*)dateFromStringsWoche:(NSString *)woche andTag:(NSString*)tag andZeit:(NSString*)zeit
{
    NSDate *erg;
    NSDateFormatter *bildeDatum = [[NSDateFormatter alloc] init];
    [bildeDatum setDateFormat:@"dd.MM.yyyy HH:mm"];
    [bildeDatum setTimeZone:[NSTimeZone defaultTimeZone]];
    
    int heuteWochentag = [self weekdayFromDate:[NSDate date]];
    BOOL geradeWoche = [self getWeekNumberFromDate:[NSDate date]]%2==0?YES:NO;
    
    
    if ([woche isEqualToString:@"wö"] || ([woche isEqualToString:@"1.Wo"] && geradeWoche) || ([woche isEqualToString:@"2.Wo"] && !geradeWoche)) {
        //Ist jede Woche
        
        NSString *dd = [NSString stringWithFormat:@"%ld",(long)[[[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:[NSDate date]] day]];
        NSString *MM = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:[NSDate date]] month]];
        NSString *yyyy = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year]];
        erg = [bildeDatum dateFromString:[NSString stringWithFormat:@"%@.%@.%@ %@",dd,MM,yyyy, zeit]];
        erg = [self addDays:-heuteWochentag toDate:erg];
        erg = [self addDays:tag.intValue toDate:erg];
    }
    else if ([woche isEqualToString:@"1.Wo"] && !geradeWoche)
    {
        //nur erste Woche
        NSString *dd = [NSString stringWithFormat:@"%ld",(long)[[[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:[NSDate date]] day]];
        NSString *MM = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:[NSDate date]] month]];
        NSString *yyyy = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year]];
        erg = [bildeDatum dateFromString:[NSString stringWithFormat:@"%@.%@.%@ %@",dd,MM,yyyy, zeit]];
        erg = [self addDays:-heuteWochentag toDate:erg];
        erg = [self addDays:tag.intValue toDate:erg];
        erg = [self addDays:7 toDate:erg];
    }
    else if ([woche isEqualToString:@"2.Wo"] && geradeWoche)
    {
        //nur zweite Woche
        NSString *dd = [NSString stringWithFormat:@"%ld",(long)[[[NSCalendar currentCalendar] components:NSDayCalendarUnit fromDate:[NSDate date]] day]];
        NSString *MM = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSMonthCalendarUnit fromDate:[NSDate date]] month]];
        NSString *yyyy = [NSString stringWithFormat:@"%ld", (long)[[[NSCalendar currentCalendar] components:NSYearCalendarUnit fromDate:[NSDate date]] year]];
        erg = [bildeDatum dateFromString:[NSString stringWithFormat:@"%@.%@.%@ %@",dd,MM,yyyy, zeit]];
        erg = [self addDays:-heuteWochentag toDate:erg];
        erg = [self addDays:tag.intValue toDate:erg];
        erg = [self addDays:7 toDate:erg];
    }
    else erg = [bildeDatum dateFromString:[NSString stringWithFormat:@"01.01.1970 %@", zeit]];
    
    if(!erg) {
        erg = [bildeDatum dateFromString:[NSString stringWithFormat:@"01.01.1970 %@", zeit]];
        NSLog(@"'%@' '%@' '%@'", woche, tag, zeit);
    }
    
    return erg;
}

-(NSDate*)nurTagFromDate:(NSDate*)date
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    return [nurTag dateFromString:[nurTag stringFromDate:date]];
}

-(BOOL)isDate1:(NSDate*)date1 onSameDayAsDate2:(NSDate*)date2
{
    return ([[self nurTagFromDate:date1] compare:[self nurTagFromDate:date2]] == NSOrderedSame);
}

-(int)getWeekNumberFromDate:(NSDate*)date
{
    NSCalendar *calender = [NSCalendar currentCalendar];
    
    return (int)[[calender components:NSWeekOfYearCalendarUnit fromDate:date] weekOfYear];
}

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSDate*)addDays:(int)day toDate:(NSDate*)date
{
    if(!date) return date;
    NSCalendar *calender = [NSCalendar currentCalendar];
    NSDateComponents *components = [[NSDateComponents alloc] init];
    components.day = day;
    NSDate *erg = [calender dateByAddingComponents:components toDate:date options:0];
    
    return erg;
}

@end
