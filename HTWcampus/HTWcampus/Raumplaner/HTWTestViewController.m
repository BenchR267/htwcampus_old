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

@end

@implementation HTWTestViewController

-(void)viewDidLoad
{
    _parser = [[HTWRaumParser alloc] init];
    _parser.delegate = self;
    [_parser startParser];
}

-(void)finished
{
    _textView.text = @"";
    for (int i=0; i < 30; i++) {
        _textView.text = [NSMutableString stringWithFormat:@"%@Raum: %@\tTag: %@\tAnfang: %@\tEnde: %@\n",_textView.text,_parser.raeume[i][@"raum"],_parser.raeume[i][@"tag"],_parser.raeume[i][@"anfang"],_parser.raeume[i][@"ende"]];
    }
}

@end
