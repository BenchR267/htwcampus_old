//
//  HTWTabBarItem.m
//  HTWcampus
//
//  Created by Benjamin Herzog on 19.05.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import "HTWTabBarItem.h"

@implementation HTWTabBarItem

- (void)awakeFromNib {
    [self setImage:self.image];
}

- (void)setImage:(UIImage *)image {
    [super setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal]];
    self.selectedImage = [image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
