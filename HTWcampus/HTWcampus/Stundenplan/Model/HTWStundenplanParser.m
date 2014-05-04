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
#import "User.h"

NSMutableData *receivedData;

@interface HTWStundenplanParser () <NSXMLParserDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate>
{
    
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
    
    User *newStudent;
    
    NSMutableString *titel;
    NSMutableString *kuerzel;
    NSMutableString *raum;
    NSMutableString *dozent;
    NSMutableString *datum;
    NSMutableString *anfang;
    NSMutableString *ende;
    NSMutableString *anfangZeit;
}

@property (nonatomic, strong) NSManagedObjectContext *context;
@property BOOL boolRaum;

@end

@implementation HTWStundenplanParser

#pragma mark - INIT

-(id)init
{
    return [self initWithMatrikelNummer:@"00000" andRaum:NO];
}

-(id)initWithMatrikelNummer:(NSString*)Matrnr andRaum:(BOOL)forRaum{
    self = [super init];
    _Matrnr = Matrnr;
    _boolRaum = forRaum;
    appDelegate = [[UIApplication sharedApplication] delegate];
    _context = [appDelegate managedObjectContext];
    return self;
}

#pragma mark - Start method

-(void)parserStart
{
    // Request String für PHP-Argumente
    NSString *myRequestString = [NSString stringWithFormat:@"matr=%@&pressme=%@",self.Matrnr,@"S+T+A+R+T"];
    
    // NSData synchron füllen (wird im ViewController durch unterschiedliche Threads ansynchron)
    NSData *myRequestData = [NSData dataWithBytes: [myRequestString UTF8String] length: [myRequestString length]];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString: @"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_app.php"]
                                                           cachePolicy:NSURLRequestUseProtocolCachePolicy
                                                       timeoutInterval:10];

    [request setHTTPMethod: @"POST"];
    // Set content-type
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"content-type"];
    // Set Request Body
    [request setHTTPBody: myRequestData];
    
    response = [[NSMutableString alloc] init];
    
    // Connection mit dem oben definierten Request
    NSURLConnection *connection = [[NSURLConnection alloc] initWithRequest:request delegate:self];
    
    
    if (connection) {
        // Connection succesfull
    }
    else {
        // Error with connection
        NSLog(@"Connection fehlgeschlagen.");
    }
}

#pragma mark - Connection delegate mathods


-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [response appendString:[[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding]];
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    // Wenn eins dieser Strings in dem HTML-File vorkommt, ist die Nummer falsch oder es gibt keine Daten dazu
    if (([response rangeOfString:@"Stundenplan im csv-Format erstellen"].length != 0) || [response rangeOfString:@"Es wurden keine Daten gefunden."].length != 0) {
        if(!_boolRaum) [_delegate HTWStundenplanParserError:@"Falsche Matrikelnummer oder Studiengruppe. Bitte erneut eingeben."];
        else [_delegate HTWStundenplanParserError:@"Raum nicht gefunden. Bitte erneut eingeben. (Format: Z 355)"];
        return;
    }
    
    NSRange startRange = [response rangeOfString:@"<Stunde>"];
    NSString *dataAfterHtml = [response substringFromIndex:startRange.location];
    
    NSRange endRange = [dataAfterHtml rangeOfString:@"<br>"];
    dataAfterHtml = [dataAfterHtml substringToIndex:endRange.location];
    
    NSMutableString *formattedXML = [NSMutableString
                                     stringWithFormat:@"<data>%@</data>",
                                     dataAfterHtml];
    
    
    // eventuell auftretende Sonderzeichen entfernen, damit der Parser ordentlich funktioniert
    [formattedXML replaceOccurrencesOfString:@"&" withString:@" und " options:NSCaseInsensitiveSearch range:NSMakeRange(0, [formattedXML length])];
    
    NSData *retData = [formattedXML dataUsingEncoding:NSUTF8StringEncoding];
    
    // Parser initialisieren
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:retData];
    
    [parser setDelegate:self];
    [parser parse];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [_delegate HTWStundenplanParserError:@"Fehler mit der Verbindung zum Internet. Bitte stellen Sie sicher, dass das iPhone online ist und versuchen Sie es danach erneut."];
}

#pragma mark - Parser delegate methods


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"data"]) {
        isData = YES;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"User"
                                       inManagedObjectContext:_context]];
        
        NSPredicate *pred =[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.Matrnr];
        [request setPredicate:pred];
        
        NSMutableArray *objects = [NSMutableArray arrayWithArray:[_context executeFetchRequest:request
                                                                                         error:nil]];
        
        // Dürfte nur ein Ergebnis haben
        for (User *student in objects) {
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
                          insertNewObjectForEntityForName:@"User"
                          inManagedObjectContext:_context];
            newStudent.matrnr = self.Matrnr;
            newStudent.letzteAktualisierung = [NSDate date];
            newStudent.raum = [NSNumber numberWithBool:self.boolRaum];
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
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"User"
                                       inManagedObjectContext:_context]];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.Matrnr]];
        
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
            NSLog(@"Neuer Datensatz:\tKennung: %@\tLetzte Aktualisierung: %@\tRaum:%@", matches.matrnr, matches.letzteAktualisierung, _boolRaum?@"ja":@"nein");
            NSLog(@"Es wurden %lu Datensätze gefunden. (Alles außer 1 ist falsch.)", (unsigned long)[objects count]);
            
        }        
        [_delegate HTWStundenplanParserFinished];
        
        return;
    }
    
    if ([elementName isEqualToString:@"Stunde"]) {
        
        isStunde = NO;
        
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        
        [dateFormatter setDateFormat:@"dd.MM.yyyy HH:mm"];
        
        Stunde *stunde = [[Stunde alloc] initWithEntity:[NSEntityDescription entityForName:@"Stunde"
                                                                    inManagedObjectContext:_context] insertIntoManagedObjectContext:_context];
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
        
        [_context save:nil];
        
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
    NSLog(@"ERROR while parsing schedule for %@: %@", self.Matrnr, parseError.localizedDescription);
}

@end
