//
//  UIFont+HTW.m
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#define FONT_SIZE_BIG 21.0
#define FONT_SIZE_BASE 18.0
#define FONT_SIZE_MEDIUM 16.0
#define FONT_SIZE_SMALL 14.0
#define FONT_SIZE_XS 12.0
#define FONT_SIZE_XXS 10.0

#import "UIFont+HTW.h"

@implementation UIFont (HTW)

+ (UIFont *)HTWBigBaseFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_BIG];
}

+ (UIFont *)HTWBaseFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_BASE];
}

+ (UIFont *)HTWMediumFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_MEDIUM];
}

+ (UIFont *)HTWSmallFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_SMALL];
}

+ (UIFont *)HTWVerySmallFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_XS];
}

+ (UIFont *)HTWSmallestFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_XS];
}

+ (UIFont *)HTWTableViewCellFont {
    return [self HTWBaseFont];
}

@end
