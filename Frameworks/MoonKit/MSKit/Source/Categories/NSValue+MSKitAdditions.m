//
//  NSValue+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/11/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSValue+MSKitAdditions.h"

@implementation NSValue (MSKitAdditions)

+ (NSValue *)valueWithMSBoundary:(MSBoundary)boundary {
    NSValue * value = [NSValue valueWithBytes:(const void *)&boundary objCType:@encode(MSBoundary)];
    return value;
}

- (MSBoundary)MSBoundaryValue {
    MSBoundary boundary;
    [self getValue:&boundary];
    return boundary;
}

@end
