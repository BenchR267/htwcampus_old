//
//  HTWAppDelegate.h
//  HTWcampus
//
//  Created by Benjamin Herzog on 23.04.14.
//  Copyright (c) 2014 Benjamin Herzog. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HTWAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (readonly, strong, nonatomic) NSManagedObjectContext *managedObjectContext;
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;
@property (readonly, strong, nonatomic) NSPersistentStoreCoordinator *persistentStoreCoordinator;

- (void)saveContext;
- (NSURL *)applicationDocumentsDirectory;

@end
