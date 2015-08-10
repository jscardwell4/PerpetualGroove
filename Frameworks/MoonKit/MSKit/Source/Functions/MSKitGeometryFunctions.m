//
//  MSKitGeometryFunctions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/22/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "MSKitGeometryFunctions.h"
#import "NSString+MSKitAdditions.h"

NSString *NSStringFromCATransform3D(CATransform3D transform) {
  NSUInteger       fieldWidth = 10;
  NSMutableArray * strings    = [NSMutableArray arrayWithCapacity:16];

  for (NSUInteger i = 0; i < 16; i++) {
    CGFloat n = 0;

    switch (i) {
      case 0:  n = transform.m11; break;
      case 1:  n = transform.m12; break;
      case 2:  n = transform.m13; break;
      case 3:  n = transform.m14; break;
      case 4:  n = transform.m21; break;
      case 5:  n = transform.m22; break;
      case 6:  n = transform.m23; break;
      case 7:  n = transform.m24; break;
      case 8:  n = transform.m31; break;
      case 9:  n = transform.m32; break;
      case 10: n = transform.m33; break;
      case 11: n = transform.m34; break;
      case 12: n = transform.m41; break;
      case 13: n = transform.m42; break;
      case 14: n = transform.m43; break;
      case 15: n = transform.m44; break;
    }

    NSString * nString = (fmod(n, 1) == 0 ? $(@"% .0f", n) : $(@"% .*f", (int)fieldWidth - 4, n));

    if (nString.length > fieldWidth) nString = [nString substringToIndex:fieldWidth];

    if (n != 0) nString = [nString stringByStrippingTrailingZeroes];

    NSUInteger padding      = fieldWidth - nString.length;
    NSUInteger leftPadding  = padding / 2;
    char       padCharacter = ' ';
    NSUInteger rightPadding = padding - leftPadding;
    [strings addObject:[NSString stringWithFormat:@"%@%@%@",
                        [NSString stringWithCharacter:padCharacter count:leftPadding],
                        nString,
                        [NSString stringWithCharacter:padCharacter count:rightPadding]]];
  }

  NSArray * row1 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,  4)]];
  NSArray * row2 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(4,  4)]];
  NSArray * row3 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(8,  4)]];
  NSArray * row4 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 4)]];

  NSString * row1String = [row1 componentsJoinedByString:@"  "];
  NSString * row2String = [row2 componentsJoinedByString:@"  "];
  NSString * row3String = [row3 componentsJoinedByString:@"  "];
  NSString * row4String = [row4 componentsJoinedByString:@"  "];

  return [NSString stringWithFormat:@"%@\n%@\n%@\n%@", row1String, row2String, row3String, row4String];
}

NSString *NSStringFromCATransform3DT(CATransform3D transform) {
  NSUInteger       fieldWidth = 10;
  NSMutableArray * strings    = [NSMutableArray arrayWithCapacity:16];

  for (NSUInteger i = 0; i < 16; i++) {
    CGFloat n = 0;

    switch (i) {
      case 0:  n = transform.m11; break;
      case 1:  n = transform.m21; break;
      case 2:  n = transform.m31; break;
      case 3:  n = transform.m41; break;
      case 4:  n = transform.m12; break;
      case 5:  n = transform.m22; break;
      case 6:  n = transform.m32; break;
      case 7:  n = transform.m42; break;
      case 8:  n = transform.m13; break;
      case 9:  n = transform.m23; break;
      case 10: n = transform.m33; break;
      case 11: n = transform.m43; break;
      case 12: n = transform.m14; break;
      case 13: n = transform.m24; break;
      case 14: n = transform.m34; break;
      case 15: n = transform.m44; break;
    }

    NSString * nString = (fmod(n, 1) == 0 ? $(@"% .0f", n) : $(@"% .*f", (int)fieldWidth - 4, n));

    if (nString.length > fieldWidth) nString = [nString substringToIndex:fieldWidth];

    if (n != 0) nString = [nString stringByStrippingTrailingZeroes];

    NSString * leftPaddingString  = @"";
    NSString * rightPaddingString = @"";

    if (nString.length < fieldWidth) {
      NSUInteger padding      = fieldWidth - nString.length;
      NSUInteger rightPadding = padding / 2;
      NSUInteger leftPadding  = padding - rightPadding;
      char       padCharacter = ' ';
      leftPaddingString = (leftPadding > 0 ? [NSString stringWithCharacter:padCharacter count:leftPadding] : @"");

      rightPaddingString = (rightPadding > 0 ? [NSString stringWithCharacter:padCharacter count:leftPadding] : @"");
    }

    [strings addObject:[NSString stringWithFormat:@"%@%@%@", leftPaddingString, nString, rightPaddingString]];
  }

  NSArray * row1 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0,  4)]];
  NSArray * row2 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(4,  4)]];
  NSArray * row3 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(8,  4)]];
  NSArray * row4 = [strings objectsAtIndexes:[NSIndexSet indexSetWithIndexesInRange:NSMakeRange(12, 4)]];

  NSString * row1String = [row1 componentsJoinedByString:@"  "];
  NSString * row2String = [row2 componentsJoinedByString:@"  "];
  NSString * row3String = [row3 componentsJoinedByString:@"  "];
  NSString * row4String = [row4 componentsJoinedByString:@"  "];

  return [NSString stringWithFormat:@"%@\n%@\n%@\n%@", row1String, row2String, row3String, row4String];
}

