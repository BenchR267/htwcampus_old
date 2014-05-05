//
//  SwitchInStundenplanSettingsTableViewCell.m
//  University
//
//  Created by Benjamin Herzog on 05.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWSwitchInStundenplanSettingsUebersichtTableViewCell.h"
#import "UIColor+HTW.h"

@implementation HTWSwitchInStundenplanSettingsUebersichtTableViewCell

-(void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    self.thumbTintColor = [UIColor HTWWhiteColor];
    self.onTintColor = [UIColor HTWBlueColor];
}

@end
