//
//  MSPainter.h
//  MSKit
//
//  Created by Jason Cardwell on 9/30/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
@import QuartzCore;

typedef NS_ENUM (NSInteger, MSPainterShape) {
    MSPainterShapeUndefined        = 0,
    MSPainterShapeRoundedRectangle = 1,
    MSPainterShapeOval             = 2,
    MSPainterShapeRectangle        = 3,
    MSPainterShapeTriangle         = 4,
    MSPainterShapeDiamond          = 5
};

@interface MSPainter : NSObject

+ (UIImage *)circledText:(NSString *)text
                    font:(UIFont *)font
         backgroundColor:(UIColor *)color
               textColor:(UIColor *)textColor
                    size:(CGSize)size;

+ (void)drawGlossGradientWithColor:(UIColor *)color
                              rect:(CGRect)rect
                           context:(CGContextRef)context
                            offset:(CGFloat)offset;

+ (void)drawLinearGradientInRect:(CGRect)rect
                  withStartColor:(CGColorRef)startColor
                        endColor:(CGColorRef)endColor
                       inContext:(CGContextRef)context;

+ (void)drawBorderForShape:(MSPainterShape)shape
                     color:(UIColor *)color
                     width:(CGFloat)width
                      join:(CGLineJoin)join
                      rect:(CGRect)rect
               cornerRadii:(CGSize)cornerRadii
                   context:(CGContextRef)context;

+ (void)drawBackdropForShape:(MSPainterShape)shape
                      inRect:(CGRect)rect
               backdropColor:(UIColor *)color
                 cornerRadii:(CGSize)cornerRadii
                   inContext:(CGContextRef)context;

+ (UIImage *)borderPathImage:(UIImage *)image color:(UIColor *)color width:(NSUInteger)width;

+ (NSArray *)borderPointsForImage:(UIImage *)image;

+ (UIBezierPath *)stretchedOvalFromRect:(CGRect)rect;

+ (UIBezierPath *)borderPathForImage:(UIImage *)image;

+ (UIImage *)embossImage:(UIImage *)image;

+ (UIImage *)blurImage:(UIImage *)image;

+ (void)drawLEDButtons;

+ (void)drawPowerButton;

+ (void)drawRoundedRectButton;

+ (void)drawRoundedRectButtonBaseInContext:(CGContextRef)context
                               buttonColor:(UIColor *)buttonColor
                               shadowColor:(UIColor *)shadowColor
                                    opaque:(BOOL)opaque
                                     frame:(CGRect)frame;

+ (void)drawRoundedRectButtonOverlayInContext:(CGContextRef)context
                                   shineColor:(UIColor *)shineColor
                                        frame:(CGRect)frame;

+ (void)drawIconButton;

+ (void)drawResizableButton;

+ (void)drawBlueButton;

+ (void)drawGlassShelf;

+ (void)drawProgressBar;

+ (void)drawOrganicSlider;

+ (void)drawCMYPad;


@end
