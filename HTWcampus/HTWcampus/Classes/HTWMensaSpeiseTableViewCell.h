//
//  HTWTableViewCell.h
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTWMensaSpeiseTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *secondaryLabel;
@property (weak, nonatomic) IBOutlet UILabel *mainLabel;
@property (weak, nonatomic) IBOutlet UILabel *mensaPreisLabel;
@end
