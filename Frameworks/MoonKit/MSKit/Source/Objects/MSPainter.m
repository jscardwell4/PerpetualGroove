//
//  MSPainter.m
//  MSKit
//
//  Created by Jason Cardwell on 9/30/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSPainter.h"
#import <malloc/malloc.h>
#import <Accelerate/Accelerate.h>
#import <stdint.h>
#import <ImageIO/ImageIO.h>
#import "MSKitMacros.h"
#import "MSKitGeometryFunctions.h"
#import "NSValue+MSKitAdditions.h"
#import "UIColor+MSKitAdditions.h"
#import "MSLog.h"
#import <MoonKit/Moonkit-swift.h>

static int ddLogLevel = LOG_LEVEL_DEBUG;
static const int msLogContext = (LOG_CONTEXT_MSKIT|LOG_CONTEXT_FILE);

#pragma mark - Typedefs

typedef struct {
    CGFloat color[4];
    CGFloat caustic[4];
    CGFloat expCoefficient;
    CGFloat expScale;
    CGFloat expOffset;
    CGFloat initialWhite;
    CGFloat finalWhite;
    CGFloat split;
} GlossParameters;

NSUInteger   (^bitmapLocation)(NSUInteger, NSUInteger, NSUInteger) =
^(NSUInteger x, NSUInteger y, NSUInteger w) {
    return (NSUInteger) (y * w * 4 + x * 4);
};

NSUInteger   (^bitmapLocationSingleChannel)(NSUInteger, NSUInteger, NSUInteger) =
^(NSUInteger x, NSUInteger y, NSUInteger w) {
    return (NSUInteger) (y * w + x);
};

CGPoint   (^imageLocation)(NSUInteger, NSUInteger) =
^(NSUInteger i, NSUInteger w) {
    CGPoint p = CGPointZero;

    p.y = i/(w * 4);
    p.x = (i - 4 * w * p.y)/4;

    return p;
};

#pragma mark - Kernels

static const int16_t kEmbossKernel[] = {
    -2, -2, 0,
    -2,  6, 0,
    0,  0, 0
};
static const int16_t kGaussianBlurKernel[] = {
    1, 2, 1,
    2, 4, 2,
    1, 2, 1
};
static const int16_t kBoxKernel[] = {
    -1, -1, -1, 3, -1, -1, -1,
    -1, -1,  0, 2,  0, -1, -1,
    -1,  0,  1, 1,  1,  0, -1,
    3,  2,  1, 0,  1,  2,  3,
    -1,  0,  1, 1,  1,  0, -1,
    -1,  0,  0, 2,  0, -1, -1,
    -1, -1, -1, 3, -1, -1, -1
};
static const int16_t kTentKernel[] = {
    1, 1, 1,
    1, 1, 1,
    1, 1, 1
};
static const int16_t kEdgeDetectionKernel[] = {
    -1, -1, -1,
    0,  0,  0,
    1,  1,  1
};

#pragma unused(kEmbossKernel, kBoxKernel, kTentKernel, kEdgeDetectionKernel)

#pragma mark - Function declarations

CGFloat perceptualGlossFractionForColor(CGFloat *inputComponents);

void perceptualCausticColorForColor(CGFloat *inputComponents, CGFloat *outputComponents);

static void glossInterpolation(void *info, const CGFloat *input, CGFloat *output);

NSData *getBitmapFromImage(UIImage *image);

NSData *vImageConformantDataForImage(UIImage *image);

CGImageRef createImageFromFileName(NSString *fileName);

NSDictionary *imageSourceFromURL(NSURL *url);

UInt8 reversePremultipliedAlpha(UInt8 channel, UInt8
                                alpha);

vImage_Error gaussianBlur(uint8_t   *inData,
                          uint8_t   *outData,
                          NSUInteger height,
                          NSUInteger width,
                          NSUInteger bytesPerRow);

vImage_Error convolve(uint8_t   *inData,
                      uint8_t   *outData,
                      NSUInteger height,
                      NSUInteger width,
                      NSUInteger bytesPerRow,
                      int16_t   *kernel,
                      uint32_t   kernelHeight,
                      uint32_t   kernelWidth,
                      int32_t    divisor);

NSData *scaledImageDataFromImageData(NSData *imageData, NSUInteger bytesPerRow, CGFloat scale);

#pragma mark - Function definitions

UInt8 reversePremultipliedAlpha(UInt8 channel, UInt8 alpha) { return channel - (channel - alpha); }

CGImageRef createImageFromFileName(NSString *fileName)
{
    NSURL *url = [NSURL fileURLWithPath:fileName];

    // Create the image source with the options left null for now
    // Keep in mind since we created it, we're responsible for getting rid of it
    CGImageSourceRef image_source = CGImageSourceCreateWithURL((__bridge CFURLRef) url, NULL);

    if (image_source == NULL) {
        // Something went wrong
        MSLogCError(@"VImage error: Couldn't create image source from URL\n");

        return NULL;
    }

    // Now that we got the source, let's create an image from the first image in the CGImageSource
    CGImageRef image = CGImageSourceCreateImageAtIndex(image_source, 0, NULL);

    // We created our image, and that's all we needed the source for, so let's release it
    CFRelease(image_source);

    if (image == NULL) {
        // something went wrong
        MSLogCError(@"VImage error: Couldn't create image source from URL\n");

        return NULL;
    }

    return image;
}

NSDictionary *imageSourceFromURL(NSURL *url)
{
    NSMutableDictionary *returnDict = [NSMutableDictionary dictionary];
    CGImageSourceRef source = CGImageSourceCreateWithURL((__bridge CFURLRef)url, NULL);

    if (source) {
        returnDict[@"imageSource"] = (__bridge_transfer id) source;

        NSDictionary *props =
        (__bridge_transfer NSDictionary *)CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);

        returnDict[@"props"] = props;

        NSDictionary *thumbOpts =
        @{(id)kCGImageSourceCreateThumbnailWithTransform     : (id)kCFBooleanTrue,
          (id)kCGImageSourceCreateThumbnailFromImageIfAbsent : (id)kCFBooleanTrue,
          (id)kCGImageSourceThumbnailMaxPixelSize            : @128};

        CGImageRef image = CGImageSourceCreateThumbnailAtIndex(source,
                                                               0,
                                                               (__bridge CFDictionaryRef)thumbOpts);

        returnDict[@"thumb"] = [UIImage imageWithCGImage:image];

        CGImageRelease(image);

        NSString *uti = (__bridge_transfer NSString *)CGImageSourceGetType(source);

        returnDict[@"uti"] = uti;

        NSDictionary *fileProps =
        (__bridge_transfer NSDictionary *)CGImageSourceCopyProperties(source, nil);

        returnDict[@"fileProps"] = fileProps;
    }

    return returnDict;
}

CGFloat perceptualGlossFractionForColor(CGFloat *inputComponents)
{
    const CGFloat REFLECTION_SCALE_NUMBER = 0.2;
    const CGFloat NTSC_RED_FRACTION = 0.299;
    const CGFloat NTSC_GREEN_FRACTION = 0.587;
    const CGFloat NTSC_BLUE_FRACTION = 0.114;
    CGFloat glossScale = NTSC_RED_FRACTION    * inputComponents[0]
    + NTSC_GREEN_FRACTION * inputComponents[1]
    + NTSC_BLUE_FRACTION  * inputComponents[2];

    glossScale = pow(glossScale, REFLECTION_SCALE_NUMBER);

    return glossScale;
}

void perceptualCausticColorForColor(CGFloat *inputComponents, CGFloat *outputComponents)
{
    const CGFloat CAUSTIC_FRACTION = 0.60;
    const CGFloat COSINE_ANGLE_SCALE = 1.4;
    const CGFloat MIN_RED_THRESHOLD = 0.95;
    const CGFloat MAX_BLUE_THRESHOLD = 0.7;
    const CGFloat GRAYSCALE_CAUSTIC_SATURATION = 0.2;
    UIColor *source = [UIColor colorWithRed:inputComponents[0]
                                      green:inputComponents[1]
                                       blue:inputComponents[2]
                                      alpha:inputComponents[3]];

    CGFloat hue, saturation, brightness, alpha;
    [source getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];

    CGFloat targetHue, targetSaturation, targetBrightness;

    [YellowColor getHue:&targetHue
             saturation:&targetSaturation
             brightness:&targetBrightness
                  alpha:&alpha];

    if (saturation < 1e-3)
    {
        hue = targetHue;
        saturation = GRAYSCALE_CAUSTIC_SATURATION;
    }

    if (hue > MIN_RED_THRESHOLD) hue -= 1.0;

    else if (hue > MAX_BLUE_THRESHOLD)
        [[UIColor magentaColor] getHue:&targetHue
                            saturation:&targetSaturation
                            brightness:&targetBrightness
                                 alpha:&alpha];

    CGFloat scaledCaustic = CAUSTIC_FRACTION * 0.5
    * (1.0 + cos(COSINE_ANGLE_SCALE * M_PI * (hue - targetHue)));
    UIColor *targetColor =
    [UIColor colorWithHue:hue * (1.0 - scaledCaustic) + targetHue * scaledCaustic
               saturation:saturation
               brightness:brightness * (1.0 - scaledCaustic) + targetBrightness * scaledCaustic
                    alpha:inputComponents[3]];

    [targetColor getRed:&outputComponents[0]
                  green:&outputComponents[1]
                   blue:&outputComponents[2]
                  alpha:&outputComponents[3]];
}

static void glossInterpolation(void *info, const CGFloat *input, CGFloat *output)
{
    GlossParameters *p = (GlossParameters *) info;
    CGFloat progress = *input;

    if (   (p->split > 0.0f && progress < p->split)
        || (p->split < 0.0f && progress > 1 + p->split))
    {
        progress = progress * 2.0;

        progress = 1.0 - p->expScale * (expf(progress * -p->expCoefficient) - p->expOffset);

        CGFloat currentWhite = progress * (p->finalWhite - p->initialWhite) + p->initialWhite;

        output[0] = p->color[0] * (1.0 - currentWhite) + currentWhite;
        output[1] = p->color[1] * (1.0 - currentWhite) + currentWhite;
        output[2] = p->color[2] * (1.0 - currentWhite) + currentWhite;
        output[3] = p->color[3] * (1.0 - currentWhite) + currentWhite;
    }
    else {
        progress = (progress - (p->split > 0.0f ?: 1 + p->split)) * 2.0;

        progress = p->expScale * (expf((1.0 - progress) * -p->expCoefficient) - p->expOffset);

        output[0] = p->color[0] * (1.0 - progress) + p->caustic[0] * progress;
        output[1] = p->color[1] * (1.0 - progress) + p->caustic[1] * progress;
        output[2] = p->color[2] * (1.0 - progress) + p->caustic[2] * progress;
        output[3] = p->color[3] * (1.0 - progress) + p->caustic[3] * progress;
    }
}

NSData *getBitmapFromImage(UIImage *image)
{
    return (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(image.CGImage));
}

NSData *vImageConformantDataForImage(UIImage *image)
{
    ImageInfo imageInfo = [image imageInfo];

    MSLogCDebug(@"%@", ImageInfoString(imageInfo));

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageInfo.width,
                                                 imageInfo.height,
                                                 imageInfo.bitsPerComponent,
                                                 imageInfo.bytesPerRow,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);

    CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, imageInfo.width, imageInfo.height), image.CGImage);

    CGImageRef imgRef  = CGBitmapContextCreateImage(context);
    NSData *   imgData = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(imgRef));

    CGImageRelease(imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return imgData;
}

vImage_Error gaussianBlur(uint8_t   *inData,
                          uint8_t   *outData,
                          NSUInteger height,
                          NSUInteger width,
                          NSUInteger bytesPerRow)
{
    vImage_Buffer src  = {inData, height, width, bytesPerRow};
    vImage_Buffer dest = {outData, height, width, bytesPerRow};
    vImage_Error err   = vImageConvolve_ARGB8888(&src,
                                                 &dest,
                                                 NULL,
                                                 0,
                                                 0,
                                                 kGaussianBlurKernel,
                                                 3,
                                                 3,
                                                 1,
                                                 NULL, // (Pixel_8888){0,0,0,0},
                                                 kvImageEdgeExtend /* kvImageBackgroundColorFill*/);

    return err;
}

vImage_Error convolve(uint8_t   *inData,
                      uint8_t   *outData,
                      NSUInteger height,
                      NSUInteger width,
                      NSUInteger bytesPerRow,
                      int16_t   *kernel,
                      uint32_t   kernelHeight,
                      uint32_t   kernelWidth,
                      int32_t    divisor)
{
    assert(NO);

    vImage_Buffer src = {inData, height, width, bytesPerRow};
    vImage_Buffer dest = {outData, height, width, bytesPerRow};
    vImage_Error err = vImageConvolve_ARGB8888(&src,
                                               &dest,
                                               NULL,
                                               0,
                                               0,
                                               kernel,
                                               kernelHeight,
                                               kernelWidth,
                                               divisor,
                                               (Pixel_8888){0, 0, 0, 0},
                                               kvImageBackgroundColorFill);

    return err;
}

NSData *scaledImageDataFromImageData(NSData *imageData, NSUInteger bytesPerRow, CGFloat scale)
{
    assert(NO);

    vImage_Buffer src = {
        (void *)imageData.bytes,
        imageData.length/bytesPerRow,
        bytesPerRow/4,
        bytesPerRow
    };

    vImage_Buffer dest = {
        malloc([imageData length] * scale),
        (imageData.length/bytesPerRow) * scale,
        (bytesPerRow/4) * scale,
        bytesPerRow * scale
    };

    vImageScale_ARGB8888(&src, &dest, NULL, kvImageNoFlags);

    NSData *scaledImageData = [NSData dataWithBytes:dest.data length:imageData.length * scale];

    free(dest.data);

    return scaledImageData;
}

@implementation MSPainter

+ (id)sharedSharedPainter
{
    static dispatch_once_t pred = 0;
    __strong static MSPainter * _sharedObject = nil;
    dispatch_once(&pred, ^{ _sharedObject = [self new]; });
    return _sharedObject;
}

+ (UIImage *)circledText:(NSString *)text
                    font:(UIFont *)font
         backgroundColor:(UIColor *)color
               textColor:(UIColor *)textColor
                    size:(CGSize)size
{
    /* Called by MacroCommandEditingViewController */

    BOOL shouldClearText = ValueIsNil(textColor);

    // Create context
    UIGraphicsBeginImageContextWithOptions(size, NO, MainScreenScale);

    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetShouldAntialias(context, YES);

    // Draw circle
    CGRect rect = (CGRect) {.origin = CGPointZero, .size = size};

    [color setFill];

    UIBezierPath *circle = [UIBezierPath bezierPathWithOvalInRect:rect];

    [circle fill];

    // Flip context
    CGContextTranslateCTM(context, 0, rect.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // Ensure font height is not too large
    CGFloat pointSize = font.pointSize;

    if (pointSize > size.height) font = [font fontWithSize:size.height];

    // Measure width of text
    CGFontRef fontRef = CGFontCreateWithFontName((__bridge CFStringRef)(font.fontName));
    CGContextSetFont(context, fontRef);
    CGContextSetFontSize(context, font.pointSize);
    UIGraphicsPushContext(context);
    CGContextSetTextDrawingMode(context, kCGTextInvisible);
    //    CGContextShowTextAtPoint(context, 0.0f, 0.0f, [text UTF8String], text.length);
    CGFontRelease(fontRef);
    CGPoint endPoint = CGContextGetTextPosition(context);

    UIGraphicsPopContext();

    // Measure height and calculate center point
    CGSize stringSize = [text sizeWithAttributes:@{NSFontAttributeName: font}];
    CGPoint textCenter = CGRectGetCenter(rect);
    CGPoint textLocation = CGPointMake(textCenter.x - endPoint.x/2.0f,
                                       fabs(textCenter.y - stringSize.height/2.0f));
#pragma unused(textLocation)
    // Draw text
    [textColor setFill];
    CGContextSetTextDrawingMode(context, kCGTextFillClip);
    //    CGContextShowTextAtPoint(context, textLocation.x, textLocation.y, [text UTF8String], text.length);

    // Clear rect with path clipped to text if text color is nil
    if (shouldClearText) CGContextClearRect(context, rect);

    // Grab the image and end the context
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

/* circledText */

+ (void)drawGlossGradientWithColor:(UIColor *)color
                              rect:(CGRect)rect
                           context:(CGContextRef)context
                            offset:(CGFloat)offset
{
    /* Called by ButtonGroupView and ButtonView overlays */
    const CGFloat EXP_COEFFICIENT = 1.2;
    const CGFloat REFLECTION_MAX = 0.60;
    const CGFloat REFLECTION_MIN = 0.20;
    GlossParameters params;

    params.expCoefficient = EXP_COEFFICIENT;
    params.expOffset = expf(-params.expCoefficient);
    params.expScale = 1.0/(1.0 - params.expOffset);
    params.split = (offset && offset >= -1.0f && offset <= 1.0f ? offset : 0.5f);

    [color getRed:&params.color[0]
            green:&params.color[1]
             blue:&params.color[2]
            alpha:&params.color[3]];

    perceptualCausticColorForColor(params.color, params.caustic);

    CGFloat glossScale = perceptualGlossFractionForColor(params.color);

    params.initialWhite = glossScale * REFLECTION_MAX;
    params.finalWhite = glossScale * REFLECTION_MIN;

    static const CGFloat input_value_range[2] = {0, 1};
    static const CGFloat output_value_ranges[8] = {0, 1, 0, 1, 0, 1, 0, 1};
    CGFunctionCallbacks callbacks = {0, glossInterpolation, NULL};
    CGFunctionRef gradientFunction = CGFunctionCreate((void *)&params,
                                                      1, // number of input values to the callback
                                                      input_value_range,
                                                      4, // number of components (r, g, b, a)
                                                      output_value_ranges,
                                                      &callbacks);

    CGPoint endPoint           = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    CGPoint startPoint         = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGShadingRef shading       = CGShadingCreateAxial(colorspace,
                                                      startPoint,
                                                      endPoint,
                                                      gradientFunction,
                                                      TRUE,
                                                      TRUE);

    UIGraphicsPushContext(context);
    CGContextClipToRect(context, rect);
    CGContextDrawShading(context, shading);
    UIGraphicsPopContext();

    CGShadingRelease(shading);
    CGColorSpaceRelease(colorspace);
    CGFunctionRelease(gradientFunction);
}

+ (void)drawLinearGradientInRect:(CGRect)rect
                  withStartColor:(CGColorRef)startColor
                        endColor:(CGColorRef)endColor
                       inContext:(CGContextRef)context
{
    assert(NO);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGFloat locs[] = {0.0, 1.0};
    NSArray *colors = @[(__bridge id)startColor, (__bridge id)endColor];
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)colors, locs);
    CGPoint startPoint = CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect));
    CGPoint endPoint   = CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect));

    UIGraphicsPushContext(context);
    CGContextAddRect(context, rect);
    CGContextClip(context);
    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);
    UIGraphicsPopContext();

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawBackdropForShape:(MSPainterShape)shape
                      inRect:(CGRect)rect
               backdropColor:(UIColor *)color
                 cornerRadii:(CGSize)cornerRadii
                   inContext:(CGContextRef)context
{
//    assert(NO);

    UIBezierPath *backdropBP = nil;

    switch (shape)
    {
        case MSPainterShapeRoundedRectangle:
            backdropBP = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:UIRectCornerAllCorners
                                                     cornerRadii:cornerRadii];
            break;

        case MSPainterShapeOval:
            backdropBP = [UIBezierPath bezierPathWithOvalInRect:rect];
            break;

        case MSPainterShapeRectangle:
            backdropBP = [UIBezierPath bezierPathWithRoundedRect:rect
                                               byRoundingCorners:UIRectCornerAllCorners
                                                     cornerRadii:cornerRadii];
            break;

        default:
            break;
    }

    UIGraphicsPushContext(context);
