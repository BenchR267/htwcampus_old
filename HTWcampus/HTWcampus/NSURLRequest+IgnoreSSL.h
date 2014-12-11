//
//  NSURLRequest+IgnoreSSL_.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 05.12.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLRequest (IgnoreSSL)

+ (BOOL)allowsAnyHTTPSCertificateForHost:(NSString*)host;

@end
