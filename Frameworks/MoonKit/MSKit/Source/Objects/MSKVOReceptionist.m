//
//  MSKVOReceptionist.m
//  MSKit
//
//  Created by Jason Cardwell on 10/15/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSKVOReceptionist.h"
#import "MSKitLoggingFunctions.h"
#import "MSKitMacros.h"
#import "NSString+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"


@interface MSKVOReceptionist ()
@property (nonatomic, strong, readwrite) NSArray                  * keyPaths;
@property (nonatomic, strong, readwrite) NSOperationQueue         * queue;
@property (nonatomic, weak,   readwrite) id                         object;
@property (nonatomic, weak,   readwrite) id                         observer;
@property (nonatomic, assign, readwrite) NSKeyValueObservingOptions options;
@property (nonatomic, assign, readwrite) void                     * context;
@property (nonatomic, strong, readwrite) NSDictionary             * change;
@property (nonatomic, copy,   readwrite) void (^handler)(MSKVOReceptionist *);
@end

@implementation MSKVOReceptionist

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                                 keyPath:(NSString *)keyPath
                                 options:(NSKeyValueObservingOptions)options
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSKVOReceptionist * receptionist))handler
{
  return [self receptionistWithObserver:observer
                              forObject:object
                               keyPaths:@[keyPath]
                                options:options
                                  queue:queue
                                handler:handler];
}

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                                keyPaths:(NSArray *)keyPaths
                                 options:(NSKeyValueObservingOptions)options
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSKVOReceptionist * receptionist))handler
{
  if (!object)           ThrowInvalidNilArgument(object);
  if (![keyPaths count]) ThrowInvalidArgument(keyPaths, "keyPaths cannot be nil or empty");
  if (!handler)          ThrowInvalidNilArgument(handler);
  if (!queue)            ThrowInvalidNilArgument(queue);

  MSKVOReceptionist * receptionist = [MSKVOReceptionist new];
  receptionist.observer = observer;
  receptionist.object   = object;
  receptionist.options  = options;
  receptionist.handler  = handler;
  receptionist.queue    = queue;
  receptionist.keyPaths = keyPaths;
  receptionist.context  = &receptionist->_context;

  for (NSString * keyPath in keyPaths)
    [object addObserver:receptionist
             forKeyPath:NSStringFromSelector(NSSelectorFromString(keyPath))
                options:options
                context:receptionist.context];

  return receptionist;
}

/// Receive the observed notification and execute's the registered handler.
- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{

  if(   [self.keyPaths containsObject:NSStringFromSelector(NSSelectorFromString(keyPath))]
     && self.object == object
     && self.context == context)
  {
    __weak MSKVOReceptionist * weakself = self;
    [self.queue addOperationWithBlock:^{
      weakself.change = change;
      if (weakself) weakself.handler(weakself);
      weakself.change = nil;
    }];
  }
}

- (void)dealloc { for (NSString * keyPath in self.keyPaths)
  [self.object removeObserver:self forKeyPath:keyPath context:self.context];
}

@end
