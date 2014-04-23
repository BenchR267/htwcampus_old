//
//  StundenplanSettingsTableViewCell.h
//  University
//
//  Created by Benjamin Herzog on 05.12.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SwitchInStundenplanSettingsTableViewCell.h"


@interface StundenplanSettingsTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet SwitchInStundenplanSettingsTableViewCell *cellSwitch;
@property (weak, nonatomic) IBOutlet UILabel *titelLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;

@property (nonatomic, strong) NSString *ID;

@end
