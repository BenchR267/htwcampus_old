//
//  HTWMensaXMLParser.h
//  HTWcampus
//
//  Created by Konstantin Werner on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HTWMensaXMLParser : NSObject

- (NSArray *)getAllMealsFromHTML:(NSData *)htmlData;
@end
