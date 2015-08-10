//
//  NSManagedObjectContext+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 1/23/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "NSManagedObjectContext+MSKitAdditions.h"
#import <objc/runtime.h>
#import "MSKitMiscellaneousFunctions.h"

static const char * kNSMOCChildContextsKey = "kNSMMOCChildContextsKey";

@implementation NSManagedObjectContext (MSKitAdditions)

+ (void)load
{

//    MSSwapInstanceMethodsForClass(self, @selector(performBlock:), @selector(MS_performBlock:));
//    MSSwapInstanceMethodsForClass(self, @selector(performBlockAndWait:), @selector(MS_performBlockAndWait:));
    MSSwapInstanceMethodsForClass(self, @selector(setParentContext:), @selector(MS_setParentContext:));
}

- (void)MS_setParentContext:(NSManagedObjectContext *)context
{
    if (self.parentContext && self.parentContext != context)
    {
        NSHashTable * childContexts = [self.parentContext childContextHashTable];
        [childContexts removeObject:self];
        objc_setAssociatedObject(self.parentContext,
                                 kNSMOCChildContextsKey,
                                 childContexts,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    if (context)
    {
        NSHashTable * childContexts = [context childContextHashTable];
        [childContexts addObject:self];
        objc_setAssociatedObject(context,
                                 kNSMOCChildContextsKey,
                                 childContexts,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }

    [self MS_setParentContext:context];
}

- (void)MS_performBlock:(void (^)())block
{
    if (self.concurrencyType == NSConfinementConcurrencyType) block();
    else [self MS_performBlock:block];
}

- (void)MS_performBlockAndWait:(void (^)())block
{
    if (self.concurrencyType == NSConfinementConcurrencyType) block();
    else [self MS_performBlockAndWait:block];
}

- (NSHashTable *)childContextHashTable
{
    NSHashTable * childContexts = objc_getAssociatedObject(self, (void *)kNSMOCChildContextsKey);
    if (!childContexts)
    {
        childContexts = [NSHashTable weakObjectsHashTable];
        objc_setAssociatedObject(self,
                                 kNSMOCChildContextsKey,
                                 childContexts,
                                 OBJC_ASSOCIATION_RETAIN_NONATOMIC);
    }
    return childContexts;
}

/*
- (void)registerAsChildOfContext:(NSManagedObjectContext *)context
{
    [self performBlockAndWait:
     ^{
         if (self.parentContext != context) self.parentContext = context;
         NSHashTable * childContexts = [context childContextHashTable];
         [childContexts addObject:self];
     }];
}
*/

- (NSSet *)childContexts
{
    NSHashTable * childContexts =  objc_getAssociatedObject(self, (void *)kNSMOCChildContextsKey);
    return [childContexts setRepresentation];
}

- (NSString *)nametag { return self.userInfo[@"nametag"]; }

- (void)setNametag:(NSString *)nametag { self.userInfo[@"nametag"] = nametag; }

- (void)deleteObjects:(NSSet *)objects
{
    assert([objects objectsPassingTest:^BOOL(id obj, BOOL *stop) {
        return [obj isKindOfClass:[NSManagedObject class]];
    }].count == objects.count);
    for (NSManagedObject * object in objects) {
        [self deleteObject:object];
    }
}

- (id)objectForURI:(NSURL *)uri
{
    NSManagedObjectID * objectID = [self.persistentStoreCoordinator
                                    managedObjectIDForURIRepresentation:uri];

    return (objectID ? [self objectWithID:objectID] : nil);
}

- (void)deleteObjectForURI:(NSURL *)uri {
  NSManagedObject * object = [self objectForURI:uri];
  if (object) [self deleteObject:object];
}

+ (NSManagedObjectContext *)childContextForContext:(NSManagedObjectContext *)context {
  if (!context) { return nil; }
  NSManagedObjectContext * childContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:context.concurrencyType];
  childContext.parentContext = context;
  return childContext;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Wrappers for MagicalRecord Save Actions
////////////////////////////////////////////////////////////////////////////////

/*
+ (void)saveWithBlock:(CoreDataBlock)block
{
    [MagicalRecord saveWithBlock:
     ^(NSManagedObjectContext *localContext)
     {
         if (localContext.parentContext)
             [localContext registerAsChildOfContext:localContext.parentContext];
         block(localContext);
     }];
}

+ (void)saveWithBlock:(CoreDataBlock)block completion:(MRSaveCompletionHandler)completion
{
    [MagicalRecord saveWithBlock:
     ^(NSManagedObjectContext *localContext)
     {
        if (localContext.parentContext)
            [localContext registerAsChildOfContext:localContext.parentContext];
        block(localContext);
    } completion:completion];
}

+ (void)saveWithBlockAndWait:(CoreDataBlock)block
{
    [MagicalRecord saveWithBlockAndWait:
     ^(NSManagedObjectContext *localContext)
     {
        if (localContext.parentContext)
            [localContext registerAsChildOfContext:localContext.parentContext];
        block(localContext);
    }];
}
*/

/*
+ (void)saveUsingCurrentThreadContextWithBlock:(CoreDataBlock)block
                                    completion:(MRSaveCompletionHandler)completion
{
    [MagicalRecord saveUsingCurrentThreadContextWithBlock:
     ^(NSManagedObjectContext *localContext)
     {
         if (localContext.parentContext)
             [localContext registerAsChildOfContext:localContext.parentContext];
         block(localContext);
     } completion:completion];
}

+ (void)saveUsingCurrentThreadContextWithBlockAndWait:(CoreDataBlock)block
{
    [MagicalRecord saveUsingCurrentThreadContextWithBlockAndWait:
     ^(NSManagedObjectContext *localContext)
     {
         if (localContext.parentContext)
             [localContext registerAsChildOfContext:localContext.parentContext];
         block(localContext);
     }];
}
*/



@end
