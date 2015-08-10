//
//  NSManagedObjectContext+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 1/23/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;
@import CoreData;

@interface NSManagedObjectContext (MSKitAdditions)

/// Wrapper for MR_workingName provided by `MagicalRecord` framework
@property (nonatomic, copy) NSString * nametag;

/// Returns the set containing any contexts registered via `registerAsChildOfContext:`.
@property (nonatomic, strong, readonly) NSSet * childContexts;

/// Adds the managed object context to the `childContexts` container of the specified `context`.
//- (void)registerAsChildOfContext:(NSManagedObjectContext *)context;

/// Method of convenience for deleting multiple managed objects
- (void)deleteObjects:(NSSet *)objects;

/// Method of convenience for going straight from `NSURL` to `NSManagedObject`
- (id)objectForURI:(NSURL *)uri;

- (void)deleteObjectForURI:(NSURL *)uri;

+ (NSManagedObjectContext *)childContextForContext:(NSManagedObjectContext *)context;

////////////////////////////////////////////////////////////////////////////////
#pragma mark Wrappers for MagicalRecord Save Actions
////////////////////////////////////////////////////////////////////////////////

/*
+ (void)saveWithBlock:(CoreDataBlock)block;

+ (void)saveWithBlock:(CoreDataBlock)block completion:(MRSaveCompletionHandler)completion;

+ (void)saveWithBlockAndWait:(CoreDataBlock)block;
*/

/*
+ (void)saveUsingCurrentThreadContextWithBlock:(CoreDataBlock)block
                                    completion:(MRSaveCompletionHandler)completion;

+ (void)saveUsingCurrentThreadContextWithBlockAndWait:(CoreDataBlock)block;
*/

@end
