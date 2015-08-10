//
//  NSSet+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 4/24/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "NSSet+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "MSLog.h"
#import "NSMutableString+MSKitAdditions.h"
#import "MoonKit/MoonKit-Swift.h"

static int ddLogLevel = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@implementation NSSet (MSKitAdditions)

- (NSArray *)allValues { return [self allObjects]; }

- (BOOL)isEmpty { return self.count == 0; }

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
//        return nil;
//    }
//
//    else
//    {
//        NSMutableString * jsonString = [[NSString stringWithData:jsonData] mutableCopy];
//        [jsonString replaceRegEx:@"^(\\s*\"[^\"]+\") :" withString:@"$1:"];
//        return jsonString;
//    }
//}

//- (id)JSONObject { return [self allObjects].JSONObject; }

+ (NSSet *)setWithArrays:(NSArray *)arrays {
    NSMutableSet * set = [NSMutableSet set];
    for (NSArray * array in arrays)
        if ([array isKindOfClass:[NSArray class]]) [set addObjectsFromArray:array];
    return set;
}

- (NSString *)componentsJoinedByString:(NSString *)string {
    return [[self allObjects] componentsJoinedByString:string];
}

- (NSSet *)setByRemovingObjectsFromSet:(NSSet *)other {
    return 
        [self
         objectsPassingTest:^BOOL(id obj, BOOL *stop) {return ![other containsObject:obj];}];
}

- (NSSet *)setByRemovingObjectsFromArray:(NSArray *)other {
    return 
        [self
         objectsPassingTest:^BOOL(id obj, BOOL *stop) {return ![other containsObject:obj];}];
}

- (NSSet *)setByRemovingObject:(id)object {
    return [self
            objectsPassingTest:^BOOL(id obj, BOOL *stop) {return (obj != object);}];
}

- (NSSet *)setByIntersectingSet:(NSSet *)other {
    return 
        [self
         objectsPassingTest:^BOOL(id obj, BOOL *stop) {return [other containsObject:obj];}];
}

- (NSSet *)setByIntersectingArray:(NSArray *)other {
    return 
        [self
         objectsPassingTest:^BOOL(id obj, BOOL *stop) {return [other containsObject:obj];}];
}

- (NSSet *)setByMappingToBlock:(id (^)(id obj))block {
    NSMutableSet * set = [NSMutableSet setWithCapacity:self.count];
    for (id obj in [self allObjects])
        [set addObject:block(obj)];
    return set;
}

- (id)objectPassingTest:(BOOL (^)(id))predicate {
    __block id passingObject = nil;
    [self enumerateObjectsUsingBlock:^(id obj, BOOL *stop) {
        if (predicate(obj)) {
            passingObject = obj;
            *stop = YES;
        }
    }];
    return passingObject;
}

- (NSSet *)filteredSetUsingPredicateWithFormat:(NSString *)format,... {
    va_list args;
    va_start(args, format);
    NSPredicate * predicate = [NSPredicate predicateWithFormat:format arguments:args];
    va_end(args);
    if (!predicate) {
        return nil;
    } else
        return [self filteredSetUsingPredicate:predicate];
}

- (NSSet *)filteredSetUsingPredicateWithBlock:(BOOL (^)(id evaluatedObject, NSDictionary *bindings))block {
    return [self filteredSetUsingPredicate:[NSPredicate predicateWithBlock:block]];
}


- (BOOL)containsObjectWithValue:(id)value forKey:(NSString *)key
{
    return ([self objectPassingTest:^BOOL(id obj)
             {
                 @try
                 {
                     if ([value isKindOfClass:[NSString class]])
                         return [value isEqualToString:[obj valueForKey:key]];
                     else
                         return (value == [obj valueForKey:key]);
                 }
                 
                 @catch (NSException *exception) { return NO; }
                 
             }]
            ? YES
            : NO);
}

- (id)objectWithValue:(id)value forKey:(NSString *)key
{
    id object = [self objectPassingTest:^BOOL(id obj)
             {
                 @try
                 {
                     if ([value isKindOfClass:[NSString class]])
                         return [value isEqualToString:[obj valueForKey:key]];
                     else
                         return (value == [obj valueForKey:key]);
                 }

                 @catch (NSException *exception) { return NO; }

             }];
    
    return object;
}

- (NSSet *)objectsWithValue:(id)value forKey:(NSString *)key
{
    NSSet * objects = [self objectsPassingTest:^BOOL(id obj, BOOL * stop)
                       {
                           @try
                           {
                               if ([value isKindOfClass:[NSString class]])
                                   return [value isEqualToString:[obj valueForKey:key]];
                               else
                                   return (value == [obj valueForKey:key]);
                           }

                           @catch (NSException *exception) { return NO; }
                           
                       }];
    
    return objects;
}

@end

@implementation NSMutableSet (MSKitAdditions)

- (void)addOrRemoveObject:(id)object
{
    if ([self member:object]) [self removeObject:object];
    else [self addObject:object];
}

@end