MSBoundary MSBoundaryMake(CGFloat lower, CGFloat upper) { return (MSBoundary) {lower, upper}; }
BOOL MSValueInBounds(CGFloat value, MSBoundary boundary) { return (value >= boundary.lower && value <= boundary.upper); }
NSUInteger MSBoundarySizeOfBoundary(MSBoundary b) { return (MAX(b.upper, b.lower) - MIN(b.upper, b.lower)); }
NSString *NSStringFromMSBoundary(MSBoundary b) { return $(@"(MSBoundary){.lower = %f, .upper = %f}", b.lower, b.upper); }

MSAspectRatio MSAspectRatioMake(CGFloat x, CGFloat y) { return (MSAspectRatio) {x, y}; }
MSAspectRatio MSAspectRatioFromSizeOverSize(CGSize a, CGSize b) { return (MSAspectRatio){a.width/b.width, a.height/b.height}; }
MSAspectRatio MSAspectRatioWithMinAxis(MSAspectRatio r) { CGFloat a = MIN(r.x, r.y); return MSAspectRatioMake(a, a); }
MSAspectRatio MSAspectRatioWithMaxAxis(MSAspectRatio r) { CGFloat a = MAX(r.x, r.y); return MSAspectRatioMake(a, a); }

CGFloat Delta(CGFloat a, CGFloat b) { return a - b; }
CGFloat CGPointGetDeltaX(CGPoint a, CGPoint b) { return Delta(a.x, b.x); }
CGFloat CGPointGetDeltaY(CGPoint a, CGPoint b) { return Delta(a.y, b.y); }
CGPoint CGPointGetDelta(CGPoint a, CGPoint b) { return (CGPoint) {.x = CGPointGetDeltaX(a, b), .y = CGPointGetDeltaY(a, b) }; }
CGFloat DeltaABS(CGFloat a, CGFloat b) { return ABS(a - b); }
CGFloat CGPointGetDeltaXABS(CGPoint a, CGPoint b) { return DeltaABS(a.x, b.x); }
CGFloat CGPointGetDeltaYABS(CGPoint a, CGPoint b) { return DeltaABS(a.y, b.y); }
CGPoint CGPointGetDeltaABS(CGPoint a, CGPoint b) { return (CGPoint) {CGPointGetDeltaXABS(a, b), CGPointGetDeltaYABS(a, b) }; }

CGPoint CGRectGetCenter(CGRect rect) { return CGPointMake(CGRectGetMidX(rect), CGRectGetMidY(rect)); }
CGPoint CGPointOriginForSizeCenter(CGSize s, CGPoint c) { return (CGPoint){c.x - s.width / 2.0, c.y - s.height / 2.0}; }
CGRect CGRectReposition(CGRect rect, CGPoint origin) { return (CGRect) {.origin = origin, .size = rect.size }; }
CGRect CGRectResize(CGRect rect, CGSize size) { return (CGRect){rect.origin, size}; }
CGRect CGRectSetHeight(CGRect rect, CGFloat h) { return (CGRect) {rect.origin, CGSizeMake(rect.size.width, h) }; }
CGRect CGRectSetWidth(CGRect rect, CGFloat w) { return (CGRect) {rect.origin, CGSizeMake(w, rect.size.height) }; }
CGRect CGRectAnchoredResize(CGRect rect, CGSize size) {
  CGPoint rectCenter = CGRectGetCenter(rect);
  CGRect  newRect    = CGRectResize(rect, size);
  CGPoint newCenter  = CGRectGetCenter(newRect);
  CGFloat xDiff = rectCenter.x - newCenter.x;
  CGFloat yDiff = rectCenter.y - newCenter.y;
  return CGRectOffset(newRect, xDiff, yDiff);
}
CGRect CGRectWithSizeAndCenter(CGSize s, CGPoint c) { return (CGRect) {CGPointOriginForSizeCenter(s, c), s }; }
CGRect CGRectCenteredOnPoint(CGRect r, CGPoint p) { return (CGRect) {CGPointOriginForSizeCenter(r.size, p), r.size }; }

