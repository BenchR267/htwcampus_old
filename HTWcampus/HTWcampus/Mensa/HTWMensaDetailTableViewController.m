//
//  HTWMensaDetailTableViewController.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 09.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWMensaDetailTableViewController.h"
#import "HTWMensaDetailParser.h"

#import "UIColor+HTW.h"
#import "UIFont+HTW.h"

#define IMAGEVIEW_TAG 4

@interface HTWMensaDetailTableViewController ()

@property (nonatomic, strong) NSDictionary *zusatzInfos;
@property (nonatomic, strong) UITextView *textView;

@end

@implementation HTWMensaDetailTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    HTWMensaDetailParser *parser = [[HTWMensaDetailParser alloc] initWithURL:[NSURL URLWithString:_speise[@"link"]]];
    [parser parseInQueue:[NSOperationQueue mainQueue] WithCompletetionHandler:^(NSDictionary *dic, NSString *errorMessage) {
        if(errorMessage)
        {
            UIAlertView *errorAlert = [[UIAlertView alloc] initWithTitle:@"Fehler"
                                                                 message:errorMessage
                                                                delegate:nil
                                                       cancelButtonTitle:@"Ok"
                                                       otherButtonTitles:nil];
            [errorAlert show];
        }
        _zusatzInfos = dic;
        [self.tableView reloadData];
    }];
    self.tableView.backgroundColor = [UIColor HTWBackgroundColor];
    self.title = _speise[@"title"];
}
- (IBAction)openInSafariPressed:(id)sender {
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:_speise[@"link"]]];
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) return 190;
    else if (indexPath.section == 1)
    {
        if(indexPath.row == 1 && [_speise[@"price"] isEqualToString:@""]) return [self heightForCellWithTextView:indexPath];
        if(indexPath.row == 1 && ![_speise[@"price"] isEqualToString:@""]) return 60;
        if(indexPath.row == 2)
            return [self heightForCellWithTextView:indexPath];
        else return 120;
    }
    return 0;
}

-(CGFloat)heightForCellWithTextView:(NSIndexPath*)indexPath
{
    if(_textView.text) return [_textView.text sizeWithAttributes:@{NSFontAttributeName: [UIFont HTWSmallFont]}].height*[_zusatzInfos[@"speiseDetails"] count] + 25;
    else return 10;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if(section == 0) return 1;
    else {
        if(![_speise[@"price"] isEqualToString:@""]) return 3;
        else return 2;
    }
}

-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}
-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if(section == 0) return nil;
    else return @"Informationen";
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell;
    if(indexPath.section == 0)
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
        [[cell.contentView viewWithTag:IMAGEVIEW_TAG] removeFromSuperview];
        UIImage *image;
        if(_zusatzInfos[@"Bild"]) image = _zusatzInfos[@"Bild"];
        else image = [UIImage imageNamed:@"noImage"];
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(cell.contentView.center.x, cell.contentView.center.y, image.size.width, image.size.height)];
        imageView.center = cell.contentView.center;
        imageView.bounds = cell.contentView.bounds;
        imageView.image = image;
        imageView.tag = IMAGEVIEW_TAG;
        [cell.contentView addSubview:imageView];
    }
    else
    {
        if((indexPath.row == 2 && ![_speise[@"price"] isEqualToString:@""]) || ((indexPath.row == 1) && [_speise[@"price"] isEqualToString:@""]))
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
            _textView = [[UITextView alloc] initWithFrame:cell.contentView.frame];
            NSMutableString *string = [NSMutableString new];
            for (NSString *this in _zusatzInfos[@"speiseDetails"]) {
                [string appendFormat:@"   - %@\n", this];
            }
            _textView.frame = CGRectMake(_textView.frame.origin.x, _textView.frame.origin.y, _textView.frame.size.width,
                                         [@"A" sizeWithAttributes:@{NSFontAttributeName: [UIFont HTWSmallFont]}].height*[_zusatzInfos[@"speiseDetails"] count] + 25);
            _textView.text = string;
            _textView.editable = NO;
            _textView.userInteractionEnabled = NO;
            _textView.font = [UIFont HTWSmallFont];
            _textView.textColor = [UIColor HTWTextColor];
            [cell addSubview:_textView];
            cell.frame = _textView.frame;
            CGSizeMake(cell.frame.size.width, _textView.contentSize.height);
        }
        else
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
            if(indexPath.row == 0)
            {
                cell.textLabel.text = _speise[@"title"];
            }
            else if (indexPath.row == 1 && ![_speise[@"price"] isEqualToString:@""])
            {
                cell.textLabel.text = _speise[@"price"];
            }
            cell.textLabel.numberOfLines = 4;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWBlueColor];
    return cell;
}

@end
