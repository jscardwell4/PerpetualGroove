//
//  MSKitLoggingFunctions.h
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#if TARGET_OS_IPHONE
#import "UIImage+MSKitAdditions.h"
#endif
@import Foundation;
@import QuartzCore;
@import Accelerate;
@import CoreData;

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Functions
////////////////////////////////////////////////////////////////////////////////

void nsprintf(NSString * formatString,...);

void printfobj(FILE * file, NSString * formatString,...);

void dumpObjectIntrospection(id obj);

#if TARGET_OS_IPHONE
NSString * PrettyFloat(CGFloat f);
NSString * PrettySize(CGSize size);
NSString * AvailableCIFiltersDescription();
NSString * NSStringFromNSAttributeType(NSAttributeType type);
NSString * NSStringFromNSDeleteRule(NSDeleteRule rule);
NSString * NSStringFromCGImageAlphaInfo(CGImageAlphaInfo info);
NSString * NSStringFromCGBitmapInfoByteOrder(CGBitmapInfo info);
NSString * AutolayoutTraceDescription();
NSString * AvailableFontsDescription();
NSString * FrameTraceDescription();
NSString * LayerTraceDescription();
NSString * NSStringFromImageInfo(ImageInfo info);
NSString * NSStringFromUIControlState(NSUInteger state);
NSString * NSStringFromvImage_Error(vImage_Error err);
NSString * NSStringFromNSTextAlignment(NSTextAlignment alignment);
NSString * NSStringFromNSLineBreakMode(NSLineBreakMode lineBreakMode);
#endif


