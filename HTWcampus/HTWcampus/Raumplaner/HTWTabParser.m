//
//  HTWTabParser.m
//  test
//
//  Created by Benjamin Herzog on 27.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWTabParser.h"

@implementation HTWTabParser

-(id)initWithContent:(NSString*)parserContent
{
    self = [self init];
    self.parserContent = parserContent;
    return self;
}

-(void)startParser
{
    if (!_parserContent) {
        [_delegate HTWerrorOccured:@"ParserContent ungültig"];
    }
    
    NSArray *lines = [_parserContent componentsSeparatedByString:@"\n"];
    for (int i=5; i<lines.count-3; i++) {
        [_delegate HTWnewLineFound];
        NSArray *teile = [lines[i] componentsSeparatedByString:@"\t"];
        for (NSString *characters in teile) {
            [_delegate HTWfoundCharacters:characters];
        }
    }
    
    [_delegate HTWdocumentEnd];
}

@end
