//
//  MSLog.m
//  MSKit
//
//  Created by Jason Cardwell on 2/23/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "MSLog.h"
@import Lumberjack;
#import "MSKitMiscellaneousFunctions.h"
#import "NSString+MSKitAdditions.h"
#import "NSOperationQueue+MSKitAdditions.h"
#import "MSKitMacros.h"
#import "NSObject+MSKitAdditions.h"
#import <pthread.h>
#import <objc/runtime.h>
#import <mach/mach_host.h>
#import <mach/host_info.h>
#import <libkern/OSAtomic.h>
#import "NSMutableString+MSKitAdditions.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSLog
////////////////////////////////////////////////////////////////////////////////
@implementation MSLog

+ (void)enableColor { setenv("XCODE_COLORS", "YES", 0); }
+ (void)disableColor { setenv("XCODE_COLORS", "NO", 0); }

+ (BOOL)shouldUseColor {
  char *xcode_colors = getenv("XCODE_COLORS");
  if (xcode_colors && (strcmp(xcode_colors, "YES") == 0)) { return YES; }
  else { return NO; }
}

+ (void)initialize
{
  if (self == [MSLog class])
    [self addDefaultFileLoggerForContext:LOG_CONTEXT_MSKIT
                               directory:[[self defaultLogDirectory]
                                          stringByAppendingPathComponent:@"MSKit"]];
}

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(NSString *)file
   function:(NSString *)function
       line:(int)line
        tag:(id)tag
     format:(NSString *)format
       args:(va_list)argList
{
  if ((level & flag) == flag)
    [DDLog log:asynchronous
         level:level
          flag:flag
       context:context
          file:[file UTF8String]
      function:[function UTF8String]
          line:line
           tag:tag
        format:format
          args:argList];
}

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(NSString *)file
   function:(NSString *)function
       line:(int)line
        tag:(id)tag
    message:(NSString *)message
{
  [self log:asynchronous
      level:level
       flag:flag
    context:context
       file:file
   function:function
       line:line
        tag:tag
     format:@"%@", message];
}

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
       file:(NSString *)file
   function:(NSString *)function
       line:(int)line
        tag:(id)tag
     format:(NSString *)format, ...
{
  va_list args;
  va_start(args, format);
  [self log:asynchronous
      level:level
       flag:flag
    context:context
       file:file
   function:function
       line:line
        tag:tag
     format:format
       args:args];
  va_end(args);
}

+ (void)log:(BOOL)asynchronous
      level:(int)level
       flag:(int)flag
    context:(int)context
   function:(NSString *)function
    message:(NSString *)message
{
  [self log:asynchronous
      level:level
       flag:flag
    context:context
       file:@""
   function:function
       line:0
        tag:nil
    message:message];
}

+ (NSString *)defaultLogDirectory
{
  return [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
                                              NSUserDomainMask,
                                              YES)[0]
          stringByAppendingPathComponent:@"Logs"];

}

+ (NSOperationQueue const *)loggingQueue
{
  static NSOperationQueue const * loggingQueue = nil;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    loggingQueue = [NSOperationQueue operationQueueWithName:@"com.moondeerstudios.mskit.log"];
  });
  return loggingQueue;
}

