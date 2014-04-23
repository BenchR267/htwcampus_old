//
//  HTWViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 23.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWViewController.h"
#import "HTWStundenplanParser.h"

@interface HTWViewController () <StundenplanParserDelegate>

@end

@implementation HTWViewController

-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    StundenplanParser *parser = [[StundenplanParser alloc] initWithMatrikelNummer:@"33886" andRaum:NO];
    [parser parserStart];
}

-(void)stundenplanParserError:(NSString *)errorMessage
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"fehler"
                                                    message:errorMessage
                                                   delegate:nil cancelButtonTitle:@"cancel"
                                          otherButtonTitles: nil];
    [alert show];
}

-(void)stundenplanParserFinished
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"fertig"
                                                    message:@"Fertig"
                                                   delegate:nil cancelButtonTitle:@"cancel"
                                          otherButtonTitles: nil];
    [alert show];
}
@end
