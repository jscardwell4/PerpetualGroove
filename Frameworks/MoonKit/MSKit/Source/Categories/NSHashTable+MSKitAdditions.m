//
//  NSHashTable+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 1/28/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSHashTable+MSKitAdditions.h"
#import "NSSet+MSKitAdditions.h"
@implementation NSHashTable (MSKitAdditions)

- (NSArray *)allValues { return self.allObjects; }

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block {
    [[self setRepresentation] enumerateObjectsUsingBlock:block];
}
- (NSString *)componentsJoinedByString:(NSString *)string {
    return [[self setRepresentation] componentsJoinedByString:string];
}

@end