+ (BOOL)isRegisteredClass:(Class)class
{
  SEL levelGetterSel = @selector(ddLogLevel);
  SEL levelSetterSel = @selector(ddSetLogLevel:);
  SEL contextGetterSel = @selector(msLogContext);
  SEL contextSetterSel = @selector(msSetLogContext:);

#if TARGET_OS_IPHONE && !TARGET_IPHONE_SIMULATOR

  // Issue #6 (GoogleCode) - Crashes on iOS 4.2.1 and iPhone 4
  //
  // Crash caused by class_getClassMethod(2).
  //
  //     "It's a bug with UIAccessibilitySafeCategory__NSObject so it didn't pop up until
  //      users had VoiceOver enabled [...]. I was able to work around it by searching the
  //      result of class_copyMethodList() instead of calling class_getClassMethod()"

  BOOL result = NO;

  unsigned int methodCount, i;
  Method *methodList = class_copyMethodList(object_getClass(class), &methodCount);

  if (methodList != NULL)
  {
    BOOL levelGetterFound = NO;
    BOOL levelSetterFound = NO;
    BOOL contextGetterFound = NO;
    BOOL contextSetterFound = NO;

    for (i = 0; i < methodCount; ++i)
    {
      SEL currentSel = method_getName(methodList[i]);

      if (currentSel == levelGetterSel)
      {
        levelGetterFound = YES;
      }

      else if (currentSel == levelSetterSel)
      {
        levelSetterFound = YES;
      }

      else if (currentSel == contextGetterSel)
      {
        contextSetterFound = YES;
      }

      else if (currentSel == contextSetterSel)
      {
        contextSetterFound = YES;
      }

      if (levelGetterFound && levelSetterFound && contextGetterFound && contextSetterFound)
      {
        result = YES;
        break;
      }
    }

    free(methodList);
  }

  return result;

#else

  // Issue #24 (GitHub) - Crashing in in ARC+Simulator
  //
  // The method +[DDLog isRegisteredClass] will crash a project when using it with ARC + Simulator.
  // For running in the Simulator, it needs to execute the non-iOS code.

  Method levelGetter = class_getClassMethod(class, levelGetterSel);
  Method levelSetter = class_getClassMethod(class, levelSetterSel);
  Method contextGetter = class_getClassMethod(class, contextGetterSel);
  Method contextSetter = class_getClassMethod(class, contextSetterSel);

  if ((levelGetter != NULL) && (levelSetter != NULL) && (contextGetter != NULL) && (contextSetter != NULL))
  {
    return YES;
  }

  Class superClass = class_getSuperclass(class);
  return (superClass ? [self isRegisteredClass:superClass] : NO);

#endif
}

+ (int)logContextForClass:(Class)aClass
{
  if ([self isRegisteredClass:aClass])
  {
    return [aClass msLogContext];
  }

  return -1;
}

+ (int)logContextForClassWithName:(NSString *)aClassName
{
  Class aClass = NSClassFromString(aClassName);

  return [self logContextForClass:aClass];
}

+ (void)setLogContext:(int)logContext forClass:(Class)aClass
{
  if ([self isRegisteredClass:aClass])
  {
    [aClass msSetLogContext:logContext];
  }
}

+ (void)setLogContext:(int)logContext forClassWithName:(NSString *)aClassName
{
  Class aClass = NSClassFromString(aClassName);

  [self setLogContext:logContext forClass:aClass];
}

+ (DDFileLogger *)defaultFileLoggerForContext:(NSUInteger)context directory:(NSString *)directory
{
  MSLogFileManager * fileManager = [[MSLogFileManager alloc] initWithLogsDirectory:directory];
  fileManager.maximumNumberOfLogFiles = 5;
  DDFileLogger * fileLogger = [[DDFileLogger alloc] initWithLogFileManager:fileManager];
  fileLogger.rollingFrequency = 60 * 60 * 24; // * 7;
  fileLogger.maximumFileSize  = 0;
  fileLogger.logFormatter = [MSLogFormatter taggingLogFormatterForContext:(int)context];
  return fileLogger;
}

+ (void)addDefaultFileLoggerForContext:(NSUInteger)context directory:(NSString *)directory
{
  [DDLog addLogger:[self defaultFileLoggerForContext:context directory:directory]];
}

+ (void)addTTYLogger
{
  MSLogFormatter * formatter =  [MSLogFormatter logFormatterForContext:LOG_CONTEXT_TTY];
  formatter.includeLogLevel = NO;
  formatter.includePrompt = @">";
  DDTTYLogger * tty = [DDTTYLogger sharedInstance];
  [tty setLogFormatter:formatter];
  [tty setColorsEnabled:YES];
  [DDLog addLogger:tty];
}

+ (void)addASLLogger
{
  MSLogFormatter * formatter =  [MSLogFormatter logFormatterForContext:LOG_CONTEXT_ASL];
  formatter.includeLogLevel = NO;
  formatter.includePrompt = @">";
  DDASLLogger * asl = [DDASLLogger sharedInstance];
  [asl setLogFormatter:formatter];
  [DDLog addLogger:asl];
}

+ (void)addTaggingTTYLogger
{
  MSLogFormatter * formatter = [MSLogFormatter taggingLogFormatterForContext:LOG_CONTEXT_TTY];
  DDTTYLogger * tty = [DDTTYLogger sharedInstance];
  [tty setLogFormatter:formatter];
  [tty setColorsEnabled:YES];
  [DDLog addLogger:tty];
}

