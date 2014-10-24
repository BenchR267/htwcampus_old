//
//  HTWCSVParser.h
//  test
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTWCSVParser;

@protocol HTWCSVParserDelegate <NSObject>

@optional
-(void)HTWCSVParserDidFoundError:(NSString*)errorMessage;
-(void)HTWCSVParserFoundNewLine;
-(void)HTWCSVParserFoundCharacters:(NSString*)characters withIndex:(int)index;
-(void)HTWCSVParserDidFinishedWorking:(HTWCSVParser*)parser;

@end

@interface HTWCSVParser : NSObject

@property (nonatomic, strong) id <HTWCSVParserDelegate> delegate;
@property (nonatomic, strong) NSDictionary *ergDict;

-(id)initWithURL:(NSURL*)url;
-(void)startHTWCSVParser;

@end
