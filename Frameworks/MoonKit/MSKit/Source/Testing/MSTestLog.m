//
//  MSTestLog.m
//  MSKit
//
//  Created by Jason Cardwell on 8/27/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "MSTestLog.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)
@implementation MSTestLog

static MSFileLogger * baseFileLogger_ = nil;
static MSLogFileManager * baseFileManager_ = nil;

+ (NSString *)baseLogDirectory
{
  static NSString const * baseLogDirectory = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    NSError * error = nil;
    NSURL * libraryDirectory = [FileManager URLForDirectory:NSLibraryDirectory
                                                   inDomain:NSUserDomainMask
                                          appropriateForURL:nil
                                                     create:NO
                                                      error:&error];
    MSHandleErrors(error);

    baseLogDirectory = [[libraryDirectory path]
                        stringByAppendingPathComponent:@"Logs/com.moondeerstudios"];

  });
  printf("baseLogDirectory: %s", [baseLogDirectory UTF8String]);
  return (NSString *)baseLogDirectory;
}

+ (void)load {
  [self attachLoggers];
}

+ (void)attachLoggers {

  DDTTYLogger * logger = [DDTTYLogger sharedInstance];

  // Create the log formatter
  MSLogFormatter * formatter =  [MSLogFormatter logFormatterForContext:LOG_CONTEXT_TTY];
  formatter.includeTimestamp        = NO;
  formatter.addReturnAfterPrefix    = NO;
  formatter.includeObjectName       = NO;
  formatter.includeSEL              = NO;
  formatter.addReturnAfterSEL       = NO;
  formatter.addReturnAfterObj       = NO;
  formatter.addReturnAfterMessage   = NO;
  formatter.collapseTrailingReturns = YES;
  formatter.includeLogLevel         = NO;
  formatter.indentMessageBody       = NO;
  formatter.includePrompt           = @">>>";

  logger.logFormatter = formatter;
  [DDLog addLogger:logger];


  baseFileManager_ = [[MSLogFileManager alloc] initWithLogsDirectory:[self baseLogDirectory]];
  baseFileManager_.maximumNumberOfLogFiles = 5;
  baseFileLogger_ = [[MSFileLogger alloc] initWithLogFileManager:baseFileManager_];
  baseFileLogger_.rollingFrequency = 0;
  baseFileLogger_.maximumFileSize  = 0;
  baseFileLogger_.logFormatter = [MSLogFormatter taggingLogFormatterForContext:LOG_CONTEXT_FILE];
  [DDLog addLogger:baseFileLogger_];

}

/*! Sent immediately before running tests to inform the observer that it's time to start observing test progress. Subclasses can override this method, but they must invoke super's implementation. */
- (void) startObserving {
  [super startObserving];
}

/*! Sent immediately after running tests to inform the observer that it's time to stop observing test progress. Subclasses can override this method, but they must invoke super's implementation. */
- (void) stopObserving {
  [super stopObserving];
}

- (void)testSuiteDidStart:(XCTestRun *)testRun {
  NSLog(@"testSuiteDidStart-testRun: %@", [testRun description]);
  [super testSuiteDidStart:testRun];
}

- (void) testSuiteDidStop:(XCTestRun *) testRun {
  [super testSuiteDidStop:testRun];
}

- (void) testCaseDidStart:(XCTestRun *) testRun {
  NSLog(@"testCaseDidStart-testRun: %@", [testRun description]);
  [super testCaseDidStart:testRun];
}

- (void) testCaseDidStop:(XCTestRun *) testRun {
  [super testCaseDidStop:testRun];
}

//- (void) testCaseDidFail:(XCTestRun *) testRun
//         withDescription:(NSString *)description
//                  inFile:(NSString *) filePath
//                  atLine:(NSUInteger) lineNumber
//{
//
//}


@end
