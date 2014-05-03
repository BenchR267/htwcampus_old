//
//  notenStartseiteHTMLParser.h
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ElementParser.h"

@interface notenStartseiteHTMLParser : NSObject
@property(nonatomic, retain) NSString *asiToken;

- (NSArray*) parseNotenspiegelFromString: (NSString*)htmlString;
- (NSString*) parseAsiTokenFromString: (NSString*)htmlString;
- (NSMutableArray*) getTableFromHtmlDocument: (DocumentRoot*) root withTablePos: (NSUInteger) tablePos;
- (NSMutableArray*) getClearCellContent: (NSString*) cellContent;
- (int) findFirstString:(NSString *) theString find:(NSString *) search;

@end
