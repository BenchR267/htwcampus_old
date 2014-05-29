//
//  HTWTabBarItem.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 19.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWTabBarItem.h"

@interface HTWTabBarItem ()

@property (nonatomic, strong) NSArray *bilder;

@end

@implementation HTWTabBarItem

-(UIImage *)selectedImage
{
    if(!_bilder) _bilder = @[[UIImage imageNamed:@"Kalender"], [UIImage imageNamed:@"Haus"], [UIImage imageNamed:@"Noten"], [UIImage imageNamed:@"Pruefung"], [UIImage imageNamed:@"Mensa"]];
    return _bilder[self.tag];
}

- (void)awakeFromNib {
    [self setImage:self.image];
}

- (void)setImage:(UIImage *)image {
    [super setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    self.selectedImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
