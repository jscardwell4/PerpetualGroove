//
//  NSHashTable+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 1/28/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
#import "MSKitProtocols.h"

@interface NSHashTable (MSKitAdditions) <MSKeySearchable>

- (void)enumerateObjectsUsingBlock:(void (^)(id obj, BOOL *stop))block;
- (NSString *)componentsJoinedByString:(NSString *)string;

@end
