//
//  StundenplanParser.m
//  WochenplanMensa
//
//  Created by Benjamin Herzog on 18.11.13.
//  Copyright (c) 2013 Benjamin Herzog. All rights reserved.
//

#import "HTWStundenplanParser.h"
#import "HTWAppDelegate.h"
#import "Stunde.h"
#import "Student.h"

NSMutableData *receivedData;

@interface StundenplanParser () <NSXMLParserDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    int lengthFormattedXML;
    
    BOOL isData;
    BOOL isStunde;
    BOOL isTitel;
    BOOL isKuerzel;
    BOOL isRaum;
    BOOL isDozent;
    BOOL isDatum;
    BOOL isAnfang;
    BOOL isEnde;
    
    
    NSMutableString *response;
    
    HTWAppDelegate *appDelegate;
    
    Student *newStudent;
    
    NSMutableString *titel;
    NSMutableString *kuerzel;
    NSMutableString *raum;
    NSMutableString *dozent;
    NSMutableString *datum;
    NSMutableString *anfang;
    NSMutableString *ende;
    NSMutableString *anfangZeit;
    NSString *ID;
}

@property (nonatomic, strong) NSManagedObjectContext *context;
@property BOOL forRaum;

@end

@implementation StundenplanParser

#pragma mark - INIT

-(id)init
{
    return [self initWithMatrikelNummer:@"00000" andRaum:NO];
}

-(id)initWithMatrikelNummer:(NSString*)Matrnr andRaum:(BOOL)forRaum{
    self = [super init];
    self.Matrnr = Matrnr;
    self.forRaum = forRaum;
    appDelegate = [[UIApplication sharedApplication] delegate];
    self.context = [appDelegate managedObjectContext];
    return self;
}

#pragma mark - Start method

-(void)parserStart
{
    // Create your request string with parameter name as defined in PHP file
    NSString *myRequestString = [NSString stringWithFormat:@"matr=%@&pressme=%@",self.Matrnr,@"S+T+A+R+T"];
    
    // Create Data from request
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_app.php"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];
    // set Request Type
    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    // Now send a request and get Response
    
    response = [[NSMutableString alloc] init];
    
    
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    
    if (connection) {
        // Connection succesfull
        NSLog(@"Connection steht.");
    }
    else {
        // Error with connection
        NSLog(@"Connection fehlgeschlagen.");
    }
}

#pragma mark - Connection delegate mathods


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    // Log Response
    [response appendString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
    
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    
    if (([response rangeOfString:@"Stundenplan im csv-Format erstellen"].length != 0) || [response rangeOfString:@"Es wurden keine Daten gefunden."].length != 0) {
        if(!_forRaum) [_delegate stundenplanParserError:@"Falsche Matrikelnummer. Bitte erneut eingeben."];
        else [_delegate stundenplanParserError:@"Raum nicht gefunden. Bitte erneut eingeben. (Format: Z 355)"];
        return;
    }
    
    NSRange startRange = [response rangeOfString:@"<Stunde>"];
    NSString *dataAfterHtml = [response substringFromIndex:startRange.location];
    
    NSRange endRange = [dataAfterHtml rangeOfString:@"<br>"];
    dataAfterHtml = [dataAfterHtml substringToIndex:endRange.location];
    
    NSMutableString *formattedXML = [NSMutableString
                                     stringWithFormat:@"<data>%@</data>",
                                     dataAfterHtml];
    
    
    [formattedXML replaceOccurrencesOfString:@"&" withString:@" und " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [formattedXML length])];
    
    lengthFormattedXML = (int)[formattedXML length];
    
    NSData *retData = [formattedXML dataUsingEncoding:NSUTF8StringEncoding];
    
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:retData];
    if (!parser)
    {
        NSLog(@"Error with parser");
        [_delegate stundenplanParserError:@"Parser Error. Bitte Internetverbindung überprüfungen und nochmal probieren."];
    }
    else NSLog(@"parser successfully initialised");
    
    [parser setDelegate:self];
    [parser parse];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_delegate stundenplanParserError:@"Error with connection. Bitte Internetverbindung überprüfungen und erneut versuchen."];
}

#pragma mark - Parser delegate methods


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"data"]) {
        isData = YES;
        
        NSEntityDescription *entityDesc =[NSEntityDescription entityForName:@"Student"
                                                     inManagedObjectContext:_context];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *pred =[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.Matrnr];
        [request setPredicate:pred];
        
        NSMutableArray *objects = [NSMutableArray arrayWithArray:[_context executeFetchRequest:request
                                                                                         error:nil]];
        
        // Dürfte nur ein Ergebnis haben
        for (Student *student in objects) {
            for (Stunde *aktuell in student.stunden) {
                [_context deleteObject:aktuell];
            }
        }
        [_context save:nil];
        
        if ([objects count] != 0) {
            newStudent = objects[0];
        }
        else {
            newStudent = [NSEntityDescription
                          insertNewObjectForEntityForName:@"Student"
                          inManagedObjectContext:_context];
            [newStudent setValue: self.Matrnr forKey:@"matrnr"];
            [newStudent setValue:[NSDate date] forKey:@"letzteAktualisierung"];
            [newStudent setRaum:[NSNumber numberWithBool:self.forRaum]];
        }
        
        
        [_context save:nil];
        return;
    }
    
    if ([elementName isEqualToString:@"Stunde"] && isData) {
        isStunde = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"titel"] && isStunde) {
        isTitel = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"kuerzel"] && isStunde) {
        isKuerzel = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"raum"] && isStunde) {
        isRaum = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"dozent"] && isStunde) {
        isDozent = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"datum"] && isStunde) {
        isDatum = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"anfang"] && isStunde) {
        isAnfang = YES;
        return;
    }
    
    if ([elementName isEqualToString:@"ende"] && isStunde) {
        isEnde = YES;
        return;
    }
}

