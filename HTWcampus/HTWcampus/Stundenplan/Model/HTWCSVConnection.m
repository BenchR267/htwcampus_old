//
//  HTWCSVParser.m
//  test
//
//  Created by Benjamin Herzog on 02.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWCSVConnection.h"
#import "HTWCSVParser.h"
#import "User.h"
#import "Stunde.h"
#import "HTWAppDelegate.h"

#define kURL [NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_kal.php"]

@interface HTWCSVConnection () <HTWCSVParserDelegate>

@property (nonatomic, strong) NSString *name;

@property (nonatomic, strong) NSString *stringToParse;

@property (nonatomic, strong) NSMutableArray *array;
@property (nonatomic, strong) Stunde *stunde;
@property (nonatomic, strong) User *student;
@property (nonatomic, strong) NSManagedObjectContext *context;

@property (nonatomic, strong) NSMutableString *anfang;
@property (nonatomic, strong) NSMutableString *ende;

@end

@implementation HTWCSVConnection

-(id)initWithPassword:(NSString*)password
{
    self = [self init];
    
    _password = password;
    _array = [[NSMutableArray alloc] init];
    _context = [[HTWAppDelegate alloc] managedObjectContext];
    
    
    return self;
}

-(void)startParser
{
    
    // Request String für PHP-Argumente
    NSString *myRequestString = [NSString stringWithFormat:@"unix=%@&pressme=%@",_password,@"S+T+A+R+T"];
    
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:kURL
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];
    
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
//    [request setValue:@"4" forHTTPHeaderField:@"w1"];

    
    // Connection mit dem oben definierten Request
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError) NSLog(@"ERROR: %@", [connectionError localizedDescription]);
        else {
            NSString *html = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            
            if ([html rangeOfString:@"Falsche Kennung"].length != 0) {
                [_delegate HTWCSVConnectionError:@"Falsche Kennung"];
                return;
            }
            
            NSRange startRange = [html rangeOfString:@"<b>"];
            NSString *name = [html substringFromIndex:startRange.location+3];
            
            NSRange endRange = [name rangeOfString:@"</b>"];
            _name = [name substringToIndex:endRange.location];
            
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<form name=Testform method=post action=\\.\\.\\/plan\\/([^>]*)>" options:0 error:nil];
            NSTextCheckingResult *result = [regex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
            if(result) {
                NSRange range = [result rangeAtIndex:1];
                NSString *filename = [html substringWithRange:range];
                NSString *fileURL = [NSString stringWithFormat:@"http://www2.htw-dresden.de/~rawa/cgi-bin/plan/%@", filename];
                
                NSFetchRequest *request = [[NSFetchRequest alloc] init];
                [request setEntity:[NSEntityDescription entityForName:@"User"
                                               inManagedObjectContext:_context]];
                
                NSPredicate *pred =[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.password];
                [request setPredicate:pred];
                
                NSMutableArray *objects = [NSMutableArray arrayWithArray:[_context executeFetchRequest:request
                                                                                                 error:nil]];
                
                // Dürfte nur ein Ergebnis haben
                for (User *this in objects) {
                    for (Stunde *aktuell in this.stunden) {
                        [_context deleteObject:aktuell];
                    }
                }
                [_context save:nil];
                
                if ([objects count] != 0) {
                    _student = objects[0];
                }
                else {
                    _student = [NSEntityDescription
                                insertNewObjectForEntityForName:@"User"
                                inManagedObjectContext:_context];
                    _student.matrnr = self.password;
                    _student.letzteAktualisierung = [NSDate date];
                    _student.raum = [NSNumber numberWithBool:NO];
                }
                
                _student.name = _name;
                _student.dozent = [NSNumber numberWithBool:YES];
                
                [_context save:nil];
                
                HTWCSVParser *parser = [[HTWCSVParser alloc] initWithURL:[NSURL URLWithString:fileURL]];
                parser.delegate = self;
                [parser startHTWCSVParser];
            }
        }
    }];
}

-(void)HTWCSVParserFoundNewLine
{
    _stunde = [[Stunde alloc] initWithEntity:[NSEntityDescription entityForName:@"Stunde" inManagedObjectContext:_context] insertIntoManagedObjectContext:_context];
    _anfang = [NSMutableString stringWithString:@" "];
    _ende = [NSMutableString stringWithString:@" "];
}

-(void)HTWCSVParserFoundCharacters:(NSString *)characters withIndex:(int)index
{
    NSError *error;
    NSArray *kurzelTeile;
    switch (index) {
        case 0:
            kurzelTeile = [characters componentsSeparatedByString:@"/"];
            _stunde.kurzel = kurzelTeile[0];
            if(kurzelTeile.count > 1) _stunde.dozent = kurzelTeile[1];
            break;
        case 1:
            [_anfang appendString:characters];
            [_anfang appendString:@" "];
            break;
        case 2:
            [_anfang appendString:characters];
            _stunde.anfang = [self dateFromString:_anfang];
            break;
        case 3:
            [_ende appendString:characters];
            [_ende appendString:@" "];
            break;
        case 4:
            [_ende appendString:characters];
            _stunde.ende = [self dateFromString:_ende];
            break;
        case 16:
            _stunde.raum = characters;
            _stunde.bemerkungen = @"";
            _stunde.anzeigen = [NSNumber numberWithBool:YES];
            _stunde.id = [NSString stringWithFormat:@"%@%d%@", _stunde.kurzel, [self weekdayFromDate:_stunde.anfang], [self uhrZeitFromDate:_stunde.anfang]];
            _stunde.titel = [_stunde.kurzel componentsSeparatedByString:@" "][0];
            [_student addStundenObject:_stunde];

            [_context save:&error];
            if(error) NSLog(@"%@", [error localizedDescription]);
            break;
            
        default:
            break;
    }
    
}

-(void)HTWCSVParserDidFoundError:(NSString *)errorMessage
{
    NSLog(@"ERROR: %@", errorMessage);
}

-(void)HTWCSVParserDidFinishedWorking:(HTWCSVParser *)parser
{
    [_context save:nil];
    [_delegate HTWCSVConnectionFinished];
}

#pragma mark - Hilfsfunktionen

-(int)weekdayFromDate:(NSDate*)date
{
    int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:date] weekday] - 2;
    if(weekday == -1) weekday=6;
    
    return weekday;
}

-(NSDate*)dateFromString:(NSString*)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"d.M.yyyy H:m:s"];
    return [formatter dateFromString:date];
}

-(NSString*)uhrZeitFromDate:(NSDate*)date
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"H:m"];
    return [formatter stringFromDate:date];
}
@end
