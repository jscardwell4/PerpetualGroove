//
//  MSKVOReceptionist.h
//  MSKit
//
//  Created by Jason Cardwell on 10/15/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
#import "MSKitDefines.h"

@interface MSKVOReceptionist : NSObject

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                                 keyPath:(NSString *)keyPath
                                 options:(NSKeyValueObservingOptions)options
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSKVOReceptionist * receptionist))handler;

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                                keyPaths:(NSArray *)keyPaths
                                 options:(NSKeyValueObservingOptions)options
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSKVOReceptionist * receptionist))handler;

@property (nonatomic, strong, readonly) NSArray                  * keyPaths;
@property (nonatomic, strong, readonly) NSOperationQueue         * queue;
@property (nonatomic, weak,   readonly) id                         object;
@property (nonatomic, weak,   readonly) id                         observer;
@property (nonatomic, assign, readonly) void                     * context;
@property (nonatomic, strong, readonly) NSDictionary             * change;
@property (nonatomic, assign, readonly) NSKeyValueObservingOptions options;
@property (nonatomic, copy,   readonly) void (^handler)(MSKVOReceptionist *);

@end
