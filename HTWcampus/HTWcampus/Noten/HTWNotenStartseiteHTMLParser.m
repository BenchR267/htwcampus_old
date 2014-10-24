//
//  notenStartseiteHTMLParser.m
//  HTWcampus
//
//  Created by Konstantin Werner on 19.03.14.
//  Copyright (c) 2014 Konstantin. All rights reserved.
//

#import "HTWNotenStartseiteHTMLParser.h"
#import "HTWAppDelegate.h"
#import "Note.h"

@interface HTWNotenStartseiteHTMLParser ()

@property (nonatomic, strong) NSManagedObjectContext *context;

@end

@implementation HTWNotenStartseiteHTMLParser

- (NSString*) parseAsiTokenFromString: (NSString*)htmlString {
    DocumentRoot *document = [Element parseHTML:htmlString];
    NSString *hrefString = [[[[[[[[document selectElements:@"table"] objectAtIndex:4] selectElements:@"tr"] objectAtIndex:1] selectElements:@"td"] objectAtIndex:0] selectElement:@"a"] attribute:@"href"];
    NSArray *splitArray = [hrefString componentsSeparatedByString:@"="];
    return splitArray.lastObject;
}

- (NSArray*) parseNotenspiegelFromString: (NSString*)htmlString {
    
    _context = [(HTWAppDelegate*)[[UIApplication sharedApplication] delegate] managedObjectContext];
    
    // Noten löschen
    NSFetchRequest *request = [[NSFetchRequest alloc] init];
    NSEntityDescription *entity = [NSEntityDescription entityForName:@"Note" inManagedObjectContext:_context];
    [request setEntity:entity];
    NSArray *tempArray = [_context executeFetchRequest:request error:nil];
    for (Note *this in tempArray) {
        [_context deleteObject:this];
    }
    
    DocumentRoot *document = [Element parseHTML:htmlString];
    NSMutableArray *notenspiegel = [[NSMutableArray alloc] init];
    NSUInteger rowCount = 0, cellCount = 0;
    
    NSArray *htmlTable = [[[document selectElements:@"table"] objectAtIndex:4] selectElements:@"tr"];
    
    for (Element *pruefungsfach in htmlTable) {
        //Skip the first two header tablerows
        if (rowCount > 1) {
            Note *fach = [NSEntityDescription insertNewObjectForEntityForName:@"Note" inManagedObjectContext:_context];
            NSArray *fachDetails = [pruefungsfach selectElements:@"td"];
            for (Element *detail in fachDetails) {
                NSMutableString *content = [detail.contentsText stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""].mutableCopy;
                switch (cellCount) {
                    case 0:
                        fach.nr = [NSNumber numberWithInt:content.intValue];
                        break;
                    case 1:
                        fach.name = content;
                        break;
                    case 2:
                        fach.semester = content;
                        break;
                    case 3:
                        [content replaceOccurrencesOfString:@"," withString:@"." options:NSCaseInsensitiveSearch range:NSMakeRange(0, content.length)];
                        fach.note = [NSNumber numberWithFloat:content.floatValue];
                        break;
                    case 4:
                        fach.status = content;
                        break;
                    case 5:
                        fach.credits = [NSNumber numberWithFloat:content.floatValue];
                        break;
                    case 8:
                        fach.versuch = [NSNumber numberWithInt:content.intValue];
                        break;
                    default:
                        break;
                }
                cellCount++;
            }
            [notenspiegel addObject:fach];
            
            cellCount = 0;
        }
        rowCount++;
    }
    notenspiegel = [notenspiegel sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
        Note *eins = obj1;
        Note *zwei = obj2;
        return [eins.name compare:zwei.name];
    }].mutableCopy;
    return [self groupSemester:notenspiegel];
}