-(void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{
    
    if (isTitel) {
        if(!titel) titel = [[NSMutableString alloc] init];
        [titel appendString:string];
        return;
    }
    
    if (isKuerzel) {
        
        
        if(!kuerzel) kuerzel = [[NSMutableString alloc] init];
        [kuerzel appendString:string];
        return;
    }
    
    if (isRaum) {
        NSRange range = [kuerzel rangeOfString:@" "];
        kuerzel = [NSMutableString stringWithString:[kuerzel substringToIndex:range.location + 2]];
        
        if(!raum) raum = [[NSMutableString alloc] init];
        [raum appendString:string];
        return;
    }
    
    if (isDozent) {
        if(!dozent) dozent = [[NSMutableString alloc] init];
        [dozent appendString:string];
        return;
    }
    
    if (isDatum) {
        if(!datum) datum = [[NSMutableString alloc] init];
        [datum appendString:string];
        [datum appendString:@" "];
        return;
    }
    
    if (isAnfang) {
        if(!anfang) anfang = [[NSMutableString alloc] init];
        if(!anfangZeit) anfangZeit = [[NSMutableString alloc] init];
        [anfangZeit appendString:string];
        [anfang appendString:datum];
        [anfang appendString:string];
        return;
    }
    
    if (isEnde) {
        if(!ende) ende = [[NSMutableString alloc] init];
        [ende appendString:datum];
        [ende appendString:string];
    }
    
}

-(void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName
{
    if ([elementName isEqualToString:@"data"]) {
        
        isData = NO;
        
        NSEntityDescription *entityDesc = [NSEntityDescription entityForName:@"Student"
                                                      inManagedObjectContext:_context];
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:entityDesc];
        
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"(matrnr = %@)", self.Matrnr];
        [request setPredicate:pred];
        
        Student *matches;
        
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
            NSLog(@"Matrikelnummer: %@\n Letzte Aktualisierung: %@", [matches valueForKey:@"matrnr"], [matches valueForKey:@"letzteAktualisierung"]);
            NSLog(@"Es wurden %lu Datensätze gefunden. (Alles außer 1 ist falsch.)", (unsigned long)[objects count]);
            // NSLog(@"Stunden: %@", [matches valueForKey:@"stunden"]);
            
        }        
        [_delegate stundenplanParserFinished];
        
        return;
    }
    
    if ([elementName isEqualToString:@"Stunde"]) {
        
        isStunde = NO;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
        
        
        NSEntityDescription *entityDesc =[NSEntityDescription entityForName:@"Stunde"
                                                     inManagedObjectContext:_context];
        
        Stunde *stunde = [[Stunde alloc] initWithEntity:entityDesc insertIntoManagedObjectContext:_context];
        stunde.titel = titel;
        stunde.kurzel = kuerzel;
        stunde.dozent = dozent;
        stunde.raum = raum;
        stunde.anfang = [dateFormatter dateFromString:anfang];
        stunde.ende = [dateFormatter dateFromString:ende];
        
        int weekday = (int)[[[NSCalendar currentCalendar] components:NSWeekdayCalendarUnit fromDate:stunde.anfang] weekday] - 2;
        if(weekday == -1) weekday=6;
        
        stunde.id = [NSString stringWithFormat:@"%@%d%@", kuerzel, weekday, anfangZeit];
        stunde.anzeigen = [NSNumber numberWithBool:YES];
        stunde.student.matrnr = _Matrnr;
        
        
        [newStudent addStundenObject:stunde];
        
        NSError *error;
        [_context save:&error];
        
        if (error) {
            NSLog(@"ERROR %@", [error localizedDescription]);
        }
        
        titel = nil;
        kuerzel = nil;
        raum = nil;
        dozent = nil;
        datum = nil;
        anfang = nil;
        anfangZeit = nil;
        ende = nil;
        return;
    }
    
    if ([elementName isEqualToString:@"titel"]) {
        isTitel = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"kuerzel"]) {
        isKuerzel = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"raum"]) {
        isRaum = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"dozent"]) {
        isDozent = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"datum"]) {
        isDatum = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"anfang"]) {
        isAnfang = NO;
        return;
    }
    
    if ([elementName isEqualToString:@"ende"]) {
        isEnde = NO;
        return;
    }
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"ERROR while parsing: %@", parseError.localizedDescription);
}

@end
