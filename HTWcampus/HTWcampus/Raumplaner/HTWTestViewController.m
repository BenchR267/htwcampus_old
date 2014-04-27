//
//  HTWTestViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 27.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWTestViewController.h"
#import "HTWRaumParser.h"

@interface HTWTestViewController () <HTWRaumParserDelegate>

@property (weak, nonatomic) IBOutlet UITextView *textView;

@property HTWRaumParser *parser;
@property (nonatomic, strong) NSDate *vorher;
@property (nonatomic, strong) NSDate *nachher;

@end

@implementation HTWTestViewController

-(void)viewDidLoad
{
    _parser = [[HTWRaumParser alloc] init];
    _parser.delegate = self;
    _vorher = [NSDate date];
    [_parser startParser];
}

-(void)finished
{
    _textView.text = @"";
    for (int i=0; i < _parser.raeumeHeute.count; i++) {
        _textView.text = [NSString stringWithFormat:@"%@Raum: %@\tAnfang: %@\n", _textView.text, _parser.raeumeHeute[i][@"raum"], _parser.raeumeHeute[i][@"anfangDatum"]];
    }
    if(_parser.raeumeHeute.count == 0) _textView.text = @"Momentan sind keine Räume belegt";
    
    
    _nachher = [NSDate date];
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Zeit Parser"
                                                    message:[NSString stringWithFormat:@"%lf sec", [_nachher timeIntervalSinceDate:_vorher]]
                                                   delegate:nil
                                          cancelButtonTitle:@"Ok"
                                          otherButtonTitles:nil];
    [alert show];
}

@end