//    [backdropBP addClip];
    [color setFill];
    [backdropBP fill];
    UIGraphicsPopContext();
}

+ (void)drawBorderForShape:(MSPainterShape)shape
                     color:(UIColor *)color
                     width:(CGFloat)width
                      join:(CGLineJoin)join
                      rect:(CGRect)rect
               cornerRadii:(CGSize)cornerRadii
                   context:(CGContextRef)context
{
//    assert(NO);

    UIBezierPath *borderBP = nil;

    switch (shape)
    {
        case MSPainterShapeUndefined:

            return;

        case MSPainterShapeRoundedRectangle:
            borderBP = [UIBezierPath bezierPathWithRoundedRect:rect
                                             byRoundingCorners:UIRectCornerAllCorners
                                                   cornerRadii:cornerRadii];
            break;

        case MSPainterShapeOval:
            borderBP = [UIBezierPath bezierPathWithOvalInRect:rect];
            break;

        case MSPainterShapeRectangle:
            borderBP = [UIBezierPath bezierPathWithRect:rect];
            break;

        case MSPainterShapeTriangle:
            break;

        case MSPainterShapeDiamond:
            break;

        default:
            break;
    }

    UIGraphicsPushContext(context);
    [color setStroke];
    borderBP.lineJoinStyle = join;
    borderBP.lineWidth = width;
    [borderBP stroke];
    UIGraphicsPopContext();
}

+ (UIBezierPath *)stretchedOvalFromRect:(CGRect)rect
{
    /* Called by ButtonView for backdrop and overlay oval shapes */
    CGFloat width = rect.size.width, height = rect.size.height;
    CGPoint a = rect.origin, b = rect.origin, c1 = CGPointZero, c2 = CGPointZero;
    CGFloat radius = 0.0, start1 = 0, end1 = 0, start2 = 0, end2 = 0;
    CGFloat delta = fabs(Delta(height, width));

    if (delta == 0)
        return [UIBezierPath bezierPathWithOvalInRect:rect];

    else if (width > height)
    {
        radius = height/2.0;
        a.x   += radius;
        a.y   += height;
        b.x   += radius + delta;
        c1.x   = a.x;
        c1.y   = a.y - radius;
        c2.x   = b.x;
        c2.y   = c1.y;
        start1 = M_PI_2;
        end1   = M_PI_2 * 3.0;
    }

    else {
        radius = width/2.0;
        a.y   += radius;
        b.x   += width;
        b.y   += radius + delta;
        c1.x   = a.x + radius;
        c1.y   = a.y;
        c2.x   = c1.x;
        c2.y   = b.y;
        start1 = M_PI;
        end1   = 0;
    }

    start2 = end1;
    end2 = start1;

    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:a];
    [path addArcWithCenter:c1 radius:radius startAngle:start1 endAngle:end1 clockwise:YES];
    [path addLineToPoint:b];
    [path addArcWithCenter:c2 radius:radius startAngle:start2 endAngle:end2 clockwise:YES];
    [path closePath];

    return path;
}

+ (NSArray *)borderPointsForImage:(UIImage *)image
{
    NSData *imageData = [image bitmapData];
    Pixel_8 *pixels = (Pixel_8 *)[imageData bytes];
    ImageInfo info = image.imageInfo;
    NSMutableArray *border = [NSMutableArray arrayWithCapacity:info.width * 2 + info.height * 2];
    Pixel_8
    alphaThreshold = 225; // cutoff for distinguishing between solid and transparent
    CGRect bounds = CGRectMake(0, 0, info.width, info.height);

    /*******************************************************************************
     *  helper function blocks
     *******************************************************************************/

    /* block for converting the index of a pixel into its corresponding point */
    CGPoint   (^imageLocation)(NSUInteger) =
    ^(NSUInteger i)
    {
        CGPoint p = CGPointZero;

        p.y = floor(i/(info.width * 4));
        p.x = (i - 4 * info.width * p.y)/4;

        return p;
    };

    /* block for converting a point into its corresponding pixel array index */
    NSUInteger   (^bitmapLocation)(CGPoint) =
    ^(CGPoint p)
    {
        return (NSUInteger) (p.y * info.width * 4 + p.x * 4);
    };

    /* Returns the
     alpha value for a given pixel location */
    Pixel_8   (^pixelAlpha)(NSUInteger) =
    ^(NSUInteger bitmapLocation)
    {
        return pixels[bitmapLocation + 3];
    };

    /* Returns the search direction given the previous direction */
    uint   (^nextDirection)(uint) =
    ^(uint d)
    {
        return (d % 2 ? (d + 6) % 8 : (d + 7) % 8);
    };

    /* Returns the neighbor point around point p in the direction d */
    CGPoint   (^pointForNeighborInDirection)(uint, CGPoint) =
    ^(uint d, CGPoint p)
    {
        switch (d)
        {
            case 0:  return CGPointMake(p.x + 1, p.y);
            case 1:  return CGPointMake(p.x + 1, p.y - 1);
            case 2:  return CGPointMake(p.x, p.y - 1);
            case 3:  return CGPointMake(p.x - 1, p.y - 1);
            case 4:  return CGPointMake(p.x - 1, p.y);
            case 5:  return CGPointMake(p.x - 1, p.y + 1);
            case 6:  return CGPointMake(p.x, p.y + 1);
            case 7:  return CGPointMake(p.x + 1, p.y + 1);
            default: return CGPointMake(-1, -1);
        }
    };

    /* Returns the pixel location for the neighbor of point p in direction d, or -1 if not in bounds
     **/
    NSInteger (^indexForNeighborInDirection)(uint, CGPoint p) =
    ^(uint d, CGPoint p)
    {
        CGPoint n = pointForNeighborInDirection(d, p);

        return (NSInteger) (CGRectContainsPoint(bounds, n) ? bitmapLocation(n) : -1);
    };

    /* Returns the pixel index for the next counter clockwise pixel around point p from direction d
     **/
    NSInteger (^nextCounterClockwiseNeighbor)(uint *, CGPoint) =
    ^(uint *d, CGPoint p)
    {
        NSInteger n = indexForNeighborInDirection(*d, p);

        while (n < 0)
        {
            *d = (*d + 1) % 8;
            n = indexForNeighborInDirection(*d, p);
        }

        assert(n > -1);

        return n;
    };

    /*******************************************************************************
     *  border point search
     *******************************************************************************/

    // find p0
    NSUInteger p0 = 0;

    while (border.count == 0 && p0 < imageData.length - 4)
    {
        if (pixelAlpha(p0) > alphaThreshold) [border addObject:NSValueWithCGPoint(imageLocation(p0))];
        else p0 += 4;
    }

    // return if p0 was not found
    if (border.count == 0) return border;

    // start neighborhood search
    uint dir = nextDirection(7);
    NSInteger pn = p0;
    BOOL stop = NO;

    do {
        NSInteger n = nextCounterClockwiseNeighbor(&dir, imageLocation(pn));

        if (n == p0)
            stop = YES;

        else if (pixelAlpha(n) > alphaThreshold)
        {
            [border addObject:NSValueWithCGPoint(imageLocation(n))];
            pn = n;
            dir = nextDirection(dir);
        }

        else
            dir = (dir + 1) % 8;
    } while (!stop);

    /*
     *  // block for determining next clockwise point in Moore neighborhood
     *  CGPoint (^__block nextClockwisePoint)(CGPoint,CGPoint) = ^(CGPoint b, CGPoint p) {
     *      CGPoint next;
     *      if (CGPointEqualToPoint(b, p))
     *          next = CGPointMake(p.x+1, p.y);
     *
     *      else if (b.x >= p.x)
     *          // b in {N,NE,E,SE,S}
     *          next = (  b.y > p.y
     *                  ? CGPointMake(b.x-1, b.y)
     *                 :(  b.y <= p.y && b.x > p.x
     *                     ? CGPointMake(b.x, b.y+1)
     *                    :CGPointMake(b.x+1, b.y)));
     *      else
     *          // b in {SW,W,NW}
     *          next = (  b.y >= p.y
     *                  ? CGPointMake(b.x, b.y-1)
     *                 :CGPointMake(b.x+1, b.y));
     *
     *      if (next.x < 0 || next.y < 0 || next.x >= imageInfo.width || next.y >= imageInfo.height)
     *          next = nextClockwisePoint(next,p);
     *
     *      return next;
     *  };
     *
     *
     *  CGPoint borderStart = CGPointZero, // first border point discovered
     *  borderPoint = CGPointZero, // center of current Moore neighborhood
     *  backtrack   = CGPointZero, // point from which borderPoint was entered
     *  current     = CGPointZero; // point under current consideration
     *
     *  NSUInteger c = 0, b = 0; // indices used while finding starting point
     *                                // find the first point from the edge that has a positive
     *
     alpha
     * value
     *  while (border.count == 0) {
     *      if (pixels[c+3] >
     alphaThreshold) {
     *          // add point to array and setup variables
     *          borderStart = imageLocation(c);
     *          [border addObject:NSValueWithCGPoint(borderStart)];
     *          borderPoint = borderStart;
     *          backtrack = imageLocation(b);
     *      } else {
     *          // check the next pixel over
     *          b = c;
     *          c += 4;
     *      }
     *  }
     *
     *  // check the next clockwise point according to Moore's neighborhood algorithm
     *  current = nextClockwisePoint(backtrack, borderPoint);
     *
     *  // continue until travel has come back to original border point
     *  while (!CGPointEqualToPoint(current, borderStart)) {
     *      NSUInteger idx = bitmapLocation(current);
     *      Pixel_8
     alpha = pixels[idx+3];
     *      if (alpha >
     alphaThreshold) {
     *          [border addObject:NSValueWithCGPoint(current)];
     *          backtrack = borderPoint;
     *          borderPoint = current;
     *      } else
     *          backtrack = current;
     *      current = nextClockwisePoint(backtrack,borderPoint);
     *  }
     */

#define DUMP_PIXEL_LOCATIONS
#ifdef DUMP_PIXEL_LOCATIONS
    NSOperationQueue *queue = [NSOperationQueue new];

    [queue addOperationWithBlock:
     ^{
         NSMutableString *string = [NSMutableString
                                    stringWithFormat:@"%@ detected border points in %zu x %zu context:\n",
                                    ClassTagSelectorString,
                                    info.width,
                                    info.height];
         for (NSValue *pv in border)
             [string appendFormat:@"%@  ", CGPointString(CGPointValue(pv))];
         MSLogDebug(@"%@", string);
     }];
#endif  /* ifdef DUMP_PIXEL_LOCATIONS */
    return border;
}

+ (UIBezierPath *)borderPathForImage:(UIImage *)image
{
    assert(NO);

    NSArray *allEdges = [self borderPointsForImage:image];
    // ImageInfo info = image.imageInfo;
    UIBezierPath *path = [UIBezierPath bezierPath];

    [path moveToPoint:[allEdges[0] CGPointValue]];

    for (int i = 1; i < [allEdges count]; i++)
        [path addLineToPoint:[allEdges[i] CGPointValue]];

    [path closePath];

    return path;
}

+ (UIImage *)borderPathImage:(UIImage *)image color:(UIColor *)color width:(NSUInteger)width
{
    assert(NO);

    UIBezierPath *path = [self borderPathForImage:image];

    path.lineWidth     = width;
    path.lineJoinStyle = kCGLineJoinRound;
    [path applyTransform:CGAffineTransformMakeScale(1/image.scale, 1/image.scale)];

    UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
    [color setStroke];
    [path stroke];
    [color setFill];
    [path fill];

    UIImage *pathImage = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return pathImage;
}

+ (UIImage *)embossImage:(UIImage *)image
{
//    assert(NO);

    ImageInfo imageInfo = image.imageInfo;
    NSData *bitmapData = vImageConformantDataForImage(image);
    UInt8 *pixels = (UInt8 *) [bitmapData bytes];
    vImage_Buffer src = {(void *) pixels, imageInfo.height, imageInfo.width, imageInfo.bytesPerRow};
    void *outData = malloc([bitmapData length]);
    vImage_Buffer dest = {outData, imageInfo.height, imageInfo.width, imageInfo.bytesPerRow};
    short kernel[9] = {-2, -2, 0, -2, 6, 0, 0, 0, 0}; // 1
    int kernelHeight = 3;
    int kernelWidth = 3;
    int divisor = 1;
    unsigned char bgColor[4] = {0, 0, 0, 0};
    vImage_Error err;

    err = vImageConvolve_ARGB8888(&src,
                                  &dest,
                                  NULL,
                                  0,
                                  0,
                                  kernel,
                                  kernelHeight,
                                  kernelWidth,
                                  divisor,
                                  bgColor,
                                  kvImageBackgroundColorFill);

    if (err != kvImageNoError) {
        MSLogError(@"%@ error with image convolusion:%li", ClassTagSelectorString, err);
        free(outData);

        return nil;
    }

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL,
                                                                  dest.data,
                                                                  [bitmapData length],
                                                                  NULL);
    CGImageRef imageRef = CGImageCreate(imageInfo.width,
                                        imageInfo.height,
                                        imageInfo.bitsPerComponent,
                                        imageInfo.bitsPerPixel,
                                        imageInfo.bytesPerRow,
                                        colorspace,
                                        (CGBitmapInfo)kCGImageAlphaPremultipliedFirst,
                                        dataProvider,
                                        NULL,
                                        false,
                                        imageInfo.renderingIntent);

    UIImage *embossedImage = [UIImage imageWithCGImage:imageRef
                                                 scale:image.scale
                                           orientation:UIImageOrientationUp];

    CGDataProviderRelease(dataProvider);
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorspace);

    return embossedImage;
}

+ (UIImage *)blurImage:(UIImage *)image
{
    assert(NO);

    ImageInfo imageInfo = image.imageInfo;
    NSData *bitmapData = vImageConformantDataForImage(image);
    UInt8 *pixels = (UInt8 *) [bitmapData bytes];

    // vImage_Buffer src = {
    // (void *)pixels,
    // imageInfo.height,
    // imageInfo.width,
    // imageInfo.bytesPerRow
    // };
    void *outData = malloc([bitmapData length]);
    // vImage_Buffer dest = {
    // outData,
    // imageInfo.height,
    // imageInfo.width,
    // imageInfo.bytesPerRow
    // };

    // short kernel[9] = {-2, -2, 0, -2, 6, 0, 0, 0, 0}; // 1
    // int kernelHeight = 3;
    // int kernelWidth = 3;
    // int divisor = 1;
    // unsigned char bgColor[4] = { 0, 0, 0, 0 };
    vImage_Error err;

    err = gaussianBlur(pixels, outData, imageInfo.height, imageInfo.width, imageInfo.bytesPerRow);

    // err = vImageConvolve_ARGB8888(&src,
    // &dest,
    // NULL,
    // 0,
    // 0,
    // kGaussianBlurKernel,
    // kernelHeight,
    // kernelWidth,
    // divisor,
    // bgColor,
    // kvImageBackgroundColorFill
    // );

    if (err != kvImageNoError) {
        MSLogError(@"%@ error with image convolusion:%li", ClassTagSelectorString, err);
        free(outData);

        return nil;
    }

    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL,
                                                                  outData,
                                                                  [bitmapData length],
                                                                  NULL);
    CGImageRef imageRef = CGImageCreate(imageInfo.width,
                                        imageInfo.height,
                                        imageInfo.bitsPerComponent,
                                        imageInfo.bitsPerPixel,
                                        imageInfo.bytesPerRow,
                                        colorspace,
                                        (CGBitmapInfo)kCGImageAlphaPremultipliedFirst,
                                        dataProvider,
                                        NULL,
                                        false,
                                        imageInfo.renderingIntent);

    UIImage *blurredImage = [UIImage imageWithCGImage:imageRef
                                                scale:image.scale
                                          orientation:UIImageOrientationUp];

    CGDataProviderRelease(dataProvider);
    CGImageRelease(imageRef);
    CGColorSpaceRelease(colorspace);

    return blurredImage;
}

