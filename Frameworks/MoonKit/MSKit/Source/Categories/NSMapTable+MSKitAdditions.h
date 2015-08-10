//
//  NSMapTable+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/14/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//


@import Foundation;
@import UIKit;
#import "MSKitProtocols.h"

@interface NSMapTable (MSKitAdditions) <MSKeySearchable, MSKeyContaining>

+ (id)weakToWeakObjectsMapTableFromDictionary:(NSDictionary *)dictionary;
+ (id)weakToStrongObjectsMapTableFromDictionary:(NSDictionary *)dictionary;
+ (id)strongToWeakObjectsMapTableFromDictionary:(NSDictionary *)dictionary;
+ (id)strongToStrongObjectsMapTableFromDictionary:(NSDictionary *)dictionary;
- (void)setObject:(id)object forKeyedSubscript:(id <NSCopying>)key;
- (id)objectForKeyedSubscript:(id)key;
- (NSArray *)allKeys;
- (BOOL)hasKey:(id<NSCopying>)key;
@end
