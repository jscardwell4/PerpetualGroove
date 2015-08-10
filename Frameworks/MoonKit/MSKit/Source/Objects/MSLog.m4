changecom('//')dnl
changequote([,])dnl
//
//  MSLogMacros.h
//  MSKit
//
//  Created by Jason Cardwell on 10/26/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "MSKitMacros.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark Log flags
////////////////////////////////////////////////////////////////////////////////

// #define LOG_FLAG_ERROR              0b0000000000000001
// #define LOG_FLAG_WARN               0b0000000000000010
// #define LOG_FLAG_INFO               0b0000000000000100
// #define LOG_FLAG_VERBOSE            0b0000000000001000
#define LOG_FLAG_DEBUG                 0b0000000000010000
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
// #define LOG_LEVEL_VERBOSE   0b0000000000001111
#define LOG_LEVEL_DEBUG        0b0000000000010011
#define LOG_LEVEL_UNITTEST     0b1111111111111111

// #define LOG_ERROR    (ddLogLevel & LOG_FLAG_ERROR   )
// #define LOG_WARN     (ddLogLevel & LOG_FLAG_WARN    )
// #define LOG_INFO     (ddLogLevel & LOG_FLAG_INFO    )
// #define LOG_VERBOSE  (ddLogLevel & LOG_FLAG_VERBOSE )
#define LOG_DEBUG       (ddLogLevel & LOG_FLAG_DEBUG   )
#define LOG_UNITTEST    (ddLogLevel & LOG_FLAG_UNITTEST)

// #define LOG_ASYNC_ERROR    (NO  && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_WARN     (YES && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_INFO     (YES && LOG_ASYNC_ENABLED)
// #define LOG_ASYNC_VERBOSE  (YES && LOG_ASYNC_ENABLED)
#define LOG_ASYNC_DEBUG       (NO  && LOG_ASYNC_ENABLED)
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
    MSLOG_C_MACRO(NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous C function macro funnel
#define MSASYNC_LOG_C_MACRO(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MACRO(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Level dependent macro funnel
#define MSLOG_MAYBE(async,lvl,flg,ctx,fnct,frmt,...) \
    WRAP(if(lvl & flg) MSLOG_MACRO(async,lvl,flg,ctx,nil,fnct,frmt,##__VA_ARGS__);)

// Objective-C level dependent macro funnel
#define MSLOG_OBJC_MAYBE(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MAYBE(async,lvl,flg,ctx,sel_getName(_cmd),frmt,##__VA_ARGS__)

// Synchronous Objective-C level dependent macro funnel
#define MSSYNC_LOG_OBJC_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MAYBE( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous Objective-C level dependent macro funnel
#define MSASYNC_LOG_OBJC_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_OBJC_MAYBE(YES,lvl,flg,ctx,frmt,##__VA_ARGS__)

// C function level dependent macro funnel
#define MSLOG_C_MAYBE(async,lvl,flg,ctx,frmt,...) \
    MSLOG_MAYBE(async,lvl,flg,ctx,__FUNCTION__,frmt,##__VA_ARGS__)

// Synchronous C function level dependent macro funnel
#define MSSYNC_LOG_C_MAYBE(lvl,flg,ctx,frmt,...) \
    MSLOG_C_MAYBE( NO,lvl,flg,ctx,frmt,##__VA_ARGS__)

// Asynchronous C function level dependent macro funnel
#define MSASYNC_LOG_C_MAYBE(lvl,flg,ctx,frmt,...) \
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

divert([-1])
define([MakeLogMacro], [[#define] MS$3Log$1$2(expr,ctx,frmt,...) \
    WRAP(if((expr))MSLOG_OBJC_MAYBE(LOG_ASYNC_[]translit($1, [a-z], [A-Z]),ddLogLevel,LOG_FLAG__[]translit($1, [a-z], [A-Z]),ctx,frmt,##__VA_ARGS__);)])dnl
divert[]dnl
MakeLogMacro(Warn,InContextIf)

MakeLogMacro(Info,InContextIf)

MakeLogMacro(Verbose,InContextIf)

MakeLogMacro(Debug,InContextIf)

MakeLogMacro(Error,InContextIf)

