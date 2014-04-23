//
//  HTWColors.m
//  HTW-App
//
//  Created by Benjamin Herzog on 16.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWColors.h"

@implementation HTWColors

-(id)init
{
    self = [super init];
    _darkTabBarTint = [UIColor colorWithRed:27/255.f green:30/255.f blue:37/255.f alpha:0.5];
    _darkNavigationBarTint = [UIColor colorWithRed:0/255.f green:0/255.f blue:0/255.f alpha:0.9];
    _darkNavigationBarStyle = UIBarStyleBlackTranslucent;
    _darkViewBackground = [UIColor colorWithRed:135/255.f green:135/255.f blue:135/255.f alpha:1];
    _darkZeitenAndButtonBackground = [UIColor colorWithRed:37/255.f green:44/255.f blue:54/255.f alpha:1];
    _darkCellBackground = [UIColor colorWithRed:37/255.f green:44/255.f blue:54/255.f alpha:1];
    _darkStricheStundenplan = [UIColor colorWithRed:50/255.f green:58/255.f blue:77/255.f alpha:0.4];
    _darkButtonIsNow = [UIColor colorWithRed:45/255.f green:112/255.f blue:120/255.f alpha:1];
    _darkButtonBorder = [UIColor colorWithRed:65/255.f green:104/255.f blue:111/255.f alpha:1.0f];
    _darkButtonBorderIsNow = [UIColor colorWithRed:67/255.f green:191/255.f blue:181/255.f alpha:1.0f];
    _darkTextColor = [UIColor whiteColor];
    return self;
}

-(void)setLight
{
    _darkTabBarTint = [UIColor colorWithRed:44/255.f green:62/255.f blue:80/255.f alpha:0.5];
    _darkNavigationBarTint = [UIColor colorWithRed:44/255.f green:62/255.f blue:80/255.f alpha:1];
    _darkNavigationBarStyle = UIBarStyleDefault;
    _darkViewBackground = [UIColor colorWithRed:236/255.f green:240/255.f blue:241/255.f alpha:1];
    _darkZeitenAndButtonBackground = [UIColor colorWithRed:54/255.f green:149/255.f blue:196/255.f alpha:0.4];
    _darkCellBackground = [UIColor colorWithRed:236/255.f green:240/255.f blue:241/255.f alpha:1];
    _darkStricheStundenplan = [UIColor colorWithRed:149/255.f green:165/255.f blue:166/255.f alpha:0.4];
    _darkButtonIsNow = [UIColor colorWithRed:102/255.f green:120/255.f blue:250/255.f alpha:0.7];
    _darkButtonBorder = [UIColor colorWithRed:52/255.f green:73/255.f blue:94/255.f alpha:0.5f];
    _darkButtonBorderIsNow = [UIColor colorWithRed:0/255.f green:0/255.f blue:0/255.f alpha:0.5];
    _darkTextColor = [UIColor darkTextColor];
}
-(void)setDark
{
    _darkTabBarTint = [UIColor colorWithRed:27/255.f green:30/255.f blue:37/255.f alpha:0.5];
    _darkNavigationBarTint = [UIColor colorWithRed:0/255.f green:0/255.f blue:0/255.f alpha:0.9];
    _darkNavigationBarStyle = UIBarStyleBlackTranslucent;
    _darkViewBackground = [UIColor colorWithRed:135/255.f green:135/255.f blue:135/255.f alpha:1];
    _darkZeitenAndButtonBackground = [UIColor colorWithRed:37/255.f green:44/255.f blue:54/255.f alpha:1];
    _darkCellBackground = [UIColor colorWithRed:37/255.f green:44/255.f blue:54/255.f alpha:1];
    _darkStricheStundenplan = [UIColor colorWithRed:50/255.f green:58/255.f blue:77/255.f alpha:0.4];
    _darkButtonIsNow = [UIColor colorWithRed:45/255.f green:112/255.f blue:120/255.f alpha:1];
    _darkButtonBorder = [UIColor colorWithRed:65/255.f green:104/255.f blue:111/255.f alpha:1.0f];
    _darkButtonBorderIsNow = [UIColor colorWithRed:67/255.f green:191/255.f blue:181/255.f alpha:1.0f];
    _darkTextColor = [UIColor whiteColor];
}

@end
