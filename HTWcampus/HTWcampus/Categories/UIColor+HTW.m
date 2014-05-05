//
//  UIColor+HTW.m
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "UIColor+HTW.h"

@implementation UIColor (HTW)

#pragma mark Base Colors
+ (UIColor *) HTWBlueColor {
    return [UIColor colorWithRed:58.0f/255.0f green:121.0f/255.0f blue:162.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWRedColor {
    return [UIColor colorWithRed:197.0f/255.0f green:79.0f/255.0f blue:52.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWDarkGrayColor {
    return [UIColor colorWithRed:115.0f/255.0f green:113.0f/255.0f blue:111.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWGrayColor {
    return [UIColor colorWithRed:181.0f/255.0f green:178.0f/255.0f blue:175.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWSandColor {
    return [UIColor colorWithRed:247/255.0f green:244.0f/255.0f blue:239.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWWhiteColor {
    return [UIColor colorWithRed:255/255.0f green:255.0f/255.0f blue:255.0f/255.0f alpha:1.0f];
}

+ (UIColor *) HTWDarkBlueColor {
    return [UIColor colorWithRed:65/255.f green:104/255.f blue:111/255.f alpha:1.0f];
}

#pragma mark Context

+ (UIColor *) HTWBackgroundColor {
    return [self HTWSandColor];
}

+ (UIColor *) HTWTextColor {
    return [self HTWDarkGrayColor];
}

+ (UIColor *) HTWTextInactiveColor {
    return [self HTWGrayColor];
}

@end
