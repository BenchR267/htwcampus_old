//
//  MensaXMLParserDelegate.m
//  HTWcampus
//
//  Created by Konstantin on 15.09.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

#import "MensaXMLParserDelegate.h"

//<item>
//    <title>Steak mit pikanter Wurstsoße (2.83 EUR / 4.48 EUR)</title>
//    <description>Rückensteak vom Schwein mit pikanter Wurstsoße und Buttererbsen, dazu Petersilienkartoffeln oder Pommes frites (Studierende: 2.83 EUR / Bedienstete: 4.48 EUR)</description>
//    <guid>http://www.studentenwerk-dresden.de/mensen/speiseplan/details-120074.html</guid>
//    <link>http://www.studentenwerk-dresden.de/mensen/speiseplan/details-120074.html</link>
//    <author>Neue Mensa</author>
//</item>

@interface MensaXMLParserDelegate ()
@property (nonatomic, strong) NSMutableDictionary *currentMeal;
@property (nonatomic, strong) NSString *aktuellesElement;
@property (nonatomic, strong) NSString *aktuellerInhalt;
@end

@implementation MensaXMLParserDelegate
@synthesize delegate;

- (id)init {
    self = [super init];
    if (self) {
        self.allMeals = [[NSMutableArray alloc] init];
        //self.feedList = @[ @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=heute",
        //                   @"http://www.studentenwerk-dresden.de/feeds/speiseplan.rss?tag=morgen"];
    }
    return self;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:@"mensaParsingFinished" object:nil];
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    NSLog(@"Fehler beim Parsen des Mensaplan.");
}
@end
