//
//  UIFont+HTW.h
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIFont (HTW)

+ (UIFont *)HTWExtraLargeFont;
+ (UIFont *)HTWLargeFont;
+ (UIFont *)HTWBaseFont;
+ (UIFont *)HTWSmallFont;
+ (UIFont *)HTWVerySmallFont;
+ (UIFont *)HTWSmallestFont;

+ (UIFont *)HTWSmallBoldFont;
+ (UIFont *)HTWBaseBoldFont;
+ (UIFont *)HTWLargeBoldFont;

+ (UIFont *)HTWSmallItalicFont;
+ (UIFont *)HTWBaseItalicFont;
+ (UIFont *)HTWLargeItalicFont;

+ (UIFont *)HTWSmallItalicBoldFont;

+ (UIFont *)HTWTableViewCellFont;

@end
