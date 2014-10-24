//
//  HTWICSExport.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 29.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWICSExport.h"
#import "Stunde.h"

@interface HTWICSExport ()

@property (nonatomic, strong) NSArray *daten;
@property (nonatomic, strong) NSString *MatrNr;

@end

@implementation HTWICSExport

-(id)initWithArray:(NSArray*)array andMatrNr:(NSString*)MatrNr
{
    self = [self init];
    self.daten = array;
    self.MatrNr = MatrNr;
    return self;
}

-(NSURL*)getFileUrl
{
    NSString *docsPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSString *filePath = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Stundenplan-%@.ics", _MatrNr]];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    
    NSError *error = nil;
    [[self getICSData] writeToURL:fileUrl atomically:YES];
    if (error) {
        NSLog(@"Error while writing to File: %@", [error localizedDescription]);
    }
    
    return fileUrl;
}

-(NSData*)getICSData
{
    NSMutableString *erg = [[NSMutableString alloc] init];
    NSDate *aktDatum = [NSDate date];
    
    [erg appendString:[NSString stringWithFormat:@"BEGIN:VCALENDAR\r\nVERSION:2.0\r\nPRODID:-//www.htw-dresden.de//iOS//DE\r\nMETHOD:PUBLISH\r\n"]];
    
    
    for (Stunde *this in _daten) {
        NSString *titel = [this.titel stringByReplacingOccurrencesOfString:@"," withString:@"\\, "];
        NSString *dozent = [this.dozent stringByReplacingOccurrencesOfString:@"," withString:@"\\, "];
        
        NSString *uuid = [[NSUUID UUID] UUIDString];
        
        [erg appendString:[NSString stringWithFormat:@"BEGIN:VEVENT\r\nUID:%@\r\n", uuid]];
        [erg appendString:[NSString stringWithFormat:@"DTSTART;TZID=Europe/Berlin:%@T%@\r\n",[self nurTagFromDate:this.anfang], [self nurUhrzeigFromDate:this.anfang]]];
        [erg appendString:[NSString stringWithFormat:@"DTEND;TZID=Europe/Berlin:%@T%@\r\n",[self nurTagFromDate:this.ende], [self nurUhrzeigFromDate:this.ende]]];
        [erg appendString:[NSString stringWithFormat:@"LAST-MODIFIED:%@T%@Z\r\nSEQUENCE:0\r\nSTATUS:CONFIRMED\r\n", [self nurTagFromDate:aktDatum], [self nurUhrzeigFromDate:aktDatum]]];
        [erg appendString:[NSString stringWithFormat:@"SUMMARY:%@\r\nDESCRIPTION:%@\r\nLOCATION:%@\r\nEND:VEVENT\r\n", titel, dozent, this.raum]];
    }
    
    [erg appendString:@"END:VCALENDAR"];
    
    NSData *ret = [erg dataUsingEncoding:NSUTF8StringEncoding];
    
    return ret;
}

-(NSString*)nurTagFromDate:(NSDate*)date
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"yyyyMMdd"];
    return [nurTag stringFromDate:date];
}

-(NSString*)nurUhrzeigFromDate:(NSDate*)date
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"HHmmss"];
    return [nurTag stringFromDate:date];
}

@end