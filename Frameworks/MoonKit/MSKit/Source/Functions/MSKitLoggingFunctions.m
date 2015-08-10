//
//  MSKitLoggingFunctions.m
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSKitLoggingFunctions.h"
#import "NSNull+MSKitAdditions.h"
#import "NSString+MSKitAdditions.h"
#import <objc/runtime.h>
#import <objc/message.h>
#import <CoreData/CoreData.h>

#if TARGET_OS_IPHONE
  #import "UIView+MSKitAdditions.h"
  #import "UIColor+MSKitAdditions.h"
#endif

#import "NSArray+MSKitAdditions.h"
#import "NSDictionary+MSKitAdditions.h"
#import "NSSet+MSKitAdditions.h"
#import "NSOrderedSet+MSKitAdditions.h"
#import "MSDictionary.h"
#import "MSStack.h"

void nsprintf(NSString * formatString, ...) {
  va_list arglist;

  if (formatString) {
    va_start(arglist, formatString);
    {
      NSString * outstring = [[NSString alloc] initWithFormat:formatString
                                                    arguments:arglist];
      fprintf(stderr, "%s\n", [outstring UTF8String]);
    }
    va_end(arglist);
  }
}

void printfobj(FILE * file, NSString * formatString, ...) {
  va_list arglist;

  if (formatString) {
    va_start(arglist, formatString);
    {
      NSString * outstring = [[NSString alloc] initWithFormat:formatString arguments:arglist];
      fprintf(file, "%s\n", [outstring UTF8String]);
    }
    va_end(arglist);
  }
}

void dumpObjectIntrospection(id obj) {
  if (!obj) return;

  NSMutableString * string = [@"" mutableCopy];

  Class        objClass     = [obj class];
  const char * objClassName = class_getName(objClass);
  [string appendFormat:@"objClassName: %s\n", objClassName];
  unsigned int outCount      = 0;
  Ivar       * objClassIvars = class_copyIvarList(objClass, &outCount);
  [string appendString:@"objClassIvars:\n"];

  for (int i = 0; i < outCount; i++) {
    Ivar         ivar             = objClassIvars[i];
    const char * ivarName         = ivar_getName(ivar);
    const char * ivarTypeEncoding = ivar_getTypeEncoding(ivar);
    [string appendFormat:@"\t%s : %s\n", ivarName, ivarTypeEncoding];
  }

  outCount = 0;
  objc_property_t * objClassProperties = class_copyPropertyList(objClass, &outCount);
  [string appendString:@"objClassProperties:\n"];

  for (int i = 0; i < outCount; i++) {
    objc_property_t property           = objClassProperties[i];
    const char    * propertyName       = property_getName(property);
    const char    * propertyAttributes = property_getAttributes(property);
    [string appendFormat:@"\t%s : %s\n", propertyName, propertyAttributes];
  }

  outCount = 0;
  Method * objClassMethods = class_copyMethodList(objClass, &outCount);
  [string appendString:@"objClassMethods:\n"];

  for (int i = 0; i < outCount; i++) {
    Method method     = objClassMethods[i];
    SEL    methodName = method_getName(method);
    [string appendFormat:@"\t%@\n", NSStringFromSelector(methodName)];
  }

  NSLog(@"%@", string);
}

