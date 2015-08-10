//
//  UIImage+MSKitAdditions.h
//  Canine Acupoints
//
//  Created by Jason Cardwell on 4/8/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
@import QuartzCore;

typedef struct {
    CGBitmapInfo bitmapInfo;
    CGImageAlphaInfo alphaInfo;
    CGBitmapInfo byteOrderInfo;
    BOOL floatComponents;
    size_t width;
    size_t height;
    size_t bitsPerPixel;
    size_t bitsPerComponent;
    size_t bytesPerRow;
    CGColorRenderingIntent renderingIntent;
    CGColorSpaceModel colorSpaceModel;
    size_t numberOfComponents;
    CGFloat scale;

} ImageInfo;

@interface UIImage (MSKitAdditions)

- (ImageInfo)imageInfo;

- (NSString *)imageInfoDescription;

+ (UIImage *)imageFromLayer:(CALayer *)layer;

- (UIImage *)recoloredImageWithColor:(UIColor *)inputColor;

+ (UIImage *)imageFromAlphaOfImage:(UIImage *)image color:(UIColor *)color;

- (CGSize)sizeThatFits:(CGSize)size;

+ (UIImage *)captureImageOfView:(UIView *)view;

- (NSData *)bitmapData;

- (NSData *)bitmapData:(CGBitmapInfo)bitmapInfo colorSpace:(CGColorSpaceRef)colorSpace;

- (NSData *)vImageConformantDataForImage;

+ (UIImage *)imageWithBitmapData:(NSData *)bitmapData imageInfo:(ImageInfo)info;

/*
+ (UIImage *)imageFromAlphaOfImage:(UIImage *)image 
                     colorGradient:(NSArray *)colors 
                         locations:(CGFloat *)locations
                        startPoint:(CGPoint)startPoint 
                          endPoint:(CGPoint)endPoint 
                         antialias:(BOOL)shouldAntialias;

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color;

+ (UIImage *)screenshot;

 + (UIImage *)imageFromImage:(UIImage *)image withDecode:(const CGFloat *)decode;

+ (UIImage *)imageMaskFromImage:(UIImage *)image withDecode:(const CGFloat *)decode;

+ (UIImage *)gradientPatternImageOfSize:(CGSize)size
                             withColors:(NSArray *)colors
                              locations:(CGFloat *)locations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint;

 - (UIImage *)inverted;

- (UIImage *)invertedAlpha;

- (UIImage *)thumbnailWithSize:(CGSize)size;

- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage;

- (UIImage *)imageDrawnInRect:(CGRect)imageRect 
               withCanvasSize:(CGSize)canvasSize
                   knockedOut:(BOOL)knockedOut;

- (UIImage *)imageDrawnInRect:(CGRect)imageRect
                    withFrame:(CGRect)frame
           andBackgroundColor:(UIColor *)backgroundColor;

- (UIImage *)imageWithMaskingColors:(const CGFloat *)maskingColors;

- (CGImageRef)createMask;

// Converts a UIImage to RGBA8 bitmap.
//   @param image - a UIImage to be converted
//   @return a RGBA8 bitmap, or NULL if any memory allocation issues. Cleanup memory with free() when done.
+ (unsigned char *)convertUIImageToBitmapRGBA8:(UIImage *)image;

// A helper routine used to convert a RGBA8 to UIImage
//   @return a new context that is owned by the caller
+ (CGContextRef)newBitmapRGBA8ContextFromImage:(CGImageRef)image;

// Converts a RGBA8 bitmap to a UIImage.
//   @param buffer - the RGBA8 unsigned char * bitmap
//   @param width - the number of pixels wide
//   @param height - the number of pixels tall
//   @return a UIImage that is autoreleased or nil if memory allocation issues
+ (UIImage *)convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(int)width
                              withHeight:(int)height;
*/

@end
