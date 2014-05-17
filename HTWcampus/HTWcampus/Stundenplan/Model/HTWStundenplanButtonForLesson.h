//
//  StundenplanButtonForLesson.h
//  University
//
//  Created by Benjamin Herzog on 11.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Stunde.h"

@interface HTWStundenplanButtonForLesson : UIButton

@property (nonatomic, strong) Stunde *lesson;
@property (nonatomic) BOOL portait;
@property (nonatomic) BOOL now;

-(id)initWithLesson:(Stunde *)lessonForButton andPortait:(BOOL)portaitForButton andCurrentDate:(NSDate*)date;

@end
