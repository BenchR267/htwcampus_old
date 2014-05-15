//
//  HTWCSVParser.h
//  test
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTWCSVConnection;

@protocol HTWCSVConnectionDelegate <NSObject>

@optional
-(void)HTWCSVConnectionFinished:(HTWCSVConnection*)connection;
-(void)HTWCSVConnection:(HTWCSVConnection*)connection Error:(NSString*)errorMessage;

@end

@interface HTWCSVConnection : NSObject

@property (nonatomic, strong) id <HTWCSVConnectionDelegate> delegate;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, strong) NSString *eName;

-(id)initWithPassword:(NSString*)password;
-(void)startParser;

@end
