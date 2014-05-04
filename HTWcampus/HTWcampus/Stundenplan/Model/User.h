//
//  User.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 04.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@class Stunde;

@interface User : NSManagedObject

@property (nonatomic, retain) NSNumber * dozent;
@property (nonatomic, retain) NSDate * letzteAktualisierung;
@property (nonatomic, retain) NSString * matrnr;
@property (nonatomic, retain) NSString * name;
@property (nonatomic, retain) NSNumber * raum;
@property (nonatomic, retain) NSSet *stunden;
@end

@interface User (CoreDataGeneratedAccessors)

- (void)addStundenObject:(Stunde *)value;
- (void)removeStundenObject:(Stunde *)value;
- (void)addStunden:(NSSet *)values;
- (void)removeStunden:(NSSet *)values;

@end
