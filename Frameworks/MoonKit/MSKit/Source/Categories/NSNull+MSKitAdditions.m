//
//  NSNull+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSNull+MSKitAdditions.h"

@implementation NSNull (MSKitAdditions)

+ (id)collectionSafeValue:(id)value {
    return (value == nil ? [NSNull null] : value);
}

+ (id)nilSafeValue:(id)value {
	return (value == [NSNull null] ? nil : value);
}

+ (BOOL)valueIsNil:(id)value {
    return (value == nil || value == [NSNull null]);
}

+ (BOOL)valueIsNotNil:(id)value {
    return ![NSNull valueIsNil:value];
}

@end
