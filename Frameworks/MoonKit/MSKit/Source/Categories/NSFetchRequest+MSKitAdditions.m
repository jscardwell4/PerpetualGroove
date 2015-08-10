//
//  NSFetchedResultsController+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 3/26/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSFetchRequest+MSKitAdditions.h"

@implementation NSFetchRequest (MSKitAdditions)

+ (NSFetchRequest *)fetchRequestWithEntityName:(NSString *)entityName predicate:(NSPredicate *)predicate
{
    NSFetchRequest * request = [[NSFetchRequest alloc] initWithEntityName:entityName];
    request.predicate = predicate;
    return request;
}

@end
