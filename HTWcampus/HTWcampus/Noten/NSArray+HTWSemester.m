//
//  NSArray+HTWSemester.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 08.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "NSArray+HTWSemester.h"

@implementation NSArray (HTWSemester)


- (NSComparisonResult)compareSemester:(NSArray*)otherSemester {
    NSString *semester = [[otherSemester objectAtIndex:0] objectForKey:@"semester"];
    NSString *jahr = [semester componentsSeparatedByString:@" "][1];
    NSLog(@"%@ und %@", (NSString*)[(NSString*)[self[0] objectForKey:@"semester"] componentsSeparatedByString:@" "][1], jahr);
    return ![(NSString*)[(NSString*)[self[0] objectForKey:@"semester"] componentsSeparatedByString:@" "][1] compare:jahr];
}

@end
