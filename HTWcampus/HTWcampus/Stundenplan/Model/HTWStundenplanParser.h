//
//  StundenplanParser.h
//  WochenplanMensa
//
//  Created by Benjamin Herzog on 18.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol HTWStundenplanParserDelegate

@optional
-(void)HTWStundenplanParserFinished;
-(void)HTWStundenplanParserError:(NSString *)errorMessage;

@end

@interface HTWStundenplanParser : NSObject

@property (nonatomic, strong) NSString *Matrnr;

@property (nonatomic, assign) id <HTWStundenplanParserDelegate> delegate;


-(void)parserStart;
-(id)initWithMatrikelNummer:(NSString*)Matrnr andRaum:(BOOL)forRaum;

@end