+ (void)drawLEDButtons
{
    //// General Declarations
    CGColorSpaceRef   colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef      context    = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor  *bgColorTop = [UIColor colorWithRed:0.184 green:0.211 blue:0.226 alpha:1];
    CGFloat   bgColorTopRGBA[4];
    [bgColorTop getRed:&bgColorTopRGBA[0]
                 green:&bgColorTopRGBA[1]
                  blue:&bgColorTopRGBA[2]
                 alpha:&bgColorTopRGBA[3]];

    UIColor  *bgColorBottom = [UIColor colorWithRed:(bgColorTopRGBA[0] * 0.5)
                                              green:(bgColorTopRGBA[1] * 0.5)
                                               blue:(bgColorTopRGBA[2] * 0.5)
                                              alpha:(bgColorTopRGBA[3] * 0.5 + 0.5)];

    UIColor  *trackColor = [UIColor colorWithRed:(bgColorTopRGBA[0] * 0.597)
                                           green:(bgColorTopRGBA[1] * 0.597)
                                            blue:(bgColorTopRGBA[2] * 0.597)
                                           alpha:(bgColorTopRGBA[3] * 0.597 + 0.403)];

    UIColor  *innerShineColor = [UIColor colorWithRed:0.84
                                                green:0.84
                                                 blue:0.84
                                                alpha:0.17];

    UIColor  *trackInnerShadowColor = [UIColor colorWithRed:0.028
                                                      green:0.028
                                                       blue:0.028
                                                      alpha:1];

    UIColor  *buttColorTop = [UIColor colorWithRed:0.151
                                             green:0.178
                                              blue:0.199
                                             alpha:1];

    CGFloat   buttColorTopRGBA[4];
    [buttColorTop getRed:&buttColorTopRGBA[0]
                   green:&buttColorTopRGBA[1]
                    blue:&buttColorTopRGBA[2]
                   alpha:&buttColorTopRGBA[3]];

    UIColor  *shineTop = [UIColor colorWithRed:(buttColorTopRGBA[0] * 0.916 + 0.084)
                                         green:(buttColorTopRGBA[1] * 0.916 + 0.084)
                                          blue:(buttColorTopRGBA[2] * 0.916 + 0.084)
                                         alpha:(buttColorTopRGBA[3] * 0.916 + 0.084)];

    CGFloat   shineTopHSBA[4];
    [shineTop getHue:&shineTopHSBA[0]
          saturation:&shineTopHSBA[1]
          brightness:&shineTopHSBA[2]
               alpha:&shineTopHSBA[3]];

    UIColor  *shineBottom = [UIColor colorWithHue:shineTopHSBA[0]
                                       saturation:shineTopHSBA[1]
                                       brightness:0.1
                                            alpha:shineTopHSBA[3]];

    UIColor  *buttColorBottom = [UIColor colorWithRed:(buttColorTopRGBA[0] * 0.4)
                                                green:(buttColorTopRGBA[1] * 0.4)
                                                 blue:(buttColorTopRGBA[2] * 0.4)
                                                alpha:(buttColorTopRGBA[3] * 0.4 + 0.6)];

    UIColor  *lightBase = [UIColor colorWithRed:0.304
                                          green:0.749
                                           blue:1
                                          alpha:1];
    CGFloat   lightBaseRGBA[4];
    [lightBase getRed:&lightBaseRGBA[0]
                green:&lightBaseRGBA[1]
                 blue:&lightBaseRGBA[2]
                alpha:&lightBaseRGBA[3]];

    CGFloat   lightBaseHSBA[4];
    [lightBase getHue:&lightBaseHSBA[0]
           saturation:&lightBaseHSBA[1]
           brightness:&lightBaseHSBA[2]
                alpha:&lightBaseHSBA[3]];

    UIColor  *shineCenter = [UIColor colorWithRed:(lightBaseRGBA[0] * 0.7 + 0.3)
                                            green:(lightBaseRGBA[1] * 0.7 + 0.3)
                                             blue:(lightBaseRGBA[2] * 0.7 + 0.3)
                                            alpha:(lightBaseRGBA[3] * 0.7 + 0.3)];

    UIColor  *lightUp = [UIColor colorWithRed:(lightBaseRGBA[0] * 0.4 + 0.6)
                                        green:(lightBaseRGBA[1] * 0.4 + 0.6)
                                         blue:(lightBaseRGBA[2] * 0.4 + 0.6)
                                        alpha:(lightBaseRGBA[3] * 0.4 + 0.6)];

    CGFloat   lightUpHSBA[4];
    [lightUp getHue:&lightUpHSBA[0]
         saturation:&lightUpHSBA[1]
         brightness:&lightUpHSBA[2]
              alpha:&lightUpHSBA[3]];

    UIColor  *symbolColor = [UIColor colorWithHue:lightUpHSBA[0]
                                       saturation:lightUpHSBA[1]
                                       brightness:0.6
                                            alpha:lightUpHSBA[3]];

    UIColor  *lightOffUp = [UIColor colorWithHue:lightBaseHSBA[0]
                                      saturation:lightBaseHSBA[1]
                                      brightness:0.264
                                           alpha:lightBaseHSBA[3]];

    UIColor  *lightOffDown = [UIColor colorWithRed:(lightBaseRGBA[0] * 0.2)
                                             green:(lightBaseRGBA[1] * 0.2)
                                              blue:(lightBaseRGBA[2] * 0.2)
                                             alpha:(lightBaseRGBA[3] * 0.2 + 0.8)];

    UIColor  *lightDown = [UIColor colorWithRed:(lightBaseRGBA[0] * 1)
                                          green:(lightBaseRGBA[1] * 1)
                                           blue:(lightBaseRGBA[2] * 1)
                                          alpha:(lightBaseRGBA[3] * 1 + 0)];

    UIColor  *ledStroke      = [lightDown colorWithAlphaComponent:1];
    UIColor  *lightGlowColor = [UIColor colorWithRed:(lightBaseRGBA[0] * 0.3 + 0.7)
                                               green:(lightBaseRGBA[1] * 0.3 + 0.7)
                                                blue:(lightBaseRGBA[2] * 0.3 + 0.7)
                                               alpha:(lightBaseRGBA[3] * 0.3 + 0.7)];

    UIColor  *shineColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0];

    //// Gradient Declarations
    NSArray        *bgGradColors      = @[(id)bgColorTop.CGColor, (id)bgColorBottom.CGColor];
    CGFloat         bgGradLocations[] = { 0, 1 };
    CGGradientRef   bgGrad = CGGradientCreateWithColors(colorSpace,
                                                        (__bridge CFArrayRef)bgGradColors,
                                                        bgGradLocations);

    NSArray        *shineGradColors      = @[(id)shineTop.CGColor, (id)shineBottom.CGColor];
    CGFloat         shineGradLocations[] = { 0, 1 };
    CGGradientRef   shineGradient = CGGradientCreateWithColors(colorSpace,
                                                               (__bridge CFArrayRef)shineGradColors,
                                                               shineGradLocations);
    NSArray        *buttonGradColors      = @[(id)buttColorTop.CGColor, (id)buttColorBottom.CGColor];
    CGFloat         buttonGradLocations[] = { 0, 1 };
    CGGradientRef   buttonGrad = CGGradientCreateWithColors(colorSpace,
                                                            (__bridge CFArrayRef)buttonGradColors,
                                                            buttonGradLocations);

    NSArray  *lightOFFGradColors = @[(id)lightOffUp.CGColor,
                                     (id)lightOffDown.CGColor];
    CGFloat         lightOFFGradLocations[] = { 0, 1 };
    CGGradientRef   lightOFFGrad = CGGradientCreateWithColors(colorSpace,
                                                              (__bridge CFArrayRef)lightOFFGradColors,
                                                              lightOFFGradLocations);
    NSArray  *lightONGradColors = @[(id)lightUp.CGColor,
                                    (id)lightDown.CGColor];
    CGFloat         lightONGradLocations[] = { 0, 1 };
    CGGradientRef   lightONGrad = CGGradientCreateWithColors(colorSpace,
                                                             (__bridge CFArrayRef)lightONGradColors,
                                                             lightONGradLocations);
    NSArray  *shineLightGradColors = @[(id)shineCenter.CGColor,
                                       (id)[UIColor colorWithRed:.257 green:.412 blue:.5 alpha:.5].CGColor,
                                       (id)shineColor.CGColor];

    CGFloat         shineLightGradLocations[] = { 0, 0.3, 0.76 };
    CGGradientRef   shineLightGrad = CGGradientCreateWithColors(colorSpace,
                                                                (__bridge CFArrayRef)shineLightGradColors,
                                                                shineLightGradLocations);

    //// Shadow Declarations
    UIColor  *innerShine             = innerShineColor;
    CGSize    innerShineOffset       = CGSizeMake(0.1, -0.1);
    CGFloat   innerShineBlurRadius   = 5;
    UIColor  *trackInner             = trackInnerShadowColor;
    CGSize    trackInnerOffset       = CGSizeMake(0.1, -0.1);
    CGFloat   trackInnerBlurRadius   = 5;
    UIColor  *shadow                 = [UIColor blackColor];
    CGSize    shadowOffset           = CGSizeMake(0.1, -0.1);
    CGFloat   shadowBlurRadius       = 2;
    UIColor  *symbolShadow           = lightBase;
    CGSize    symbolShadowOffset     = CGSizeMake(0.1, -0.1);
    CGFloat   symbolShadowBlurRadius = 3;
    UIColor  *lightGlow              = lightGlowColor;
    CGSize    lightGlowOffset        = CGSizeMake(0.1, -0.1);
    CGFloat   lightGlowBlurRadius    = 9;

    //// Frames
    CGRect   frameTrack   = CGRectMake(35, 74, 234, 75);
    CGRect   frameB1 = CGRectMake(47, 91, 69, 46);
    CGRect   frameB2 = CGRectMake(117, 93, 67, 42);
    CGRect   frameB3 = CGRectMake(186, 93, 67, 42);

    //// Subframes
    CGRect   symFrameChat =
    CGRectMake(CGRectGetMinX(frameB3) + floor((CGRectGetWidth(frameB3) - 63) * 0.50000 + 0.5),
               CGRectGetMinY(frameB3) + floor((CGRectGetHeight(frameB3) - 38) * 0.50000 + 0.5),
               63,
               38);
    CGRect   chat =
    CGRectMake(CGRectGetMinX(symFrameChat)
               + floor((CGRectGetWidth(symFrameChat) - 20) * 0.51163 + 0.5),
               CGRectGetMinY(symFrameChat)
               + floor((CGRectGetHeight(symFrameChat) - 20) * 0.44444 + 0.5),
               20,
               20);

    CGRect   symFrameCamera =
    CGRectMake(CGRectGetMinX(frameB2) + floor((CGRectGetWidth(frameB2) - 63) * 0.50000 + 0.5),
               CGRectGetMinY(frameB2) + floor((CGRectGetHeight(frameB2) - 38) * 0.50000 + 0.5),
               63,
               38);

    CGRect   camera =
    CGRectMake(CGRectGetMinX(symFrameCamera)
               + floor((CGRectGetWidth(symFrameCamera) - 20) * 0.51163 + 0.5),
               CGRectGetMinY(symFrameCamera)
               + floor((CGRectGetHeight(symFrameCamera) - 20) * 0.44444 + 0.5),
               20,
               20);

    CGRect   group = CGRectMake(CGRectGetMinX(frameB1) + 1,
                                CGRectGetMinY(frameB1) + 2,
                                CGRectGetWidth(frameB1) - 2,
                                CGRectGetHeight(frameB1) - 5);

    CGRect   symFrameAperture =
    CGRectMake(CGRectGetMinX(frameB1) + floor((CGRectGetWidth(frameB1) - 63) * 0.50000 + 0.5),
               CGRectGetMinY(frameB1) + floor((CGRectGetHeight(frameB1) - 38) * 0.50000 + 0.5),
               63,
               38);
    CGRect   apertureSymbol =
    CGRectMake(CGRectGetMinX(symFrameAperture)
               + floor((CGRectGetWidth(symFrameAperture) - 20) * 0.51163 + 0.5),
               CGRectGetMinY(symFrameAperture)
               + floor((CGRectGetHeight(symFrameAperture) - 20) * 0.44444 + 0.5),
               20,
               20);

    //// background Drawing
    UIBezierPath  *backgroundPath = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 300, 225)];
    UIGraphicsPushContext(context);
    [backgroundPath addClip];
    CGContextDrawLinearGradient(context, bgGrad, CGPointMake(150, 0), CGPointMake(150, 225), 0);
    UIGraphicsPopContext();

    //// trackandback
    {
        //// track Drawing
        UIBezierPath  *trackPath = [UIBezierPath
                                    bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(frameTrack) + 9,
                                                                         CGRectGetMinY(frameTrack) + 15,
                                                                         213,
                                                                         50)
                                    cornerRadius:4];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, innerShineOffset, innerShineBlurRadius, innerShine.CGColor);
        [trackColor setFill];
        [trackPath fill];

        ////// track Inner Shadow
        CGRect   trackBorderRect = CGRectInset([trackPath bounds],
                                               -trackInnerBlurRadius,
                                               -trackInnerBlurRadius);
        trackBorderRect = CGRectOffset(trackBorderRect,
                                       -trackInnerOffset.width,
                                       -trackInnerOffset.height);
        trackBorderRect = CGRectInset(CGRectUnion(trackBorderRect, [trackPath bounds]), -1, -1);

        UIBezierPath  *trackNegativePath = [UIBezierPath bezierPathWithRect:trackBorderRect];
        [trackNegativePath appendPath:trackPath];
        trackNegativePath.usesEvenOddFillRule = YES;

        UIGraphicsPushContext(context);
        {
            CGFloat   xOffset = trackInnerOffset.width + round(trackBorderRect.size.width);
            CGFloat   yOffset = trackInnerOffset.height;
            CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset),
                                                            yOffset + copysign(0.1, yOffset)),
                                        trackInnerBlurRadius,
                                        trackInner.CGColor);

            [trackPath addClip];
            CGAffineTransform   transform =
            CGAffineTransformMakeTranslation(-round(trackBorderRect.size.width), 0);
            [trackNegativePath applyTransform:transform];
            [[UIColor grayColor] setFill];
            [trackNegativePath fill];
        }
        UIGraphicsPopContext();

        UIGraphicsPopContext();
    }

    //// button1
    {
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);

        //// buttonOuter1 Drawing
        CGRect         buttonOuter1Rect = CGRectMake(CGRectGetMinX(frameB1) + 1,
                                                     CGRectGetMinY(frameB1) + 2,
                                                     CGRectGetWidth(frameB1) - 2,
                                                     CGRectGetHeight(frameB1) - 4);
        UIBezierPath  *buttonOuter1Path = [UIBezierPath bezierPathWithRect:buttonOuter1Rect];
        UIGraphicsPushContext(context);
        [buttonOuter1Path addClip];
        CGContextDrawLinearGradient(context,
                                    shineGradient,
                                    CGPointMake(CGRectGetMidX(buttonOuter1Rect),
                                                CGRectGetMinY(buttonOuter1Rect)),
                                    CGPointMake(CGRectGetMidX(buttonOuter1Rect),
                                                CGRectGetMaxY(buttonOuter1Rect)),
                                    0);
        UIGraphicsPopContext();

        //// buttonInner1 Drawing
        CGRect         buttonInner1Rect = CGRectMake(CGRectGetMinX(frameB1) + 1.5,
                                                     CGRectGetMinY(frameB1) + 3,
                                                     CGRectGetWidth(frameB1) - 3,
                                                     CGRectGetHeight(frameB1) - 6);
        UIBezierPath  *buttonInner1Path = [UIBezierPath bezierPathWithRect:buttonInner1Rect];
        UIGraphicsPushContext(context);
        [buttonInner1Path addClip];
        CGContextDrawLinearGradient(context,
                                    buttonGrad,
                                    CGPointMake(CGRectGetMidX(buttonInner1Rect),
                                                CGRectGetMinY(buttonInner1Rect)),
                                    CGPointMake(CGRectGetMidX(buttonInner1Rect),
                                                CGRectGetMaxY(buttonInner1Rect)),
                                    0);
        UIGraphicsPopContext();

        //// Group
        {
            UIGraphicsPushContext(context);
            CGContextSetBlendMode(context, kCGBlendModeColorDodge);
            CGContextBeginTransparencyLayer(context, NULL);

            //// buttInnerShine1 Drawing
            CGRect buttInnerShine1Rect =
            CGRectMake(CGRectGetMinX(group) + floor(CGRectGetWidth(group) * 0.00746) + 0.5,
                       CGRectGetMinY(group) + floor(CGRectGetHeight(group) * 0.00000 + 0.5),
                       floor(CGRectGetWidth(group) * 0.99254) - floor(CGRectGetWidth(group) * 0.00746),
                       floor(CGRectGetHeight(group) * 1.00000 + 0.5) - floor(CGRectGetHeight(group) * 0.00000 + 0.5));
            UIBezierPath  *buttInnerShine1Path = [UIBezierPath bezierPathWithRect:buttInnerShine1Rect];
            UIGraphicsPushContext(context);
            [buttInnerShine1Path addClip];
            CGFloat   buttInnerShine1ResizeRatio = MIN(CGRectGetWidth(buttInnerShine1Rect)/66,
                                                       CGRectGetHeight(buttInnerShine1Rect)/41);
            CGContextDrawRadialGradient(context,
                                        shineLightGrad,
                                        CGPointMake(CGRectGetMidX(buttInnerShine1Rect) + 0 * buttInnerShine1ResizeRatio,
                                                    CGRectGetMidY(buttInnerShine1Rect) + -30.13 * buttInnerShine1ResizeRatio),
                                        7.18 * buttInnerShine1ResizeRatio,
                                        CGPointMake(CGRectGetMidX(buttInnerShine1Rect) + 0 * buttInnerShine1ResizeRatio,
                                                    CGRectGetMidY(buttInnerShine1Rect) + -20 * buttInnerShine1ResizeRatio),
                                        83.63 * buttInnerShine1ResizeRatio,
                                        kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
            UIGraphicsPopContext();

            CGContextEndTransparencyLayer(context);
            UIGraphicsPopContext();
        }

        //// aperture symbol
        {
            //// Aperture Drawing
            UIBezierPath  *aperturePath = [UIBezierPath bezierPath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.66162 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.43688 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.83947 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.13488 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.50000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.00000 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.75025 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.05181 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.63159 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.00000 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.40900 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.00916 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.46881 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.00000 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.43859 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.00372 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.66162 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.43688 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.62347 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.62500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.98228 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.62500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 1.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.50000 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.99269 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.58484 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 1.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.54347 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.88366 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.18297 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 1.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.37897 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.95531 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.26947 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.62347 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.62500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.51562 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.31250 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.34663 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.02650 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.03713 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.31250 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.20600 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.07209 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.09228 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.17644 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.51562 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.31250 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.48853 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.68750 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.65700 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.97241 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.96291 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.68750 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.79603 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.92603 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.90822 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.82238 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.48853 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.68750 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.37828 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.37500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.01769 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.37500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.50000 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.00725 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.41516 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.45653 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.11738 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.81838 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.00000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.62159 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.04516 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.73156 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.37828 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.37500 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            [aperturePath moveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.34119 * CGRectGetWidth(apertureSymbol),
                                                  CGRectGetMinY(apertureSymbol) + 0.56128 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.16169 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.86622 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.50000 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 1.00000 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.25084 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.94850 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.36903 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 1.00000 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addCurveToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.59503 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.99047 * CGRectGetHeight(apertureSymbol))
                            controlPoint1:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.53253 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 1.00000 * CGRectGetHeight(apertureSymbol))
                            controlPoint2:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.56422 * CGRectGetWidth(apertureSymbol),
                                                      CGRectGetMinY(apertureSymbol) + 0.99634 * CGRectGetHeight(apertureSymbol))];
            [aperturePath addLineToPoint:CGPointMake(CGRectGetMinX(apertureSymbol) + 0.34119 * CGRectGetWidth(apertureSymbol),
                                                     CGRectGetMinY(apertureSymbol) + 0.56128 * CGRectGetHeight(apertureSymbol))];
            [aperturePath closePath];
            UIGraphicsPushContext(context);
            CGContextSetShadowWithColor(context, symbolShadowOffset, symbolShadowBlurRadius, symbolShadow.CGColor);
            [lightBase setFill];
            [aperturePath fill];
            UIGraphicsPopContext();
        }

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// button2
    {
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        CGContextSetAlpha(context, 0.5);
        CGContextBeginTransparencyLayer(context, NULL);

        //// buttonOuter2 Drawing
        CGRect         buttonOuter2Rect = CGRectMake(CGRectGetMinX(frameB2), CGRectGetMinY(frameB2), 67, 42);
        UIBezierPath  *buttonOuter2Path = [UIBezierPath bezierPathWithRect:buttonOuter2Rect];
        UIGraphicsPushContext(context);
        [buttonOuter2Path addClip];
        CGContextDrawLinearGradient(context, shineGradient, CGPointMake(CGRectGetMidX(buttonOuter2Rect), CGRectGetMinY(buttonOuter2Rect)), CGPointMake(CGRectGetMidX(buttonOuter2Rect), CGRectGetMaxY(buttonOuter2Rect)), 0);
        UIGraphicsPopContext();

        //// buttonInner2 Drawing
        CGRect         buttonInner2Rect = CGRectMake(CGRectGetMinX(frameB2) + 0.5, CGRectGetMinY(frameB2) + 1, 66, 40);
        UIBezierPath  *buttonInner2Path = [UIBezierPath bezierPathWithRect:buttonInner2Rect];
        UIGraphicsPushContext(context);
        [buttonInner2Path addClip];
        CGContextDrawLinearGradient(context, buttonGrad, CGPointMake(CGRectGetMidX(buttonInner2Rect), CGRectGetMinY(buttonInner2Rect)), CGPointMake(CGRectGetMidX(buttonInner2Rect), CGRectGetMaxY(buttonInner2Rect)), 0);
        UIGraphicsPopContext();

        //// Camera
        {
            //// Oval Drawing
            UIBezierPath  *ovalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMinX(camera) + 10, CGRectGetMinY(camera) + CGRectGetHeight(camera) - 10, 5, 5)];
            [symbolColor setFill];
            [ovalPath fill];

            //// Bezier 7 Drawing
            UIBezierPath  *bezier7Path = [UIBezierPath bezierPath];
            [bezier7Path moveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.87500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 0.77222 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.04241 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.71288 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.00000 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.76378 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.01775 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.74047 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.00000 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 0.54125 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.00000 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.48175 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.04328 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.51334 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.00000 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.48981 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.01819 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 0.37513 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 0.12500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.05597 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.30597 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 0.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 1.00000 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 1.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 1.00000 * CGRectGetHeight(camera))];
            [bezier7Path addLineToPoint:CGPointMake(CGRectGetMinX(camera) + 1.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.87500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 1.00000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.30597 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.94409 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.25000 * CGRectGetHeight(camera))];
            [bezier7Path closePath];
            [bezier7Path moveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.18750 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.50000 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.12500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.43750 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.15297 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.50000 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.12500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.47203 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.18750 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.12500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.40297 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.15297 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.25000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.43750 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.22203 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.25000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.40297 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.18750 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.50000 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.25000 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.47203 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.22203 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.50000 * CGRectGetHeight(camera))];
            [bezier7Path closePath];
            [bezier7Path moveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.62500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.87500 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.37500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.62500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.48694 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.87500 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.37500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.76306 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.62500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.37500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.48694 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.48694 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.87500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.62500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.76306 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.37500 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.87500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.48694 * CGRectGetHeight(camera))];
            [bezier7Path addCurveToPoint:CGPointMake(CGRectGetMinX(camera) + 0.62500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.87500 * CGRectGetHeight(camera))
                           controlPoint1:CGPointMake(CGRectGetMinX(camera) + 0.87500 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.76306 * CGRectGetHeight(camera))
                           controlPoint2:CGPointMake(CGRectGetMinX(camera) + 0.76306 * CGRectGetWidth(camera), CGRectGetMinY(camera) + 0.87500 * CGRectGetHeight(camera))];
            [bezier7Path closePath];
            [symbolColor setFill];
            [bezier7Path fill];
        }

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// button3
    {
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);

        //// buttonOuter3 Drawing
        CGRect         buttonOuter3Rect = CGRectMake(CGRectGetMinX(frameB3), CGRectGetMinY(frameB3), 67, 42);
        UIBezierPath  *buttonOuter3Path = [UIBezierPath bezierPathWithRect:buttonOuter3Rect];
        UIGraphicsPushContext(context);
        [buttonOuter3Path addClip];
        CGContextDrawLinearGradient(context, shineGradient, CGPointMake(CGRectGetMidX(buttonOuter3Rect), CGRectGetMinY(buttonOuter3Rect)), CGPointMake(CGRectGetMidX(buttonOuter3Rect), CGRectGetMaxY(buttonOuter3Rect)), 0);
        UIGraphicsPopContext();

        //// buttonInner3 Drawing
        CGRect         buttonInner3Rect = CGRectMake(CGRectGetMinX(frameB3) + 0.5, CGRectGetMinY(frameB3) + 1, 66, 40);
        UIBezierPath  *buttonInner3Path = [UIBezierPath bezierPathWithRect:buttonInner3Rect];
        UIGraphicsPushContext(context);
        [buttonInner3Path addClip];
        CGContextDrawLinearGradient(context, buttonGrad, CGPointMake(CGRectGetMidX(buttonInner3Rect), CGRectGetMinY(buttonInner3Rect)), CGPointMake(CGRectGetMidX(buttonInner3Rect), CGRectGetMaxY(buttonInner3Rect)), 0);
        UIGraphicsPopContext();

        //// Chat
        {
            //// Bezier 8 Drawing
            UIBezierPath  *bezier8Path = [UIBezierPath bezierPath];
            [bezier8Path moveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.81178 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.38166 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.78419 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.50319 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.81094 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.42500 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.80128 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.46587 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.87500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.87428 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.51819 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.87500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.59156 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.87500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.65600 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.87500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))];
            [bezier8Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.42506 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.85009 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.54359 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.47069 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.78931 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.39478 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.82716 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.79078 * CGRectGetHeight(chat))];
            [bezier8Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.38622 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.56475 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.60028 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.37941 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.58081 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.56250 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.38256 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.56409 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.37891 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.56250 * CGRectGetHeight(chat))];
            [bezier8Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25634 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.56250 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.25231 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.58184 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.60253 * CGRectGetHeight(chat))];
            [bezier8Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.75000 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 1.00000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.88806 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.36194 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 1.00000 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.87500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.93091 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.55591 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.87500 * CGRectGetHeight(chat))];
            [bezier8Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.87500 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 1.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.87500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.87500 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 1.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.80469 * CGRectGetHeight(chat))];
            [bezier8Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.81178 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.38166 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 1.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.47209 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.91309 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.40125 * CGRectGetHeight(chat))];
            [bezier8Path closePath];
            [symbolColor setFill];
            [bezier8Path fill];

            //// Bezier 9 Drawing
            UIBezierPath  *bezier9Path = [UIBezierPath bezierPath];
            [bezier9Path moveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.12500 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.25000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.54662 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.12500 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.14125 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.57494 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.47503 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.41591 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.60522 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.45222 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.52931 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.41437 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.45653 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.25000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.28094 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.12500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.21266 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.12500 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.12500 * CGRectGetHeight(chat))];
            [bezier9Path closePath];
            [bezier9Path moveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.25000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.06641 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.25013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.50000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.00000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.42969 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.12500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.50000 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.37500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.50000 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.44409 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.50000 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.55603 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.37500 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.63806 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.62500 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.51306 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.25000 * CGRectGetHeight(chat))];
            [bezier9Path addCurveToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))
                           controlPoint1:CGPointMake(CGRectGetMinX(chat) + 0.75013 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.07747 * CGRectGetHeight(chat))
                           controlPoint2:CGPointMake(CGRectGetMinX(chat) + 0.62500 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))];
            [bezier9Path addLineToPoint:CGPointMake(CGRectGetMinX(chat) + 0.50000 * CGRectGetWidth(chat), CGRectGetMinY(chat) + 0.00000 * CGRectGetHeight(chat))];
            [bezier9Path closePath];
            [symbolColor setFill];
            [bezier9Path fill];
        }

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// LEDs
    {
        //// LED3OFF Drawing
        UIBezierPath  *lED3OFFPath = [UIBezierPath bezierPathWithRect:CGRectMake(204, 86, 31, 3)];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, innerShineOffset, innerShineBlurRadius, innerShine.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [lED3OFFPath addClip];
        CGContextDrawRadialGradient(context, lightOFFGrad, CGPointMake(219.5, 87.5), 0, CGPointMake(219.5, 87.5), 12.4, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        [lightOffDown setStroke];
        lED3OFFPath.lineWidth = 0.5;
        [lED3OFFPath stroke];

        //// LED2OFF Drawing
        UIBezierPath  *lED2OFFPath = [UIBezierPath bezierPathWithRect:CGRectMake(135, 85.5, 31, 3)];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, innerShineOffset, innerShineBlurRadius, innerShine.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [lED2OFFPath addClip];
        CGContextDrawRadialGradient(context, lightOFFGrad, CGPointMake(150.5, 87), 0.14, CGPointMake(150.5, 87), 12.4, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        [lightOffDown setStroke];
        lED2OFFPath.lineWidth = 0.5;
        [lED2OFFPath stroke];

        //// LED1ON Drawing
        UIBezierPath  *lED1ONPath = [UIBezierPath bezierPathWithRect:CGRectMake(66, 85.5, 31, 3)];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, lightGlowOffset, lightGlowBlurRadius, lightGlow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [lED1ONPath addClip];
        CGContextDrawRadialGradient(context, lightONGrad, CGPointMake(81.5, 87), 0.14, CGPointMake(81.5, 87), 12.4, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        [ledStroke setStroke];
        lED1ONPath.lineWidth = 0.5;
        [lED1ONPath stroke];
    }

    //// Cleanup
    CGGradientRelease(bgGrad);
    CGGradientRelease(shineGradient);
    CGGradientRelease(buttonGrad);
    CGGradientRelease(lightOFFGrad);
    CGGradientRelease(lightONGrad);
    CGGradientRelease(shineLightGrad);
    CGColorSpaceRelease(colorSpace);
}


+ (void)drawPowerButton {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *symbolShadow = [UIColor colorWithRed:0.496
                                            green:0.496
                                             blue:0.496
                                            alpha:1];
    UIColor *symbolONColor = [UIColor colorWithRed:0.798
                                             green:0.949
                                              blue:1
                                             alpha:1];
    UIColor *backGroundColorTop = [UIColor colorWithRed:0.769
                                                  green:0.813
                                                   blue:0.827
                                                  alpha:1];
    CGFloat backGroundColorTopHSBA[4];
    [backGroundColorTop getHue:&backGroundColorTopHSBA[0]
                    saturation:&backGroundColorTopHSBA[1]
                    brightness:&backGroundColorTopHSBA[2]
                         alpha:&backGroundColorTopHSBA[3]];

    UIColor *backGroundColorBottom = [UIColor colorWithHue:backGroundColorTopHSBA[0]
                                                saturation:0.154
                                                brightness:backGroundColorTopHSBA[2]
                                                     alpha:backGroundColorTopHSBA[3]];
    UIColor *smallShadowColor = [UIColor colorWithRed:0.296
                                                green:0.296
                                                 blue:0.296
                                                alpha:1];
    UIColor *testColor = [UIColor colorWithRed:1
                                         green:1
                                          blue:1
                                         alpha:1];
    UIColor *baseColor2 = [UIColor colorWithRed:0.26
                                          green:0.451
                                           blue:0.745
                                          alpha:1];
    CGFloat baseColor2RGBA[4];
    [baseColor2 getRed:&baseColor2RGBA[0]
                 green:&baseColor2RGBA[1]
                  blue:&baseColor2RGBA[2]
                 alpha:&baseColor2RGBA[3]];

    CGFloat baseColor2HSBA[4];
    [baseColor2 getHue:&baseColor2HSBA[0]
            saturation:&baseColor2HSBA[1]
            brightness:&baseColor2HSBA[2]
                 alpha:&baseColor2HSBA[3]];

    UIColor *bottomColor2 = [UIColor colorWithHue:baseColor2HSBA[0]
                                       saturation:baseColor2HSBA[1]
                                       brightness:0.8
                                            alpha:baseColor2HSBA[3]];
    CGFloat bottomColor2RGBA[4];
    [bottomColor2 getRed:&bottomColor2RGBA[0]
                   green:&bottomColor2RGBA[1]
                    blue:&bottomColor2RGBA[2]
                   alpha:&bottomColor2RGBA[3]];

    UIColor *bottomOutColor2 = [UIColor colorWithRed:(bottomColor2RGBA[0] * 0.9)
                                               green:(bottomColor2RGBA[1] * 0.9)
                                                blue:(bottomColor2RGBA[2] * 0.9)
                                               alpha:(bottomColor2RGBA
                                                      [3] * 0.9 + 0.1)];
    UIColor *topColor2 = [UIColor colorWithRed:(baseColor2RGBA[0] * 0.2 + 0.8)
                                         green:(baseColor2RGBA[1] * 0.2 + 0.8)
                                          blue:(baseColor2RGBA[2] * 0.2 + 0.8)
                                         alpha:(baseColor2RGBA[3] * 0.2 + 0.8)];
    CGFloat topColor2RGBA[4];
    [topColor2 getRed:&topColor2RGBA[0]
                green:&topColor2RGBA[1]
                 blue:&topColor2RGBA[2]
                alpha:&topColor2RGBA[3]];

    UIColor *topOutColor2 = [UIColor colorWithRed:(topColor2RGBA[0] * 0 + 1)
                                            green:(topColor2RGBA[1] * 0 + 1)
                                             blue:(topColor2RGBA[2] * 0 + 1)
                                            alpha:(topColor2RGBA
                                                   [3] * 0 + 1)];
    UIColor *symbolOffShadowColor = [UIColor colorWithRed:0
                                                    green:0
                                                     blue:0
                                                    alpha:1];

    //// Gradient Declarations
    NSArray *backgroundGradientColors = @[(id)backGroundColorTop.CGColor, (id)backGroundColorBottom.CGColor];
    CGFloat backgroundGradientLocations[] = {0, 1};
    CGGradientRef backgroundGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)backgroundGradientColors, backgroundGradientLocations);
    NSArray *buttonOutGradient2Colors = @[(id)bottomOutColor2.CGColor, (id)[UIColor colorWithRed:0.625
                                                                                           green:0.718
                                                                                            blue:0.86
                                                                                           alpha:1].CGColor, (id)topOutColor2.CGColor];
    CGFloat buttonOutGradient2Locations[] = {0, 0.69, 1};
    CGGradientRef buttonOutGradient2 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)buttonOutGradient2Colors, buttonOutGradient2Locations);
    NSArray *buttonGradient2Colors = @[(id)bottomColor2.CGColor, (id)topColor2.CGColor];
    CGFloat buttonGradient2Locations[] = {0, 1};
    CGGradientRef buttonGradient2 = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)buttonGradient2Colors, buttonGradient2Locations);

    //// Shadow Declarations
    UIColor *shadow = symbolShadow;
    CGSize shadowOffset = CGSizeMake(0.1, 210.1);
    CGFloat shadowBlurRadius = 15;
    UIColor *glow = symbolONColor;
    CGSize glowOffset = CGSizeMake(0.1, -0.1);
    CGFloat glowBlurRadius = 7.5;
    UIColor *smallShadow = smallShadowColor;
    CGSize smallShadowOffset = CGSizeMake(0.1, 3.1);
    CGFloat smallShadowBlurRadius = 5.5;
    UIColor *symbolOffShadow = symbolOffShadowColor;
    CGSize symbolOffShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat symbolOffShadowBlurRadius = 7;

    //// Frames
    CGRect frame = CGRectMake(0, 0, 120, 130);

    //// Subframes
    CGRect symbol = CGRectMake(CGRectGetMinX(frame) + 39, CGRectGetMinY(frame) + 35, CGRectGetWidth(frame) - 77, CGRectGetHeight(frame) - 85);

    //// BackgroundGroup
    {
        UIGraphicsPushContext(context);
        CGContextSetAlpha(context, 0.38);
        CGContextBeginTransparencyLayer(context, NULL);

        //// background Drawing
        UIBezierPath *backgroundPath = [UIBezierPath bezierPathWithRect:CGRectMake(-60, -56, 250, 240)];
        UIGraphicsPushContext(context);
        [backgroundPath addClip];
        CGContextDrawLinearGradient(context, backgroundGradient, CGPointMake(65, -56), CGPointMake(65, 184), 0);
        UIGraphicsPopContext();

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// GroupShadow
    {
        UIGraphicsPushContext(context);
        CGContextSetAlpha(context, 0.75);
        CGContextSetBlendMode(context, kCGBlendModeMultiply);
        CGContextBeginTransparencyLayer(context, NULL);

        //// LongShadow Drawing
        UIBezierPath *longShadowPath = [UIBezierPath bezierPath];
        [longShadowPath moveToPoint:CGPointMake(58.79, -91.94)];
        [longShadowPath addCurveToPoint:CGPointMake(94.83, -171.47)
                          controlPoint1:CGPointMake(105.69, -91.51)
                          controlPoint2:CGPointMake(108.82, -151.54)];
        [longShadowPath addCurveToPoint:CGPointMake(58.79, -191.24)
                          controlPoint1:CGPointMake(91.21, -176.63)
                          controlPoint2:CGPointMake(83.49, -191.41)];
        [longShadowPath addCurveToPoint:CGPointMake(23.82, -171.47)
                          controlPoint1:CGPointMake(34.73, -191.08)
                          controlPoint2:CGPointMake(26.78, -176.84)];
        [longShadowPath addCurveToPoint:CGPointMake(58.79, -91.94)
                          controlPoint1:CGPointMake(11.99, -149.99)
                          controlPoint2:CGPointMake(15.59, -92.33)];
        [longShadowPath closePath];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, shadowOffset, shadowBlurRadius, shadow.CGColor);
        [baseColor2 setFill];
        [longShadowPath fill];
        UIGraphicsPopContext();

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// outerRing Drawing
    CGRect outerRingRect = CGRectMake(CGRectGetMinX(frame) + 15.5, CGRectGetMinY(frame) + 13.5, CGRectGetWidth(frame) - 31, CGRectGetHeight(frame) - 41);
    UIBezierPath *outerRingPath = [UIBezierPath bezierPathWithOvalInRect:outerRingRect];
    UIGraphicsPushContext(context);
    CGContextSetShadowWithColor(context, smallShadowOffset, smallShadowBlurRadius, smallShadow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [outerRingPath addClip];
    CGContextDrawLinearGradient(context, buttonOutGradient2, CGPointMake(CGRectGetMidX(outerRingRect), CGRectGetMaxY(outerRingRect)), CGPointMake(CGRectGetMidX(outerRingRect), CGRectGetMinY(outerRingRect)), 0);
    CGContextEndTransparencyLayer(context);
    UIGraphicsPopContext();

    //// innerRing Drawing
    CGRect innerRingRect = CGRectMake(CGRectGetMinX(frame) + 18.5, CGRectGetMinY(frame) + 16.5, CGRectGetWidth(frame) - 37, CGRectGetHeight(frame) - 47);
    UIBezierPath *innerRingPath = [UIBezierPath bezierPathWithOvalInRect:innerRingRect];
    UIGraphicsPushContext(context);
    [innerRingPath addClip];
    CGContextDrawLinearGradient(context, buttonGradient2, CGPointMake(CGRectGetMidX(innerRingRect), CGRectGetMaxY(innerRingRect)), CGPointMake(CGRectGetMidX(innerRingRect), CGRectGetMinY(innerRingRect)), 0);
    UIGraphicsPopContext();

    //// Symbol
    {
        //// symbolOFF Drawing
        UIBezierPath *symbolOFFPath = [UIBezierPath bezierPath];
        [symbolOFFPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50194 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04446 * CGRectGetHeight(symbol))];
        [symbolOFFPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.49855 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04445 * CGRectGetHeight(symbol))];
        [symbolOFFPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50194 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04446 * CGRectGetHeight(symbol))];
        [symbolOFFPath closePath];
        [symbolOFFPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.86006 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 1.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.37097 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 1.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.67348 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.14645 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.86006 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.65829 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 1.04665 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.34171 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 1.04665 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.14645 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + -0.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.67348 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + -0.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.37097 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.25581 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18889 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.17353 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.16157 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.22375 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.16086 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.26156 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.29438 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.28788 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.21692 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.28490 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.27238 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.26156 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.75007 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.12987 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.42021 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.12987 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.62423 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.75007 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.39325 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.87590 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.60675 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.87590 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.29438 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.87013 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.62423 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.87013 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.42021 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.70569 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.26272 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.70967 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.21188 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.76722 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.15688 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.83173 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.15986 * CGRectGetHeight(symbol))];
        [symbolOFFPath closePath];
        [symbolOFFPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50000 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.56518 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.45505 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.54495 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.56518 * CGRectGetHeight(symbol))];
        [symbolOFFPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.07778 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50000 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.03482 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.54495 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))];
        [symbolOFFPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.07778 * CGRectGetHeight(symbol))
                         controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.45505 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))
                         controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.03482 * CGRectGetHeight(symbol))];
        [symbolOFFPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))];
        [symbolOFFPath closePath];
        UIGraphicsPushContext(context);
        [symbolOFFPath addClip];
        CGRect symbolOFFBounds = CGPathGetPathBoundingBox(symbolOFFPath.CGPath);
        CGContextDrawLinearGradient(context, buttonGradient2, CGPointMake(CGRectGetMidX(symbolOFFBounds) + 0.13 * CGRectGetWidth(symbolOFFBounds)/43, CGRectGetMidY(symbolOFFBounds) + 41.12 * CGRectGetHeight(symbolOFFBounds)/45), CGPointMake(CGRectGetMidX(symbolOFFBounds) + 1.05 * CGRectGetWidth(symbolOFFBounds)/43, CGRectGetMidY(symbolOFFBounds) + -40.14 * CGRectGetHeight(symbolOFFBounds)/45), kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
        UIGraphicsPopContext();

        ////// symbolOFF Inner Shadow
        CGRect symbolOFFBorderRect = CGRectInset([symbolOFFPath bounds], -symbolOffShadowBlurRadius, -symbolOffShadowBlurRadius);
        symbolOFFBorderRect = CGRectOffset(symbolOFFBorderRect, -symbolOffShadowOffset.width, -symbolOffShadowOffset.height);
        symbolOFFBorderRect = CGRectInset(CGRectUnion(symbolOFFBorderRect, [symbolOFFPath bounds]), -1, -1);

        UIBezierPath *symbolOFFNegativePath = [UIBezierPath bezierPathWithRect:symbolOFFBorderRect];
        [symbolOFFNegativePath appendPath:symbolOFFPath];
        symbolOFFNegativePath.usesEvenOddFillRule = YES;

        UIGraphicsPushContext(context);
        {
            CGFloat xOffset = symbolOffShadowOffset.width + round(symbolOFFBorderRect.size.width);
            CGFloat yOffset = symbolOffShadowOffset.height;
            CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), symbolOffShadowBlurRadius, symbolOffShadow.CGColor);

            [symbolOFFPath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(symbolOFFBorderRect.size.width), 0);
            [symbolOFFNegativePath applyTransform:transform];
            [[UIColor grayColor] setFill];
            [symbolOFFNegativePath fill];
        }
        UIGraphicsPopContext();

        //// symbolON Drawing
        UIBezierPath *symbolONPath = [UIBezierPath bezierPath];
        [symbolONPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50194 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04446 * CGRectGetHeight(symbol))];
        [symbolONPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.49855 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04445 * CGRectGetHeight(symbol))];
        [symbolONPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50194 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.04446 * CGRectGetHeight(symbol))];
        [symbolONPath closePath];
        [symbolONPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.86006 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 1.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.37097 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 1.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.67348 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.14645 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.86006 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.65829 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 1.04665 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.34171 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 1.04665 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.14645 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + -0.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.67348 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + -0.04882 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.37097 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.25581 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18889 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.17353 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.16157 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.22375 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.16086 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.26156 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.29438 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.28788 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.21692 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.28490 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.27238 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.26156 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.75007 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.12987 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.42021 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.12987 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.62423 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.75007 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.39325 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.87590 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.60675 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.87590 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.29438 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.87013 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.62423 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.87013 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.42021 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.73844 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.70569 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.26272 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.70967 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.21188 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.85355 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.18438 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.76722 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.15688 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.83173 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.15986 * CGRectGetHeight(symbol))];
        [symbolONPath closePath];
        [symbolONPath moveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50000 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.56518 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.45505 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.54495 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.60000 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.56518 * CGRectGetHeight(symbol))];
        [symbolONPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.07778 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.50000 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.58140 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.03482 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.54495 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))];
        [symbolONPath addCurveToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.07778 * CGRectGetHeight(symbol))
                        controlPoint1:CGPointMake(CGRectGetMinX(symbol) + 0.45505 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.00000 * CGRectGetHeight(symbol))
                        controlPoint2:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.03482 * CGRectGetHeight(symbol))];
        [symbolONPath addLineToPoint:CGPointMake(CGRectGetMinX(symbol) + 0.41860 * CGRectGetWidth(symbol), CGRectGetMinY(symbol) + 0.52222 * CGRectGetHeight(symbol))];
        [symbolONPath closePath];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, glowOffset, glowBlurRadius, glow.CGColor);
        [testColor setFill];
        [symbolONPath fill];
        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(backgroundGradient);
    CGGradientRelease(buttonOutGradient2);
    CGGradientRelease(buttonGradient2);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawRoundedRectButtonBaseInContext:(CGContextRef)context
                               buttonColor:(UIColor *)buttonColor
                               shadowColor:(UIColor *)shadowColor
                                    opaque:(BOOL)opaque
                                     frame:(CGRect)frame {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    //// Color Declarations
    if (!shadowColor)
        shadowColor = [UIColor colorWithRed:0
                                      green:0
                                       blue:0
                                      alpha:0.8];

    else if (shadowColor.colorSpaceModel != kCGColorSpaceModelRGB)
        shadowColor = [shadowColor rgbColor];

    if (!buttonColor)
        buttonColor = [UIColor colorWithRed:0.18
                                      green:0.631
                                       blue:0
                                      alpha:1];

    else if (buttonColor.colorSpaceModel != kCGColorSpaceModelRGB)
        buttonColor = [buttonColor rgbColor];

    CGFloat buttonColorRGBA[4];

    [buttonColor getRed:&buttonColorRGBA[0]
                  green:&buttonColorRGBA[1]
                   blue:&buttonColorRGBA[2]
                  alpha:&buttonColorRGBA[3]];

    UIColor *baseGradientBottomColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.6)
                                                       green:(buttonColorRGBA[1] * 0.6)
                                                        blue:(buttonColorRGBA[2] * 0.6)
                                                       alpha:(buttonColorRGBA[3] * 0.6 + 0.4)];

    //// Gradient Declarations
    NSArray *baseGradientColors = @[(id)buttonColor.CGColor, (id)baseGradientBottomColor.CGColor];

    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);

    //// Shadow Declarations
    UIColor *buttonShadow = shadowColor;
    CGSize buttonShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat buttonShadowBlurRadius = 2;

    //// Button
    {
        UIGraphicsPushContext(context);

        if (!opaque) CGContextSetAlpha(context, 0.75);

        CGContextBeginTransparencyLayer(context, NULL);

        //// ButtonRectangle Drawing
        CGRect rect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, CGRectGetHeight(frame) - 4);

        UIBezierPath *buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:7];
        UIGraphicsPushContext(context);

        CGContextSetShadowWithColor(context, buttonShadowOffset, buttonShadowBlurRadius, buttonShadow.CGColor);

        CGContextBeginTransparencyLayer(context, NULL);

        [buttonRectanglePath addClip];

        CGContextDrawLinearGradient(context, baseGradient, CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)), CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), 0);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(baseGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawRoundedRectButtonOverlayInContext:(CGContextRef)context
                                   shineColor:(UIColor *)shineColor
                                        frame:(CGRect)frame {
    //// General Declarations
    CGContextClearRect(context, frame);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    if (!shineColor) shineColor = [UIColor colorWithRed:0.948
                                                  green:0.948
                                                   blue:0.948
                                                  alpha:0.82];
    UIColor *topShine = [shineColor colorWithAlphaComponent:0.5];
    UIColor *bottomShine = [shineColor colorWithAlphaComponent:0.1];

    //// Gradient Declarations
    NSArray *shineGradientColors = @[(id)shineColor.CGColor, (id)[UIColor colorWithRed:0.948
                                                                                 green:0.948
                                                                                  blue:0.948
                                                                                 alpha:0.66].CGColor, (id)topShine.CGColor, (id)[UIColor colorWithRed:0.948
                                                                                                                                                green:0.948
                                                                                                                                                 blue:0.948
                                                                                                                                                alpha:0.3].CGColor, (id)bottomShine.CGColor];

    CGFloat shineGradientLocations[] = {0, 0.05, 0.09, 0.66, 1};

    CGGradientRef shineGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)shineGradientColors, shineGradientLocations);

    //// Button
    {
        //// Rounded Rectangle Drawing
        CGRect rect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, floor((CGRectGetHeight(frame) - 1) * 0.48649 + 0.5));

        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:7];

        UIGraphicsPushContext(context);

        [roundedRectanglePath addClip];

        CGContextDrawLinearGradient(context, shineGradient, CGPointMake(CGRectGetMidX(rect), CGRectGetMinY(rect)), CGPointMake(CGRectGetMidX(rect), CGRectGetMaxY(rect)), 0);

        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(shineGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawRoundedRectButton {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *iconShadow = [UIColor colorWithRed:0
                                          green:0
                                           blue:0
                                          alpha:0.8];
    UIColor *buttonColor = [UIColor colorWithRed:0.18
                                           green:0.631
                                            blue:0
                                           alpha:1];
    CGFloat buttonColorRGBA[4];
    [buttonColor getRed:&buttonColorRGBA[0]
                  green:&buttonColorRGBA[1]
                   blue:&buttonColorRGBA[2]
                  alpha:&buttonColorRGBA[3]];

    UIColor *baseGradientBottomColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.6)
                                                       green:(buttonColorRGBA[1] * 0.6)
                                                        blue:(buttonColorRGBA[2] * 0.6)
                                                       alpha:(buttonColorRGBA[3] * 0.6 + 0.4)];

    UIColor *upperShine = [UIColor colorWithRed:0.948
                                          green:0.948
                                           blue:0.948
                                          alpha:0.82];
    UIColor *topShine = [upperShine colorWithAlphaComponent:0.5];
    UIColor *bottomShine = [upperShine colorWithAlphaComponent:0.1];

    //// Gradient Declarations
    NSArray *baseGradientColors = @[(id)buttonColor.CGColor, (id)baseGradientBottomColor.CGColor];

    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);
    NSArray *shineGradientColors = @[(id)upperShine.CGColor, (id)[UIColor colorWithRed:0.948
                                                                                 green:0.948
                                                                                  blue:0.948
                                                                                 alpha:0.66].CGColor, (id)topShine.CGColor, (id)[UIColor colorWithRed:0.948
                                                                                                                                                green:0.948
                                                                                                                                                 blue:0.948
                                                                                                                                                alpha:0.3].CGColor, (id)bottomShine.CGColor];

    CGFloat shineGradientLocations[] = {0, 0.05, 0.09, 0.66, 1};
    CGGradientRef shineGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)shineGradientColors, shineGradientLocations);

    //// Shadow Declarations
    UIColor *buttonShadow = iconShadow;
    CGSize buttonShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat buttonShadowBlurRadius = 2;

    //// Frames
    CGRect frame = CGRectMake(0, 0, 229, 38);

    //// Button
    {
        UIGraphicsPushContext(context);
        CGContextSetAlpha(context, 0.75);
        CGContextBeginTransparencyLayer(context, NULL);

        //// ButtonRectangle Drawing
        CGRect buttonRectangleRect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, CGRectGetHeight(frame) - 4);
        UIBezierPath *buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect:buttonRectangleRect cornerRadius:7];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, buttonShadowOffset, buttonShadowBlurRadius, buttonShadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [buttonRectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient, CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMinY(buttonRectangleRect)), CGPointMake(CGRectGetMidX(buttonRectangleRect), CGRectGetMaxY(buttonRectangleRect)), 0);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        //// Rounded Rectangle Drawing
        CGRect roundedRectangleRect = CGRectMake(CGRectGetMinX(frame) + 2, CGRectGetMinY(frame) + 1, CGRectGetWidth(frame) - 4, floor((CGRectGetHeight(frame) - 1) * 0.48649 + 0.5));
        UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:roundedRectangleRect cornerRadius:7];
        UIGraphicsPushContext(context);
        [roundedRectanglePath addClip];
        CGContextDrawLinearGradient(context, shineGradient, CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMinY(roundedRectangleRect)), CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMaxY(roundedRectangleRect)), 0);
        UIGraphicsPopContext();

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(baseGradient);
    CGGradientRelease(shineGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawIconButton {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *iconShadow = [UIColor colorWithRed:0
                                          green:0
                                           blue:0
                                          alpha:0.8];
    UIColor *baseColor = [UIColor colorWithRed:0.156
                                         green:0.364
                                          blue:0.687
                                         alpha:1];
    CGFloat baseColorRGBA[4];
    [baseColor getRed:&baseColorRGBA[0]
                green:&baseColorRGBA[1]
                 blue:&baseColorRGBA[2]
                alpha:&baseColorRGBA[3]];

    UIColor *baseGradientBottomColor = [UIColor colorWithRed:(baseColorRGBA[0] * 0.8)
                                                       green:(baseColorRGBA[1] * 0.8)
                                                        blue:(baseColorRGBA[2] * 0.8)
                                                       alpha:(baseColorRGBA[3] * 0.8 + 0.2)];
    UIColor *strokeColor = [UIColor colorWithRed:0
                                           green:0
                                            blue:0
                                           alpha:0.23];
    UIColor *upperShine = [UIColor colorWithRed:1
                                          green:1
                                           blue:1
                                          alpha:1];
    UIColor *bottomShine = [upperShine colorWithAlphaComponent:0.1];
    UIColor *topShine = [upperShine colorWithAlphaComponent:0.9];

    //// Gradient Declarations
    NSArray *shineGradientColors = @[(id)topShine.CGColor, (id)[UIColor colorWithRed:1
                                                                               green:1
                                                                                blue:1
                                                                               alpha:0.5].CGColor, (id)bottomShine.CGColor];
    CGFloat shineGradientLocations[] = {0, 0.42, 1};
    CGGradientRef shineGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)shineGradientColors, shineGradientLocations);
    NSArray *baseGradientColors = @[(id)baseColor.CGColor, (id)baseGradientBottomColor.CGColor];
    CGFloat baseGradientLocations[] = {0, 1};
    CGGradientRef baseGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)baseGradientColors, baseGradientLocations);

    //// Shadow Declarations
    UIColor *iconBottomShadow = iconShadow;
    CGSize iconBottomShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat iconBottomShadowBlurRadius = 4;
    UIColor *upperShineShadow = upperShine;
    CGSize upperShineShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat upperShineShadowBlurRadius = 1;

    //// ShadowGroup
    {
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, iconBottomShadowOffset, iconBottomShadowBlurRadius, iconBottomShadow.CGColor);
        CGContextSetBlendMode(context, kCGBlendModeMultiply);
        CGContextBeginTransparencyLayer(context, NULL);

        //// shadowRectangle Drawing
        UIBezierPath *shadowRectanglePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6, 3, 57, 57) cornerRadius:11];
        [baseColor setFill];
        [shadowRectanglePath fill];

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// Button
    {
        //// ButtonRectangle Drawing
        UIBezierPath *buttonRectanglePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(6, 3, 57, 57) cornerRadius:11];
        UIGraphicsPushContext(context);
        [buttonRectanglePath addClip];
        CGContextDrawLinearGradient(context, baseGradient, CGPointMake(34.5, 3), CGPointMake(34.5, 60), 0);
        UIGraphicsPopContext();

        ////// ButtonRectangle Inner Shadow
        CGRect buttonRectangleBorderRect = CGRectInset([buttonRectanglePath bounds], -upperShineShadowBlurRadius, -upperShineShadowBlurRadius);
        buttonRectangleBorderRect = CGRectOffset(buttonRectangleBorderRect, -upperShineShadowOffset.width, -upperShineShadowOffset.height);
        buttonRectangleBorderRect = CGRectInset(CGRectUnion(buttonRectangleBorderRect, [buttonRectanglePath bounds]), -1, -1);

        UIBezierPath *buttonRectangleNegativePath = [UIBezierPath bezierPathWithRect:buttonRectangleBorderRect];
        [buttonRectangleNegativePath appendPath:buttonRectanglePath];
        buttonRectangleNegativePath.usesEvenOddFillRule = YES;

        UIGraphicsPushContext(context);
        {
            CGFloat xOffset = upperShineShadowOffset.width + round(buttonRectangleBorderRect.size.width);
            CGFloat yOffset = upperShineShadowOffset.height;
            CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), upperShineShadowBlurRadius, upperShineShadow.CGColor);

            [buttonRectanglePath addClip];
            CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(buttonRectangleBorderRect.size.width), 0);
            [buttonRectangleNegativePath applyTransform:transform];
            [[UIColor grayColor] setFill];
            [buttonRectangleNegativePath fill];
        }
        UIGraphicsPopContext();

        [strokeColor setStroke];
        buttonRectanglePath.lineWidth = 1;
        [buttonRectanglePath stroke];

        //// UpperShinner
        {
            UIGraphicsPushContext(context);
            CGContextSetBlendMode(context, kCGBlendModeHardLight);
            CGContextBeginTransparencyLayer(context, NULL);

            //// UpperShinnyPart Drawing
            UIBezierPath *upperShinnyPartPath = [UIBezierPath bezierPath];
            [upperShinnyPartPath moveToPoint:CGPointMake(63, 17)];
            [upperShinnyPartPath addLineToPoint:CGPointMake(63, 27)];
            [upperShinnyPartPath addCurveToPoint:CGPointMake(35, 33)
                                   controlPoint1:CGPointMake(55, 32)
                                   controlPoint2:CGPointMake(45.03, 33)];
            [upperShinnyPartPath addCurveToPoint:CGPointMake(6, 27)
                                   controlPoint1:CGPointMake(26, 33)
                                   controlPoint2:CGPointMake(14, 32)];
            [upperShinnyPartPath addLineToPoint:CGPointMake(6, 17)];
            [upperShinnyPartPath addCurveToPoint:CGPointMake(17, 4)
                                   controlPoint1:CGPointMake(6, 7)
                                   controlPoint2:CGPointMake(11, 4)];
            [upperShinnyPartPath addLineToPoint:CGPointMake(52, 4)];
            [upperShinnyPartPath addCurveToPoint:CGPointMake(63, 17)
                                   controlPoint1:CGPointMake(58, 4)
                                   controlPoint2:CGPointMake(63, 7)];
            [upperShinnyPartPath closePath];
            UIGraphicsPushContext(context);
            [upperShinnyPartPath addClip];
            CGContextDrawLinearGradient(context, shineGradient, CGPointMake(34.5, 4), CGPointMake(34.5, 33), 0);
            UIGraphicsPopContext();

            ////// UpperShinnyPart Inner Shadow
            CGRect upperShinnyPartBorderRect = CGRectInset([upperShinnyPartPath bounds], -upperShineShadowBlurRadius, -upperShineShadowBlurRadius);
            upperShinnyPartBorderRect = CGRectOffset(upperShinnyPartBorderRect, -upperShineShadowOffset.width, -upperShineShadowOffset.height);
            upperShinnyPartBorderRect = CGRectInset(CGRectUnion(upperShinnyPartBorderRect, [upperShinnyPartPath bounds]), -1, -1);

            UIBezierPath *upperShinnyPartNegativePath = [UIBezierPath bezierPathWithRect:upperShinnyPartBorderRect];
            [upperShinnyPartNegativePath appendPath:upperShinnyPartPath];
            upperShinnyPartNegativePath.usesEvenOddFillRule = YES;

            UIGraphicsPushContext(context);
            {
                CGFloat xOffset = upperShineShadowOffset.width + round(upperShinnyPartBorderRect.size.width);
                CGFloat yOffset = upperShineShadowOffset.height;
                CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), upperShineShadowBlurRadius, upperShineShadow.CGColor);

                [upperShinnyPartPath addClip];
                CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(upperShinnyPartBorderRect.size.width), 0);
                [upperShinnyPartNegativePath applyTransform:transform];
                [[UIColor grayColor] setFill];
                [upperShinnyPartNegativePath fill];
            }
            UIGraphicsPopContext();

            CGContextEndTransparencyLayer(context);
            UIGraphicsPopContext();
        }
    }

    //// Cleanup
    CGGradientRelease(shineGradient);
    CGGradientRelease(baseGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawResizableButton {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *frameColorTop = [UIColor colorWithRed:0.151
                                             green:0.151
                                              blue:0.151
                                             alpha:1];
    UIColor *frameShadowColor = [UIColor colorWithRed:1
                                                green:1
                                                 blue:1
                                                alpha:0.4];
    UIColor *buttonColor = [UIColor colorWithRed:0.731
                                           green:0
                                            blue:0.091
                                           alpha:1];
    CGFloat buttonColorRGBA[4];
    [buttonColor getRed:&buttonColorRGBA[0]
                  green:&buttonColorRGBA[1]
                   blue:&buttonColorRGBA[2]
     alpha
                       :&buttonColorRGBA[3]];

    UIColor *glossyColorUp = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.2 + 0.8)
                                             green:(buttonColorRGBA[1] * 0.2 + 0.8)
                                              blue:(buttonColorRGBA[2] * 0.2 + 0.8)
                                             alpha:(buttonColorRGBA[3] * 0.2 + 0.8)];
    UIColor *glossyColorBottom = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.6 + 0.4)
                                                 green:(buttonColorRGBA[1] * 0.6 + 0.4)
                                                  blue:(buttonColorRGBA[2] * 0.6 + 0.4)
                                                 alpha:(buttonColorRGBA[3] * 0.6 + 0.4)];

    //// Gradient Declarations
    NSArray *glossyGradientColors = @[(id)glossyColorUp.CGColor, (id)glossyColorBottom.CGColor];
    CGFloat glossyGradientLocations[] = {0, 1};
    CGGradientRef glossyGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)glossyGradientColors, glossyGradientLocations);

    //// Shadow Declarations
    UIColor *frameInnerShadow = frameShadowColor;
    CGSize frameInnerShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat frameInnerShadowBlurRadius = 3;
    UIColor *buttonInnerShadow = [UIColor blackColor];
    CGSize buttonInnerShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat buttonInnerShadowBlurRadius = 12;
    UIColor *textShadow = [UIColor blackColor];
    CGSize textShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat textShadowBlurRadius = 1;
    UIColor *buttonShadow = [UIColor blackColor];
    CGSize buttonShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat buttonShadowBlurRadius = 3;

    //// Frames
    CGRect frame = CGRectMake(50, 34, 162, 47);

    //// Abstracted Attributes
    NSString *textContent = @"STOP";

    //// outerFrame Drawing
    UIBezierPath *outerFramePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(frame) + 7.5, CGRectGetMinY(frame) + 6.5, CGRectGetWidth(frame) - 15, CGRectGetHeight(frame) - 14) cornerRadius:8];
    UIGraphicsPushContext(context);
    CGContextSetShadowWithColor(context, buttonShadowOffset, buttonShadowBlurRadius, buttonShadow.CGColor);
    [frameColorTop setFill];
    [outerFramePath fill];
    UIGraphicsPopContext();

    [[UIColor blackColor] setStroke];
    outerFramePath.lineWidth = 1;
    [outerFramePath stroke];

    //// innerFrame Drawing
    UIBezierPath *innerFramePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(frame) + 10.5, CGRectGetMinY(frame) + 9.5, CGRectGetWidth(frame) - 21, CGRectGetHeight(frame) - 20) cornerRadius:5];
    UIGraphicsPushContext(context);
    CGContextSetShadowWithColor(context, frameInnerShadowOffset, frameInnerShadowBlurRadius, frameInnerShadow.CGColor);
    [buttonColor setFill];
    [innerFramePath fill];

    ////// innerFrame Inner Shadow
    CGRect innerFrameBorderRect = CGRectInset([innerFramePath bounds], -buttonInnerShadowBlurRadius, -buttonInnerShadowBlurRadius);
    innerFrameBorderRect = CGRectOffset(innerFrameBorderRect, -buttonInnerShadowOffset.width, -buttonInnerShadowOffset.height);
    innerFrameBorderRect = CGRectInset(CGRectUnion(innerFrameBorderRect, [innerFramePath bounds]), -1, -1);

    UIBezierPath *innerFrameNegativePath = [UIBezierPath bezierPathWithRect:innerFrameBorderRect];
    [innerFrameNegativePath appendPath:innerFramePath];
    innerFrameNegativePath.usesEvenOddFillRule = YES;

    UIGraphicsPushContext(context);
    {
        CGFloat xOffset = buttonInnerShadowOffset.width + round(innerFrameBorderRect.size.width);
        CGFloat yOffset = buttonInnerShadowOffset.height;
        CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), buttonInnerShadowBlurRadius, buttonInnerShadow.CGColor);

        [innerFramePath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(innerFrameBorderRect.size.width), 0);
        [innerFrameNegativePath applyTransform:transform];
        [[UIColor grayColor] setFill];
        [innerFrameNegativePath fill];
    }
    UIGraphicsPopContext();

    UIGraphicsPopContext();

    [[UIColor blackColor] setStroke];
    innerFramePath.lineWidth = 1;
    [innerFramePath stroke];

    //// Rounded Rectangle Drawing
    CGRect roundedRectangleRect = CGRectMake(CGRectGetMinX(frame) + 13, CGRectGetMinY(frame) + 11, CGRectGetWidth(frame) - 26, 9);
    UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:roundedRectangleRect cornerRadius:4];
    UIGraphicsPushContext(context);
    [roundedRectanglePath addClip];
    CGContextDrawLinearGradient(context, glossyGradient, CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMinY(roundedRectangleRect)), CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMaxY(roundedRectangleRect)), 0);
    UIGraphicsPopContext();

    //// Text Drawing
    CGRect textRect = CGRectMake(CGRectGetMinX(frame) + 23, CGRectGetMinY(frame) + floor((CGRectGetHeight(frame) - 23) * 0.45833 + 0.5), CGRectGetWidth(frame) - 45, 23);
    UIGraphicsPushContext(context);
    CGContextSetShadowWithColor(context, textShadowOffset, textShadowBlurRadius, textShadow.CGColor);
    [glossyColorUp setFill];
    NSMutableParagraphStyle * paragraphStyle = [NSMutableParagraphStyle new];
    paragraphStyle.alignment = NSTextAlignmentCenter;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    [textContent drawInRect:textRect
             withAttributes:@{NSFontAttributeName: [UIFont fontWithName:@"LucidaGrande-Bold" size:18],
                              NSParagraphStyleAttributeName : paragraphStyle}];
    UIGraphicsPopContext();

    //// Cleanup
    CGGradientRelease(glossyGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawBlueButton {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *upColorOut = [UIColor colorWithRed:0.748
                                          green:0.748
                                           blue:0.748
                                          alpha:1];
    UIColor *bottomColorDown = [UIColor colorWithRed:0.16
                                               green:0.16
                                                blue:0.16
                                               alpha:1];
    UIColor *upColorInner = [UIColor colorWithRed:0.129
                                            green:0.132
                                             blue:0.148
                                            alpha:1];
    UIColor *bottomColorInner = [UIColor colorWithRed:0.975
                                                green:0.975
                                                 blue:0.985
                                                alpha:1];
    UIColor *buttonColor = [UIColor colorWithRed:0
                                           green:0.272
                                            blue:0.883
                                           alpha:1];
    CGFloat buttonColorRGBA[4];
    [buttonColor getRed:&buttonColorRGBA[0]
                  green:&buttonColorRGBA[1]
                   blue:&buttonColorRGBA[2]
     alpha
                       :&buttonColorRGBA[3]];

    UIColor *buttonTopColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.8)
                                              green:(buttonColorRGBA[1] * 0.8)
                                               blue:(buttonColorRGBA[2] * 0.8)
                                              alpha:(buttonColorRGBA
                                                     [3] * 0.8 + 0.2)];
    UIColor *buttonBottomColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0 + 1)
                                                 green:(buttonColorRGBA[1] * 0 + 1)
                                                  blue:(buttonColorRGBA[2] * 0 + 1)
                                                 alpha:(buttonColorRGBA[3] * 0 + 1)];
    UIColor *buttonFlareUpColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.3 + 0.7)
                                                  green:(buttonColorRGBA[1] * 0.3 + 0.7)
                                                   blue:(buttonColorRGBA[2] * 0.3 + 0.7)
                                                  alpha:(buttonColorRGBA[3] * 0.3 + 0.7)];
    UIColor *buttonFlareBottomColor = [UIColor colorWithRed:(buttonColorRGBA[0] * 0.8 + 0.2)
                                                      green:(buttonColorRGBA[1] * 0.8 + 0.2)
                                                       blue:(buttonColorRGBA[2] * 0.8 + 0.2)
                                                      alpha:(buttonColorRGBA[3] * 0.8 + 0.2)];
    UIColor *flareWhite = [UIColor colorWithRed:1
                                          green:1
                                           blue:1
                                          alpha:0.83];

    //// Gradient Declarations
    NSArray *ringGradientColors = @[(id)upColorOut.CGColor, (id)bottomColorDown.CGColor];
    CGFloat ringGradientLocations[] = {0, 1};
    CGGradientRef ringGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)ringGradientColors, ringGradientLocations);
    NSArray *ringInnerGradientColors = @[(id)upColorInner.CGColor, (id)bottomColorInner.CGColor];
    CGFloat ringInnerGradientLocations[] = {0, 1};
    CGGradientRef ringInnerGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)ringInnerGradientColors, ringInnerGradientLocations);
    NSArray *buttonGradientColors = @[(id)buttonBottomColor.CGColor, (id)buttonTopColor.CGColor];
    CGFloat buttonGradientLocations[] = {0, 1};
    CGGradientRef buttonGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)buttonGradientColors, buttonGradientLocations);
    NSArray *overlayGradientColors = @[(id)flareWhite.CGColor, (id)[UIColor clearColor].CGColor];
    CGFloat overlayGradientLocations[] = {0, 1};
    CGGradientRef overlayGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)overlayGradientColors, overlayGradientLocations);
    NSArray *buttonFlareGradientColors = @[(id)buttonFlareUpColor.CGColor, (id)buttonFlareBottomColor.CGColor];
    CGFloat buttonFlareGradientLocations[] = {0, 1};
    CGGradientRef buttonFlareGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)buttonFlareGradientColors, buttonFlareGradientLocations);

    //// Shadow Declarations
    UIColor *buttonInnerShadow = [UIColor blackColor];
    CGSize buttonInnerShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat buttonInnerShadowBlurRadius = 5;
    UIColor *buttonOuterShadow = [UIColor blackColor];
    CGSize buttonOuterShadowOffset = CGSizeMake(0.1, 2.1);
    CGFloat buttonOuterShadowBlurRadius = 5;

    //// outerOval Drawing
    UIBezierPath *outerOvalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(5, 5, 63, 63)];
    UIGraphicsPushContext(context);
    CGContextSetShadowWithColor(context, buttonOuterShadowOffset, buttonOuterShadowBlurRadius, buttonOuterShadow.CGColor);
    CGContextBeginTransparencyLayer(context, NULL);
    [outerOvalPath addClip];
    CGContextDrawLinearGradient(context, ringGradient, CGPointMake(36.5, 5), CGPointMake(36.5, 68), 0);
    CGContextEndTransparencyLayer(context);
    UIGraphicsPopContext();

    //// overlayOval Drawing
    UIBezierPath *overlayOvalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(5, 5, 63, 63)];
    UIGraphicsPushContext(context);
    [overlayOvalPath addClip];
    CGContextDrawRadialGradient(context, overlayGradient, CGPointMake(36.5, 12.23), 17.75, CGPointMake(36.5, 36.5), 44.61, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    UIGraphicsPopContext();

    //// innerOval Drawing
    UIBezierPath *innerOvalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(12, 12, 49, 49)];
    UIGraphicsPushContext(context);
    [innerOvalPath addClip];
    CGContextDrawLinearGradient(context, ringInnerGradient, CGPointMake(36.5, 12), CGPointMake(36.5, 61), 0);
    UIGraphicsPopContext();

    //// buttonOval Drawing
    UIBezierPath *buttonOvalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(14, 13, 46, 46)];
    UIGraphicsPushContext(context);
    [buttonOvalPath addClip];
    CGContextDrawRadialGradient(context, buttonGradient, CGPointMake(37, 63.23), 2.44, CGPointMake(37, 44.48), 23.14, kCGGradientDrawsBeforeStartLocation | kCGGradientDrawsAfterEndLocation);
    UIGraphicsPopContext();

    ////// buttonOval Inner Shadow
    CGRect buttonOvalBorderRect = CGRectInset([buttonOvalPath bounds], -buttonInnerShadowBlurRadius, -buttonInnerShadowBlurRadius);
    buttonOvalBorderRect = CGRectOffset(buttonOvalBorderRect, -buttonInnerShadowOffset.width, -buttonInnerShadowOffset.height);
    buttonOvalBorderRect = CGRectInset(CGRectUnion(buttonOvalBorderRect, [buttonOvalPath bounds]), -1, -1);

    UIBezierPath *buttonOvalNegativePath = [UIBezierPath bezierPathWithRect:buttonOvalBorderRect];
    [buttonOvalNegativePath appendPath:buttonOvalPath];
    buttonOvalNegativePath.usesEvenOddFillRule = YES;

    UIGraphicsPushContext(context);
    {
        CGFloat xOffset = buttonInnerShadowOffset.width + round(buttonOvalBorderRect.size.width);
        CGFloat yOffset = buttonInnerShadowOffset.height;
        CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), buttonInnerShadowBlurRadius, buttonInnerShadow.CGColor);

        [buttonOvalPath addClip];
        CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(buttonOvalBorderRect.size.width), 0);
        [buttonOvalNegativePath applyTransform:transform];
        [[UIColor grayColor] setFill];
        [buttonOvalNegativePath fill];
    }
    UIGraphicsPopContext();

    //// flareOval Drawing
    UIBezierPath *flareOvalPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(22, 14, 29, 15)];
    UIGraphicsPushContext(context);
    [flareOvalPath addClip];
    CGContextDrawLinearGradient(context, buttonFlareGradient, CGPointMake(36.5, 14), CGPointMake(36.5, 29), 0);
    UIGraphicsPopContext();

    //// Cleanup
    CGGradientRelease(ringGradient);
    CGGradientRelease(ringInnerGradient);
    CGGradientRelease(buttonGradient);
    CGGradientRelease(overlayGradient);
    CGGradientRelease(buttonFlareGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawGlassShelf {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *shineColor = [UIColor colorWithRed:1
                                          green:1
                                           blue:1
                                          alpha:1];
    UIColor *topColor = [UIColor colorWithRed:0.63
                                        green:0.661
                                         blue:0.651
                                        alpha:1];
    UIColor *background = [UIColor colorWithRed:0.282
                                          green:0.282
                                           blue:0.282
                                          alpha:1];
    UIColor *backShadowColor = [UIColor colorWithRed:0.07
                                               green:0.168
                                                blue:0.085
                                               alpha:0.97];
    UIColor *glassColor = [UIColor colorWithRed:0.203
                                          green:0.529
                                           blue:0.424
                                          alpha:1];
    CGFloat glassColorRGBA[4];
    [glassColor getRed:&glassColorRGBA[0]
                 green:&glassColorRGBA[1]
                  blue:&glassColorRGBA[2]
                 alpha:&glassColorRGBA[3]];

    CGFloat glassColorHSBA[4];
    [glassColor getHue:&glassColorHSBA[0]
            saturation:&glassColorHSBA[1]
            brightness:&glassColorHSBA[2]
                 alpha:&glassColorHSBA[3]];

    UIColor *edgeColor = [UIColor colorWithHue:glassColorHSBA[0]
                                    saturation:0.224
                                    brightness:glassColorHSBA[2]
                                         alpha:glassColorHSBA[3]];
    UIColor *glassFrontColor = [UIColor colorWithHue:glassColorHSBA[0]
                                          saturation:0.278
                                          brightness:glassColorHSBA[2]
                                               alpha:glassColorHSBA[3]];
    UIColor *glassEdgeColor = [UIColor colorWithRed:(glassColorRGBA[0] * 0.717 + 0.283)
                                              green:(glassColorRGBA[1] * 0.717 + 0.283)
                                               blue:(glassColorRGBA[2] * 0.717 + 0.283)
                                              alpha:(glassColorRGBA[3] * 0.717 + 0.283)];
    UIColor *glassEdgeShine = [UIColor colorWithHue:glassColorHSBA[0]
                                         saturation:glassColorHSBA[1]
                                         brightness:1
                                              alpha:glassColorHSBA[3]];
    UIColor *glassFrontTop = [UIColor colorWithHue:glassColorHSBA[0]
                                        saturation:glassColorHSBA[1]
                                        brightness:0.397
                                             alpha:glassColorHSBA[3]];
    UIColor *glassFrontBottom = [UIColor colorWithHue:glassColorHSBA[0]
                                           saturation:glassColorHSBA[1]
                                           brightness:0.3
                                                alpha:glassColorHSBA[3]];

    //// Gradient Declarations
    NSArray *backGradientColors = @[(id)shineColor.CGColor, (id)[UIColor colorWithRed:0.705
                                                                                green:0.764
                                                                                 blue:0.745
                                                                                alpha:1].CGColor, (id)edgeColor.CGColor];
    CGFloat backGradientLocations[] = {0, 0.01, 1};
    CGGradientRef backGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)backGradientColors, backGradientLocations);
    NSArray *topGradientColors = @[(id)topColor.CGColor, (id)glassFrontColor.CGColor, (id)[UIColor colorWithRed:0.405
                                                                                                          green:0.595
                                                                                                           blue:0.534
                                                                                                          alpha:1].CGColor, (id)glassEdgeColor.CGColor];
    CGFloat topGradientLocations[] = {0, 0.99, 0.99, 1};
    CGGradientRef topGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)topGradientColors, topGradientLocations);
    NSArray *frontGradientColors = @[(id)glassEdgeShine.CGColor, (id)[UIColor colorWithRed:0.268
                                                                                     green:0.698
                                                                                      blue:0.56
                                                                                     alpha:1].CGColor, (id)glassFrontTop.CGColor, (id)glassColor.CGColor, (id)glassFrontBottom.CGColor];
    CGFloat frontGradientLocations[] = {0, 0.05, 0.16, 0.84, 1};
    CGGradientRef frontGradient = CGGradientCreateWithColors(colorSpace, (__bridge CFArrayRef)frontGradientColors, frontGradientLocations);

    //// Shadow Declarations
    UIColor *backShadow = backShadowColor;
    CGSize backShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat backShadowBlurRadius = 6;
    UIColor *bottomShadow = backShadowColor;
    CGSize bottomShadowOffset = CGSizeMake(2.1, 10.1);
    CGFloat bottomShadowBlurRadius = 30;

    //// Frames
    CGRect frame = CGRectMake(0, 0, 300, 88);

    //// shelf
    {
        //// botomShadowRectangle Drawing
        UIBezierPath *botomShadowRectanglePath = [UIBezierPath bezierPath];
        [botomShadowRectanglePath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 46.5)];
        [botomShadowRectanglePath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 23.53, CGRectGetMaxY(frame) - 50.5)
                                    controlPoint1:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 48.71)
                                    controlPoint2:CGPointMake(CGRectGetMinX(frame) + 21.3, CGRectGetMaxY(frame) - 50.5)];
        [botomShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 25.53, CGRectGetMaxY(frame) - 50.5)];
        [botomShadowRectanglePath addCurveToPoint:CGPointMake(CGRectGetMaxX(frame) - 21.5, CGRectGetMaxY(frame) - 46.5)
                                    controlPoint1:CGPointMake(CGRectGetMaxX(frame) - 23.3, CGRectGetMaxY(frame) - 50.5)
                                    controlPoint2:CGPointMake(CGRectGetMaxX(frame) - 21.5, CGRectGetMaxY(frame) - 48.71)];
        [botomShadowRectanglePath addCurveToPoint:CGPointMake(CGRectGetMaxX(frame) - 42.87, CGRectGetMaxY(frame) - 29.5)
                                    controlPoint1:CGPointMake(CGRectGetMaxX(frame) - 21.5, CGRectGetMaxY(frame) - 46.5)
                                    controlPoint2:CGPointMake(CGRectGetMaxX(frame) - 41.7, CGRectGetMaxY(frame) - 29.5)];
        [botomShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 38.35, CGRectGetMaxY(frame) - 29.5)];
        [botomShadowRectanglePath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 46.5)
                                    controlPoint1:CGPointMake(CGRectGetMinX(frame) + 37.17, CGRectGetMaxY(frame) - 29.5)
                                    controlPoint2:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 46.5)];
        [botomShadowRectanglePath closePath];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, bottomShadowOffset, bottomShadowBlurRadius, bottomShadow.CGColor);
        [background setFill];
        [botomShadowRectanglePath fill];
        UIGraphicsPopContext();

        //// backShadowRectangle Drawing
        UIBezierPath *backShadowRectanglePath = [UIBezierPath bezierPath];
        [backShadowRectanglePath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 23.5, CGRectGetMaxY(frame) - 43.5)];
        [backShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 26.5, CGRectGetMaxY(frame) - 43.5)];
        [backShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 41.81, CGRectGetMaxY(frame) - 17.5)];
        [backShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 39.81, CGRectGetMaxY(frame) - 17.5)];
        [backShadowRectanglePath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 23.5, CGRectGetMaxY(frame) - 43.5)];
        [backShadowRectanglePath closePath];
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, backShadowOffset, backShadowBlurRadius, backShadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);
        [backShadowRectanglePath addClip];
        CGRect backShadowRectangleBounds = CGPathGetPathBoundingBox(backShadowRectanglePath.CGPath);
        CGContextDrawLinearGradient(context, backGradient, CGPointMake(CGRectGetMidX(backShadowRectangleBounds), CGRectGetMaxY(backShadowRectangleBounds)), CGPointMake(CGRectGetMidX(backShadowRectangleBounds), CGRectGetMinY(backShadowRectangleBounds)), 0);
        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();

        //// topUnder Drawing
        UIBezierPath *topUnderPath = [UIBezierPath bezierPath];
        [topUnderPath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 18.5, CGRectGetMaxY(frame) - 42)];
        [topUnderPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 21.5, CGRectGetMaxY(frame) - 42)];
        [topUnderPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 41.81, CGRectGetMaxY(frame) - 16)];
        [topUnderPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 39.81, CGRectGetMaxY(frame) - 16)];
        [topUnderPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 18.5, CGRectGetMaxY(frame) - 42)];
        [topUnderPath closePath];
        UIGraphicsPushContext(context);
        [topUnderPath addClip];
        CGRect topUnderBounds = CGPathGetPathBoundingBox(topUnderPath.CGPath);
        CGContextDrawLinearGradient(context, backGradient, CGPointMake(CGRectGetMidX(topUnderBounds), CGRectGetMaxY(topUnderBounds)), CGPointMake(CGRectGetMidX(topUnderBounds), CGRectGetMinY(topUnderBounds)), 0);
        UIGraphicsPopContext();

        //// top Drawing
        UIBezierPath *topPath = [UIBezierPath bezierPath];
        [topPath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 41)];
        [topPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 21.5, CGRectGetMaxY(frame) - 41)];
        [topPath addLineToPoint:CGPointMake(CGRectGetMaxX(frame) - 42.32, CGRectGetMaxY(frame) - 17)];
        [topPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 41.32, CGRectGetMaxY(frame) - 17)];
        [topPath addLineToPoint:CGPointMake(CGRectGetMinX(frame) + 19.5, CGRectGetMaxY(frame) - 41)];
        [topPath closePath];
        UIGraphicsPushContext(context);
        [topPath addClip];
        CGRect topBounds = CGPathGetPathBoundingBox(topPath.CGPath);
        CGContextDrawLinearGradient(context, topGradient, CGPointMake(CGRectGetMidX(topBounds), CGRectGetMaxY(topBounds)), CGPointMake(CGRectGetMidX(topBounds), CGRectGetMinY(topBounds)), 0);
        UIGraphicsPopContext();

        //// front Drawing
        CGRect frontRect = CGRectMake(CGRectGetMinX(frame) + 19, CGRectGetMinY(frame) + CGRectGetHeight(frame) - 51.5, CGRectGetWidth(frame) - 40, 10);
        UIBezierPath *frontPath = [UIBezierPath bezierPathWithRoundedRect:frontRect byRoundingCorners:UIRectCornerBottomLeft | UIRectCornerBottomRight cornerRadii:CGSizeMake(2, 2)];
        [frontPath closePath];
        UIGraphicsPushContext(context);
        [frontPath addClip];
        CGContextDrawLinearGradient(context, frontGradient, CGPointMake(CGRectGetMidX(frontRect), CGRectGetMaxY(frontRect)), CGPointMake(CGRectGetMidX(frontRect), CGRectGetMinY(frontRect)), 0);
        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(backGradient);
    CGGradientRelease(topGradient);
    CGGradientRelease(frontGradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawProgressBar {
    //// General Declarations
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = UIGraphicsGetCurrentContext();

    //// Color Declarations
    UIColor *highlight = [UIColor colorWithRed:0.438
                                         green:0.438
                                          blue:0.438
                                         alpha:0.63];
    UIColor *topColor = [UIColor colorWithRed:1
                                        green:1
                                         blue:1
                                        alpha:1];
    CGFloat topColorRGBA[4];
    [topColor getRed:&topColorRGBA[0]
               green:&topColorRGBA[1]
                blue:&topColorRGBA[2]
               alpha:&topColorRGBA[3]];

    UIColor *bottomColor = [UIColor colorWithRed:(topColorRGBA[0] * 0.857)
                                           green:(topColorRGBA[1] * 0.857)
                                            blue:(topColorRGBA[2] * 0.857)
                                           alpha:(topColorRGBA[3] * 0.857 + 0.143)];
    UIColor *whiteEdgeColor = [UIColor colorWithRed:1
                                              green:1
                                               blue:1
                                              alpha:0.53];
    UIColor *outerShadowColor = [UIColor colorWithRed:0.699
                                                green:0.699
                                                 blue:0.699
                                                alpha:1];
    UIColor *progressColor = [UIColor colorWithRed:0.885
                                             green:1
                                              blue:0
                                             alpha:1];
    UIColor *activeBarBackColor = [UIColor colorWithRed:0.533
                                                  green:0.533
                                                   blue:0.533
                                                  alpha:1];

    //// Gradient Declarations
    NSArray *gradientColors = @[(id)topColor.CGColor,
                                (id)[UIColor colorWithRed:0.929
                                                    green:0.929
                                                     blue:0.929
                                                    alpha:1].CGColor,
                                (id)bottomColor.CGColor];

    CGFloat gradientLocations[] = {0, 0.42, 1};
    CGGradientRef gradient = CGGradientCreateWithColors(colorSpace,
                                                        (__bridge CFArrayRef)gradientColors,
                                                        gradientLocations);

    //// Shadow Declarations
    UIColor *sheetShadow = highlight;
    CGSize sheetShadowOffset = CGSizeMake(0.1, 1.1);
    CGFloat sheetShadowBlurRadius = 7;
    UIColor *whiteEdgeShadow = whiteEdgeColor;
    CGSize whiteEdgeShadowOffset = CGSizeMake(0.1, -1.1);
    CGFloat whiteEdgeShadowBlurRadius = 1;
    UIColor *trackInnerShadow = highlight;
    CGSize trackInnerShadowOffset = CGSizeMake(0.1, -0.1);
    CGFloat trackInnerShadowBlurRadius = 4.9;
    UIColor *activeBarShadow = activeBarBackColor;
    CGSize activeBarShadowOffset = CGSizeMake(1.1, -0.1);
    CGFloat activeBarShadowBlurRadius = 2;

    //// Frames
    CGRect progressIndicatorFrame = CGRectMake(0, 0, 233, 43);

    //// Subframes
    CGRect progressActive = CGRectMake(CGRectGetMinX(progressIndicatorFrame) + 17, CGRectGetMinY(progressIndicatorFrame) + 16, CGRectGetWidth(progressIndicatorFrame) - 109, 10);
    CGRect activeProgressFrame = CGRectMake(CGRectGetMinX(progressActive) + floor(CGRectGetWidth(progressActive) * 0.00000 + 0.5), CGRectGetMinY(progressActive) + floor(CGRectGetHeight(progressActive) * 0.00000 + 0.5), floor(CGRectGetWidth(progressActive) * 1.00000 + 0.5) - floor(CGRectGetWidth(progressActive) * 0.00000 + 0.5), floor(CGRectGetHeight(progressActive) * 1.00000 + 0.5) - floor(CGRectGetHeight(progressActive) * 0.00000 + 0.5));
    CGRect groupColorizer = CGRectMake(CGRectGetMinX(activeProgressFrame) + 2, CGRectGetMinY(activeProgressFrame) + 2, CGRectGetWidth(activeProgressFrame) - 3, 6);

    //// progressBarSheet
    {
        UIGraphicsPushContext(context);
        CGContextSetShadowWithColor(context, sheetShadowOffset, sheetShadowBlurRadius, sheetShadow.CGColor);
        CGContextBeginTransparencyLayer(context, NULL);

        //// ProgressBar
        {
            //// Rounded Rectangle Drawing
            CGRect roundedRectangleRect = CGRectMake(CGRectGetMinX(progressIndicatorFrame) + 7.5, CGRectGetMinY(progressIndicatorFrame) + 7, CGRectGetWidth(progressIndicatorFrame) - 15, 28);
            UIBezierPath *roundedRectanglePath = [UIBezierPath bezierPathWithRoundedRect:roundedRectangleRect cornerRadius:14];
            UIGraphicsPushContext(context);
            [roundedRectanglePath addClip];
            CGContextDrawLinearGradient(context, gradient, CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMaxY(roundedRectangleRect)), CGPointMake(CGRectGetMidX(roundedRectangleRect), CGRectGetMinY(roundedRectangleRect)), 0);
            UIGraphicsPopContext();

            ////// Rounded Rectangle Inner Shadow
            CGRect roundedRectangleBorderRect = CGRectInset([roundedRectanglePath bounds], -whiteEdgeShadowBlurRadius, -whiteEdgeShadowBlurRadius);
            roundedRectangleBorderRect = CGRectOffset(roundedRectangleBorderRect, -whiteEdgeShadowOffset.width, -whiteEdgeShadowOffset.height);
            roundedRectangleBorderRect = CGRectInset(CGRectUnion(roundedRectangleBorderRect, [roundedRectanglePath bounds]), -1, -1);

            UIBezierPath *roundedRectangleNegativePath = [UIBezierPath bezierPathWithRect:roundedRectangleBorderRect];
            [roundedRectangleNegativePath appendPath:roundedRectanglePath];
            roundedRectangleNegativePath.usesEvenOddFillRule = YES;

            UIGraphicsPushContext(context);
            {
                CGFloat xOffset = whiteEdgeShadowOffset.width + round(roundedRectangleBorderRect.size.width);
                CGFloat yOffset = whiteEdgeShadowOffset.height;
                CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), whiteEdgeShadowBlurRadius, whiteEdgeShadow.CGColor);

                [roundedRectanglePath addClip];
                CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(roundedRectangleBorderRect.size.width), 0);
                [roundedRectangleNegativePath applyTransform:transform];
                [[UIColor grayColor] setFill];
                [roundedRectangleNegativePath fill];
            }
            UIGraphicsPopContext();

            //// progreessTrack Drawing
            UIBezierPath *progreessTrackPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(progressIndicatorFrame) + 18.5, CGRectGetMinY(progressIndicatorFrame) + 17.5, CGRectGetWidth(progressIndicatorFrame) - 37, 7) cornerRadius:3.5];
            UIGraphicsPushContext(context);
            CGContextSetShadowWithColor(context, whiteEdgeShadowOffset, whiteEdgeShadowBlurRadius, whiteEdgeShadow.CGColor);
            [outerShadowColor setFill];
            [progreessTrackPath fill];

            ////// progreessTrack Inner Shadow
            CGRect progreessTrackBorderRect = CGRectInset([progreessTrackPath bounds], -trackInnerShadowBlurRadius, -trackInnerShadowBlurRadius);
            progreessTrackBorderRect = CGRectOffset(progreessTrackBorderRect, -trackInnerShadowOffset.width, -trackInnerShadowOffset.height);
            progreessTrackBorderRect = CGRectInset(CGRectUnion(progreessTrackBorderRect, [progreessTrackPath bounds]), -1, -1);

            UIBezierPath *progreessTrackNegativePath = [UIBezierPath bezierPathWithRect:progreessTrackBorderRect];
            [progreessTrackNegativePath appendPath:progreessTrackPath];
            progreessTrackNegativePath.usesEvenOddFillRule = YES;

            UIGraphicsPushContext(context);
            {
                CGFloat xOffset = trackInnerShadowOffset.width + round(progreessTrackBorderRect.size.width);
                CGFloat yOffset = trackInnerShadowOffset.height;
                CGContextSetShadowWithColor(context, CGSizeMake(xOffset + copysign(0.1, xOffset), yOffset + copysign(0.1, yOffset)), trackInnerShadowBlurRadius, trackInnerShadow.CGColor);

                [progreessTrackPath addClip];
                CGAffineTransform transform = CGAffineTransformMakeTranslation(-round(progreessTrackBorderRect.size.width), 0);
                [progreessTrackNegativePath applyTransform:transform];
                [[UIColor grayColor] setFill];
                [progreessTrackNegativePath fill];
            }
            UIGraphicsPopContext();

            UIGraphicsPopContext();

            [highlight setStroke];
            progreessTrackPath.lineWidth = 1;
            [progreessTrackPath stroke];

            //// ProgressActive
            {
                //// progreessTrackActive Drawing
                UIBezierPath *progreessTrackActivePath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(activeProgressFrame) + 2, CGRectGetMinY(activeProgressFrame) + 2, CGRectGetWidth(activeProgressFrame) - 3, CGRectGetHeight(activeProgressFrame) - 4) cornerRadius:3];
                UIGraphicsPushContext(context);
                CGContextSetShadowWithColor(context, activeBarShadowOffset, activeBarShadowBlurRadius, activeBarShadow.CGColor);
                [progressColor setFill];
                [progreessTrackActivePath fill];
                UIGraphicsPopContext();

                //// GroupColorizer
                {
                    UIGraphicsPushContext(context);
                    CGContextSetBlendMode(context, kCGBlendModeColor);
                    CGContextBeginTransparencyLayer(context, NULL);

                    //// trackColorizer Drawing
                    UIBezierPath *trackColorizerPath = [UIBezierPath bezierPathWithRoundedRect:CGRectMake(CGRectGetMinX(groupColorizer) + floor(CGRectGetWidth(groupColorizer) * 0.00000 + 0.5), CGRectGetMinY(groupColorizer) + floor(CGRectGetHeight(groupColorizer) * 0.00000 + 0.5), floor(CGRectGetWidth(groupColorizer) * 1.00000 + 0.5) - floor(CGRectGetWidth(groupColorizer) * 0.00000 + 0.5), floor(CGRectGetHeight(groupColorizer) * 1.00000 + 0.5) - floor(CGRectGetHeight(groupColorizer) * 0.00000 + 0.5)) cornerRadius:3];
                    [progressColor setFill];
                    [trackColorizerPath fill];

                    CGContextEndTransparencyLayer(context);
                    UIGraphicsPopContext();
                }
            }
        }

        CGContextEndTransparencyLayer(context);
        UIGraphicsPopContext();
    }

    //// Cleanup
    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorSpace);
}

