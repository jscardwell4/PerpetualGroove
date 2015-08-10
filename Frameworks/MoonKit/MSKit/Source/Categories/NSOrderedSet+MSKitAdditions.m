//
//  NSOrderedSet+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/20/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSOrderedSet+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "NSMutableString+MSKitAdditions.h"
#import "MSLog.h"
#import "MoonKit/MoonKit-Swift.h"

static int ddLogLevel = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@implementation NSOrderedSet (MSKitAdditions)

- (NSArray *)allValues { return self.array; }

- (BOOL)isEmpty { return self.count == 0; }

- (NSOrderedSet *)setByMappingToBlock:(id (^)(id obj))block {
    NSMutableOrderedSet * set = [NSMutableOrderedSet orderedSetWithCapacity:self.count];
    for (id obj in self)
        [set addObject:block(obj)];
    return set;
}

- (id)objectPassingTest:(BOOL (^)(id obj, NSUInteger idx))predicate {
    __block id object = nil;
    [self enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        if (predicate(obj, idx))
        {
            *stop = YES;
            object = obj;
        }
    }];
    return object;
}

- (NSString *)componentsJoinedByString:(NSString *)string {
    return [[self array] componentsJoinedByString:string];
}

//- (NSString *)JSONString
//{
//    id jsonObject = self.JSONObject;
//    NSError * error;
//    NSData * jsonData = [NSJSONSerialization dataWithJSONObject:jsonObject
//                                                        options:NSJSONWritingPrettyPrinted
//                                                          error:&error];
//    if (error || !jsonData)
//    {
//        MSHandleErrors(error);
//        return @"";
//    }
//
//    else
//    {
//        NSMutableString * jsonString = [[NSString stringWithData:jsonData] mutableCopy];
//        [jsonString replaceRegEx:@"^(\\s*\"[^\"]+\") :" withString:@"$1:"];
//        return jsonString;
//    }
//}


//- (id)JSONObject { return [self array].JSONObject; }

@end
