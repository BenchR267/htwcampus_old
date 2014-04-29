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
    
    [erg appendString:[NSString stringWithFormat:@"BEGIN:VCALENDAR\nVERSION:2.0\nPRODID:-//www.htw-dresden.de//iOS//DE\nMETHOD:PUBLISH\n"]];
    
    
    for (Stunde *this in _daten) {
        NSString *titel = [this.titel stringByReplacingOccurrencesOfString:@"," withString:@"\\, "];
        NSString *dozent = [this.dozent stringByReplacingOccurrencesOfString:@"," withString:@"\\, "];
        
        NSString *uuid = [[NSUUID UUID] UUIDString];
        
        [erg appendString:[NSString stringWithFormat:@"BEGIN:VEVENT\nUID:%@\n", uuid]];
        [erg appendString:[NSString stringWithFormat:@"DTSTART:%@T%@Z\n",[self nurTagFromDate:this.anfang], [self nurUhrzeigFromDate:this.anfang]]];
        [erg appendString:[NSString stringWithFormat:@"DTEND:%@T%@Z\n",[self nurTagFromDate:this.ende], [self nurUhrzeigFromDate:this.ende]]];
        [erg appendString:[NSString stringWithFormat:@"LAST-MODIFIED:%@T%@Z\nSEQUENCE:0\nSTATUS:CONFIRMED\n", [self nurTagFromDate:aktDatum], [self nurUhrzeigFromDate:aktDatum]]];
        [erg appendString:[NSString stringWithFormat:@"SUMMARY:%@\nDESCRIPTION:%@\nLOCATION:%@\nEND:VEVENT\n", titel, dozent, this.raum]];
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
