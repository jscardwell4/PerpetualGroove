//
//  MSSingleton.m
//  MSKit
//
//  Created by Jason Cardwell on 9/13/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSSingleton.h"
#import <objc/runtime.h>

static NSMutableDictionary const * instances;

@implementation MSSingleton

+ (void)initialize
{
    if (self == [MSSingleton class])
        instances = [@{} mutableCopy];

    else
    {
/*
        unsigned int outCount = 0;
        Method * methodList = class_copyMethodList(self, &outCount);
        BOOL replaceIsAbstract = YES;
        SEL isAbstractSel = @selector(isAbstract);
        for (unsigned int i = 0; i < outCount; i++) {
            Method m = methodList[i];
            SEL s = method_getName(m);
            if (sel_isEqual(isAbstractSel, s))
            {
                replaceIsAbstract = NO;
                break;
            }
        }
        Method rootIsAbstract = class_getClassMethod([MSSingleton class], @selector(isAbstract));
        if (replaceIsAbstract)
        {
            BOOL(^isAbstractBlock)(id) = ^(id _self) {
                return NO;
            };
            IMP isAbstractImp = imp_implementationWithBlock(isAbstractBlock);
            class_replaceMethod(objc_getMetaClass(class_getName(self)),
                                @selector(isAbstract),
                                isAbstractImp,
                                method_getTypeEncoding(rootIsAbstract));
        }

        if (![self isAbstract])
        {
*/
            __block dispatch_once_t once = 0;
            id(^sharedInstanceBlock)(id) = ^(id _self) {
                dispatch_once(&once, ^ { instances[NSStringFromClass(_self)] = [_self new]; });
                return instances[NSStringFromClass(_self)];
            };
            IMP sharedInstanceImp = imp_implementationWithBlock(sharedInstanceBlock);
            class_replaceMethod(objc_getMetaClass(class_getName(self)),
                                @selector(sharedInstance),
                                sharedInstanceImp,
                                "@@:");
//        }
    }
}


+ (instancetype)sharedInstance
{
    return nil;
}

//+ (BOOL)isAbstract { return YES; }

@end