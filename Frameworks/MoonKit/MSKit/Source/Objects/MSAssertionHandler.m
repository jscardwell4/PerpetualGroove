//
//  MSAssertionHandler.m
//  MSKit
//
//  Created by Jason Cardwell on 3/6/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSAssertionHandler.h"
#import "MSKitLoggingFunctions.h"
#import "NSString+MSKitAdditions.h"

@implementation MSAssertionHandler

- (void)handleFailureInFunction:(NSString *)functionName
                           file:(NSString *)fileName
                     lineNumber:(NSInteger)line
                    description:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    {
        nsprintf(@"\u00ABASSERTION FAILURE\u00BB [%@] %@\n",
                 functionName,
                 [[NSString alloc] initWithFormat:format arguments:args]);
    }
    va_end(args);
}

- (void)handleFailureInMethod:(SEL)selector
                       object:(id)object
                         file:(NSString *)fileName
                   lineNumber:(NSInteger)line
                  description:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    {
        nsprintf(@"\u00ABASSERTION FAILURE\u00BB [%@ %@] %@\n",
                 ClassString([object class]),
                 SelectorString(selector),
                 [[NSString alloc] initWithFormat:format arguments:args]);
    }
     va_end(args);
}

@end
