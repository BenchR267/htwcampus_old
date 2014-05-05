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

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

-(void)drawRect:(CGRect)rect {
    _mainLabel.font = _secondaryLabel.font = [UIFont HTWBaseFont];
    _mensaPreisLabel.font = [UIFont HTWVerySmallFont];
    
    _mainLabel.textColor = [UIColor HTWTextColor];
    _secondaryLabel.textColor = [UIColor HTWBlueColor];
    _mensaPreisLabel.textColor = [UIColor HTWBlueColor];
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
