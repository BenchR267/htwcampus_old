//
//  landscapeSegue.m
//  University
//
//  Created by Benjamin Herzog on 30.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "landscapeSegue.h"

@implementation landscapeSegue

-(void) perform
{
    [[[self sourceViewController] navigationController] pushViewController:[self destinationViewController] animated:NO];
}

@end
