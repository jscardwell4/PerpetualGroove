//
//  NSURL+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 4/8/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "NSURL+MSKitAdditions.h"

@implementation NSURL (MSKitAdditions)

+ (NSURL *)urlFromData:(NSData *)data
{
    if (!data || ![data isKindOfClass:[NSData class]])
        return nil;

    NSURL * url = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    if ([url isKindOfClass:[NSURL class]])
        return url;
    else
        return nil;
}

- (NSData *)data { return [NSKeyedArchiver archivedDataWithRootObject:self]; }

@end