+ (void)drawOrganicSlider {
    //// Color Declarations
    UIColor *sliderColor = [UIColor colorWithRed:0
                                           green:0.988
                                            blue:1
                                           alpha:1];

    //// Frames
    CGRect frame = CGRectMake(39, 3, 20, 34);

    //// Group
    {
        //// track Drawing
        UIBezierPath *trackPath = [UIBezierPath bezierPath];
        [trackPath moveToPoint:CGPointMake(CGRectGetMinX(frame) + 10.01, CGRectGetMinY(frame) + 5.7)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 18.72, CGRectGetMinY(frame) + 9.5)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 15.22, CGRectGetMinY(frame) + 5.74)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 17.42, CGRectGetMinY(frame) + 9.02)];
        [trackPath addCurveToPoint:CGPointMake(91.01, 12.7)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 20.02, CGRectGetMinY(frame) + 9.98)
                     controlPoint2:CGPointMake(91.01, 12.7)];
        [trackPath addCurveToPoint:CGPointMake(100.13, 20)
                     controlPoint1:CGPointMake(96.6, 12.7)
                     controlPoint2:CGPointMake(100.13, 15.86)];
        [trackPath addCurveToPoint:CGPointMake(91.01, 27.3)
                     controlPoint1:CGPointMake(100.13, 24.14)
                     controlPoint2:CGPointMake(96.6, 27.3)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 18.72, CGRectGetMinY(frame) + 24.5)
                     controlPoint1:CGPointMake(91.01, 27.3)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 20.02, CGRectGetMinY(frame) + 24.03)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 10.07, CGRectGetMinY(frame) + 28.3)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 17.41, CGRectGetMinY(frame) + 24.97)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 14.96, CGRectGetMinY(frame) + 28.34)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 1.28, CGRectGetMinY(frame) + 24.5)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 5.1, CGRectGetMinY(frame) + 28.26)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 2.5, CGRectGetMinY(frame) + 25.07)];
        [trackPath addCurveToPoint:CGPointMake(28.29, 27.3)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 0.07, CGRectGetMinY(frame) + 23.93)
                     controlPoint2:CGPointMake(28.29, 27.3)];
        [trackPath addCurveToPoint:CGPointMake(19.17, 20)
                     controlPoint1:CGPointMake(22.7, 27.3)
                     controlPoint2:CGPointMake(19.17, 24.14)];
        [trackPath addCurveToPoint:CGPointMake(28.29, 12.7)
                     controlPoint1:CGPointMake(19.17, 15.86)
                     controlPoint2:CGPointMake(22.7, 12.7)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 1.28, CGRectGetMinY(frame) + 9.5)
                     controlPoint1:CGPointMake(28.29, 12.7)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 0.07, CGRectGetMinY(frame) + 10.01)];
        [trackPath addCurveToPoint:CGPointMake(CGRectGetMinX(frame) + 10.01, CGRectGetMinY(frame) + 5.7)
                     controlPoint1:CGPointMake(CGRectGetMinX(frame) + 2.5, CGRectGetMinY(frame) + 8.99)
                     controlPoint2:CGPointMake(CGRectGetMinX(frame) + 4.79, CGRectGetMinY(frame) + 5.66)];
        [trackPath closePath];
        [[UIColor whiteColor] setStroke];
        trackPath.lineWidth = 1.5;
        [trackPath stroke];

        //// knob Drawing
        UIBezierPath *knobPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(CGRectGetMinX(frame) + 2.5, CGRectGetMinY(frame) + 9.5, 15, 15)];
        [sliderColor setFill];
        [knobPath fill];

        //// rCap Drawing
        UIBezierPath *rCapPath = [UIBezierPath bezierPath];
        [rCapPath moveToPoint:CGPointMake(97.86, 14.34)];
        [rCapPath addCurveToPoint:CGPointMake(97.86, 25.66)
                    controlPoint1:CGPointMake(100.98, 17.47)
                    controlPoint2:CGPointMake(100.98, 22.53)];
        [rCapPath addCurveToPoint:CGPointMake(87, 27.33)
                    controlPoint1:CGPointMake(95.46, 28.05)
                    controlPoint2:CGPointMake(89.93, 28.61)];
        [rCapPath addCurveToPoint:CGPointMake(87.27, 27.07)
                    controlPoint1:CGPointMake(87.09, 27.25)
                    controlPoint2:CGPointMake(87.18, 27.16)];
        [rCapPath addCurveToPoint:CGPointMake(87.27, 12.93)
                    controlPoint1:CGPointMake(91.18, 23.17)
                    controlPoint2:CGPointMake(91.18, 16.83)];
        [rCapPath addCurveToPoint:CGPointMake(87.01, 12.66)
                    controlPoint1:CGPointMake(87.18, 12.84)
                    controlPoint2:CGPointMake(87.09, 12.75)];
        [rCapPath addCurveToPoint:CGPointMake(97.86, 14.34)
                    controlPoint1:CGPointMake(89.94, 11.39)
                    controlPoint2:CGPointMake(95.47, 11.95)];
        [rCapPath closePath];
        [rCapPath moveToPoint:CGPointMake(96, 16.88)];
        [rCapPath addLineToPoint:CGPointMake(94, 16.88)];
        [rCapPath addLineToPoint:CGPointMake(94, 19)];
        [rCapPath addLineToPoint:CGPointMake(92, 19)];
        [rCapPath addLineToPoint:CGPointMake(92, 21)];
        [rCapPath addLineToPoint:CGPointMake(94, 21)];
        [rCapPath addLineToPoint:CGPointMake(94, 23)];
        [rCapPath addLineToPoint:CGPointMake(96, 23)];
        [rCapPath addLineToPoint:CGPointMake(96, 21)];
        [rCapPath addLineToPoint:CGPointMake(98, 21)];
        [rCapPath addLineToPoint:CGPointMake(98, 19)];
        [rCapPath addLineToPoint:CGPointMake(96, 19)];
        [rCapPath addLineToPoint:CGPointMake(96, 16.88)];
        [rCapPath closePath];
        [[UIColor whiteColor] setFill];
        [rCapPath fill];
        
        //// lCap Drawing
        UIBezierPath *lCapPath = [UIBezierPath bezierPath];
        [lCapPath moveToPoint:CGPointMake(21.34, 14.34)];
        [lCapPath addCurveToPoint:CGPointMake(21.34, 25.66)
                    controlPoint1:CGPointMake(18.22, 17.47)
                    controlPoint2:CGPointMake(18.22, 22.53)];
        [lCapPath addCurveToPoint:CGPointMake(32.2, 27.33)
                    controlPoint1:CGPointMake(23.74, 28.05)
                    controlPoint2:CGPointMake(29.28, 28.61)];
        [lCapPath addCurveToPoint:CGPointMake(31.93, 27.07)
                    controlPoint1:CGPointMake(32.11, 27.25)
                    controlPoint2:CGPointMake(32.02, 27.16)];
        [lCapPath addCurveToPoint:CGPointMake(31.93, 12.93)
                    controlPoint1:CGPointMake(28.02, 23.17)
                    controlPoint2:CGPointMake(28.02, 16.83)];
        [lCapPath addCurveToPoint:CGPointMake(32.19, 12.66)
                    controlPoint1:CGPointMake(32.02, 12.84)
                    controlPoint2:CGPointMake(32.11, 12.75)];
        [lCapPath addCurveToPoint:CGPointMake(21.34, 14.34)
                    controlPoint1:CGPointMake(29.26, 11.39)
                    controlPoint2:CGPointMake(23.74, 11.95)];
        [lCapPath closePath];
        [lCapPath moveToPoint:CGPointMake(27, 19)];
        [lCapPath addLineToPoint:CGPointMake(27, 21)];
        [lCapPath addLineToPoint:CGPointMake(22, 21)];
        [lCapPath addLineToPoint:CGPointMake(22, 19)];
        [lCapPath addLineToPoint:CGPointMake(27, 19)];
        [lCapPath closePath];
        [[UIColor whiteColor] setFill];
        [lCapPath fill];
    }
}

