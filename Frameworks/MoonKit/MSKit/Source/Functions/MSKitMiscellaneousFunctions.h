//
//  MSKitMiscellaneousFunctions.h
//  Remote
//
//  Created by Jason Cardwell on 4/22/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
#import "MSKitProtocols.h"

NSString * MSNonce();

void MSRunSyncOnMain(dispatch_block_t block);
void MSRunAsyncOnMain(dispatch_block_t block);
void MSSwapInstanceMethodsForClass(Class c, SEL m1, SEL m2);
void MSSwapInstanceMethods(Class c1, SEL m1, Class c2, SEL m2);
void MSDelayedRunOnMain(int64_t seconds, dispatch_block_t block);

BOOL MSSelectorInProtocol(SEL selector, Protocol * protocol, BOOL isRequired, BOOL isInstance);

NSString * classNametagWithSuffix(NSString *suffix, id obj);
#define ClassNametagWithSuffix(SUFFIX) classNametagWithSuffix(SUFFIX, self)

NSArray * findValuesForKeyInContainer(id<NSCopying>key, id<MSKeySearchable>container);
id        findFirstValueForKeyInContainer(id<NSCopying>key, id<MSKeySearchable>container);