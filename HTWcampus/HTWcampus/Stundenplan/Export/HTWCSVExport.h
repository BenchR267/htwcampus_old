//
//  HTWCSVExport.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 29.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTWCSVExport : NSObject

@property (nonatomic, strong) NSString *MatrNr;

-(id)initWithArray:(NSArray*)array andMatrNr:(NSString*)MatrNr;
-(NSURL*)getFileUrl;

@end
