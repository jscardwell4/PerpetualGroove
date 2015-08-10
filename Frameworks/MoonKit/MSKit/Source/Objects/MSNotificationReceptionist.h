//
//  MSNotificationReceptionist.h
//  MSKit
//
//  Created by Jason Cardwell on 8/27/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

@import Foundation;

@interface MSNotificationReceptionist : NSObject

+ (instancetype)receptionistWithObserver:(id)observer
                               forObject:(id)object
                        notificationName:(NSString *)name
                                   queue:(NSOperationQueue *)queue
                                 handler:(void (^)(MSNotificationReceptionist * receptionist))handler;

@property (nonatomic, weak,   readonly) id                  observer;
@property (nonatomic, strong, readonly) id                  object;
@property (nonatomic, copy,   readonly) NSString          * name;
@property (nonatomic, strong, readonly) NSOperationQueue  * queue;
@property (nonatomic, strong, readonly) NSNotification    * notification;


@end
