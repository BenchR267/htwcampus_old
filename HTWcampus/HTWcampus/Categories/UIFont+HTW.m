//
//  UIFont+HTW.m
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#define FONT_SIZE_LARGE 21.0
#define FONT_SIZE_BASE 18.0
#define FONT_SIZE_MEDIUM 16.0
#define FONT_SIZE_SMALL 14.0
#define FONT_SIZE_XS 12.0
#define FONT_SIZE_XXS 10.0

#import "UIFont+HTW.h"

@implementation UIFont (HTW)

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wobjc-protocol-method-implementation"

+ (UIFont *)boldSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"PTSans-Bold" size:fontSize];
}

+ (UIFont *)systemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"PTSans-Regular" size:fontSize];
}

+ (UIFont *)italicSystemFontOfSize:(CGFloat)fontSize {
    return [UIFont fontWithName:@"PTSans-Italic" size:fontSize];
}

#pragma clang diagnostic pop

+ (UIFont *)HTWLargeFont {
    return [UIFont fontWithName:@"PTSans-Regular" size:FONT_SIZE_LARGE];
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

#pragma mark Bold Fonts

+ (UIFont *)HTWSmallBoldFont {
    return [UIFont fontWithName:@"PTSans-Bold" size:FONT_SIZE_SMALL];
}

+ (UIFont *)HTWBaseBoldFont {
    return [UIFont fontWithName:@"PTSans-Bold" size:FONT_SIZE_BASE];
}

+ (UIFont *)HTWLargeBoldFont {
    return [UIFont fontWithName:@"PTSans-Bold" size:FONT_SIZE_LARGE];
}

#pragma mark Italic Fonts

+ (UIFont *)HTWSmallItalicFont {
    return [UIFont fontWithName:@"PTSans-Italic" size:FONT_SIZE_SMALL];
}

+ (UIFont *)HTWBaseItalicFont {
    return [UIFont fontWithName:@"PTSans-Italic" size:FONT_SIZE_BASE];
}

+ (UIFont *)HTWLargeItalicFont {
    return [UIFont fontWithName:@"PTSans-Italic" size:FONT_SIZE_LARGE];
}

# pragma mark BoldItalic Fonts

+ (UIFont *)HTWSmallItalicBoldFont {
    return [UIFont fontWithName:@"PTSans-BoldItalic" size:FONT_SIZE_SMALL];
}

#pragma mark Context

+ (UIFont *)HTWTableViewCellFont {
    return [self HTWBaseFont];
}

@end