CGSize CGSizeAddedToSize(CGSize a, CGSize b) { return (CGSize) {a.width + b.width, a.height + b.height }; }
CGSize CGSizeApplyScale(CGSize size, CGFloat scale) { return CGSizeMake(size.width * scale, size.height * scale); }
BOOL CGSizeContainsSize(CGSize a, CGSize b) { return (a.width >= b.width && a.height >= b.height); }
CGSize CGSizeUnionSize(CGSize a, CGSize b) { return CGSizeMake(MAX(a.width, b.width), MAX(a.height, b.height)); }
CGSize CGSizeGetDelta(CGSize a, CGSize b) { return CGSizeMake(a.width - b.width, a.height - b.height); }
CGFloat CGSizeMinAxis(CGSize size) { return MIN(size.width, size.height); }
CGFloat CGSizeMaxAxis(CGSize size) { return MAX(size.width, size.height); }
CGFloat CGSizeGetArea(CGSize size) { return size.width * size.height; }
BOOL CGSizeGreaterThanSize(CGSize s1, CGSize s2) { return (CGSizeGetArea(s1) > CGSizeGetArea(s2)); }
BOOL CGSizeLessThanSize(CGSize s1, CGSize s2) { return (CGSizeGetArea(s1) < CGSizeGetArea(s2)); }
BOOL CGSizeGreaterThanOrEqualToSize(CGSize s1, CGSize s2) {
  return (CGSizeGreaterThanSize(s1, s2) || CGSizeEqualToSize(s1, s2));
}
BOOL CGSizeLessThanOrEqualToSize(CGSize s1, CGSize s2) { return (CGSizeLessThanSize(s1, s2) || CGSizeEqualToSize(s1, s2)); }
CGSize CGSizeIntegral(CGSize s) { return (CGSize){round(s.width), round(s.height)}; }
CGSize CGSizeIntegralRoundingUp(CGSize s) {
  CGSize roundedSize = CGSizeIntegral(s);
  if (roundedSize.width < s.width) roundedSize.width += 1;
  if (roundedSize.height < s.height) roundedSize.height += 1;
  return roundedSize;
}
CGSize CGSizeIntegralRoundingDown(CGSize s) {
  CGSize roundedSize = CGSizeIntegral(s);
  if (roundedSize.width > s.width) roundedSize.width -= 1;
  if (roundedSize.height > s.height) roundedSize.height -= 1;
  return roundedSize;
}
CGSize CGSizeMaxSize(CGSize s1, CGSize s2) { return (CGSizeGetArea(s1) > CGSizeGetArea(s2) ? s1 : s2); }
CGSize CGSizeMinSize(CGSize s1, CGSize s2) { return (CGSizeGetArea(s1) < CGSizeGetArea(s2) ? s1 : s2); }
CGSize CGSizeAspectMappedToWidth(CGSize s, CGFloat w) { return CGSizeMake(w, (w * s.height) / s.width); }
CGSize CGSizeAspectMappedToHeight(CGSize s, CGFloat h) { return CGSizeMake((h * s.width) / s.height, h); }
CGSize CGSizeAspectMappedToSize(CGSize s1, CGSize s2, BOOL bound) {
  CGSize sw = CGSizeAspectMappedToWidth(s1, s2.width);
  CGSize sh = CGSizeAspectMappedToHeight(s1, s2.height);
  CGSize s  = (bound ? CGSizeMinSize(sw, sh) : CGSizeMaxSize(sw, sh));
  return s;
}

