//
//  StundenplanParser.h
//  WochenplanMensa
//
//  Created by Benjamin Herzog on 18.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol StundenplanParserDelegate

@optional
-(void)stundenplanParserFinished;
-(void)stundenplanParserError:(NSString *)errorMessage;

@end

@interface StundenplanParser : NSObject

@property (nonatomic, strong) NSString *Matrnr;

@property (nonatomic, assign) id <StundenplanParserDelegate> delegate;


-(void)parserStart;
-(id)initWithMatrikelNummer:(NSString*)Matrnr andRaum:(BOOL)forRaum;

@end