+ (void)drawCMYPad {
    //// General Declarations
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    //// Color Declarations
    UIColor *c = [UIColor colorWithRed:0
                                 green:0.573
                                  blue:0.821
                                 alpha:1];
    UIColor *k = [UIColor colorWithRed:0.3
                                 green:0.3
                                  blue:0.3
                                 alpha:1];
    UIColor *m = [UIColor colorWithRed:0.801
                                 green:0
                                  blue:0.417
                                 alpha:1];
    UIColor *y = [UIColor colorWithRed:0.967
                                 green:0.896
                                  blue:0.084
                                 alpha:1];
    
    //// pad Drawing
    UIBezierPath *padPath = [UIBezierPath bezierPath];
    [padPath moveToPoint:CGPointMake(60, 21.59)];
    [padPath addCurveToPoint:CGPointMake(95.86, 26.14)
               controlPoint1:CGPointMake(71.31, 14.9)
               controlPoint2:CGPointMake(86.14, 16.42)];
    [padPath addCurveToPoint:CGPointMake(95.86, 67.86)
               controlPoint1:CGPointMake(107.38, 37.66)
               controlPoint2:CGPointMake(107.38, 56.34)];
    [padPath addCurveToPoint:CGPointMake(89.41, 72.75)
               controlPoint1:CGPointMake(93.9, 69.82)
               controlPoint2:CGPointMake(91.72, 71.45)];
    [padPath addCurveToPoint:CGPointMake(80.86, 95.86)
               controlPoint1:CGPointMake(90.04, 81.03)
               controlPoint2:CGPointMake(87.19, 89.53)];
    [padPath addCurveToPoint:CGPointMake(39.14, 95.86)
               controlPoint1:CGPointMake(69.34, 107.38)
               controlPoint2:CGPointMake(50.66, 107.38)];
    [padPath addCurveToPoint:CGPointMake(30.59, 72.75)
               controlPoint1:CGPointMake(32.81, 89.53)
               controlPoint2:CGPointMake(29.96, 81.03)];
    [padPath addCurveToPoint:CGPointMake(24.14, 67.86)
               controlPoint1:CGPointMake(28.28, 71.45)
               controlPoint2:CGPointMake(26.1, 69.82)];
    [padPath addCurveToPoint:CGPointMake(24.14, 26.14)
               controlPoint1:CGPointMake(12.62, 56.34)
               controlPoint2:CGPointMake(12.62, 37.66)];
    [padPath addCurveToPoint:CGPointMake(60, 21.59)
               controlPoint1:CGPointMake(33.86, 16.42)
               controlPoint2:CGPointMake(48.69, 14.9)];
    [padPath closePath];
    [[UIColor whiteColor] setFill];
    [padPath fill];
    [[UIColor whiteColor] setStroke];
    padPath.lineWidth = 10;
    [padPath stroke];
    
    //// CMY
    {
        //// Group C
        {
            UIGraphicsPushContext(context);
            CGContextSetBlendMode(context, kCGBlendModeMultiply);
            CGContextBeginTransparencyLayer(context, NULL);
            
            //// Oval C Drawing
            UIBezierPath *ovalCPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(15.5, 17.5, 59, 59)];
            [c setFill];
            [ovalCPath fill];
            [k setStroke];
            ovalCPath.lineWidth = 1;
            [ovalCPath stroke];
            
            CGContextEndTransparencyLayer(context);
            UIGraphicsPopContext();
        }
        
        //// Group M
        {
            UIGraphicsPushContext(context);
            CGContextSetBlendMode(context, kCGBlendModeMultiply);
            CGContextBeginTransparencyLayer(context, NULL);
            
            //// Oval M Drawing
            UIBezierPath *ovalMPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(45.5, 17.5, 59, 59)];
            [m setFill];
            [ovalMPath fill];
            [k setStroke];
            ovalMPath.lineWidth = 1;
            [ovalMPath stroke];
            
            CGContextEndTransparencyLayer(context);
            UIGraphicsPopContext();
        }
        
        //// Group Y
        {
            UIGraphicsPushContext(context);
            CGContextSetBlendMode(context, kCGBlendModeMultiply);
            CGContextBeginTransparencyLayer(context, NULL);
            
            //// Oval Y Drawing
            UIBezierPath *ovalYPath = [UIBezierPath bezierPathWithOvalInRect:CGRectMake(30.5, 45.5, 59, 59)];
            [y setFill];
            [ovalYPath fill];
            [k setStroke];
            ovalYPath.lineWidth = 1;
            [ovalYPath stroke];
            
            CGContextEndTransparencyLayer(context);
            UIGraphicsPopContext();
        }
    }
}


@end
