//
//  HTWPruefungsParser.h
//  test
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTWPruefungsParser : NSObject

@property (nonatomic, strong) NSURL *pruefungsSeitenURL;

-(id)initWithURL:(NSURL*)url andImmaJahr:(NSString*)jahr andStudienGruppe:(NSString*)gruppe andBDM:(NSString*)BDM;
-(void)startWithCompletetionHandler:(void(^)(NSArray *erg, NSString *errorMessage))handler;

@end
