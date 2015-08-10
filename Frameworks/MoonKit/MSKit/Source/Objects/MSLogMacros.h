//
//  MSLogMacros.h
//  MSKit
//
//  Created by Jason Cardwell on 10/26/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

////////////////////////////////////////////////////////////////////////////////
#pragma mark Xcode Colors
////////////////////////////////////////////////////////////////////////////////

#define XCODE_COLORS_ESCAPE @"\033["

#define XCODE_COLORS_RESET_FG  XCODE_COLORS_ESCAPE @"fg;" // Clear any foreground color
#define XCODE_COLORS_RESET_BG  XCODE_COLORS_ESCAPE @"bg;" // Clear any background color
#define XCODE_COLORS_RESET     XCODE_COLORS_ESCAPE @";"   // Clear any foreground or background color

////////////////////////////////////////////////////////////////////////////////
#pragma mark Log flags
////////////////////////////////////////////////////////////////////////////////


// #define LOG_FLAG_ERROR              0b0000000000000001
// #define LOG_FLAG_WARN               0b0000000000000010
// #define LOG_FLAG_INFO               0b0000000000000100
// #define LOG_FLAG_DEBUG              0b0000000000001000
// #define LOG_FLAG_VERBOSE            0b0000000000010000

#define LOG_FLAG_TTY                   0b0000000000100000
#define LOG_FLAG_ASL                   0b0000000001000000
#define LOG_FLAG_CONSOLE               0b0000000001100000
#define LOG_FLAG_FILE                  0b0000000010000000
#define LOG_FLAG_UNITTEST              0b0000000100000000
#define LOG_FLAG_UNITTESTPASS          0b0000001000000000
#define LOG_FLAG_UNITTESTFAIL          0b0000010000000000
#define LOG_FLAG_MSKIT                 0b0000100000000000
#define LOG_FLAG_MAGICALRECORD         0b0001000000000000


////////////////////////////////////////////////////////////////////////////////
#pragma mark Log levels
////////////////////////////////////////////////////////////////////////////////


// #define LOG_LEVEL_OFF       0b0000000000000000
// #define LOG_LEVEL_ERROR     0b0000000000000001
// #define LOG_LEVEL_WARN      0b0000000000000011
// #define LOG_LEVEL_INFO      0b0000000000000111
// #define LOG_LEVEL_DEBUG     0b0000000000001111
// #define LOG_LEVEL_VERBOSE   0b0000000000011111
#define LOG_LEVEL_UNITTEST     0b1111111111111111

// #define LOG_ERROR    (ddLogLevel & LOG_FLAG_ERROR   )
// #define LOG_WARN     (ddLogLevel & LOG_FLAG_WARN    )
// #define LOG_INFO     (ddLogLevel & LOG_FLAG_INFO    )
// #define LOG_VERBOSE  (ddLogLevel & LOG_FLAG_VERBOSE )
//#define LOG_DEBUG       (ddLogLevel & LOG_FLAG_DEBUG   )
#define LOG_UNITTEST    (ddLogLevel & LOG_FLAG_UNITTEST)

// #define LOG_ASYNC_ERROR    (NO  && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_WARN     (YES && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_INFO     (YES && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_VERBOSE  (YES && LOG_ASYNC_ENABLED)
//#undef LOG_ASYNC_DEBUG
//#define LOG_ASYNC_DEBUG       (NO  && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_UNITTEST    (NO  && LOG_ASYNC_ENABLED)


////////////////////////////////////////////////////////////////////////////////
#pragma mark Log contexts
////////////////////////////////////////////////////////////////////////////////


#define LOG_CONTEXT_DEFAULT  0b0000000000000000
#define LOG_CONTEXT_FILE     0b0000000000000001
#define LOG_CONTEXT_TTY      0b0000000000000010
#define LOG_CONTEXT_ASL      0b0000000000000100
#define LOG_CONTEXT_CONSOLE  0b0000000000000110
#define LOG_CONTEXT_MSKIT    0b0000000000001000
#define LOG_CONTEXT_UNITTEST 0b0000000000010111
#define LOG_CONTEXT_ANY      0b1111111111111111


////////////////////////////////////////////////////////////////////////////////
#pragma mark Base Logging Macros
////////////////////////////////////////////////////////////////////////////////


