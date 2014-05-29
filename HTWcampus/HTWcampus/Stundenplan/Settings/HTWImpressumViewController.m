//
//  HTWImpressumViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 29.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWImpressumViewController.h"
#import <MessageUI/MFMailComposeViewController.h>

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

@interface HTWImpressumViewController () <MFMailComposeViewControllerDelegate>
@property (weak, nonatomic) IBOutlet UITextView *textView;

@end

@implementation HTWImpressumViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor HTWBackgroundColor];
    self.textView.backgroundColor = [UIColor HTWBackgroundColor];
    self.textView.font = [UIFont HTWSmallFont];
    self.textView.textColor = [UIColor HTWTextColor];
    NSString* filePath = [[NSBundle mainBundle] pathForResource:@"Impressum"
                                                         ofType:@"txt"];
    self.textView.text = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
}

- (IBAction)mailButtonPressed:(id)sender {
    MFMailComposeViewController* controller = [[MFMailComposeViewController alloc] init];
    controller.mailComposeDelegate = self;
    [controller setToRecipients:@[@"htwcampusapp@htw-dresden.de"]];
    [controller setSubject:@"[iOS] Feedback HTWcampus"];
    [controller setMessageBody:@"" isHTML:NO];
    if (controller) [self presentViewController:controller animated:YES completion:nil];
}

- (void)mailComposeController:(MFMailComposeViewController*)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError*)error;
{
    if (result == MFMailComposeResultSent) {
        NSLog(@"Mail geschickt!");
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}


@end
