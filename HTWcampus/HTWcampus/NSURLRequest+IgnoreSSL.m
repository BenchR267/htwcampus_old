//
//  NSURLRequest+IgnoreSSL_.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 05.12.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "NSURLRequest+IgnoreSSL.h"

@implementation NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host
{
    return YES;
}
    
@end
