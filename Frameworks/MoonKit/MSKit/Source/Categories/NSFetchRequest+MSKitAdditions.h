//
//  NSFetchedResultsController+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 3/26/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import CoreData;

@interface NSFetchRequest (MSKitAdditions)

+ (NSFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName
                                     predicate:(NSPredicate *)predicate;

@end

#define NSFetchRequestForEntity(ENTITY) [NSFetchRequest fetchRequestWithEntityName:ENTITY]
#define NSFetchRequestFromClass 		NSFetchRequestForEntity(NSStringFromClass([self class]))

#define NSFetchRequestForEntityWithPredicate(ENTITY,FORMAT,...) \
    [NSFetchRequest fetchRequestWithEntityName:ENTITY         \
                                     predicate:[NSPredicate predicateWithFormat:FORMAT,__VA_ARGS__]]

#define NSFetchRequestFromClassWithPredicate(FORMAT,...) \
    NSFetchRequestForEntityWithPredicate(NSStringFromClass([self class]),FORMAT,__VA_ARGS__)
