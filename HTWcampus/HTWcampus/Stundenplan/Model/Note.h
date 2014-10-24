//
//  Note.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 20.08.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface Note : NSManagedObject

@property (nonatomic, retain) NSNumber * nr;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSString * semester;
@property (nonatomic, retain) NSNumber * note;
@property (nonatomic, retain) NSString * status;
@property (nonatomic, retain) NSNumber * credits;
@property (nonatomic, retain) NSNumber * versuch;

@end
