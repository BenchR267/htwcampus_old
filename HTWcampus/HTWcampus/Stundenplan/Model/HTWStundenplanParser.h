//
//  StundenplanParser.h
//  WochenplanMensa
//
//  Created by Benjamin Herzog on 18.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@class HTWStundenplanParser;

@protocol HTWStundenplanParserDelegate

@optional
-(void)HTWStundenplanParserFinished:(HTWStundenplanParser*)parser;
-(void)HTWStundenplanParser:(HTWStundenplanParser*)parser Error:(NSString *)errorMessage;

@end

@interface HTWStundenplanParser : NSObject

@property (nonatomic, strong) NSString *Matrnr;
@property (nonatomic, strong) NSString *name;
@property int tag;

@property (nonatomic, assign) id <HTWStundenplanParserDelegate> delegate;


-(void)parserStart;
-(id)initWithMatrikelNummer:(NSString*)Matrnr andRaum:(BOOL)forRaum;

@end
