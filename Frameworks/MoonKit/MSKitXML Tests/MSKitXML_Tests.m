//
//  MSKitXML_Tests.m
//  MSKitXML Tests
//
//  Created by Jason Cardwell on 9/3/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "NSString+MSKitAdditions.h"
#import "MSDictionary.h"
#import "NSArray+MSKitAdditions.h"
#import "Lumberjack/Lumberjack.h"
#import "MSLog.h"
#import "MSKitMacros.h"

static int ddLogLevel   = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface MSKitXML_Tests : XCTestCase

@end

@implementation MSKitXML_Tests

+ (void)load {
  [MSLog addTaggingTTYLogger];
}

- (void)testDictionaryFromXML1 {

  NSString * filePath = $(@"%@/Test1.xml",
                          [[NSUserDefaults standardUserDefaults] stringForKey:@"XCTestedBundlePath"]);

  NSData * xmlData = [NSData dataWithContentsOfFile:filePath];
  MSLogDebug(@"%@\n\n", [NSString stringWithData:xmlData]);
  MSDictionary * dictionary = [MSDictionary dictionaryByParsingXML:xmlData];
  MSLogDebug(@"%@\n",   [dictionary formattedDescription]);

  
}

- (void)testDictionaryFromXML2 {

  NSString * filePath = $(@"%@/Test2.xml",
                          [[NSUserDefaults standardUserDefaults] stringForKey:@"XCTestedBundlePath"]);

  NSData * xmlData = [NSData dataWithContentsOfFile:filePath];
  MSLogDebug(@"%@\n\n", [NSString stringWithData:xmlData]);
  MSDictionary * dictionary = [MSDictionary dictionaryByParsingXML:xmlData];
  MSLogDebug(@"%@\n",   [dictionary formattedDescription]);

  
}

- (void)testDictionaryFromXML3 {

  NSString * filePath = $(@"%@/Test3.xml",
                          [[NSUserDefaults standardUserDefaults] stringForKey:@"XCTestedBundlePath"]);

  NSData * xmlData = [NSData dataWithContentsOfFile:filePath];
  MSLogDebug(@"%@\n\n", [NSString stringWithData:xmlData]);
  MSDictionary * dictionary = [MSDictionary dictionaryByParsingXML:xmlData];
  MSLogDebug(@"%@\n",   [dictionary formattedDescription]);

  
}

@end
