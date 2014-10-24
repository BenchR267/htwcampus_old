//
//  HTWPruefungSettingsViewController.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 28.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol HTWPruefungsSettingsDelegate <NSObject>

@optional
-(void)HTWPruefungsSettingsDone;

@end

@interface HTWPruefungSettingsViewController : UIViewController

@property (nonatomic, strong) id <HTWPruefungsSettingsDelegate> delegate;

@end
