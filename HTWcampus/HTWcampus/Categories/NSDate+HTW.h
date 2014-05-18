//
//  NSDate+HTW.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 18.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (HTW)

+(int)getWeekDay;
+(NSDate*)getFromString:(NSString*)dateAsString withFormat:(NSString*)format;

-(int)getWeekDay;
-(NSString*)getWeekDayString;
-(NSString*)getAsStringWithFormat:(NSString*)formatString;
-(NSDate*)getDayOnly;

@end
