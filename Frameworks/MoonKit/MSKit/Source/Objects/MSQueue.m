//
//  MSQueue.m
//  MSKit
//
//  Created by Jason Cardwell on 9/24/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSQueue.h"

@interface MSQueueNode : NSObject
@property (nonatomic, strong) MSQueueNode * next;
@property (nonatomic, strong) id value;
@end
@implementation MSQueueNode @end

@interface MSQueue ()
@property (nonatomic, assign, readwrite) NSUInteger count;
@property (nonatomic, strong) MSQueueNode * head;
@property (nonatomic, strong) MSQueueNode * tail;
@end

@implementation MSQueue

+ (MSQueue *)queue { return [self new]; }

- (BOOL)isEmpty {
    return self->_count == 0;
}

- (void)enqueue:(id)obj {
    MSQueueNode * n = [[MSQueueNode alloc] init];
    n.value = obj;
    if (self.tail) {
        self.tail.next = n;
        self.tail = n;
    } else {
        self.tail = self.head = n;
    }
    self->_count++;
}

- (id)dequeue {
    MSQueueNode * n = self.head;
    id v = n.value;
    if (n) {
        self.head = n.next;
        self->_count--;
        if (self->_count < 2)
            self.tail = self.head;
    }
    return v;
}

- (void)empty {
    self.head = self.tail = nil;
    self->_count = 0;
}


@end
