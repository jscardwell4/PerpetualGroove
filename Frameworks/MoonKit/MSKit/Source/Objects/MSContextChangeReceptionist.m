//
//  MSContextChangeReceptionist.m
//  MSKit
//
//  Created by Jason Cardwell on 3/11/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSContextChangeReceptionist.h"
#import "MSKitMacros.h"

@interface MSContextChangeReceptionist ()

@property (nonatomic, weak,   readwrite) id                observer;
@property (nonatomic, weak,   readwrite) NSManagedObject * object;
@property (nonatomic, strong, readwrite) NSNotification  * notification;
@property (nonatomic, copy,   readwrite) NSString        * name;
@end

@implementation MSContextChangeReceptionist

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(NSManagedObject *)object
                        notificationName:(NSString *)name
                                 handler:(void (^)(MSContextChangeReceptionist * receptionist))handler
{
  if (!object) ThrowInvalidNilArgument(object);

  if (!handler) ThrowInvalidNilArgument(handler);

  MSContextChangeReceptionist * receptionist = [MSContextChangeReceptionist new];
  receptionist.observer = observer;
  receptionist.object   = object;
  receptionist.name     = name;

  NSManagedObjectContext * moc = object.managedObjectContext;

  [NotificationCenter addObserverForName:name
                                  object:moc
                                   queue:nil
                              usingBlock:^(NSNotification * note) {

                                receptionist.notification = note;

                                [moc performBlockAndWait:^{ handler(receptionist); }];

                                receptionist.notification = nil;
                              }];
  return receptionist;
}

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(NSManagedObject *)object
                        notificationName:(NSString *)name
                           updateHandler:(void (^)(MSContextChangeReceptionist * receptionist))update
                           deleteHandler:(void (^)(MSContextChangeReceptionist * receptionist))delete {
  if (!object) ThrowInvalidNilArgument(object);

  if (!(update || delete)) ThrowInvalidArgument(handler, "at least one handler must be non-nil");

  MSContextChangeReceptionist * receptionist = [MSContextChangeReceptionist new];
  receptionist.observer = observer;
  receptionist.object   = object;
  receptionist.name     = name;

  NSManagedObjectContext * moc = object.managedObjectContext;

  [NotificationCenter addObserverForName:name
                                  object:moc
                                   queue:nil
                              usingBlock:^(NSNotification * note) {

                                receptionist.notification = note;

                                if (  update
                                   && [note.userInfo[NSUpdatedObjectsKey] containsObject:object]
                                   && [[object changedValues] count])

                                  [moc performBlockAndWait:^{ update(receptionist); }];


                                if (  delete
                                   && [note.userInfo[NSDeletedObjectsKey] containsObject:object])

                                  [moc performBlockAndWait:^{ delete(receptionist); }];


                                receptionist.notification = nil;

                              }];

  return receptionist;
}

- (void)dealloc {
  [NotificationCenter removeObserver:self name:_name object:_object.managedObjectContext];
}

@end