+ (void)addTaggingASLLogger
{
  MSLogFormatter * formatter = [MSLogFormatter taggingLogFormatterForContext:LOG_CONTEXT_ASL];
  DDASLLogger * asl = [DDASLLogger sharedInstance];
  [asl setLogFormatter:formatter];
  [DDLog addLogger:asl];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSLogMessage
////////////////////////////////////////////////////////////////////////////////

#define LOG_LEVEL 2
#define NSLogError(frmt, ...)    do {if (LOG_LEVEL >= 1) NSLog((frmt), ## __VA_ARGS__);} while (0)
#define NSLogWarn(frmt, ...)     do {if (LOG_LEVEL >= 2) NSLog((frmt), ## __VA_ARGS__);} while (0)
#define NSLogInfo(frmt, ...)     do {if (LOG_LEVEL >= 3) NSLog((frmt), ## __VA_ARGS__);} while (0)
#define NSLogVerbose(frmt, ...)  do {if (LOG_LEVEL >= 4) NSLog((frmt), ## __VA_ARGS__);} while (0)

@implementation MSLogMessage @end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSFileLogger
////////////////////////////////////////////////////////////////////////////////

@implementation MSFileLogger

- (void)rollLogFile
{
  if (self.reopenLastFile)
    self.reopenLastFile = NO;

  else
    [super rollLogFile];
}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSLogFileManager
////////////////////////////////////////////////////////////////////////////////
@interface MSLogFileManager ()

@property (nonatomic, copy, readwrite) NSString * currentLogFile;
@property (nonatomic, copy, readwrite) NSString * customLogsDirectory;

@end

@implementation MSLogFileManager

- (NSString *)createNewLogFile
{
  NSString * logsDirectory = [self logsDirectory];
  do
  {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"M∕d∕yy H∶mm∶ss.SSS"];
    NSString *fileName = [[df stringFromDate:CurrentDate] stringByAppendingFormat:@".log"];

    if (self.fileNamePrefix)
      fileName = [self.fileNamePrefix stringByAppendingFormat:@" - %@", fileName];

    else if (![@"Logs" isEqualToString:logsDirectory])
      fileName = [[logsDirectory lastPathComponent] stringByAppendingFormat:@"-%@", fileName];

    NSString *filePath = [logsDirectory stringByAppendingPathComponent:fileName];

    if (![[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
      NSLogVerbose(@"MSLogFileManager: Creating new log file: %@", fileName);

      [[NSFileManager defaultManager] createFileAtPath:filePath contents:nil attributes:nil];

      // Since we just created a new log file, we may need to delete some old log files
      [self deleteOldLogFiles];
      self.currentLogFile = filePath;
      break;
    }

  } while (YES);

  return _currentLogFile;
}

- (NSString *)logsDirectory { return self.customLogsDirectory ?: [super logsDirectory]; }

- (void)setLogsDirectory:(NSString *)logsDirectory
{
  BOOL isValidDirectory = NO;
  if (![[NSFileManager defaultManager] fileExistsAtPath:logsDirectory])
  {
    NSError *err = nil;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:logsDirectory
                                   withIntermediateDirectories:YES attributes:nil error:&err])
    {
      NSLogError(@"DDFileLogManagerDefault: Error creating logsDirectory: %@", err);
    }

    else
      isValidDirectory = YES;
  }

  else
    isValidDirectory = YES;

  if (isValidDirectory) self.customLogsDirectory = logsDirectory;
}

- (BOOL)isLogFile:(NSString *)fileName
{
  return ([fileName hasSuffix:@".log"]);
}

- (NSString *)generateShortUUID { return [MSNonce() substringToIndex:6]; }

- (void)deleteOldLogFiles
{
  NSLogVerbose(@"DDLogFileManagerDefault: deleteOldLogFiles");

  NSUInteger maxNumLogFiles = self.maximumNumberOfLogFiles;
  if (maxNumLogFiles == 0)
  {
    // Unlimited - don't delete any log files
    return;
  }

  NSArray *sortedLogFileInfos = [self sortedLogFileInfos];

  // Do we consider the first file?
  // We are only supposed to be deleting archived files.
  // In most cases, the first file is likely the log file that is currently being written to.
  // So in most cases, we do not want to consider this file for deletion.

  NSUInteger count = [sortedLogFileInfos count];
  BOOL excludeFirstFile = NO;

  if (count > 0)
  {
    DDLogFileInfo *logFileInfo = [sortedLogFileInfos objectAtIndex:0];

    if (!logFileInfo.isArchived)
    {
      excludeFirstFile = YES;
    }
  }

  NSArray *sortedArchivedLogFileInfos;
  if (excludeFirstFile)
  {
    count--;
    sortedArchivedLogFileInfos = [sortedLogFileInfos subarrayWithRange:NSMakeRange(1, count)];
  }
  else
  {
    sortedArchivedLogFileInfos = sortedLogFileInfos;
  }

  NSUInteger i;
  for (i = maxNumLogFiles; i < count; i++)
  {
    DDLogFileInfo *logFileInfo = [sortedArchivedLogFileInfos objectAtIndex:i];

    NSLogInfo(@"DDLogFileManagerDefault: Deleting file: %@", logFileInfo.fileName);

    [[NSFileManager defaultManager] removeItemAtPath:logFileInfo.filePath error:nil];
  }
}

