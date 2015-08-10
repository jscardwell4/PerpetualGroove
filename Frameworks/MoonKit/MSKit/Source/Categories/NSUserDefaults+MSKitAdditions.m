//
//  NSUserDefaults+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/14/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSUserDefaults+MSKitAdditions.h"

@implementation NSUserDefaults (MSKitAdditions)

- (id)objectForKeyedSubscript:(NSString *)key {
    return [self objectForKey:key];
}
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key {
    [self setObject:object forKey:key];
}

@end
