//
//  MSCompletionBlockOperation.m
//  MSKit
//
//  Created by Jason Cardwell on 4/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "MSCompletionBlockOperation.h"
#import "NSArray+MSKitAdditions.h"
#import <objc/runtime.h>

@implementation MSCompletionBlockOperation {
    BOOL       _finished;
    BOOL       _executing;
    BOOL       _success;
    id         _target;
    SEL        _selector;
    NSArray  * _arguments;
    id         _completion;
    NSString * _encoding;
}

+ (MSCompletionBlockOperation *)operationWithTarget:(id)target
                                           selector:(SEL)selector
                                          arguments:(NSArray *)arguments
                                         completion:(id)completion
{
    MSCompletionBlockOperation * blockOperation = [self new];
    blockOperation->_target     = target;
    blockOperation->_selector   = selector;
    blockOperation->_arguments  = [arguments copy];
    blockOperation->_completion = [completion copy];
    return blockOperation;
}

- (BOOL)isConcurrent { return YES; }

- (void)start
{

    assert(_target && _selector && _arguments);


/*
    if (![_target respondsToSelector:_selector])
        // bug out
        ;

    Method method = ([_target class] == _target
                     ? class_getClassMethod([_target class], _selector)
                     : class_getInstanceMethod([_target class], _selector));

    const char * encoding = method_getTypeEncoding(method);
    unsigned int numberOfArguments = method_getNumberOfArguments(method);

*/
    // Always check for cancellation before launching the task.
    if ([self isCancelled])
    {
        [self willChangeValueForKey:@"isFinished"];
        _finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

    // If the operation is not canceled, begin executing the task.
    [self willChangeValueForKey:@"isExecuting"];
    [NSThread detachNewThreadSelector:@selector(main) toTarget:self withObject:nil];
    _executing = YES;
    [self didChangeValueForKey:@"isExecuting"];
}

- (BOOL)isExecuting { return _executing; }

- (BOOL)isFinished { return _finished; }

- (void)main
{

    // do work

    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];
    _executing = NO;
    _finished = YES;
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

- (BOOL)wasSuccessful { return (_success && _finished && ![self isCancelled]); }


@end
