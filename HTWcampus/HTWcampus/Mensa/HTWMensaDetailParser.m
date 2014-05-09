//
//  HTWMensaDetailParser.m
//  test
//
//  Created by Benjamin Herzog on 09.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMensaDetailParser.h"

@interface HTWMensaDetailParser () <NSXMLParserDelegate>
{
    void (^completition)(NSDictionary* dic, NSString *error);
    
    BOOL inEssenBild;
    BOOL inSpeisePlanDetails;
    BOOL inLi;
}

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSXMLParser *parser;
@property (nonatomic, strong) NSMutableArray *speisedetails;
@property (nonatomic, strong) NSMutableString *tempString;

@property (nonatomic, strong) NSMutableDictionary *infos;

@end

@implementation HTWMensaDetailParser

-(id)initWithURL:(NSURL*)url
{
    self = [self init];
    _url = url;
    _infos = [[NSMutableDictionary alloc] init];
    _speisedetails = [[NSMutableArray alloc] init];
    return self;
}

-(void)parseWithCompletetionHandler:(void(^)(NSDictionary *dic, NSString *errorMessage))handler
{
    completition = handler;

    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:_url] queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        NSString *html = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSRange startRange = [html rangeOfString:@"<div id=\"spalterechtsnebenmenue\">"];
        NSMutableString *dataAfterHtml = [NSMutableString stringWithString:[html substringFromIndex:startRange.location]];
        NSRange endRange = [dataAfterHtml rangeOfString:@"<div id=\"speiseplaninfos\">"];
        dataAfterHtml = [NSMutableString stringWithString:[dataAfterHtml substringToIndex:endRange.location]];
        [dataAfterHtml replaceOccurrencesOfString:@"&" withString:@" und " options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml appendString:@"</div>"];
        
        _parser = [[NSXMLParser alloc] initWithData:[dataAfterHtml dataUsingEncoding:NSUTF8StringEncoding]];
        _parser.delegate = self;
        [_parser parse];
    }];
    
    
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    completition(nil,parseError.localizedDescription);
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"div"] && [attributeDict[@"id"] isEqualToString:@"essenbild"]) {
        inEssenBild = YES;
    }
    else if ([elementName isEqualToString:@"a"] && inEssenBild)
    {
        [_infos setObject:[NSURL URLWithString:attributeDict[@"href"]] forKey:@"bildURL"];
    }
    else if ([elementName isEqualToString:@"div"] && [attributeDict[@"id"] isEqualToString:@"speiseplandetailsrechts"])
    {
        inSpeisePlanDetails = YES;
    }
    else if (inSpeisePlanDetails && [elementName isEqualToString:@"li"])
    {
        inLi = YES;
        _tempString = [NSMutableString new];
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(inLi)
        [_tempString appendString:string];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"div"] && inEssenBild) {
        inEssenBild = NO;
    }
    else if ([elementName isEqualToString:@"div"] && inSpeisePlanDetails) {
        inSpeisePlanDetails = NO;
    }
    else if([elementName isEqualToString:@"li"] && inLi)
    {
        inLi = NO;
        [_speisedetails addObject:_tempString];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    [_infos setObject:_speisedetails forKey:@"speiseDetails"];
    
    [NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:_infos[@"bildURL"]]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
                               UIImage *image = [UIImage imageWithData:data];
                               if(image) [_infos setObject:image forKey:@"Bild"];
                               completition(_infos,nil);
                           }];
}

@end
