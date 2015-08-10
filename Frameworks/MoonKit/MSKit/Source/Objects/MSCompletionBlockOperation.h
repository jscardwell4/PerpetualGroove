//
//  MSCompletionBlockOperation.h
//  MSKit
//
//  Created by Jason Cardwell on 4/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

@import Foundation;

typedef void(^MSEmptyCompletionBlock)(void);
typedef void(^MSBOOLCompletionBlock)(BOOL);
typedef void(^MSBOOLBOOLCompletionBlock)(BOOL, BOOL);
typedef void(^MSBOOLErrorCompletionBlock)(NSError *);
typedef void(^MSErrorCompletionBlock)(BOOL, NSError *);

typedef NS_ENUM(uint8_t, MSCompletionBlockType) {
    MSEmptyCompletionBlockType     = 0,
    MSBOOLCompletionBlockType      = 1,
    MSBOOLBOOLCompletionBlockType  = 2,
    MSBOOLErrorCompletionBlockType = 3,
    MSErrorCompletionBlockType     = 4
};

@interface MSCompletionBlockOperation : NSOperation

+ (MSCompletionBlockOperation *)operationWithTarget:(id)target
                                           selector:(SEL)selector
                                          arguments:(NSArray *)arguments
                                         completion:(id)completion;

@end
