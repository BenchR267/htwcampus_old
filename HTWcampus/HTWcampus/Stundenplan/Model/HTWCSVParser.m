//
//  HTWCSVParser.m
//  test
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWCSVParser.h"

@interface HTWCSVParser ()

@property (nonatomic, strong) NSURL *parseURL;
@property (nonatomic, strong) NSString *parseString;
@property (nonatomic, strong) NSMutableArray *keys;

@end

@implementation HTWCSVParser


-(id)initWithURL:(NSURL*)url
{
    self = [self init];
    _parseURL = url;
    _ergDict = [[NSDictionary alloc] init];
    _keys = [[NSMutableArray alloc] init];
    return self;
}

-(void)startHTWCSVParser
{
    NSError *error;
    _parseString = [NSString stringWithContentsOfURL:_parseURL encoding:NSASCIIStringEncoding error:&error];
    if (error) 
        [_delegate HTWCSVParserDidFoundError:[error localizedDescription]];
    
    NSArray *lines = [_parseString componentsSeparatedByString:@"\r"];
    NSArray *parts = [lines[0] componentsSeparatedByString:@","];
    for (NSString *this in parts) {
        NSString *erg = [this stringByReplacingOccurrencesOfString:@"\"" withString:@""];
        [_keys addObject:erg];
    }
    
    
    
    
    for (int i = 1; i < lines.count; i++) {
        [_delegate HTWCSVParserFoundNewLine];
        NSArray *parts = [lines[i] componentsSeparatedByString:@","];
        for (int j = 0; j < 21; j++) {
            NSString *erg = [parts[j] stringByReplacingOccurrencesOfString:@"\"" withString:@""];
            if([erg isEqualToString:@""]) erg = @" ";
            [_delegate HTWCSVParserFoundCharacters:erg withIndex:j];
        }
    }
    
    [_delegate HTWCSVParserDidFinishedWorking:self];
}

@end