//
//  NSURL+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 4/8/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;

@interface NSURL (MSKitAdditions)

+ (NSURL *)urlFromData:(NSData *)data;

- (NSData *)data;

@end
