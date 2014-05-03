//
//  MensaXMLParserDelegate.h
//  HTWcampus
//
//  Created by Konstantin on 15.09.13.
//  Copyright (c) 2013 Konstantin. All rights reserved.
//

@protocol CustomMensaManagerDelegate <NSObject>
@required
- (void)reloadView;
@end


#import <Foundation/Foundation.h>
#import "mensaViewController.h"

@interface MensaXMLParserDelegate : NSObject <NSXMLParserDelegate> {
    __unsafe_unretained id<CustomMensaManagerDelegate> delegate;
}

@property (nonatomic, strong) NSMutableArray *allMeals;
@property (assign) id<CustomMensaManagerDelegate> delegate;
@property (nonatomic, strong) NSArray *feedList;

@end
