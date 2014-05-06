//
//  HTWMensaWebViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 06.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMensaWebViewController.h"

@interface HTWMensaWebViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;

@end

@implementation HTWMensaWebViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.title = _titleString;
    NSURLRequest *request = [NSURLRequest requestWithURL:_detailURL];
    [_webView loadRequest:request];
}
- (IBAction)openSafariPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:_detailURL];
}

@end
