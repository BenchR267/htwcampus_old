//
//  HTWCSVParser.h
//  test
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTWCSVConnectionDelegate <NSObject>

@optional
-(void)HTWCSVConnectionFinished;

@end

@interface HTWCSVConnection : NSObject

@property (nonatomic, strong) id <HTWCSVConnectionDelegate> delegate;

-(id)initWithPassword:(NSString*)password;
-(void)startParser;

@end
