//
//  MSError.h
//  MSKit
//
//  Created by Jason Cardwell on 4/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;

@interface MSError : NSError

+ (instancetype)errorWithError:(NSError *)error message:(NSString *)message;

@property (nonatomic, copy, readonly)   NSString * message;
@property (nonatomic, strong, readonly) NSError  * error;

@end
