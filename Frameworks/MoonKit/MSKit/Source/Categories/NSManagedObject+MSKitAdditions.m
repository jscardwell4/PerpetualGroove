//
//  NSManagedObject+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 3/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "NSManagedObject+MSKitAdditions.h"
#import "MSKitMacros.h"
@import CocoaLumberjackSwift;
#import "NSSet+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"
#import "NSDictionary+MSKitAdditions.h"
#import "NSManagedObjectContext+MSKitAdditions.h"
#import "MSLog.h"

MSKEY_DEFINITION(MSDefaultValueForContainingClass);
MSKEY_DEFINITION(MSDefaultValueForSubentity);
static int ddLogLevel   = DDLogLevelDebug;
static int msLogContext = LOG_CONTEXT_CONSOLE;

#pragma unused(ddLogLevel,msLogContext)

@implementation NSManagedObject (MSKitAdditions)

+ (instancetype)createInContext:(NSManagedObjectContext *)moc {
  if (!moc)
    ThrowInvalidNilArgument(moc);

  NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass(self)
                                             inManagedObjectContext:moc];

  if (entity)
    return [[self alloc] initWithEntity:entity insertIntoManagedObjectContext:moc];
  else
    return nil;
}

- (instancetype)initWithContext:(NSManagedObjectContext *)moc {
  if (!moc)
    ThrowInvalidNilArgument(moc);
  NSEntityDescription * entity = [NSEntityDescription entityForName:NSStringFromClass([self class])
                                             inManagedObjectContext:moc];

  if (entity)
    self = [self initWithEntity:entity insertIntoManagedObjectContext:moc];

  return self;
}

+ (instancetype)findFirstInContext:(NSManagedObjectContext *)moc {
  if (!moc) return nil;

  NSFetchRequest * request = [NSFetchRequest fetchRequestWithEntityName:NSStringFromClass(self)];

  request.fetchLimit = 1;
  NSError * error   = nil;
  NSArray * results = [moc executeFetchRequest:request error:&error];

  if (error) { MSHandleErrors(error); }

  if ([results count] > 0) { return results[0]; } else { return nil; }
}

- (id)committedValueForKey:(NSString *)key {
  return NilSafe([self committedValuesForKeys:@[key]][key]);
}

- (BOOL)hasChangesForKey:(NSString *)key {
  if ([self hasChanges] && [self changedValues][key])
    return YES;
  else
    return NO;
}

- (NSURL *)permanentURI {
  if ([self.objectID isTemporaryID])
    [self.managedObjectContext obtainPermanentIDsForObjects:@[self] error:nil];

  return [self.objectID URIRepresentation];
}

+ (instancetype)objectForURI:(NSURL *)uri context:(NSManagedObjectContext *)moc {
  if (!moc) ThrowInvalidNilArgument(moc);
  else if (!uri) ThrowInvalidNilArgument(uri);
  else return [moc objectForURI:uri];
}

- (instancetype)faultedObject {
  return [self.managedObjectContext existingObjectWithID:self.objectID error:nil];
}

- (NSAttributeDescription *)attributeDescriptionForAttribute:(NSString *)attributeName {
  return [self.entity attributesByName][attributeName];
}

- (id)defaultValueForAttribute:(NSString *)attributeName {
  return [self attributeDescriptionForAttribute:attributeName].defaultValue;
}

@end