// Wrapper for Lumberjack's `LOG_MACRO` through which all following macros are funneled,
// in case I ever want to alter behavior
#define MSLOG_MACRO(isAsynchronous,lvl,flg,ctx,atag,fnct,frmt,...) \
    LOG_MACRO(isAsynchronous,lvl,flg,ctx,atag,fnct,frmt,##__VA_ARGS__)

// Objective-C macro funnel
#define MSLOG_OBJC_MACRO(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MACRO(async,lvl,flg,ctx,nil,sel_getName(_cmd),frmt,##__VA_ARGS__)

// Synchronous Objective-C macro funnel
#define MSSYNC_LOG_OBJC_MACRO(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MACRO( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous Objective-C macro funnel
#define MSASYNC_LOG_OBJC_MACRO(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MACRO(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// C function macro funnel
#define MSLOG_C_MACRO(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MACRO(async,lvl,flg,ctx,nil,__FUNCTION__,frmt,##__VA_ARGS__)

// Synchronous C function macro funnel
#define MSSYNC_LOG_C_MACRO(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MACRO( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous C function macro funnel
#define MSASYNC_LOG_C_MACRO(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MACRO(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Level dependent macro funnel
#define MSLOG_MAYBE(async,lvl,flg,ctx,fnct,frmt,...) \
    WRAP(if(lvl & flg) MSLOG_MACRO(async,lvl,flg,ctx,nil,fnct,frmt,##__VA_ARGS__);)

// Objective-C level dependent macro funnel
#define  MSLOG_OBJC_MAYBE(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MAYBE(async,lvl,flg,ctx,sel_getName(_cmd),frmt,##__VA_ARGS__)

// Synchronous Objective-C level dependent macro funnel
#define  MSSYNC_LOG_OBJC_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MAYBE( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous Objective-C level dependent macro funnel
#define  MSASYNC_LOG_OBJC_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// C function level dependent macro funnel
#define  MSLOG_C_MAYBE(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MAYBE(async,lvl,flg,ctx,__FUNCTION__,frmt,##__VA_ARGS__)

// Synchronous C function level dependent macro funnel
#define  MSSYNC_LOG_C_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MAYBE( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous C function level dependent macro funnel
#define  MSASYNC_LOG_C_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MAYBE(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Objective-C with tag macro funnel
#define MSLOG_OBJC_TAG_MACRO(async,lvl,flg,ctx,tag,frmt,...) \
    MSLOG_MACRO(async,lvl,flg,ctx,tag,sel_getName(_cmd),frmt,##__VA_ARGS__)

// C function with tag macro funnel
#define MSLOG_C_TAG_MACRO(async,lvl,flg,ctx,tag,frmt,...) \
    MSLOG_MACRO(async,lvl,flg,ctx,tag,__FUNCTION__,frmt,##__VA_ARGS__)

// Level dependent with tag macro funnel
#define MSLOG_TAG_MAYBE(async,lvl,flg,ctx,tag,fnct,frmt,...) \
    WRAP(if(lvl & flg) MSLOG_MACRO(async,lvl,flg,ctx,tag,fnct,frmt,##__VA_ARGS__);)

// Objective-C level dependent with tag macro funnel
#define MSLOG_OBJC_TAG_MAYBE(async,lvl,flg,ctx,tag,frmt,...) \
    MSLOG_TAG_MAYBE(async,lvl,flg,ctx,tag,sel_getName(_cmd),frmt,##__VA_ARGS__)

// C function level dependent with tag macro funnel
#define MSLOG_C_TAG_MAYBE(async,lvl,flg,ctx,tag,frmt,...) \
    MSLOG_TAG_MAYBE(async,lvl,flg,ctx,tag,__FUNCTION__,frmt,##__VA_ARGS__)

#define _LVL ddLogLevel
#define _CTX msLogContext

// Log Objective-C with LOG_FLAG_ERROR
#define MSLogErrorInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,frmt,##__VA_ARGS__)

// Log Objective-C with LOG_FLAG_WARN
#define MSLogWarnInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,frmt,##__VA_ARGS__)

// Log Objective-C with LOG_FLAG_INFO
#define MSLogInfoInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,frmt,##__VA_ARGS__)

// Log Objective-C with LOG_FLAG_VERBOSE
#define MSLogVerboseInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,frmt,##__VA_ARGS__)

// Log Objective-C with LOG_FLAG_DEBUG
#define MSLogDebugInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,frmt,##__VA_ARGS__)

// Log Objective-C with LOG_FLAG_UNITTEST
#define MSLogUnitTestInContext(ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(LOG_ASYNC_UNITTEST,_LVL,LOG_FLAG_UNITTEST,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_ERROR
#define MSLogCErrorInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_WARN
#define MSLogCWarnInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_INFO
#define MSLogCInfoInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_VERBOSE
#define MSLogCVerboseInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_DEBUG
#define MSLogCDebugInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,frmt,##__VA_ARGS__)

// Log C function with LOG_FLAG_UNITTEST
#define MSLogCUnitTestInContext(ctx,frmt,...) \
    MSLOG_C_MAYBE(LOG_ASYNC_UNITTEST,_LVL,LOG_FLAG_UNITTEST,ctx,frmt,##__VA_ARGS__)

#define _TAG (@{ MSLogObjectNameKey : CollectionSafe([[self shortDescription] copy]), \
                 MSLogClassNameKey  : CollectionSafe(ClassString([self class])) })

#define _WEAKTAG (@{ MSLogObjectNameKey : CollectionSafe([[weakself shortDescription] copy]), \
                 MSLogClassNameKey  : CollectionSafe(ClassString([weakself class])) })

#define MSLogErrorInContextTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,_TAG,frmt,##__VA_ARGS__)

#define MSLogWarnInContextTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,_TAG,frmt,##__VA_ARGS__)

#define MSLogInfoInContextTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,_TAG,frmt,##__VA_ARGS__)

#define MSLogVerboseInContextTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,_TAG,frmt,##__VA_ARGS__)

#define MSLogDebugInContextTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,_TAG,frmt,##__VA_ARGS__)

#define MSLogErrorInContextWeakTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,_WEAKTAG,frmt,##__VA_ARGS__)

#define MSLogWarnInContextWeakTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,_WEAKTAG,frmt,##__VA_ARGS__)

#define MSLogInfoInContextWeakTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,_WEAKTAG,frmt,##__VA_ARGS__)

#define MSLogVerboseInContextWeakTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,_WEAKTAG,frmt,##__VA_ARGS__)

#define MSLogDebugInContextWeakTag(ctx,frmt,...) \
    MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,_WEAKTAG,frmt,##__VA_ARGS__)

#define MSLogCErrorInContextTag(ctx,frmt,...) \
    MSLOG_C_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,@{},frmt,##__VA_ARGS__)

#define MSLogCWarnInContextTag(ctx,frmt,...) \
    MSLOG_C_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,@{},frmt,##__VA_ARGS__)

#define MSLogCInfoInContextTag(ctx,frmt,...) \
    MSLOG_C_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,@{},frmt,##__VA_ARGS__)

#define MSLogCVerboseInContextTag(ctx,frmt,...) \
    MSLOG_C_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,@{},frmt,##__VA_ARGS__)

#define MSLogCDebugInContextTag(ctx,frmt,...) \
    MSLOG_C_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,@{},frmt,##__VA_ARGS__)

 #define MSLogErrorInContextIf(expr,ctx,frmt,...) \
 WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,frmt,##__VA_ARGS__);)

#define MSLogWarnInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,frmt,##__VA_ARGS__);)

#define MSLogInfoInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,frmt,##__VA_ARGS__);)

#define MSLogVerboseInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,frmt,##__VA_ARGS__);)

#define MSLogDebugInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,frmt,##__VA_ARGS__);)

#define MSLogErrorInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,_TAG,frmt,##__VA_ARGS__);)

#define MSLogWarnInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,_TAG,frmt,##__VA_ARGS__);)

#define MSLogInfoInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,_TAG,frmt,##__VA_ARGS__);)

#define MSLogVerboseInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,_TAG,frmt,##__VA_ARGS__);)

#define MSLogDebugInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,_TAG,frmt,##__VA_ARGS__);)

#define MSLogErrorInContextWeakTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,_WEAKTAG,frmt,##__VA_ARGS__);)

#define MSLogWarnInContextWeakTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,_WEAKTAG,frmt,##__VA_ARGS__);)

#define MSLogInfoInContextWeakTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,_WEAKTAG,frmt,##__VA_ARGS__);)

#define MSLogVerboseInContextWeakTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,_WEAKTAG,frmt,##__VA_ARGS__);)

#define MSLogDebugInContextWeakTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_OBJC_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,_WEAKTAG,frmt,##__VA_ARGS__);)

#define MSLogCErrorInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,frmt,##__VA_ARGS__);)

#define MSLogCWarnInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,frmt,##__VA_ARGS__);)

#define MSLogCInfoInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,frmt,##__VA_ARGS__);)

#define MSLogCVerboseInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,frmt,##__VA_ARGS__);)

#define MSLogCDebugInContextIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,frmt,##__VA_ARGS__);)

#define MSLogCErrorInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_TAG_MAYBE(LOG_ASYNC_ERROR,_LVL,LOG_FLAG_ERROR,ctx,nil,frmt,##__VA_ARGS__);)

#define MSLogCWarnInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_TAG_MAYBE(LOG_ASYNC_WARN,_LVL,LOG_FLAG_WARN,ctx,nil,frmt,##__VA_ARGS__);)

#define MSLogCInfoInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_TAG_MAYBE(LOG_ASYNC_INFO,_LVL,LOG_FLAG_INFO,ctx,nil,frmt,##__VA_ARGS__);)

#define MSLogCVerboseInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_TAG_MAYBE(LOG_ASYNC_VERBOSE,_LVL,LOG_FLAG_VERBOSE,ctx,nil,frmt,##__VA_ARGS__);)

#define MSLogCDebugInContextTagIf(expr,ctx,frmt,...) \
WRAP(if((expr))MSLOG_C_TAG_MAYBE(LOG_ASYNC_DEBUG,_LVL,LOG_FLAG_DEBUG,ctx,nil,frmt,##__VA_ARGS__);)

#define MSLogError(frmt,...)   MSLogErrorInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogWarn(frmt,...)    MSLogWarnInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogInfo(frmt,...)    MSLogInfoInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogVerbose(frmt,...) MSLogVerboseInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogDebug(frmt,...)   MSLogDebugInContext(_CTX,frmt,##__VA_ARGS__)

#define MSLogCError(frmt,...)   MSLogCErrorInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogCWarn(frmt,...)    MSLogCWarnInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogCInfo(frmt,...)    MSLogCInfoInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogCVerbose(frmt,...) MSLogCVerboseInContext(_CTX,frmt,##__VA_ARGS__)
#define MSLogCDebug(frmt,...)   MSLogCDebugInContext(_CTX,frmt,##__VA_ARGS__)

#define MSLogErrorTag(frmt,...)   MSLogErrorInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogWarnTag(frmt,...)    MSLogWarnInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogInfoTag(frmt,...)    MSLogInfoInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogVerboseTag(frmt,...) MSLogVerboseInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogDebugTag(frmt,...)   MSLogDebugInContextTag(_CTX,frmt,##__VA_ARGS__)

#define MSLogErrorWeakTag(frmt,...)   MSLogErrorInContextWeakTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogWarnWeakTag(frmt,...)    MSLogWarnInContextWeakTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogInfoWeakTag(frmt,...)    MSLogInfoInContextWeakTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogVerboseWeakTag(frmt,...) MSLogVerboseInContextWeakTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogDebugWeakTag(frmt,...)   MSLogDebugInContextWeakTag(_CTX,frmt,##__VA_ARGS__)

#define MSLogCErrorTag(frmt,...)   MSLogCErrorInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogCWarnTag(frmt,...)    MSLogCWarnInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogCInfoTag(frmt,...)    MSLogCInfoInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogCVerboseTag(frmt,...) MSLogCVerboseInContextTag(_CTX,frmt,##__VA_ARGS__)
#define MSLogCDebugTag(frmt,...)   MSLogCDebugInContextTag(_CTX,frmt,##__VA_ARGS__)

#define MSLogErrorIf(expr,frmt,...)   MSLogErrorInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogWarnIf(expr,frmt,...)    MSLogWarnInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogInfoIf(expr,frmt,...)    MSLogInfoInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogVerboseIf(expr,frmt,...) MSLogVerboseInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogDebugIf(expr,frmt,...)   MSLogDebugInContextIf(expr,_CTX,frmt,##__VA_ARGS__)

#define MSLogErrorTagIf(expr,frmt,...)   MSLogErrorInContextTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogWarnTagIf(expr,frmt,...)    MSLogWarnInContextTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogInfoTagIf(expr,frmt,...)    MSLogInfoInContextTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogVerboseTagIf(expr,frmt,...) MSLogVerboseInContextTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogDebugTagIf(expr,frmt,...)   MSLogDebugInContextTagIf(expr,_CTX,frmt,##__VA_ARGS__)

#define MSLogErrorWeakTagIf(expr,frmt,...)   MSLogErrorInContextWeakTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogWarnWeakTagIf(expr,frmt,...)    MSLogWarnInContextWeakTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogInfoWeakTagIf(expr,frmt,...)    MSLogInfoInContextWeakTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogVerboseWeakTagIf(expr,frmt,...) MSLogVerboseInContextWeakTagIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogDebugWeakTagIf(expr,frmt,...)   MSLogDebugInContextWeakTagIf(expr,_CTX,frmt,##__VA_ARGS__)

#define MSLogCErrorIf(expr,frmt,...)   MSLogCErrorInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogCWarnIf(expr,frmt,...)    MSLogCWarnInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogCInfoIf(expr,frmt,...)    MSLogCInfoInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogCVerboseIf(expr,frmt,...) MSLogCVerboseInContextIf(expr,_CTX,frmt,##__VA_ARGS__)
#define MSLogCDebugIf(expr,frmt,...)   MSLogCDebugInContextIf(expr,_CTX,frmt,##__VA_ARGS__)

#define LOG_BLOCK_MAYBE(lvl,flg,ctx,block) \
WRAP(if(lvl&flg){[[MSLog loggingQueue] addOperationWithBlock:block];})

#define MSLogBlockError(block)   LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_ERROR,_CTX,block)
#define MSLogBlockWarn(block)    LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_WARN,_CTX,block)
#define MSLogBlockDebug(block)   LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_DEBUG,_CTX,block)
#define MSLogBlockInfo(block)    LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_INFO,_CTX,block)
#define MSLogBlockVerbose(block) LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_VERBOSE,_CTX,block)
#define MSLogBlockError(block)   LOG_BLOCK_MAYBE(ddLogLevel,LOG_FLAG_ERROR,_CTX,block)

#define MSAggrogateErrorMessage(ERROR)                                                                   \
  ({                                                                                                     \
     NSMutableString * errorMessage = [@"MSHandleErrors--\n" mutableCopy];                               \
     NSError * handledError = ERROR;                                                                     \
     if ([ERROR isKindOfClass:[MSError class]])                                                          \
     {                                                                                                   \
       NSString * message = ((MSError *)ERROR).message;                                                  \
       if (message) [errorMessage appendFormat:@"!! %@ !!", message];                                    \
       handledError = ((MSError *)ERROR).error;                                                          \
     }                                                                                                   \
                                                                                                         \
     NSDictionary  * userInfo = [handledError userInfo];                                                 \
     for (NSArray * detailedError in [userInfo allValues])                                               \
     {                                                                                                   \
       if ([detailedError isKindOfClass:[NSArray class]])                                                \
       {                                                                                                 \
         for (NSError * e in detailedError)                                                              \
         {                                                                                               \
           if ([e respondsToSelector:@selector(userInfo)])                                               \
             [errorMessage appendFormat:@"Error Details: %@\n", [e userInfo]];                           \
                                                                                                         \
           else                                                                                          \
             [errorMessage appendFormat:@"Error Details: %@\n", e];                                      \
         }                                                                                               \
       }                                                                                                 \
                                                                                                         \
       else                                                                                              \
         [errorMessage appendFormat:@"Error: %@\n", detailedError];                                      \
     }                                                                                                   \
     [errorMessage appendFormat:@"Error Message: %@\n", [handledError localizedDescription]];            \
     [errorMessage appendFormat:@"Error Domain: %@\n", [handledError domain]];                           \
     [errorMessage appendFormat:@"Recovery Suggestion: %@", [handledError localizedRecoverySuggestion]]; \
     [errorMessage   replaceOccurrencesOfString:@"\\\\"                                                  \
                                     withString:@"\\"                                                    \
                                        options:0                                                        \
                                          range:NSMakeRange(0, errorMessage.length)];                    \
     errorMessage;                                                                                       \
   })

#define MSHandleErrors(ERROR) \
  ({ BOOL result = NO;        \
     if (ERROR) { MSLogError(@"%@", MSAggrogateErrorMessage(ERROR)); result = YES; } result; })
#define MSHandleCErrors(ERROR) \
  ({ BOOL result = NO;         \
     if (ERROR) { MSLogCError(@"%@", MSAggrogateErrorMessage(ERROR)); result = YES; } result; })
#define MSHandleErrorsTag(ERROR) \
  ({ BOOL result = NO;           \
     if (ERROR) { MSLogErrorTag(@"%@", MSAggrogateErrorMessage(ERROR)); result = YES; } result; })
#define MSHandleErrorsWeakTag(ERROR)                                                      \
  ({ BOOL result = NO;                                                                    \
     if (ERROR) { MSLogErrorWeakTag(@"%@", MSAggrogateErrorMessage(ERROR)); result = YES; \
     } result; })
#define MSHandleCErrorsTag(ERROR) \
  ({ BOOL result = NO;            \
     if (ERROR) { MSLogCErrorTag(@"%@", MSAggrogateErrorMessage(ERROR)); result = YES; } result; })
