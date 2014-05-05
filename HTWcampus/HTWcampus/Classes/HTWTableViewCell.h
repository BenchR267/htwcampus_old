//
//  HTWTableViewCell.h
//  HTWcampus
//
//  Created by Konstantin Werner on 05.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTWTableViewCell : UITableViewCell
@property (weak, nonatomic) IBOutlet UILabel *openingsLabel;
@property (weak, nonatomic) IBOutlet UILabel *mensaName;
@property (weak, nonatomic) IBOutlet UILabel *mensaPreisLabel;
@end
