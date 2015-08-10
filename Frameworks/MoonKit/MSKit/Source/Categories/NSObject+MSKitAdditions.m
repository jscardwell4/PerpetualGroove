//
//  NSObject+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 3/5/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSObject+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import <objc/runtime.h>
#import "MSKitLoggingFunctions.h"

@implementation NSObject (MSKitAdditions)

- (id)JSONValue { return [self description]; }

- (void)addObserver:(NSObject *)observer
        forKeyPaths:(NSArray *)keyPaths
            options:(NSKeyValueObservingOptions)options
            context:(void *)context
{
    [keyPaths enumerateObjectsUsingBlock:^(NSString * keyPath, NSUInteger idx, BOOL *stop) {
        [self addObserver:observer forKeyPath:keyPath options:options context:context];
    }];
}

- (void)removeObserver:(NSObject *)observer
           forKeyPaths:(NSArray *)keyPaths
               context:(void *)context NS_AVAILABLE(10_7, 5_0)
{
    [keyPaths enumerateObjectsUsingBlock:^(NSString * keyPath, NSUInteger idx, BOOL *stop) {
        [self removeObserver:observer forKeyPath:keyPath context:context];
    }];
}

- (void)removeObserver:(NSObject *)observer forKeyPaths:(NSArray *)keyPaths
{
    [keyPaths enumerateObjectsUsingBlock:^(NSString * keyPath, NSUInteger idx, BOOL *stop) {
        [self removeObserver:observer forKeyPath:keyPath];
    }];
}

- (NSDictionary *)dictionaryWithValuesForKeyPaths:(NSArray *)keyPaths
{
    NSMutableDictionary * dictionary = [@{} mutableCopy];
    for (NSString * keyPath in keyPaths)
        dictionary[keyPath] = ([self valueForKeyPath:keyPath] ?: [NSNull null]);

    return dictionary;
}

- (NSString *)shortDescription { return [self description];}

+ (NSArray *)propertyList
{
    unsigned int outcount;
    objc_property_t * properties = class_copyPropertyList([self class], &outcount);
    NSMutableArray * list = [NSMutableArray arrayWithCapacity:outcount];
    for (int i = 0; i < outcount; i++)
        [list addObject:@(property_getName(properties[i]))];
    
    return list;
}

- (NSString *)className { return NSStringFromClass([self class]); }

- (NSString *)classTag { return [NSString stringWithFormat:@"<%@:%p", self.className, self]; }

static const char * MSObjectCommentKey = "MSObjectCommentKey";

- (NSString *)comment { return objc_getAssociatedObject(self, (void *)MSObjectCommentKey); }

- (void)setComment:(NSString *)comment
{
    objc_setAssociatedObject(self,
                             (void *)MSObjectCommentKey,
                             comment,
                             OBJC_ASSOCIATION_COPY_NONATOMIC);
}

- (void)dumpIntrospection { dumpObjectIntrospection(self); }

@end
