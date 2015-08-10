//
//  NSObject+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 3/5/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//


@import Foundation;

@interface NSObject (MSKitAdditions)

- (void)addObserver:(NSObject *)observer
        forKeyPaths:(NSArray *)keyPaths
            options:(NSKeyValueObservingOptions)options
            context:(void *)context;

- (void)removeObserver:(NSObject *)observer
           forKeyPaths:(NSArray *)keyPaths
               context:(void *)context NS_AVAILABLE(10_7, 5_0);

- (void)removeObserver:(NSObject *)observer forKeyPaths:(NSArray *)keyPaths;

- (NSDictionary *)dictionaryWithValuesForKeyPaths:(NSArray *)keyPaths;

+ (NSArray *)propertyList;

- (void)dumpIntrospection;

//@property (nonatomic, readonly) id         JSONValue;
@property (nonatomic, readonly) NSString * shortDescription;
@property (nonatomic, readonly) NSString * className;
@property (nonatomic, readonly) NSString * classTag;
@property (nonatomic, copy)     NSString * comment;

@end