- (void)didRollAndArchiveLogFile:(NSString *)logFilePath {}

@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSLogFormatter
////////////////////////////////////////////////////////////////////////////////

@implementation MSLogFormatter

+ (MSLogFormatter *)logFormatterForContext:(int)context
{
  return [[MSLogFormatter alloc] initWithContext:context];
}

+ (MSLogFormatter *)taggingLogFormatterForContext:(int)context
{
  MSLogFormatter * logFormatter = [self logFormatterForContext:context];
  logFormatter.includeContext          = YES;
  logFormatter.includeTimestamp        = YES;
  logFormatter.addReturnAfterPrefix    = NO;
  logFormatter.includeObjectName       = NO;
  logFormatter.includeSEL              = YES;
  logFormatter.addReturnAfterSEL       = YES;
  logFormatter.addReturnAfterObj       = NO;
  logFormatter.addReturnAfterMessage   = YES;
  logFormatter.collapseTrailingReturns = NO;
  logFormatter.useFileInsteadOfSEL     = NO;
  logFormatter.includeLogLevel         = NO;
  logFormatter.indentMessageBody       = NO;
  return logFormatter;
}

- (id)initWithContext:(int)context
{
  if (self = [super init]) {
    _context           = context;
    _includeLogLevel   = YES;
    _indentMessageBody = YES;
  }

  return self;
}

- (NSString *)formatLogMessage:(DDLogMessage *)logMessage
{
  return (   _context >= 0
          && (   (logMessage->logContext == _context)
              || (logMessage->logContext & _context)
              || (_context & logMessage->logContext))
          ? [self formattedLogMessageForMessage:logMessage]
          : nil);
}

MSKEY_DEFINITION(MSLogClassName);
MSKEY_DEFINITION(MSLogObjectName);
MSKEY_DEFINITION(MSLogObject);
MSKEY_DEFINITION(MSLogContext);

