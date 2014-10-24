//
//  HTWNeueStudiengruppe.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTWNeueStudiengruppe : UITableViewController

@property (weak, nonatomic) IBOutlet UITextField *jahrTextField;
@property (weak, nonatomic) IBOutlet UITextField *gruppeTextField;
@property (weak, nonatomic) IBOutlet UIPickerView *BDMPicker;

@end
