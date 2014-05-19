//
//  notenViewController.h
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HTWNotenStartseiteHTMLParser.h"

@interface NSURLRequest(Private)
+(void)setAllowsAnyHTTPSCertificate:(BOOL)inAllow forHost:(NSString *)inHost;
@end

@interface HTWNotenTableViewController : UITableViewController <UITextFieldDelegate> {
    bool isLoading;
    float notendurchschnitt;
    
    NSString *username;
    NSString *password;
}
@property (strong, nonatomic) NSArray *notenspiegel;

- (IBAction)reloadNotenspiegel:(id)sender;
- (void)showLoginPopup;
- (float)calculateAverageGradeFromNotenspiegel: (NSArray *)notenspiegel;
@end
