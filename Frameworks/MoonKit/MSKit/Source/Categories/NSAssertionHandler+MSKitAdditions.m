//
//  NSAssertionHandler+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 10/26/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "NSAssertionHandler+MSKitAdditions.h"
#import "MSLog.h"

@implementation NSAssertionHandler (MSKitAdditions)


/*
+ (void)load
{
    MSSwapInstanceMethodsForClass(self,
                                  @selector(handleFailureInFunction:file:lineNumber:description:),
                                  @selector(MS_handleFailureInFunction:file:lineNumber:description:));
    MSSwapInstanceMethodsForClass(self,
                                  @selector(handleFailureInMethod:object:file:lineNumber:description:),
                                  @selector(MS_handleFailureInMethod:object:file:lineNumber:description:));
}
*/

- (void)MS_handleFailureInMethod:(SEL)selector
                          object:(id)object
                            file:(NSString *)fileName
                      lineNumber:(int)line
                     description:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    [DDLog log:YES
         level:LOG_LEVEL_ERROR
          flag:LOG_FLAG_ERROR
       context:LOG_CONTEXT_CONSOLE
          file:[fileName UTF8String]
      function:[NSStringFromSelector(selector) UTF8String]
          line:line
           tag:nil
        format:format
          args:args];
    va_end(args);
}

- (void)MS_handleFailureInFunction:(NSString *)functionName
                              file:(NSString *)fileName
                        lineNumber:(int)line
                       description:(NSString *)format, ...
{
    va_list args;
    va_start(args, format);
    [DDLog log:YES
         level:LOG_LEVEL_ERROR
          flag:LOG_FLAG_ERROR
       context:LOG_CONTEXT_CONSOLE
          file:[fileName UTF8String]
      function:[functionName UTF8String]
          line:line
           tag:nil
        format:format
          args:args];
    va_end(args);
}

@end
