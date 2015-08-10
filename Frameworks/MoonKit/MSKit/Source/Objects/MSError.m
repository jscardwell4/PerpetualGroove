//
//  MSError.m
//  MSKit
//
//  Created by Jason Cardwell on 4/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSError.h"

@implementation MSError {
    NSString * _message;
    NSError  * _error;
}

+ (instancetype)errorWithError:(NSError *)error message:(NSString *)message
{
    MSError * e = [self new];
    e->_error   = error;
    e->_message = [message copy];
    return e;
}

- (NSString *)message { return _message; }

- (NSError *)error { return _error; }

@end
