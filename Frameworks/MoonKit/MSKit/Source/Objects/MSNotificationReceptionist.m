//
//  MSNotificationReceptionist.m
//  MSKit
//
//  Created by Jason Cardwell on 8/27/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "MSNotificationReceptionist.h"
#import "MSKitMacros.h"

@interface MSNotificationReceptionist ()

@property (nonatomic, weak,   readwrite) id                 observer;
@property (nonatomic, strong, readwrite) id                 object;
@property (nonatomic, copy,   readwrite) NSString         * name;
@property (nonatomic, strong, readwrite) NSOperationQueue * queue;
@property (nonatomic, strong, readwrite) NSNotification   * notification;

@end

@implementation MSNotificationReceptionist

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                        notificationName:(NSString *)name
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSNotificationReceptionist * receptionist))handler
{

  if (!handler) ThrowInvalidNilArgument(handler);

  MSNotificationReceptionist * receptionist = [MSNotificationReceptionist new];
  receptionist.observer = observer;
  receptionist.object   = object;
  receptionist.name     = name;
  receptionist.queue    = queue;

  [NotificationCenter addObserverForName:name
                                  object:object
                                   queue:queue
                              usingBlock:^(NSNotification * note) {
                                receptionist.notification = note;
                                handler(receptionist);
                                receptionist.notification = nil;
                              }];
  return receptionist;
}

- (void)dealloc { [NotificationCenter removeObserver:self name:_name object:_object]; }

@end
