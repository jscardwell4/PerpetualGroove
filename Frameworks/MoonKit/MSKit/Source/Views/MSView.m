//
//  MSView.m
//  Remote
//
//  Created by Jason Cardwell on 3/23/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSView.h"
#import "MSKitMacros.h"
#import "UIColor+MSKitAdditions.h"
#import "MSPainter.h"

@implementation MSView

- (id)initWithFrame:(CGRect)frame {
  if (self = [super initWithFrame:frame]) {
    _borderThickness = 1.0;
    _borderRadii     = CGSizeMake(5, 5);
    _glossColor      = UIColorMake(1, 1, 1, 0.02);
    self.opaque      = NO;
  }

  return self;
}

- (void)setStyle:(MSViewStyle)style {
  _style = style;
  [self setNeedsDisplay];
}

- (void)setBorderColor:(UIColor *)borderColor {
  _borderColor = borderColor;
  [self setNeedsDisplay];
}

- (void)setGlossColor:(UIColor *)glossColor {
  _glossColor = glossColor;
  [self setNeedsDisplay];
}

- (void)setBorderThickness:(CGFloat)borderThickness {
  _borderThickness = borderThickness;
  [self setNeedsDisplay];
}

- (void)setBorderRadii:(CGSize)borderRadii {
  _borderRadii = borderRadii;
  [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

  CGContextRef context = UIGraphicsGetCurrentContext();

  if (self.clearsContextBeforeDrawing) CGContextClearRect(context, self.bounds);

  uint8_t preset = (_style & MSViewStylePresetMask);

  if (preset) {
    [self drawPreset:preset context:context];
    return;
  }


  uint8_t        border = (_style & MSViewStyleBorderMask);
  MSPainterShape shape  = (border == MSViewStyleBorderRoundedRect
                           ? MSPainterShapeRoundedRectangle
                           : MSPainterShapeRectangle);

  [MSPainter drawBackdropForShape:shape
                           inRect:rect
                    backdropColor:self.backgroundColor
                      cornerRadii:self.borderRadii
                        inContext:context];

  if (border)
    [MSPainter drawBorderForShape:shape
                            color:self.borderColor
                            width:self.borderThickness
                             join:kCGLineJoinMiter
                             rect:rect
                      cornerRadii:self.borderRadii
                          context:context];


  if (_style & MSViewStyleDrawGloss)
    [MSPainter drawGlossGradientWithColor:self.glossColor
                                     rect:rect
                                  context:context
                                   offset:0];

}

- (void)drawPreset:(uint32_t)preset context:(CGContextRef)context {

  NSAssert(preset != 0, @"Draw preset request with custom flag");

  switch (preset) {
    case 1:[self drawPresetStyle1InContext:context]; break;
    default:                                          break;
  }
}

- (void)drawPresetStyle1InContext:(CGContextRef)context {
  CGContextSaveGState(context);

  [self.backgroundColor setFill];
  UIRectFillUsingBlendMode(self.bounds, kCGBlendModeSoftLight);

  CGRect lightFrame = self.bounds;
  CGRect darkFrame  = CGRectInset(lightFrame, 1.0f, 1.0f);
  darkFrame.size.width -= 1.0f;


  [[WhiteColor colorWithAlphaComponent:1.0f] setStroke];
  CGContextSetShadowWithColor(context,
                              (CGSize) {0.0f, 0.0f }, 1.0f,
                              [WhiteColor CGColor]);
  UIRectFrame(lightFrame);

  [[BlackColor colorWithAlphaComponent:0.25f] setStroke];
  UIRectClip(darkFrame);
  CGContextSetShadow(context, (CGSize) {.width = 1.0f, .height = 1.0f }, 1.0f);
  UIRectFrame(darkFrame);

  [[WhiteColor colorWithAlphaComponent:0.5f] setStroke];
  CGContextSetShadowWithColor(context,
                              (CGSize) {0.0f, 0.0f }, 1.0f,
                              [WhiteColor CGColor]);
  UIRectFrame(lightFrame);

  CGContextRestoreGState(context);

}

@end
