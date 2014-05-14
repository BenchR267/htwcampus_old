//
//  HTWPruefungsParser.m
//  test
//
//  Created by Benjamin Herzog on 12.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWPruefungsParser.h"
#import "HTWAppDelegate.h"

@interface HTWPruefungsParser () <NSXMLParserDelegate>
{
    void (^completion)(NSArray* erg, NSString *error);
    
    NSString* jahr;
    NSString* gruppe;
    NSString *BDM;
    
    NSString* dozent;
    
    BOOL dozentB;
    
    int nummerTR;
    int nummerTD;
    BOOL isInTD;
}

@property (nonatomic, strong) NSXMLParser *parser;

@property (nonatomic, strong) NSMutableArray *pruefungenArray;
@property (nonatomic, strong) NSMutableDictionary *pruefungDic;
@property (nonatomic, strong) NSMutableString *stringFound;

@property (nonatomic, strong) NSArray *keys;

@end

@implementation HTWPruefungsParser


-(id)initWithURL:(NSURL*)url andImmaJahr:(NSString*)ejahr andStudienGruppe:(NSString*)egruppe andBDM:(NSString*)eBDM
{
    if(self = [self init])
    {
        self.pruefungsSeitenURL = url;
        jahr = ejahr;
        gruppe = egruppe;
        BDM = eBDM;
        dozentB = NO;
        
        _pruefungenArray = [[NSMutableArray alloc] init];
        _pruefungDic = [[NSMutableDictionary alloc] init];
        
        _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    }
    return self;
}

-(id)initWithURL:(NSURL*)url andDozent:(NSString*)edozent
{
    if(self = [self init])
    {
        self.pruefungsSeitenURL = url;
        if(edozent){
            NSMutableString *dozentUmlaut = [NSMutableString stringWithString:edozent];
            [dozentUmlaut replaceOccurrencesOfString:@"ü"
                                          withString:@"%FC"
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, edozent.length)];
            [dozentUmlaut replaceOccurrencesOfString:@"ä"
                                          withString:@"%E4"
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, edozent.length)];
            [dozentUmlaut replaceOccurrencesOfString:@"ö"
                                          withString:@"%F6"
                                             options:NSCaseInsensitiveSearch
                                               range:NSMakeRange(0, edozent.length)];
            dozent = dozentUmlaut;
        }
        else dozent = @" ";
        dozentB = YES;
        
        _pruefungenArray = [[NSMutableArray alloc] init];
        _pruefungDic = [[NSMutableDictionary alloc] init];
        
        _keys = @[@"Fakultät",@"Studiengang",@"Jahr/Semester",@"Abschluss",@"Studienrichtung",@"Modul",@"Art",@"Tag",@"Zeit",@"Raum",@"Prüfender",@"Nächste WD"];
    }
    return self;
}

-(void)startWithCompletetionHandler:(void(^)(NSArray *erg, NSString *errorMessage))handler
{
    completion = handler;
    
    // Request String für PHP-Argumente
    NSString *myRequestString;
    if(!dozentB)
        myRequestString = [NSString stringWithFormat:@"was=1&feld1=%@&feld2=%@&feld3=%@", jahr, gruppe, BDM];
    else
        myRequestString = [NSString stringWithFormat:@"was=3&feld1=%s", dozent.UTF8String];
    
    
    NSData *myRequestData = [myRequestString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:NO];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:_pruefungsSeitenURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];
    
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    
    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if(connectionError) { NSLog(@"%@", connectionError.localizedDescription); return;}
        
        NSMutableString *html = [[NSMutableString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        
        NSRange startRange = [html rangeOfString:@"</h2>"];
        NSMutableString *dataAfterHtml = [NSMutableString stringWithString:[html substringFromIndex:startRange.location + @"</h2>\n".length]];
        NSRange endRange = [dataAfterHtml rangeOfString:@"</table>"];
        dataAfterHtml = [NSMutableString stringWithString:[dataAfterHtml substringToIndex:endRange.location]];
        [dataAfterHtml appendString:@"</table>"];
        [dataAfterHtml replaceOccurrencesOfString:@"&nbsp;" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"<br>" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"&" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"\n" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@"<table border cellpadding=5>" withString:@"<table>" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];
        [dataAfterHtml replaceOccurrencesOfString:@" nowrap" withString:@"" options:NSCaseInsensitiveSearch range:NSMakeRange(0, dataAfterHtml.length)];

        NSData *dataForParser = [dataAfterHtml dataUsingEncoding:NSUTF8StringEncoding];
        
        _parser = [[NSXMLParser alloc] initWithData:dataForParser];
        _parser.delegate = self;
        [_parser parse];
        [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
    }];
}

-(void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"%@",parseError.localizedDescription);
}

-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"td"])
    {
        isInTD = YES;
        
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    if(isInTD) [_stringFound appendString:string];
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"tr"])
    {
        nummerTR++;
        nummerTD = 0;
        [_pruefungenArray addObject:_pruefungDic];
        _pruefungDic = [NSMutableDictionary new];
    }
    else if ([elementName isEqualToString:@"td"])
    {
        isInTD = NO;
        nummerTD++;
        if(_stringFound.length > 0) [_pruefungDic setObject:_stringFound forKey:_keys[nummerTD-1]];
        else [_pruefungDic setObject:@" " forKey:_keys[nummerTD - 1]];
        _stringFound = [NSMutableString new];
    }
}

-(void)parserDidEndDocument:(NSXMLParser *)parser
{
    completion(_pruefungenArray,nil);
}

@end
