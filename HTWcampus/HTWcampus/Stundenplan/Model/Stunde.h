//
//  Stunde.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 23.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Student;

@interface Stunde : NSManagedObject

@property (nonatomic, retain) NSDate * anfang;
@property (nonatomic, retain) NSNumber * anzeigen;
@property (nonatomic, retain) NSString * bemerkungen;
@property (nonatomic, retain) NSString * dozent;
@property (nonatomic, retain) NSDate * ende;
@property (nonatomic, retain) NSString * id;
@property (nonatomic, retain) NSString * kurzel;
@property (nonatomic, retain) NSString * raum;
@property (nonatomic, retain) NSString * titel;
@property (nonatomic, retain) Student *student;

@end