UIEdgeInsets UIEdgeInsetsForSizeCenteredInSize(CGSize s1, CGSize s2) {
  CGSize delta = CGSizeGetDelta(s2, s1);
  CGFloat verticalOffset = delta.height / 2.0;
  CGFloat horizontalOffset = delta.width / 2.0;
  return UIEdgeInsetsMake(verticalOffset, horizontalOffset, verticalOffset, horizontalOffset);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CGAffineTransform
////////////////////////////////////////////////////////////////////////////////////////////////////

CGAffineTransform CGAffineTransformMakeScaleTranslate(CGFloat sx, CGFloat sy, CGFloat dx, CGFloat dy) {
  return CGAffineTransformMake(sx, 0.f, 0.f, sy, dx, dy);
}

CGAffineTransform CGAffineTransformMakeShear(CGFloat shearX, CGFloat shearY) {
  return CGAffineTransformMake(1.f, shearY, shearX, 1.f, 0.f, 0.f);
}

CGAffineTransform CGAffineTransformShear(CGAffineTransform transform, CGFloat shearX, CGFloat shearY) {
  CGAffineTransform sheared = CGAffineTransformMakeShear(shearX, shearY);
  return CGAffineTransformConcat(transform, sheared);
}

CGFloat CGAffineTransformGetDeltaX(CGAffineTransform transform) { return transform.tx; }
CGFloat CGAffineTransformGetDeltaY(CGAffineTransform transform) { return transform.ty; }
CGFloat CGAffineTransformGetScaleX(CGAffineTransform t) { return sqrtf((t.a * t.a) + (t.c * t.c)); }
CGFloat CGAffineTransformGetScaleY(CGAffineTransform t) { return sqrtf((t.b * t.b) + (t.d * t.d)); }
CGFloat CGAffineTransformGetShearX(CGAffineTransform transform) { return transform.b; }
CGFloat CGAffineTransformGetShearY(CGAffineTransform transform) { return transform.c; }
CGFloat CGPointAngleBetweenPoints(CGPoint p1, CGPoint p2) { return atan2f(p2.y - p1.y, p2.x - p1.x); }

CGFloat CGAffineTransformGetRotation(CGAffineTransform transform) {
  // No exact way to get rotation out without knowing order of all previous operations
  // So, we'll cheat. We'll apply the transformation to two points and then determine the
  // angle betwen those two points

  CGPoint testPoint1   = CGPointMake(-100.f, 0.f);
  CGPoint testPoint2   = CGPointMake(100.f, 0.f);
  CGPoint transformed1 = CGPointApplyAffineTransform(testPoint1, transform);
  CGPoint transformed2 = CGPointApplyAffineTransform(testPoint2, transform);
  return CGPointAngleBetweenPoints(transformed1, transformed2);
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - CATransform3D
////////////////////////////////////////////////////////////////////////////////////////////////////

CATransform3D CATransform3DMakePerspective(CGFloat eyeDistance) {
  return (CATransform3D) { 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, -1. / eyeDistance, 0, 0, 0, 1 };
}

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Conversions
////////////////////////////////////////////////////////////////////////////////////////////////////

CGFloat DegreesToRadians(CGFloat degrees) { return degrees * M_PI / 180.0; }
CGFloat RadiansToDegrees(CGFloat radians) { return radians * 180.0 / M_PI; }

////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark - Core Text
////////////////////////////////////////////////////////////////////////////////////////////////////

CGFloat GetLineHeightForFont(CTFontRef iFont) {
  CGFloat lineHeight = 0.0;

  if (iFont == NULL) return 0.0;

  // Get the ascent from the font, already scaled for the font's size
  lineHeight += CTFontGetAscent(iFont);

  // Get the descent from the font, already scaled for the font's size
  lineHeight += CTFontGetDescent(iFont);

  // Get the leading from the font, already scaled for the font's size
  lineHeight += CTFontGetLeading(iFont);

  return lineHeight;
}

CGRect CGRectBoundToRect(CGRect slave, CGRect master) {
  CGFloat slaveMinX  = CGRectGetMinX(slave);
  CGFloat slaveMaxX  = CGRectGetMaxX(slave);
  CGFloat slaveMinY  = CGRectGetMinY(slave);
  CGFloat slaveMaxY  = CGRectGetMaxY(slave);
  CGFloat masterMinX = CGRectGetMinX(master);
  CGFloat masterMaxX = CGRectGetMaxX(master);
  CGFloat masterMinY = CGRectGetMinY(master);
  CGFloat masterMaxY = CGRectGetMaxY(master);

  CGFloat pushX = (slaveMinX >= masterMinX ? 0.0f : masterMinX - slaveMinX);
  CGFloat pushY = (slaveMinY >= masterMinY ? 0.0f : masterMinY - slaveMinY);
  CGFloat pullX = (slaveMaxX <= masterMaxX ? 0.0f : slaveMaxX - masterMaxX);
  CGFloat pullY = (slaveMaxY <= masterMaxY ? 0.0f : slaveMaxY - masterMaxY);

  return CGRectMake(slave.origin.x + pushX + pullX,
                    slave.origin.y + pushY + pullY,
                    MIN(slave.size.width + pushX + pullX,  slave.size.width),
                    MIN(slave.size.height + pushY + pullY, slave.size.height));
}
