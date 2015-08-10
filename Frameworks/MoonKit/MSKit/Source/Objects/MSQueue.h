//
//  MSQueue.h
//  MSKit
//
//  Created by Jason Cardwell on 9/24/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;

@interface MSQueue : NSObject

+ (MSQueue *)queue;
- (void)enqueue:(id)obj;
- (id)dequeue;
- (void)empty;

@property (nonatomic, assign, readonly) BOOL isEmpty;
@property (nonatomic, assign, readonly) NSUInteger count;

@end
