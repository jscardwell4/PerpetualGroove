//
//  NSOperationQueue+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 2/5/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSOperationQueue+MSKitAdditions.h"

@implementation NSOperationQueue (MSKitAdditions)

+ (NSOperationQueue *)operationQueueWithName:(NSString *)name {
    NSOperationQueue *queue = [[self alloc] init];
    if (name) queue.name = name;
    return queue;
}

@end
