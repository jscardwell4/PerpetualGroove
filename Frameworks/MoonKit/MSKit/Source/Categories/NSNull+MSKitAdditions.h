//
//  NSNull+MSKitAdditions.h
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;

#define NullObject            [NSNull null]

#define ValueIsNil(v)        [NSNull valueIsNil:v]
#define ValueIsNotNil(v)     [NSNull valueIsNotNil:v]
#define CollectionSafe(v)    [NSNull collectionSafeValue:v]
#define NilSafe(v)           [NSNull nilSafeValue:v]

@interface NSNull (MSKitAdditions)

+ (id)collectionSafeValue:(id)value;
+ (id)nilSafeValue:(id)value;
+ (BOOL)valueIsNil:(id)value;
+ (BOOL)valueIsNotNil:(id)value;

@end
