//
//  HTWTabParser.h
//  test
//
//  Created by Benjamin Herzog on 27.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTWTabParserDelegate <NSObject>

@required
-(void)HTWnewLineFound;
-(void)HTWfoundCharacters:(NSString*)characters;
-(void)HTWdocumentEnd;
-(void)HTWerrorOccured:(NSString*)errorMessage;

@end

@interface HTWTabParser : NSObject

@property NSString *parserContent;
@property id <HTWTabParserDelegate> delegate;

-(id)initWithContent:(NSString*)parserContent;
-(void)startParser;

@end
