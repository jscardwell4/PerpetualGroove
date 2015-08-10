//
//  MSKitGeometryFunctions.h
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import CoreText;
@import CoreGraphics;
@import QuartzCore;
@import UIKit;

NSString *NSStringFromCATransform3D(CATransform3D transform);
NSString *NSStringFromCATransform3DT(CATransform3D transform);

typedef struct MSBoundary_s { CGFloat   lower, upper; } MSBoundary;
MSBoundary MSBoundaryMake(CGFloat lower, CGFloat upper);
BOOL MSValueInBounds(CGFloat value, MSBoundary boundary);
NSUInteger MSBoundarySizeOfBoundary(MSBoundary boundary);
NSString *NSStringFromMSBoundary(MSBoundary boundary);

typedef struct MSAspectRatio_s { CGFloat x, y; } MSAspectRatio;
MSAspectRatio MSAspectRatioMake(CGFloat x, CGFloat y);
MSAspectRatio MSAspectRatioFromSizeOverSize(CGSize a, CGSize b);
MSAspectRatio MSAspectRatioWithMinAxis(MSAspectRatio r);
MSAspectRatio MSAspectRatioWithMaxAxis(MSAspectRatio r);

#define MSAspectRatioOneToOne MSAspectRatioMake(1.0f, 1.0f)
#define MSAspectRatioUnpack(a) a.x, a.y

#define M_PI_3  M_PI/3.0     // 60º
#define M_PI_6  M_PI/6.0     // 30º
#define M_PI_12 M_PI/12.0    // 15º
#define M_PI_18 M_PI/18.0    // 10º
#define M_PI_36 M_PI/36.0    // 5º
CGFloat Delta(CGFloat a, CGFloat b);
CGFloat CGPointGetDeltaX(CGPoint a, CGPoint b);
CGFloat CGPointGetDeltaY(CGPoint a, CGPoint b);
CGPoint CGPointGetDelta(CGPoint a, CGPoint b);

#define CGPointDeltaPoint(a, b) CGPointGetDelta(a, b)
CGFloat DeltaABS(CGFloat a, CGFloat b);
CGFloat CGPointGetDeltaXABS(CGPoint a, CGPoint b);
CGFloat CGPointGetDeltaYABS(CGPoint a, CGPoint b);
CGPoint CGPointGetDeltaABS(CGPoint a, CGPoint b);

#define CGPointDeltaPointABS(a, b) CGPointGetDeltaABS(a, b)
CGPoint CGRectGetCenter(CGRect rect);
CGPoint CGPointOriginForSizeCenter(CGSize size, CGPoint center);
CGRect CGRectReposition(CGRect rect, CGPoint origin);
CGRect CGRectResize(CGRect rect, CGSize size);
CGRect CGRectSetHeight(CGRect rect, CGFloat h);
CGRect CGRectSetWidth(CGRect rect, CGFloat w);
CGRect CGRectAnchoredResize(CGRect rect, CGSize size);
CGRect CGRectWithSizeAndCenter(CGSize size, CGPoint center);
CGRect CGRectCenteredOnPoint(CGRect rect, CGPoint point);

#define CGSizeMax CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX)
#define CGSizeUnpack(s)  s.width, s.height
#define CGPointUnpack(p) p.x, p.y
CGSize CGSizeAddedToSize(CGSize a, CGSize b);
CGSize CGSizeApplyScale(CGSize size, CGFloat scale);
BOOL CGSizeContainsSize(CGSize a, CGSize b);
CGSize CGSizeUnionSize(CGSize a, CGSize b);
CGSize CGSizeGetDelta(CGSize a, CGSize b);

#define CGSizeMakeSquare(v) CGSizeMake(v, v)
CGFloat CGSizeMinAxis(CGSize size);
CGFloat CGSizeMaxAxis(CGSize size);
CGFloat CGSizeGetArea(CGSize size);
BOOL CGSizeGreaterThanSize(CGSize s1, CGSize s2);
BOOL CGSizeLessThanSize(CGSize s1, CGSize s2);
BOOL CGSizeGreaterThanOrEqualToSize(CGSize s1, CGSize s2);
BOOL CGSizeLessThanOrEqualToSize(CGSize s1, CGSize s2);
CGSize CGSizeIntegral(CGSize s);
CGSize CGSizeIntegralRoundingUp(CGSize s);
CGSize CGSizeIntegralRoundingDown(CGSize s);
CGSize CGSizeMaxSize(CGSize s1, CGSize s2);
CGSize CGSizeMinSize(CGSize s1, CGSize s2);
CGSize CGSizeAspectMappedToWidth(CGSize s, CGFloat w);
CGSize CGSizeAspectMappedToHeight(CGSize s, CGFloat h);
CGSize CGSizeAspectMappedToSize(CGSize s1, CGSize s2, BOOL bound);
UIEdgeInsets UIEdgeInsetsForSizeCenteredInSize(CGSize s1, CGSize s2);
CGAffineTransform CGAffineTransformMakeScaleTranslate(CGFloat sx, CGFloat sy, CGFloat dx, CGFloat dy);
CGAffineTransform CGAffineTransformMakeShear(CGFloat shearX, CGFloat shearY);
CGAffineTransform CGAffineTransformShear(CGAffineTransform transform, CGFloat shearX, CGFloat shearY);
CGFloat CGAffineTransformGetDeltaX(CGAffineTransform transform);
CGFloat CGAffineTransformGetDeltaY(CGAffineTransform transform);
CGFloat CGAffineTransformGetScaleX(CGAffineTransform transform);
CGFloat CGAffineTransformGetScaleY(CGAffineTransform transform);
CGFloat CGAffineTransformGetShearX(CGAffineTransform transform);
CGFloat CGAffineTransformGetShearY(CGAffineTransform transform);
CGFloat CGPointAngleBetweenPoints(CGPoint first, CGPoint second);
CGFloat CGAffineTransformGetRotation(CGAffineTransform transform);
CATransform3D CATransform3DMakePerspective(CGFloat eyeDistance);
CGFloat DegreesToRadians(CGFloat degrees);
CGFloat RadiansToDegrees(CGFloat radians);
CGFloat GetLineHeightForFont(CTFontRef iFont);
CGRect CGRectBoundToRect(CGRect slave, CGRect master);
