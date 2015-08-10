//
//  NSOrderedSet+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 10/20/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
#import "MSKitProtocols.h"

@interface NSOrderedSet (MSKitAdditions) <MSKeySearchable>

@property (nonatomic, readonly) BOOL isEmpty;
//@property (nonatomic, weak, readonly, nonnull) id JSONObject;
//@property (nonatomic, weak, readonly, nonnull) NSString * JSONString;

- (nonnull NSOrderedSet *)setByMappingToBlock:(id __nonnull (^ __nonnull)(id __nonnull obj))block;

- (nullable id)objectPassingTest:(BOOL (^ __nonnull)(id __nonnull obj, NSUInteger idx))predicate;

- (nonnull NSString *)componentsJoinedByString:(NSString * __nonnull)string;

@end
