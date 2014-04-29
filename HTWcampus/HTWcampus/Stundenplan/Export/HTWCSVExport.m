//
//  HTWCSVExport.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 29.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWCSVExport.h"
#import "Stunde.h"

@interface HTWCSVExport ()

@property (nonatomic, strong) NSArray *daten;
@property (nonatomic, strong) NSString *MatrNr;

@end

@implementation HTWCSVExport

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
    NSString *filePath = [docsPath stringByAppendingPathComponent:[NSString stringWithFormat:@"Stundenplan_%@.csv", _MatrNr]];
    NSURL *fileUrl     = [NSURL fileURLWithPath:filePath];
    
    NSError *error = nil;
    [[self getCSVString] writeToURL:fileUrl atomically:YES encoding:NSUTF8StringEncoding error:&error];
    if (error) {
        NSLog(@"Error while writing to File: %@", [error localizedDescription]);
    }
    
    return fileUrl;
}

-(NSString*)getCSVString
{
    NSMutableString *erg = [[NSMutableString alloc] init];
    
    [erg appendString:@"Subject;Start Date;Start Time;End Date;End Time;Description;Location\n"];
    
    
    for (Stunde *this in _daten) {
        [erg appendString:[NSString stringWithFormat:@"%@;%@;%@;%@;%@;%@ %@;%@\n", this.kurzel, [self nurTagFromDate:this.anfang], [self nurUhrzeigFromDate:this.anfang],
                           [self nurTagFromDate:this.ende], [self nurUhrzeigFromDate:this.ende], this.titel, this.dozent, this.raum]];
    }
    return (NSString*)erg;
}

-(NSString*)nurTagFromDate:(NSDate*)date
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"dd.MM.yyyy"];
    return [nurTag stringFromDate:date];
}

-(NSString*)nurUhrzeigFromDate:(NSDate*)date
{
    NSDateFormatter *nurTag = [[NSDateFormatter alloc] init];
    [nurTag setDateFormat:@"HH:mm:ss"];
    return [nurTag stringFromDate:date];
}

@end