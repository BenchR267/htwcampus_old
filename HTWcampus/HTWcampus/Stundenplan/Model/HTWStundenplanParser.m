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

#import "NSDate+HTW.h"

NSMutableData *receivedData;

@interface HTWStundenplanParser () <NSXMLParserDelegate>
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

    NSString *semester;
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
    self.tag = 0;
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
    
    [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:YES];
    // Connection mit dem oben definierten Request
    [NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {
        
        if (connectionError) {
            if(_delegate)
            {
                [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
                [_delegate HTWStundenplanParser:self Error:@"Fehler mit der Verbindung zum Internet. Bitte stellen Sie sicher, dass das iPhone online ist und versuchen Sie es danach erneut."];
                return;
            }
        }
        
        NSString *html = [[NSString alloc] initWithData:data encoding:NSASCIIStringEncoding];
        [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] setNetworkActivityIndicatorVisible:NO];
        // Wenn eins dieser Strings in dem HTML-File vorkommt, ist die Nummer falsch oder es gibt keine Daten dazu
        if (([html rangeOfString:@"Stundenplan im csv-Format erstellen"].length != 0) || [html rangeOfString:@"Es wurden keine Daten gefunden."].length != 0) {
            if(!_boolRaum) [_delegate HTWStundenplanParser:self Error:@"Leider war die Matrikelnummer oder Studiengruppe nicht richtig. Bitte probieren Sie es nochmal."];
            else [_delegate HTWStundenplanParser:self Error:@"Leider wurde der Raum mit dieser Kennung nicht gefunden. Bitte probieren Sie es nochmal."];
            return;
        }

        NSString *htmlForSemester = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www2.htw-dresden.de/~rawa/cgi-bin/auf/raiplan_app.php"] encoding:NSASCIIStringEncoding error:nil];
        semester = [htmlForSemester substringFromIndex:[htmlForSemester rangeOfString:@"</h3><h2>"].location + @"</h3><h2>".length];
        NSArray *teile = [semester componentsSeparatedByString:@" "];
        semester = [NSString stringWithFormat:@"%@ %@", teile[0], teile[1]];

        [[NSUserDefaults standardUserDefaults] setObject:semester forKey:@"Semester"];
        
        NSRange startRange = [html rangeOfString:@"<Stunde>"];
        NSString *dataAfterHtml = [html substringFromIndex:startRange.location];
        
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
    }];
}

#pragma mark - Parser delegate methods


-(void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict
{
    if ([elementName isEqualToString:@"data"]) {
        isData = YES;

        newStudent = [NSEntityDescription
                      insertNewObjectForEntityForName:@"User"
                      inManagedObjectContext:_context];
        newStudent.matrnr = [NSString stringWithFormat:@"%@+temp",self.Matrnr];
        newStudent.letzteAktualisierung = [NSDate date];
        newStudent.raum = [NSNumber numberWithBool:self.boolRaum];
        if(_name) newStudent.name = _name;

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

        [_context save:nil];

        isData = NO;
        
        NSFetchRequest *request = [[NSFetchRequest alloc] init];
        [request setEntity:[NSEntityDescription entityForName:@"User"
                                       inManagedObjectContext:_context]];
        
        [request setPredicate:[NSPredicate predicateWithFormat:@"(matrnr = %@)", [NSString stringWithFormat:@"%@+temp",self.Matrnr]]];
        
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
            NSLog(@"Neuer Stundenplan-Datensatz:\tKennung: %@\tLetzte Aktualisierung: %@\tRaum:%@", [matches.matrnr componentsSeparatedByString:@"+"][0], matches.letzteAktualisierung, _boolRaum?@"ja":@"nein");
        }

        // Vergleichen
        NSFetchRequest *request2 = [[NSFetchRequest alloc] initWithEntityName:@"User"];
        [request2 setPredicate:[NSPredicate predicateWithFormat:@"(matrnr = %@)", self.Matrnr]];

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


        if(!_boolRaum) [[NSUserDefaults standardUserDefaults] setObject:self.Matrnr forKey:@"Matrikelnummer"];
        if(_delegate) [_delegate HTWStundenplanParserFinished:self];
        
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
        stunde.anfang = [NSDate getFromString:anfang withFormat:@"dd.MM.yyyy HH:mm"];
        stunde.ende = [NSDate getFromString:ende withFormat:@"dd.MM.yyyy HH:mm"];
        
        stunde.id = [NSString stringWithFormat:@"%@%d%@", kuerzel, [stunde.anfang getWeekDay], anfangZeit];
        stunde.anzeigen = [NSNumber numberWithBool:YES];

        stunde.semester = semester;
        
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

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{
    NSLog(@"ERROR while parsing schedule for %@: %@", self.Matrnr, parseError.localizedDescription);
}

@end
