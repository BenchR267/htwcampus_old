//
//  HTWMensaXMLParser.m
//  HTWcampus
//
//  Created by Konstantin Werner on 14.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMensaXMLParser.h"

@interface HTWMensaXMLParser () <NSXMLParserDelegate>
@property (nonatomic, strong) NSMutableDictionary *currentMeal;
@property (nonatomic, strong) NSString *aktuellesElement;
@property (nonatomic, strong) NSString *aktuellerInhalt;
@property (nonatomic, strong) NSMutableArray *allMeals;
@property (nonatomic, strong) NSXMLParser *xmlParser;
@end

@implementation HTWMensaXMLParser

- (NSArray *)getAllMealsFromHTML:(NSData *)htmlData {
    _allMeals = [[NSMutableArray alloc] init];
    _xmlParser = [[NSXMLParser alloc] initWithData:htmlData];
    _xmlParser.delegate = self;
    if ([_xmlParser parse]) {
        
    };
    return _allMeals;
}

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict {
    if ([elementName isEqualToString:@"item"]) {
        self.currentMeal = [[NSMutableDictionary alloc] init];
        return;
    }
    if (self.currentMeal) {
        self.aktuellesElement = elementName;
        self.aktuellerInhalt = @"";
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName {
    if ([elementName isEqualToString:@"item"]) {
        [self.allMeals addObject:self.currentMeal];
        self.currentMeal = nil;
        return;
    }
    
    //<title> contains both meal name and pricing information
    if ([elementName isEqualToString:@"title"]) {
        if([self.aktuellerInhalt rangeOfString:@"("].length > 0) {
            NSUInteger start = [self.aktuellerInhalt rangeOfString:@"("].location;
            NSString *title = [self.aktuellerInhalt substringToIndex:start];
            title = [title stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            
			NSString *price = [self.self.aktuellerInhalt substringFromIndex:start+1];
			price = [price stringByReplacingOccurrencesOfString:@")" withString:@""];
			price = [price stringByReplacingOccurrencesOfString:@" EUR" withString:@"€"];
            
			NSMutableString *finalPrice = [[NSMutableString alloc] initWithString:price];
			NSUInteger slash = [finalPrice rangeOfString:@"/"].location;
			
			if([finalPrice rangeOfString:@"/"].length > 0)
			{
				[finalPrice insertString:@" Mitarbeiter:" atIndex:slash+1];
				finalPrice = [NSMutableString stringWithFormat:@"%@ %@", @"Studenten:", finalPrice];
			}
			[self.currentMeal setObject:title forKey:@"title"];
			[self.currentMeal setObject:finalPrice forKey:@"price"];
			[self.currentMeal setObject:[NSNumber numberWithBool:YES] forKey:@"show"];
        }
        else {
            NSString *title = [self.aktuellerInhalt stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [self.currentMeal setObject:title forKey:@"title"];
            [self.currentMeal setObject:title forKey:@"desc"];
			[self.currentMeal setObject:@"" forKey:@"price"];
			[self.currentMeal setObject:[NSNumber numberWithBool:YES] forKey:@"show"];
        }
    }
    
    //Cut out the pricing in <description>
    if ([elementName isEqualToString:@"description"]) {
        if ([self.aktuellerInhalt rangeOfString:@"(Stud"].length > 0)
        {
            NSUInteger start = [self.aktuellerInhalt rangeOfString:@"(Stud"].location;
            NSString *description = [self.aktuellerInhalt substringToIndex:start];
            description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [self.currentMeal setObject:description forKey:@"desc"];
        }
        else if ([self.aktuellerInhalt rangeOfString:@"("].length > 0)
        {
            NSUInteger start = [self.aktuellerInhalt rangeOfString:@"("].location;
            NSString *description = [self.aktuellerInhalt substringToIndex:start];
            description = [description stringByReplacingOccurrencesOfString:@"\n" withString:@""];
            [self.currentMeal setObject:description forKey:@"desc"];
        }
    }
    
    if ([elementName isEqualToString:@"author"]) {
        NSString *mensaName = self.aktuellerInhalt;
        mensaName = [mensaName stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        [self.currentMeal setObject:mensaName forKey:@"mensa"];
    }
    
    if ([elementName isEqualToString:@"link"]) {
        NSString *link = self.aktuellerInhalt;
        [self.currentMeal setObject:link forKey:@"link"];
    }
    
    self.aktuellesElement = nil;
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (self.currentMeal) {
        self.aktuellerInhalt = [self.aktuellerInhalt stringByAppendingString:string];
    }
}

-(void)parserDidEndDocument: (NSXMLParser *)parser {
    NSLog(@"Parsen der Mensen erfolgreich beendet");
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"Fehler beim Parsen des Mensaplan.");
}

@end
