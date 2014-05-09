//
//  HTWMensaDetailParser.h
//  test
//
//  Created by Benjamin Herzog on 09.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTWMensaDetailParser : NSObject

-(id)initWithURL:(NSURL*)url;
-(void)parseWithCompletetionHandler:(void(^)(NSDictionary *dic, NSString *errorMessage))handler;

@end