- (NSArray*) groupSemester:(NSArray *)notenspiegel {
    NSMutableArray *newNotenspiegel = [[NSMutableArray alloc] init];
    int tempIndex = 0;
    int indexCount = 0;
    NSMutableDictionary *semesterIndex = [[NSMutableDictionary alloc] init];
    
    for (Note *fach in notenspiegel) {
        if (!([semesterIndex count] == 0)) {
            if ([[semesterIndex objectForKey:[NSNumber numberWithInt:tempIndex]] isEqualToString:fach.semester]) {
                [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            }
            else {
                //check if semester alread exists or not
                bool foundSemester = false;
                for (NSString* key in semesterIndex) {
                    NSString *value = [semesterIndex objectForKey:key];
                    
                    if ([value isEqualToString:fach.semester]) {
                        foundSemester = true;
                        tempIndex = [key intValue];
                        break;
                    }
                }
                if (!foundSemester) {
                    [semesterIndex setObject:fach.semester forKey:[@(indexCount) stringValue]];
                    [newNotenspiegel addObject:[[NSMutableArray alloc] init]];
                    tempIndex = indexCount;
                    indexCount++;
                }
                
                [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            }
        }
        else {
            tempIndex = indexCount;
            [newNotenspiegel addObject:[[NSMutableArray alloc] init]];
            [semesterIndex setObject:fach.semester forKey:[@(tempIndex) stringValue]];
            [[newNotenspiegel objectAtIndex:tempIndex] addObject:fach];
            indexCount++;
        }
    }
    return newNotenspiegel;
}

// build array-structure from html-data
- (NSMutableArray*) getTableFromHtmlDocument:(DocumentRoot*)document withTablePos:(NSUInteger) tablePos
{
	NSArray *tabRows = [[[document selectElements:@"table"] objectAtIndex:tablePos] selectElements:@"tr"];
	NSUInteger rowCount = 0, cellCount = 0;
	NSMutableArray *tab1Cells = [[NSMutableArray alloc] init];
	
	for( Element *tr in tabRows)
	{
		// skip first row (daynames)
		if(rowCount == 0){
			rowCount++;
			continue;
		}
		[tab1Cells addObject:[tr childElements]];
	}
	
	rowCount = 0;
	
	// prepare data structure
	NSMutableArray *daysWo = [NSMutableArray arrayWithCapacity:5];
	for(int i = 0; i < 6; i++)
	{
		[daysWo addObject:[NSMutableArray array]];
	}
	
	NSString *time = @"";
	
	// build stundenplan
	for (NSArray *tdAr in tab1Cells)
	{
		for( Element *td in tdAr)
		{
			// skip first cell (time)
			if(cellCount == 0)
			{
				time = [td contentsSource];
				cellCount++;
				continue;
			}
			
			// get cell in row
			NSString *tdText = [td contentsSource];
			// don't add empty cells
			if([tdText length] == 6)
			{
				cellCount++;
				continue;
			}
			
			
			NSMutableArray *tdContent = [self getClearCellContent: tdText];
			
			NSMutableDictionary *firstCell = [tdContent objectAtIndex:0];
            NSString *blocknr = [[NSString alloc] initWithFormat:@"%i", (int)rowCount+1];
			[firstCell setObject:time forKey:@"time"];
            [firstCell setObject:blocknr forKey:@"blocknr"];
			[[daysWo objectAtIndex:cellCount - 1] addObject:firstCell];
			
			// if more than 1 content in cell (2 entries for one timeslot) -  and second cell
			if([tdContent count] == 2)
			{
				NSMutableDictionary *secondCell = [tdContent objectAtIndex:1];
				[secondCell setObject:time forKey:@"time"];
                [secondCell setObject:blocknr forKey:@"blocknr"];
				[[daysWo objectAtIndex:cellCount - 1] addObject:secondCell];
			}
            
			cellCount++;
		}
		cellCount = 0;
        rowCount++;
	}
	return daysWo;
}


// clears the cell from unwanted html and return a dictionary
- (NSMutableArray*) getClearCellContent: (NSString*) cellContent
{
	NSMutableArray *returnContent = [[NSMutableArray alloc] init];
	NSMutableDictionary *content = [[NSMutableDictionary alloc] init];
	NSMutableDictionary *content_2 = [[NSMutableDictionary alloc] init];
    
	NSArray *temp;
	
	temp = [cellContent componentsSeparatedByString:@"<br>"];
	
	NSInteger innerCount = 0;
	
	for(NSString __strong *element in temp)
	{
		// clear all &nbsp;
		element = [element stringByReplacingOccurrencesOfString:@"&nbsp;" withString:@""];
		
		// clear html checkbox
		int start, ende;
		start = [self findFirstString:element find:@"<input"];
		ende = [self findFirstString:element find:@">"];
		
		if(start != -1 && ende != -1)
		{
			NSRange replaceRange = NSMakeRange(start, ende-start+1);
			element = [element stringByReplacingOccurrencesOfString:[element substringWithRange:replaceRange] withString:@""];
		}
		
		// build dictionary
        
        
		switch (innerCount) {
			case 0:
                //contains title
				[content setObject:element forKey:@"title"];
				break;
			case 1: {
                //contains short Title & workshop type (V, Pr, U)
                NSString *secondLine = element;
                NSArray *helpArray = [secondLine componentsSeparatedByString:@" "];
                if ([helpArray count] > 1) {
                    NSString *titleShort = [helpArray objectAtIndex:0];
                    [content setObject:titleShort forKey:@"titleShort"];
                    NSString *type = [[helpArray objectAtIndex:1] substringToIndex:1];
                    [content setObject:type forKey:@"type"];
                }
                else {
                    // possibly "Gremien"-Slot
                    if ([secondLine rangeOfString:@" d- "].location == NSNotFound) {
                        [content setObject:secondLine forKey:@"title"];
                        [content setObject:@"Gremien" forKey:@"titleShort"];
                        [content setObject:@"" forKey:@"docent"];
                        [content setObject:@"G" forKey:@"type"];
                        // Any other less precisely defined dates
                        [content setObject:secondLine forKey:@"titleShort"];
                        [content setObject:@"" forKey:@"docent"];
                        [content setObject:@"" forKey:@"type"];;
                    }
                    
                    
                }
                break;
            }
			case 2: {
                //contains room & docent
                NSString *helpString = element;
                if ([helpString isEqualToString:@" - "]) {
                    [content setObject:@"" forKey:@"room"];
                }
                else {
                    NSArray *helpArray = [helpString componentsSeparatedByString:@" - "];
                    NSString *room = [helpArray objectAtIndex:0];
                    NSString *docent = [helpArray objectAtIndex:1];
                    
                    
                    [content setObject:room forKey:@"room"];
                    [content setObject:docent forKey:@"docent"];
                }
				break;            }
			case 4:
				[content_2 setObject:element forKey:@"title"];
				break;
			case 5: {
                //contains short Title & workshop type (V, Pr, U)
                NSString *secondLine = element;
                NSArray *helpArray = [secondLine componentsSeparatedByString:@" "];
                if ([helpArray count] > 1) {
                    NSString *titleShort = [helpArray objectAtIndex:0];
                    [content_2 setObject:titleShort forKey:@"titleShort"];
                    NSString *type = [[helpArray objectAtIndex:1] substringToIndex:1];
                    [content_2 setObject:type forKey:@"type"];
                }
                else {
                    // possibly "Gremien"-Slot
                    [content_2 setObject:secondLine forKey:@"title"];
                    [content_2 setObject:@"Gremien" forKey:@"titleShort"];
                    
                }
                break;
            }
			case 6: {
                //contains room & docent
                NSString *helpString = element;
                if ([helpString isEqualToString:@" - "]) {
                    [content_2 setObject:@"" forKey:@"room"];
                }
                else {
                    NSArray *helpArray = [helpString componentsSeparatedByString:@" - "];
                    NSString *room = [helpArray objectAtIndex:0];
                    NSString *docent = [helpArray objectAtIndex:1];
                    
                    
                    [content_2 setObject:room forKey:@"room"];
                    [content_2 setObject:docent forKey:@"docent"];
                }
				break;
            }
			default:
				break;
		}
		innerCount++;
	}
	
	[returnContent addObject:content];
	// set another cell for subject at same timeslot
	if([content_2 count] > 0 )
	{
		[returnContent addObject:content_2];
	}
	
	return returnContent;
}


// searches for first appearance of a string in string -> because cocoa has no such function!!
- (int) findFirstString:(NSString *) theString find:(NSString *) search
{
	NSRange range = [theString rangeOfString:search options: NSCaseInsensitiveSearch];
	
	if (range.length > 0) {
		return (int)range.location;
	}
	return -1;
	
}
@end
