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

@interface HTWMensaDetailTableViewController ()

@property (nonatomic, strong) NSDictionary *zusatzInfos;

@end

@implementation HTWMensaDetailTableViewController

-(void)viewDidLoad
{
    [super viewDidLoad];
    HTWMensaDetailParser *parser = [[HTWMensaDetailParser alloc] initWithURL:[NSURL URLWithString:_speise[@"link"]]];
    [parser parseWithCompletetionHandler:^(NSDictionary *dic, NSString *errorMessage) {
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
        if(indexPath.row == 1 && [_speise[@"price"] isEqualToString:@""]) return 220;
        if(indexPath.row == 2)
            return 220;
        else return 80;
    }
    return 0;
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
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:cell.contentView.frame];
        if(_zusatzInfos[@"Bild"]) imageView.image = _zusatzInfos[@"Bild"];
        else imageView.image = [UIImage imageNamed:@"noimage.png"];
        [cell.contentView addSubview:imageView];
    }
    else
    {
        if((indexPath.row == 2 && ![_speise[@"price"] isEqualToString:@""]) || ((indexPath.row == 1) && [_speise[@"price"] isEqualToString:@""]))
        {
            cell = [tableView dequeueReusableCellWithIdentifier:@"imageCell"];
            UITextView *textView = [[UITextView alloc] initWithFrame:cell.contentView.frame];
            for (NSString *this in _zusatzInfos[@"speiseDetails"]) {
                NSMutableString *string = [NSMutableString stringWithString:textView.text];
                [string appendFormat:@"   - %@\n", this];
                textView.text = string;
            }
            textView.editable = NO;
            textView.userInteractionEnabled = NO;
            textView.font = [UIFont HTWSmallFont];
            textView.textColor = [UIColor HTWTextColor];
            [cell addSubview:textView];
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
            cell.textLabel.numberOfLines = 2;
            cell.textLabel.lineBreakMode = NSLineBreakByWordWrapping;
        }
    }
    cell.textLabel.font = [UIFont HTWTableViewCellFont];
    cell.textLabel.textColor = [UIColor HTWBlueColor];
    return cell;
}

@end
