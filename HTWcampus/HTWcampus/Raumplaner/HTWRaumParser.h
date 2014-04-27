//
//  HTWRaumParser.h
//  test
//
//  Created by Benjamin Herzog on 27.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTWRaumParserDelegate <NSObject>

@optional
-(void)finished;

@end

@interface HTWRaumParser : NSObject

@property (nonatomic, strong) NSMutableArray *raeume;
@property (nonatomic, strong) NSMutableArray *raeumeHeute;
@property id <HTWRaumParserDelegate> delegate;

-(void)startParser;

@end