- (NSString *)formattedLogMessageForMessage:(DDLogMessage *)logMessage
{
  NSMutableString * formattedLogMessage = (  _includePrompt
                                           ? [_includePrompt mutableCopy]
                                           : [@"" mutableCopy]);
  NSString * objectName = nil;
  NSString * className  = nil;
  NSString * contextName = nil;
  id         object     = nil;
  if (isDictionaryKind(logMessage->tag))
  {
    NSDictionary * tagDict = (NSDictionary *)logMessage->tag;
    object      = tagDict[MSLogObjectKey];
    objectName  = tagDict[MSLogObjectNameKey];
    contextName = tagDict[MSLogContextKey];
    if (object && !objectName) objectName = [object shortDescription];
    className  = tagDict[MSLogClassNameKey];
    if (object && !className) className = ClassString([object class]);
  }

  if (_includeContext && StringIsNotEmpty(contextName))
    [formattedLogMessage appendFormat:@"(%@) ", contextName];

  if (_includeLogLevel) {
    NSString * logLevel = nil;

    switch (logMessage->logFlag) {
      case LOG_FLAG_ERROR:    logLevel = @"E"; break;
      case LOG_FLAG_WARN:     logLevel = @"W"; break;
      case LOG_FLAG_INFO:     logLevel = @"I"; break;
      case LOG_FLAG_DEBUG:    logLevel = @"D"; break;
      case LOG_FLAG_VERBOSE:  logLevel = @"V"; break;
      default:                logLevel = @"?"; break;
    }
    [formattedLogMessage appendFormat:@"[%@", logLevel];
  }

  if (_includeTimestamp) {
    NSDateFormatter *df = [NSDateFormatter new];
    [df setDateFormat:@"M/d/yy H:mm:ss.SSS"];
    NSString * timeStampSegment = [df stringFromDate:logMessage->timestamp];
    NSString * format = [MSLog shouldUseColor] ? @"\033[fg125,125,125;(%@)\033[fg;" : @"(%@)";
    [formattedLogMessage appendFormat:format, timeStampSegment];
  }

  if (_includeLogLevel) [formattedLogMessage appendString:@"]"];



  if (_addReturnAfterPrefix && formattedLogMessage.length > 0)
    [formattedLogMessage appendString:@"\n"];
  else
    [formattedLogMessage appendString:@" "];

  if (_includeSEL) {
    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet]
          characterIsMember:[formattedLogMessage
                             characterAtIndex:formattedLogMessage.length - 1]])
      [formattedLogMessage appendString:@" "];

    NSString * selSegment = nil;
    if (self.useFileInsteadOfSEL) {
      NSString * fileName = [NSString stringWithUTF8String:logMessage->file].lastPathComponent;
      NSString * functionName = [NSString stringWithUTF8String:logMessage->function];
      selSegment = $(@"«%@» %@", fileName, functionName);
    } else {
      selSegment = (StringIsNotEmpty(className)
                    ? $(@"[%@ %@]", className, [logMessage methodName])
                    : $(@"[%@]", [logMessage methodName]));
    }
    NSString * format = [MSLog shouldUseColor] ? @"\033[fg171,101,38;%@\033[fg;" : @"%@";
    [formattedLogMessage appendFormat:format, selSegment];
    [formattedLogMessage appendString:(_addReturnAfterSEL ? @"\n" : @" ")];
  }

  if (_includeObjectName && StringIsNotEmpty(objectName)) {
    if (![[NSCharacterSet whitespaceAndNewlineCharacterSet]
          characterIsMember:[formattedLogMessage
                             characterAtIndex:formattedLogMessage.length - 1]])
      [formattedLogMessage appendString:@" "];
    [formattedLogMessage appendFormat:@"\u00AB%@\u00BB", objectName];
    [formattedLogMessage appendString:(_addReturnAfterObj ? @"\n" : @" ")];
  }

  if (StringIsNotEmpty(logMessage->logMsg))
  {
    NSString * message = [logMessage->logMsg stringByUnescapingControlCharacters];

    if (_indentMessageBody) message = [message stringByReplacingRegEx:@"\n" withString:@"\n\t"];

    [formattedLogMessage appendString:message];
    if (_addReturnAfterMessage) [formattedLogMessage appendString:@"\n\n"];
    if (_collapseTrailingReturns) [formattedLogMessage replaceRegEx:@"[\\n]+$"
                                                         withString:@""];
  }

  return formattedLogMessage;
}

@end

/*
 ////////////////////////////////////////////////////////////////////////////////
 #pragma mark - MSASLFileLogger
 ////////////////////////////////////////////////////////////////////////////////
 @implementation MSASLFileLogger {
 NSString     * _filePath;
 NSURL        * _fileURL;
 NSFileHandle * _fileHandle;
 aslclient      _client;
 }

 - (id)initWithLogFormatter:(MSLogFormatter *)logFormatter filePath:(NSString *)filePath
 {
 if (self = [super init])
 {
 [self setLogFormatter:logFormatter];
 _filePath = [filePath copy];
 _fileURL = [NSURL fileURLWithPath:filePath];
 _fileHandle = [NSFileHandle fileHandleForWritingAtPath:_filePath];
 _client = asl_open_from_file(_fileHandle.fileDescriptor, NULL, "com.moondeerstudios.aslfile");
 if (asl_add_log_file(_client, _fileHandle.fileDescriptor))
 printf("failed to add log file to asl");
 }
 return self;
 }

 - (void)logMessage:(DDLogMessage *)logMessage
 {
	NSString * logMsg = (formatter
 ? [formatter formatLogMessage:logMessage]
 : logMessage->logMsg);

	if (logMsg)
	{
 const char * msg = [logMsg UTF8String];

 int aslLogLevel;
 switch (logMessage->logFlag)
 {
 // Note: By default ASL will filter anything above level 5 (Notice).
 // So our mappings shouldn't go above that level.

 case LOG_FLAG_ERROR: aslLogLevel = ASL_LEVEL_CRIT;    break;
 case LOG_FLAG_WARN:  aslLogLevel = ASL_LEVEL_ERR;     break;
 case LOG_FLAG_INFO:  aslLogLevel = ASL_LEVEL_WARNING; break;
 default:             aslLogLevel = ASL_LEVEL_NOTICE;  break;
 }

 asl_log(_client, NULL, aslLogLevel, "%s", msg);
	}
 }

 - (NSString *)loggerName
 {
	return @"com.moondeerstudios.aslLogger";
 }

 @end
 */
