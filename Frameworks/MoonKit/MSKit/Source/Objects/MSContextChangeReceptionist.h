//
//  MSContextChangeReceptionist.h
//  MSKit
//
//  Created by Jason Cardwell on 3/11/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import CoreData;
#import "MSKitDefines.h"

@interface MSContextChangeReceptionist : NSObject

+ (instancetype)receptionistWithObserver:(id)observer
															 forObject:(NSManagedObject *)object
		                    notificationName:(NSString *)name
		                             handler:(void(^)(MSContextChangeReceptionist * receptionist))handler;

+ (instancetype)receptionistWithObserver:(id)observer
															 forObject:(NSManagedObject *)object
                        notificationName:(NSString *)name
                           updateHandler:(void(^)(MSContextChangeReceptionist * receptionist))update
                           deleteHandler:(void(^)(MSContextChangeReceptionist * receptionist))delete;


@property (nonatomic, weak,   readonly) id                  observer;
@property (nonatomic, weak,   readonly) NSManagedObject   * object;
@property (nonatomic, strong, readonly) NSNotification    * notification;
@property (nonatomic, copy,   readonly) NSString          * name;

@end