#if TARGET_OS_IPHONE

  NSString *PrettyFloat(CGFloat f) {
    if (f == 0) {
      return @"0";
    } else if (f == 1) {
      return @"1";
    } else {
      return [[NSString stringWithFormat:@"%.3f", f] stringByStrippingTrailingZeroes];
    }
  }

  NSString *PrettySize(CGSize size) {
    return $(@"%@ x %@", PrettyFloat(size.width), PrettyFloat(size.height));
  }

  NSString *NSStringFromUIControlState(NSUInteger state) {
    NSString * controlStateString = nil;
    switch (state) {
      case UIControlStateHighlighted:
        controlStateString = @"UIControlStateHighlighted";
        break;

      case UIControlStateHighlighted | UIControlStateSelected:
        controlStateString = @"UIControlStateHighlighted|UIControlStateSelected";
        break;

      case UIControlStateHighlighted | UIControlStateDisabled:
        controlStateString = @"UIControlStateHighlighted|UIControlStateDisabled";
        break;

      case UIControlStateDisabled | UIControlStateSelected:
        controlStateString = @"UIControlStateDisabled|UIControlStateSelected";
        break;

      case UIControlStateSelected | UIControlStateHighlighted | UIControlStateDisabled:
        controlStateString = @"UIControlStateSelected|UIControlStateHighlighted|UIControlStateDisabled";
        break;

      case UIControlStateSelected:
        controlStateString = @"UIControlStateSelected";
        break;

      case UIControlStateDisabled:
        controlStateString = @"UIControlStateDisabled";
        break;

      case UIControlStateApplication:
        controlStateString = @"UIControlStateApplication";
        break;

      case UIControlStateReserved:
        controlStateString = @"UIControlStateReserved";
        break;

      case UIControlStateNormal:
        controlStateString = @"UIControlStateNormal";
        break;

      default:
        controlStateString = @"Invalid Control State";
        break;
    }

    return controlStateString;
  }

  NSString *NSStringFromImageInfo(ImageInfo info) {
    NSString * alphaInfo          = NSStringFromCGImageAlphaInfo(info.alphaInfo);
    NSString * byteOrderInfo      = NSStringFromCGBitmapInfoByteOrder(info.byteOrderInfo);
    NSString * floatComponents    = NSStringFromBOOL(info.floatComponents);
    NSString * width              = PrettyFloat(info.width);
    NSString * height             = PrettyFloat(info.height);
    NSString * bitsPerPixel       = [NSString stringWithFormat:@"%zd", info.bitsPerPixel];
    NSString * bitsPerComponent   = [NSString stringWithFormat:@"%zd", info.bitsPerComponent];
    NSString * bytesPerRow        = [NSString stringWithFormat:@"%zd", info.bytesPerRow];
    NSString * renderingIntent    = NSStringFromCGColorRenderingIntent(info.renderingIntent);
    NSString * colorSpaceModel    = NSStringFromCGColorSpaceModel(info.colorSpaceModel);
    NSString * numberOfComponents = [NSString stringWithFormat:@"%zi", info.numberOfComponents];
    NSString * scale              = PrettyFloat(info.scale);

    NSString * infoString =
      [NSString stringWithFormat:
       @"CGImageInfo:\n"
       "\talphaInfo:%@\n"
       "\tbyteOrderInfo:%@\n"
       "\tfloatComponents:%@\n"
       "\twidth:%@\n"
       "\theight:%@\n"
       "\tbitsPerPixel:%@\n"
       "\tbitsPerComponent:%@\n"
       "\tbytesPerRow:%@\n"
       "\trenderingIntent:%@\n"
       "\tcolorSpaceModel:%@\n"
       "\tnumberOfComponents:%@\n"
       "\tscale:%@",
       alphaInfo,
       byteOrderInfo,
       floatComponents,
       width,
       height,
       bitsPerPixel,
       bitsPerComponent,
       bytesPerRow,
       renderingIntent,
       colorSpaceModel,
       numberOfComponents,
       scale
      ];
    return infoString;
  }

  NSString *AutolayoutTraceDescription() {
    #pragma clang diagnostic push
    #pragma clang diagnostic ignored "-Wundeclared-selector"
    return [[[UIApplication sharedApplication] keyWindow] performSelector:@selector(_autolayoutTrace)];
    #pragma clang diagnostic pop
  }

  NSString *AvailableFontsDescription() {
    NSMutableString * availableFonts =
      [[NSMutableString alloc] initWithString:@"\nAvailable fonts...\n"];
    NSArray * familyNames = [UIFont familyNames];

    for (NSString * familyName in familyNames) {

      [availableFonts appendFormat:@"\t%@:\n", familyName];

      NSArray * familyFonts = [UIFont fontNamesForFamilyName:familyName];

      for (NSString * familyFont in familyFonts)
        [availableFonts appendFormat:@"\t\t%@\n", familyFont];
    }

    return availableFonts;
  }

  NSString *FrameTraceDescription() {
    NSMutableString * outstring = [@"\n" mutableCopy];

    __block void (^dumpView)(UIView *, int) = nil;
    __block void(__weak ^ weakDumpView)(UIView *, int) = nil;
    dumpView = ^(UIView * view, int indent) {

      [outstring appendString:[NSString stringWithString:@"|   " count:indent]];

      [outstring appendFormat:@"*<%@:%p%@> frame:%@\n",
       [[view class] description],
       view,
       (view.nametag ? [NSString stringWithFormat:@":'%@'", view.nametag] : @""),
       NSStringFromCGRect(view.frame)];

      for (UIView * subview in view.subviews)
        weakDumpView(subview, indent + 1);
    };
    weakDumpView = dumpView;

    dumpView([[UIApplication sharedApplication] keyWindow], 0);

    return outstring;
  }

  NSString *LayerTraceDescription() {
    NSMutableString * outstring = [@"\n" mutableCopy];

    __block void (^dumpLayer)(CALayer *, int) = nil;
    __block void(__weak ^ weakDumpLayer)(CALayer *, int) = nil;
    dumpLayer = ^(CALayer * layer, int indent) {

      [outstring appendString:[NSString stringWithString:@"|   " count:indent]];

      [outstring appendFormat:@"*%@\n", [layer debugDescription]];

      for (CALayer * sublayer in layer.sublayers)
        weakDumpLayer(sublayer, indent + 1);
    };

    weakDumpLayer = dumpLayer;
    dumpLayer([[UIApplication sharedApplication] keyWindow].layer, 0);

    return outstring;
  }

  NSString *AvailableCIFiltersDescription() {
    NSArray * builtinFilters = [CIFilter filterNamesInCategory:kCICategoryBuiltIn];
    return [NSString stringWithFormat:@"\nAvailable fitlers...\n\t%@", [builtinFilters componentsJoinedByString:@"\n\t"]];
  }

  NSString *NSStringFromNSAttributeType(NSAttributeType type) {
    switch (type) {
      case NSUndefinedAttributeType: return @"NSUndefinedAttributeType";
      case NSInteger16AttributeType: return @"NSInteger16AttributeType";
      case NSInteger32AttributeType: return @"NSInteger32AttributeType";
      case NSInteger64AttributeType: return @"NSInteger64AttributeType";
      case NSDecimalAttributeType: return @"NSDecimalAttributeType";
      case NSDoubleAttributeType: return @"NSDoubleAttributeType";
      case NSFloatAttributeType: return @"NSFloatAttributeType";
      case NSStringAttributeType: return @"NSStringAttributeType";
      case NSBooleanAttributeType: return @"NSBooleanAttributeType";
      case NSDateAttributeType: return @"NSDateAttributeType";
      case NSBinaryDataAttributeType: return @"NSBinaryDataAttributeType";
      case NSTransformableAttributeType: return @"NSTransformableAttributeType";
      case NSObjectIDAttributeType: return @"NSObjectIDAttributeType";
      default: return nil;
    }
  }

  NSString *NSStringFromNSDeleteRule(NSDeleteRule rule) {
    switch (rule) {
      case NSNoActionDeleteRule: return @"NSNoActionDeleteRule";
      case NSNullifyDeleteRule: return @"NSNullifyDeleteRule";
      case NSCascadeDeleteRule: return @"NSCascadeDeleteRule";
      case NSDenyDeleteRule: return @"NSDenyDeleteRule";
      default: return nil;
    }
  }

  NSString *NSStringFromCGImageAlphaInfo(CGImageAlphaInfo info) {
    /*
       kCGImageAlphaNone,
       kCGImageAlphaPremultipliedLast,
       kCGImageAlphaPremultipliedFirst,
       kCGImageAlphaLast,
       kCGImageAlphaFirst,
       kCGImageAlphaNoneSkipLast,
       kCGImageAlphaNoneSkipFirst
     */
    NSString * alphaInfoString = nil;
    switch (info) {
      case kCGImageAlphaNone:
        alphaInfoString = @"kCGImageAlphaNone";
        break;

      case kCGImageAlphaPremultipliedLast:
        alphaInfoString = @"kCGImageAlphaPremultipliedLast";
        break;

      case kCGImageAlphaPremultipliedFirst:
        alphaInfoString = @"kCGImageAlphaPremultipliedFirst";
        break;

      case kCGImageAlphaLast:
        alphaInfoString = @"kCGImageAlphaLast";
        break;

      case kCGImageAlphaFirst:
        alphaInfoString = @"kCGImageAlphaFirst";
        break;

      case kCGImageAlphaNoneSkipLast:
        alphaInfoString = @"kCGImageAlphaNoneSkipLast";
        break;

      case kCGImageAlphaNoneSkipFirst:
        alphaInfoString = @"kCGImageAlphaNoneSkipFirst";
        break;

      case kCGImageAlphaOnly:
        alphaInfoString = @"kCGImageAlphaOnly";
        break;
    }

    return alphaInfoString;
  }

  NSString *NSStringFromCGBitmapInfoByteOrder(CGBitmapInfo info) {
    /*
       kCGBitmapByteOrderDefault
       kCGBitmapByteOrder16Little
       kCGBitmapByteOrder32Little
       kCGBitmapByteOrder16Big
       kCGBitmapByteOrder32Big
     */
    NSString * byteOrderInfoString = nil;
    switch (info & kCGBitmapByteOrderMask) {
      case kCGBitmapByteOrderDefault:
        byteOrderInfoString = @"kCGBitmapByteOrderDefault";
        break;
      case kCGBitmapByteOrder16Little:
        byteOrderInfoString = @"kCGBitmapByteOrder16Little";
        break;
      case kCGBitmapByteOrder32Little:
        byteOrderInfoString = @"kCGBitmapByteOrder32Little";
        break;
      case kCGBitmapByteOrder16Big:
        byteOrderInfoString = @"kCGBitmapByteOrder16Big";
        break;
      case kCGBitmapByteOrder32Big:
        byteOrderInfoString = @"kCGBitmapByteOrder32Big";
        break;
    }

    return byteOrderInfoString;
  }

  NSString *NSStringFromvImage_Error(vImage_Error err) {
    /*
         kvImageNoError
         kvImageRoiLargerThanInputBuffer
         kvImageInvalidKernelSize
         kvImageInvalidEdgeStyle
         kvImageInvalidOffset_X
         kvImageInvalidOffset_Y
         kvImageMemoryAllocationError
         kvImageNullPointerArgument
         kvImageInvalidParameter
         kvImageBufferSizeMismatch
         kvImageUnknownFlagsBit
     */
    NSString * errString = nil;
    switch (err) {
      case kvImageNoError:
        errString = @"kvImageNoError";
        break;

      case kvImageRoiLargerThanInputBuffer:
        errString = @"kvImageRoiLargerThanInputBuffer";
        break;

      case kvImageInvalidKernelSize:
        errString = @"kvImageInvalidKernelSize";
        break;

      case kvImageInvalidEdgeStyle:
        errString = @"kvImageInvalidEdgeStyle";
        break;

      case kvImageInvalidOffset_X:
        errString = @"kvImageInvalidOffset_X";
        break;

      case kvImageInvalidOffset_Y:
        errString = @"kvImageInvalidOffset_Y";
        break;

      case kvImageMemoryAllocationError:
        errString = @"kvImageMemoryAllocationError";
        break;

      case kvImageNullPointerArgument:
        errString = @"kvImageNullPointerArgument";
        break;

      case kvImageInvalidParameter:
        errString = @"kvImageInvalidParameter";
        break;

      case kvImageBufferSizeMismatch:
        errString = @"kvImageBufferSizeMismatch";
        break;

      case kvImageUnknownFlagsBit:
        errString = @"kvImageUnknownFlagsBit";
        break;
    }

    return errString;
  }

  NSString *NSStringFromNSTextAlignment(NSTextAlignment alignment) {
    switch (alignment) {
      case 0:  return @"NSTextAlignmentLeft";
      case 1:  return @"NSTextAlignmentCenter";
      case 2:  return @"NSTextAlignmentRight";
      case 3:  return @"NSTextAlignmentJustified";
      case 4:  return @"NSTextAlignmentNatural";
      default: return nil;
    }
  }

  NSString *NSStringFromNSLineBreakMode(NSLineBreakMode lineBreakMode) {
    switch (lineBreakMode) {
      case 0:  return @"NSLineBreakByCharWrapping";
      case 1:  return @"NSLineBreakByClipping";
      case 2:  return @"NSLineBreakByTruncatingHead";
      case 3:  return @"NSLineBreakByTruncatingTail";
      case 4:  return @"NSLineBreakByTruncatingMiddle";
      default: return nil;
    }
  }

#endif
