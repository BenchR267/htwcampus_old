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
    NSString *string = [NSString stringWithContentsOfURL:[NSURL URLWithString:kURL] encoding:NSASCIIStringEncoding error:nil];
    HTWTabParser *parser = [[HTWTabParser alloc] initWithContent:string];
    parser.delegate = self;
    _raeume = [[NSMutableArray alloc] init];
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
    if ([date compare:earlierDate] == NSOrderedDescending) {
        if ( [date compare:laterDate] == NSOrderedAscending ) {
            return YES;
        }
    }
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

- (NSDate*) dateFromStrings:(NSString *)woche andTag:(NSString*)tag andZeit:(NSString*)zeit
{
    NSDate *erg = [[NSDate alloc] init];
    NSDateFormatter *bildeDatum = [[NSDateFormatter alloc] init];
    [bildeDatum setDateFormat:@"dd.MM.yyyy HH:mm"];
    
    
    if ([woche isEqualToString:@"wö"]) {
        //Ist jede Woche
        erg = [bildeDatum dateFromString:[NSString stringWithFormat:@""]];
    }
    else if ([woche isEqualToString:@"1.Wo"])
    {
        //nur erste Woche
    }
    else if ([woche isEqualToString:@"2.Wo"])
    {
        //nur zweite Woche
    }
    
    return erg;
}

@end
