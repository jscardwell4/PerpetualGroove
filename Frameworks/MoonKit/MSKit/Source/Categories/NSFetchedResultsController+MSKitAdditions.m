//
//  NSFetchedResultsController+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/28/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSFetchedResultsController+MSKitAdditions.h"

@implementation NSFetchedResultsController (MSKitAdditions)

- (id)objectForKeyedSubscript:(id)key
{
    return ([key isKindOfClass:[NSIndexPath class]]
            ? [self objectAtIndexPath:(NSIndexPath *)key]
            : ([key isKindOfClass:[NSManagedObject class]]
               ? [self indexPathForObject:key]
               : nil));
}

@end
