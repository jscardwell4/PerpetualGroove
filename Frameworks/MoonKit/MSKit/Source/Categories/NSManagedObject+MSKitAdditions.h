//
//  NSManagedObject+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 3/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import CoreData;

#import "MSKitDefines.h"

//MSEXTERN_KEY(MSDefaultValueForContainingClass);
//MSEXTERN_KEY(MSDefaultValueForSubentity);
MSEXTERN_STRING MSDefaultValueForContainingClassKey;
MSEXTERN_STRING MSDefaultValueForSubentityKey;
@interface NSManagedObject (MSKitAdditions)

- (id)committedValueForKey:(NSString *)key;
- (BOOL)hasChangesForKey:(NSString *)key;

- (NSURL *)permanentURI;

+ (instancetype)createInContext:(NSManagedObjectContext *)moc;
- (instancetype)initWithContext:(NSManagedObjectContext *)moc;
+ (instancetype)objectForURI:(NSURL *)uri context:(NSManagedObjectContext *)moc;

+ (instancetype)findFirstInContext:(NSManagedObjectContext *)moc;
- (NSAttributeDescription *)attributeDescriptionForAttribute:(NSString *)attributeName;

- (id)defaultValueForAttribute:(NSString *)attributeName;

- (instancetype)faultedObject;

@end

#define NSManagedObjectFromClass(CONTEXT)                               \
    [NSEntityDescription                                                \
        insertNewObjectForEntityForName:NSStringFromClass([self class]) \
                 inManagedObjectContext:CONTEXT]
