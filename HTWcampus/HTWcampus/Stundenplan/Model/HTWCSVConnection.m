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

#import "NSDate+HTW.h"

#define kURL [NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_kal.php"]

@interface HTWCSVConnection () <HTWCSVParserDelegate>
{
    NSString *semester;
}

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
    if ([_password isEqualToString:@""] && _delegate) {
        [_delegate HTWCSVConnection:self Error:@"Leider war die Kennung nicht richtig. Bitte probieren Sie es nochmal."];
        return;
    }
    
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

    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    // Connection mit dem oben definierten Request
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        if (connectionError)
        {
            [(HTWAppDelegate *)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
            NSLog(@"ERROR: %@", [connectionError localizedDescription]);
            [_delegate HTWCSVConnection:self Error:@"Es scheint ein Problem mit der Internet-Verbindung zu geben. Bitte stellen Sie sicher, dass eine Verbindung besteht und versuchen Sie es danach erneut."];
            return;
        }
        else {
            NSString *html = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
            
            if ([html rangeOfString:@"Falsche Kennung"].length != 0) {
                [_delegate HTWCSVConnection:self Error:@"Leider war die Kennung nicht richtig. Bitte probieren Sie es nochmal."];
                return;
            }

            NSString *htmlForSemester = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_app.php"] encoding:NSASCIIStringEncoding error:nil];
            semester = [htmlForSemester substringFromIndex:[htmlForSemester rangeOfString:@"</h3><h2>"].location + @"</h3><h2>".length];
            NSArray *teile = [semester componentsSeparatedByString:@" "];
            semester = [NSString stringWithFormat:@"%@ %@", teile[0], teile[1]];

            [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] setObject:semester forKey:@"Semester"];
            
            if(!_eName)
            {
                NSRange startRange = [html rangeOfString:@"<b>"];
                NSString *name = [html substringFromIndex:startRange.location+3];
                
                NSRange endRange = [name rangeOfString:@"</b>"];
                _name = [name substringToIndex:endRange.location];
            }
            else
            {
                _name = _eName;
            }
            
            
            
            NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"<form name=Testform method=post action=\\.\\.\\/plan\\/([^>]*)>" options:0 error:nil];
            NSTextCheckingResult *result = [regex firstMatchInString:html options:0 range:NSMakeRange(0, html.length)];
            if(result) {
                NSRange range = [result rangeAtIndex:1];
                NSString *filename = [html substringWithRange:range];
                NSString *fileURL = [NSString stringWithFormat:@"http://www2.htw-dresden.de/~rawa/cgi-bin/plan/%@", filename];

                _student = [NSEntityDescription
                            insertNewObjectForEntityForName:@"User"
                            inManagedObjectContext:_context];
                _student.matrnr = [NSString stringWithFormat:@"%@+temp",self.password];
                _student.letzteAktualisierung = [NSDate date];
                _student.raum = [NSNumber numberWithBool:NO];

                _student.name = _name;
                _student.dozent = [NSNumber numberWithBool:YES];
                
                [_context save:nil];
                
                HTWCSVParser *parser = [[HTWCSVParser alloc] initWithURL:[NSURL URLWithString:fileURL]];
                parser.delegate = self;
                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                [parser startHTWCSVParser];
            }
            else [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
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
            _stunde.id = [NSString stringWithFormat:@"%@%d%@", _stunde.kurzel, [_stunde.anfang getWeekDay], [self uhrZeitFromDate:_stunde.anfang]];
            _stunde.titel = [_stunde.kurzel componentsSeparatedByString:@" "][0];
            _stunde.semester = semester;
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
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    [request setEntity:[NSEntityDescription entityForName:@"User"
                                   inManagedObjectContext:_context]];

    [request setPredicate:[NSPredicate predicateWithFormat:@"(matrnr = %@)", [NSString stringWithFormat:@"%@+temp",self.password]]];

    User *matches;

    NSError *error;
    NSArray *objects = [_context executeFetchRequest:request
                                               error:&error];

    if (error) {
        NSLog(@"ERROR: %@", [error localizedDescription]);
    }

    if ([objects count] == 0) {
        NSLog(@"No matches");
    } else {
        matches = objects[0];
    }

    // Vergleichen
    NSFetchRequest *request2 = [[NSFetchRequest alloc] initWithEntityName:@"User"];
    [request2 setPredicate:[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.password]];

    User *matches2;
    NSArray *objects2 = [_context executeFetchRequest:request2
                                                error:&error];

    if (error) {
        NSLog(@"ERROR: %@", [error localizedDescription]);
    }

    if ([objects2 count] == 0) {
        matches.matrnr = [matches.matrnr componentsSeparatedByString:@"+"][0];
        NSLog(@"No matches. New User. Stunden: %lu", (unsigned long)matches.stunden.count);
    } else {
        NSLog(@"User exists in database. Add non existing Stunden..");
        matches2 = objects2[0];
        NSLog(@"Vorher: %lu", (unsigned long)matches2.stunden.count);
        for (Stunde *temp1 in [matches.stunden allObjects]) {
            if([self is:temp1 in:[matches2.stunden allObjects]])
            {
                continue;
            }
            else [matches2 addStundenObject:temp1];
        }
        NSLog(@"Nachher: %lu", (unsigned long)matches2.stunden.count);
        [_context deleteObject:matches];
    }
    [_context save:nil];
    [[[NSUserDefaults alloc] initWithSuiteName:@"group.BenchR.TodayExtensionSharingDefaults"] setObject:self.password forKey:@"Matrikelnummer"];
    [_delegate HTWCSVConnectionFinished:self];
}

#pragma mark - Hilfsfunktionen

-(BOOL)is:(Stunde*)stunde in:(NSArray*)stunden
{
    for (Stunde *temp in stunden) {
        if([temp.titel isEqualToString:stunde.titel] && [temp.anfang isEqualToDate:stunde.anfang] && [temp.kurzel isEqualToString:stunde.kurzel])
        {
            return YES;
        }
    }
    return NO;
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
