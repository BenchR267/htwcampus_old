//
//  HTWColors.h
//  HTW-App
//
//  Created by Benjamin Herzog on 16.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTWColors : NSObject

@property (nonatomic, strong) UIColor *darkTabBarTint;
@property (nonatomic) UIBarStyle darkNavigationBarStyle;
@property (nonatomic, strong) UIColor *darkNavigationBarTint;
@property (nonatomic, strong) UIColor *darkViewBackground;
@property (nonatomic, strong) UIColor *darkZeitenBackground;
@property (nonatomic, strong) UIColor *darkButtonBackground;
@property (nonatomic, strong) UIColor *darkButtonText;
@property (nonatomic, strong) UIColor *darkCellBackground;
@property (nonatomic, strong) UIColor *darkCellText;
@property (nonatomic, strong) UIColor *darkButtonIsNow;
@property (nonatomic, strong) UIColor *darkButtonBorder;
@property (nonatomic, strong) UIColor *darkButtonBorderIsNow;
@property (nonatomic, strong) UIColor *darkStricheStundenplan;
@property (nonatomic, strong) UIColor *darkTextColor;


-(void)setLight;
-(void)setDark;


@end
