//
//  HTWTableViewCell.m
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMensaSpeiseTableViewCell.h"
#import "UIFont+HTW.h"
#import "UIColor+HTW.h"

@implementation HTWMensaSpeiseTableViewCell


-(void)drawRect:(CGRect)rect {
    _mainLabel.font = _secondaryLabel.font = [UIFont HTWBaseFont];
    _mensaPreisLabel.font = [UIFont HTWVerySmallFont];
    
    _mainLabel.textColor = [UIColor HTWTextColor];
    _secondaryLabel.textColor = [UIColor HTWBlueColor];
    _mensaPreisLabel.textColor = [UIColor HTWBlueColor];
}

@end
