//
//  UIImage+MSKitAdditions.m
//  Canine Acupoints
//
//  Created by Jason Cardwell on 4/8/11.
//  Copyright 2011 Moondeer Studios. All rights reserved.
//

#import "UIImage+MSKitAdditions.h"
#import <QuartzCore/QuartzCore.h>
#import "MSKitLoggingFunctions.h"
#import "MSKitMacros.h"
#import "MSKitGeometryFunctions.h"
@implementation UIImage (MSKitAdditions)


- (ImageInfo)imageInfo {
    CGBitmapInfo bitmapInfo = CGImageGetBitmapInfo(self.CGImage);
    CGImageAlphaInfo alphaInfo = CGImageGetAlphaInfo(self.CGImage);
    CGBitmapInfo byteOrderInfo = bitmapInfo & kCGBitmapByteOrderMask;
    BOOL floatComponents = (bitmapInfo & kCGBitmapFloatComponents) ? YES : NO;
    size_t width = CGImageGetWidth(self.CGImage);
    size_t height = CGImageGetHeight(self.CGImage);
    size_t bitsPerPixel = CGImageGetBitsPerPixel(self.CGImage);
    size_t bitsPerComponent = CGImageGetBitsPerComponent(self.CGImage);
    size_t bytesPerRow = CGImageGetBytesPerRow(self.CGImage);
    CGColorRenderingIntent renderingIntent = CGImageGetRenderingIntent(self.CGImage);
    CGColorSpaceModel colorSpaceModel = CGColorSpaceGetModel(CGImageGetColorSpace(self.CGImage));
    size_t numberOfComponents = CGColorSpaceGetNumberOfComponents(CGImageGetColorSpace(self.CGImage));
    CGFloat scale = self.scale;
    return (ImageInfo){
        .bitmapInfo = bitmapInfo,
        .alphaInfo = alphaInfo,
        .byteOrderInfo = byteOrderInfo,
        .floatComponents = floatComponents,
        .width = width,
        .height = height,
        .bitsPerPixel = bitsPerPixel,
        .bitsPerComponent = bitsPerComponent,
        .bytesPerRow = bytesPerRow,
        .renderingIntent = renderingIntent,
        .colorSpaceModel = colorSpaceModel,
        .numberOfComponents = numberOfComponents,
        .scale = scale
    };
}

- (NSString *)imageInfoDescription {    
    return ImageInfoString(self.imageInfo);
}

- (UIImage *)recoloredImageWithColor:(UIColor *)inputColor {
	
	if (!inputColor)
		return self;
	
	CIImage   * beginImage = [CIImage imageWithCGImage:[self CGImage]];
	CIContext * context = [CIContext contextWithOptions:nil];
	
	CGFloat    red, green, blue, white, alpha;
	CGColorRef cgColor = [inputColor CGColor];
	NSUInteger numOfComponents = CGColorGetNumberOfComponents(cgColor);
	
	if (numOfComponents == 2) {
		[inputColor getWhite:&white alpha:&alpha];
		red = green = blue = white;
	}
	else {
		[inputColor getRed:&red green:&green blue:&blue alpha:&alpha];
	}
	
	CIColor  * overlayColor = [CIColor colorWithRed:red green:green blue:blue alpha:alpha];
	CIFilter * filter = [CIFilter filterWithName:@"CISourceInCompositing"];
	CIImage  * inputBackgroundImage = [CIImage imageWithColor:overlayColor];
	[filter setValue:inputBackgroundImage forKey:@"inputImage"];
	[filter setValue:beginImage forKey:@"inputBackgroundImage"];
	CIImage * outputImage = filter.outputImage;
	CGRect    outputRect = beginImage.extent;
	CGFloat   scale = MainScreenScale;
	
	CGImageRef cgimg = [context createCGImage:outputImage fromRect:outputRect];
	
	UIImage *newImage = nil;
	
	if (cgimg != NULL) {
		newImage = [UIImage imageWithCGImage:cgimg 
									   scale:scale 
								 orientation:UIImageOrientationUp];
	}
	
	CGImageRelease(cgimg);
	
	return newImage;
}

+ (UIImage *)imageFromAlphaOfImage:(UIImage *)image color:(UIColor *)color {
    UIImage * returnImage;
    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);
    
    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -image.size.height);
    CGContextClipToMask(context, imageRect, image.CGImage);
    [color setFill];
    CGContextFillRect(context, imageRect);
    
    returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return returnImage;
}

- (CGSize)sizeThatFits:(CGSize)size {
    
  if (size.height == 0 || size.width == 0) {
    return CGSizeZero;
  }
	
	CGSize originalSize = self.size;
	CGSize goalSize = size;
	goalSize.width /= self.scale;
	goalSize.height /= self.scale;
	
	CGSize fittedSize = CGSizeAspectMappedToSize(originalSize, goalSize, YES);
    return (CGSizeLessThanSize(originalSize, fittedSize) ? originalSize :fittedSize);
}

+ (UIImage *)captureImageOfView:(UIView *)view {
    UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (NSData *)bitmapData {
    CGImageRef cgImage = [self CGImage];
    CGDataProviderRef dataProvider = CGImageGetDataProvider(cgImage);
    NSData * bitmapData = CFBridgingRelease(CGDataProviderCopyData(dataProvider));
    return bitmapData;
}

- (NSData *)vImageConformantDataForImage {
    ImageInfo imageInfo = [self imageInfo];

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(NULL,
                                                 imageInfo.width,
                                                 imageInfo.height,
                                                 imageInfo.bitsPerComponent,
                                                 imageInfo.bytesPerRow,
                                                 colorSpace,
                                                 (CGBitmapInfo)kCGImageAlphaPremultipliedFirst);


    CGContextDrawImage(context,
                       CGRectMake(0.0f, 0.0f, imageInfo.width, imageInfo.height),
                       self.CGImage);

    CGImageRef imageRef = CGBitmapContextCreateImage(context);

    NSData * imageData = (__bridge_transfer NSData *)CGDataProviderCopyData(CGImageGetDataProvider(imageRef));

    CGImageRelease(imageRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return imageData;
}

- (NSData *)bitmapData:(CGBitmapInfo)bitmapInfo colorSpace:(CGColorSpaceRef)colorSpace {

    if (colorSpace == NULL)
        return nil;
    
    ImageInfo imageInfo = self.imageInfo;
    NSUInteger dataLength = imageInfo.height * imageInfo.bytesPerRow;

    void * contextBuffer = malloc(dataLength);
    CGContextRef context = CGBitmapContextCreate(contextBuffer,
                                                 imageInfo.width, 
                                                 imageInfo.height, 
                                                 imageInfo.bitsPerComponent, 
                                                 imageInfo.bytesPerRow, 
                                                 colorSpace,
                                                 bitmapInfo);
    
    
    CGContextDrawImage(context, 
                       (CGRect){.size = CGSizeMake(imageInfo.width, imageInfo.height)},
                       self.CGImage);
    
    NSData * imageData = [NSData dataWithBytesNoCopy:CGBitmapContextGetData(context)
                                              length:dataLength
                                        freeWhenDone:NO];
    free(contextBuffer);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    return imageData;
    
}

+ (UIImage *)imageWithBitmapData:(NSData *)bitmapData imageInfo:(ImageInfo)info {
    
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, 
                                                              bitmapData.bytes,
                                                              bitmapData.length, 
                                                              NULL);
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGImageRef cgImage =  CGImageCreate(info.width,
                                        info.height,
                                        info.bitsPerComponent,
                                        info.bitsPerPixel,
                                        info.bytesPerRow,
                                        colorSpace,
                                        info.bitmapInfo,
                                        provider,
                                        NULL,
                                        false,
                                        kCGRenderingIntentDefault);
    UIImage * image = [UIImage imageWithCGImage:cgImage
                                          scale:info.scale
                                    orientation:UIImageOrientationUp];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return image;
}

+ (UIImage *)imageFromLayer:(CALayer *)layer
{
    if (!layer) return nil;

    UIGraphicsBeginImageContextWithOptions(layer.bounds.size,
                                           layer.opaque,
                                           layer.rasterizationScale);
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

/*
+ (UIImage *)imageFromImage:(UIImage *)image withDecode:(const CGFloat *)decode {
    return [UIImage imageWithCGImage:CGImageCreate(image.size.width,
                                                   image.size.height,
                                                   CGImageGetBitsPerComponent(image.CGImage),
                                                   CGImageGetBitsPerPixel(image.CGImage),
                                                   CGImageGetBytesPerRow(image.CGImage),
                                                   CGImageGetColorSpace(image.CGImage),
                                                   CGImageGetBitmapInfo(image.CGImage),
                                                   CGImageGetDataProvider(image.CGImage),
                                                   decode,
                                                   CGImageGetShouldInterpolate(image.CGImage),
                                                   CGImageGetRenderingIntent(image.CGImage))];
}

+ (UIImage *)imageMaskFromImage:(UIImage *)image withDecode:(const CGFloat *)decode {
    return [UIImage imageWithCGImage:CGImageMaskCreate(image.size.width,
                                                       image.size.height,
                                                       CGImageGetBitsPerComponent(image.CGImage),
                                                       CGImageGetBitsPerPixel(image.CGImage),
                                                       CGImageGetBytesPerRow(image.CGImage),
                                                       CGImageGetDataProvider(image.CGImage),
                                                       decode,
                                                       CGImageGetRenderingIntent(image.CGImage))];
}

- (UIImage *)inverted {
    const CGFloat decode[] = { 1.0, 0.0, 1.0, 0.0, 1.0, 0.0, 0.0, 1.0 };

    return [UIImage imageWithCGImage:CGImageCreate(self.size.width,
                                                   self.size.height,
                                                   CGImageGetBitsPerComponent(self.CGImage),
                                                   CGImageGetBitsPerPixel(self.CGImage),
                                                   CGImageGetBytesPerRow(self.CGImage),
                                                   CGImageGetColorSpace(self.CGImage),
                                                   CGImageGetBitmapInfo(self.CGImage),
                                                   CGImageGetDataProvider(self.CGImage),
                                                   decode,
                                                   CGImageGetShouldInterpolate(self.CGImage),
                                                   CGImageGetRenderingIntent(self.CGImage))];
}

- (UIImage *)invertedAlpha {
    const CGFloat decode[] = { 0.0, 1.0, 0.0, 1.0, 0.0, 1.0, 1.0, 0.0 };

    return [UIImage imageWithCGImage:CGImageCreate(self.size.width,
                                                   self.size.height,
                                                   CGImageGetBitsPerComponent(self.CGImage),
                                                   CGImageGetBitsPerPixel(self.CGImage),
                                                   CGImageGetBytesPerRow(self.CGImage),
                                                   CGImageGetColorSpace(self.CGImage),
                                                   CGImageGetBitmapInfo(self.CGImage),
                                                   CGImageGetDataProvider(self.CGImage),
                                                   decode,
                                                   CGImageGetShouldInterpolate(self.CGImage),
                                                   CGImageGetRenderingIntent(self.CGImage))];
}

+ (UIImage *)imageFromAlphaOfImage:(UIImage *)image 
                     colorGradient:(NSArray *)colors
                         locations:(CGFloat *)locations
                        startPoint:(CGPoint)startPoint 
                          endPoint:(CGPoint)endPoint 
                         antialias:(BOOL)shouldAntialias
{
    UIImage * returnImage;
    CGRect    imageRect = CGRectMake(0, 0, image.size.width, image.size.height);

    UIGraphicsBeginImageContextWithOptions(image.size, NO, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -image.size.height);
    CGContextClipToMask(context, imageRect, image.CGImage);

    CGGradientRef   gradient;
    CGColorSpaceRef colorspace;
    size_t          num_locations = [colors count];
    CGFloat         components[num_locations * 4];
    int             i = 0;
    for (UIColor * color in colors) {
        //
        const CGFloat * colorComponents;
        size_t          numberOfComponents = CGColorGetNumberOfComponents(color.CGColor);
        colorComponents = CGColorGetComponents(color.CGColor);
        if (numberOfComponents == 2) {
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[1];
        } else {
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[1];
            components[i++] = colorComponents[2];
            components[i++] = colorComponents[3];
        }
    }

    colorspace = CGColorSpaceCreateDeviceRGB();
    gradient = CGGradientCreateWithColorComponents(colorspace, components,
                                                   locations, num_locations);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    returnImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);

    return returnImage;
}


- (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage {
    CGImageRef maskRef = maskImage.CGImage;

    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);

    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);

    return [UIImage imageWithCGImage:masked];
}

+ (UIImage *)imageNamed:(NSString *)name withColor:(UIColor *)color {
    // load the image
    UIImage * img = [UIImage imageNamed:name];

    // begin a new image context, to draw our colored image onto
    UIGraphicsBeginImageContext(img.size);

    // get a reference to that context we created
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    // set the fill color
    [color setFill];

    // translate/flip the graphics context (for transforming from CG* coords to UI* coords
    CGContextTranslateCTM(context, 0, img.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    // set the blend mode to color burn, and the original image
    CGContextSetBlendMode(context, kCGBlendModeMultiply);
    CGRect rect = CGRectMake(0, 0, img.size.width, img.size.height);
    // CGContextDrawImage(context, rect, img.CGImage);

    // set a mask that matches the shape of the image, then draw (color burn) a colored rectangle
    CGContextClipToMask(context, rect, img.CGImage);
    CGContextAddRect(context, rect);
    CGContextDrawPath(context, kCGPathFill);

    // generate a new UIImage from the graphics context we drew onto
    UIImage * coloredImg = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    // return the color-burned image
    return coloredImg;
}

+ (UIImage *)screenshot {
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;

    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);

    CGContextRef context = UIGraphicsGetCurrentContext();

    // Iterate over every window from back to front
    for (UIWindow * window in [[UIApplication sharedApplication] windows]) {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen]) {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * [[window layer] anchorPoint].x,
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);

            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];

            // Restore the context
            CGContextRestoreGState(context);
        }
    }

    // Retrieve the screenshot image
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *)thumbnailWithSize:(CGSize)size {
    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    else
        UIGraphicsBeginImageContext(size);
    CGSize imageSize = [self sizeThatFits:size];
    CGRect imageRect = CGRectMake(size.width - imageSize.width / 2.0,
                                  size.height - imageSize.height / 2.0,
                                  imageSize.width,
                                  imageSize.height);
    [self drawInRect:imageRect];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (UIImage *)imageDrawnInRect:(CGRect)imageRect
               withCanvasSize:(CGSize)canvasSize 
                   knockedOut:(BOOL)knockedOut 
{
    UIGraphicsBeginImageContextWithOptions(canvasSize, NO, [UIScreen mainScreen].scale);

    CGRect       canvasRect = { .origin = CGPointZero, .size = canvasSize };
    CGContextRef context = UIGraphicsGetCurrentContext();
    [[UIColor blackColor] setFill];
    CGContextFillRect(context, canvasRect);

    if (knockedOut) {
        UIGraphicsPushContext(context);
        CGContextScaleCTM(context, 1, -1);
        CGContextTranslateCTM(context, 0, -canvasSize.height);
        CGRect transformedRect;
        transformedRect.size = imageRect.size;
        transformedRect.origin.x = imageRect.origin.x;
        transformedRect.origin.y = canvasSize.height - imageRect.size.height - imageRect.origin.y;
        CGContextClipToMask(context, transformedRect, self.CGImage);
        UIGraphicsPopContext();
        CGContextClearRect(context, canvasRect);
    } else
        [self drawInRect:imageRect];

    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *)imageDrawnInRect:(CGRect)imageRect 
                    withFrame:(CGRect)frame
           andBackgroundColor:(UIColor *)backgroundColor 
{
    UIGraphicsBeginImageContextWithOptions(frame.size, YES, [UIScreen mainScreen].scale);

    CGContextRef context = UIGraphicsGetCurrentContext();

    [backgroundColor setFill];
    CGContextFillRect(context, frame);

    [self drawInRect:imageRect];

    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    return image;
}

- (UIImage *)imageWithMaskingColors:(const CGFloat *)maskingColors {
    CGImageRef maskedImage = [self createMask];
    CGImageRef newImage = CGImageCreateWithMaskingColors(maskedImage, maskingColors);

    return [UIImage imageWithCGImage:newImage];
}

- (CGImageRef)createMask {
    CGImageRef             ref = self.CGImage;
    int                    mWidth = CGImageGetWidth(ref);
    int                    mHeight = CGImageGetHeight(ref);
    int                    count = mWidth * mHeight * 4;
    void                 * bufferdata = malloc(count);

    CGColorSpaceRef        colorSpaceRef = CGColorSpaceCreateDeviceRGB();
    CGBitmapInfo           bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGContextRef           cgctx = CGBitmapContextCreate(bufferdata, mWidth, mHeight, 8, mWidth * 4, colorSpaceRef, kCGImageAlphaPremultipliedFirst);

    CGRect                 rect = { 0, 0, mWidth, mHeight };

    CGContextDrawImage(cgctx, rect, ref);
    bufferdata = CGBitmapContextGetData(cgctx);

    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, bufferdata, mWidth * mHeight * 4, NULL);
    CGImageRef        savedimageref = CGImageCreate(mWidth, mHeight, 8, 32, mWidth * 4, colorSpaceRef, bitmapInfo, provider, NULL, NO, renderingIntent);
    CFRelease(colorSpaceRef);
    return savedimageref;
}

+ (unsigned char *)convertUIImageToBitmapRGBA8:(UIImage *)image {
    CGImageRef imageRef = image.CGImage;

    // Create a bitmap context to draw the uiimage into
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:imageRef];

    if (!context)
        return NULL;

    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);

    CGRect rect = CGRectMake(0, 0, width, height);

    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, imageRef);

    // Get a pointer to the data
    unsigned char * bitmapData = (unsigned char *)CGBitmapContextGetData(context);

    // Copy the data and release the memory (return memory allocated with new)
    size_t          bytesPerRow = CGBitmapContextGetBytesPerRow(context);
    size_t          bufferLength = bytesPerRow * height;

    unsigned char * newBitmap = NULL;

    if (bitmapData) {
        newBitmap = (unsigned char *)malloc(sizeof(unsigned char) * bytesPerRow * height);

        if (newBitmap)          // Copy the data
            for (int i = 0; i < bufferLength; ++i)
                newBitmap[i] = bitmapData[i];

        free(bitmapData);
    } else
        // NSLog(@"Error getting bitmap pixel data\n");

    CGContextRelease(context);

    return newBitmap;
}

+ (CGContextRef)newBitmapRGBA8ContextFromImage:(CGImageRef)image {
    CGContextRef    context = NULL;
    CGColorSpaceRef colorSpace;
    uint32_t      * bitmapData;

    size_t          bitsPerPixel = 32;
    size_t          bitsPerComponent = 8;
    size_t          bytesPerPixel = bitsPerPixel / bitsPerComponent;

    size_t          width = CGImageGetWidth(image);
    size_t          height = CGImageGetHeight(image);

    size_t          bytesPerRow = width * bytesPerPixel;
    size_t          bufferLength = bytesPerRow * height;

    colorSpace = CGColorSpaceCreateDeviceRGB();

    if (!colorSpace) {
        // NSLog(@"Error allocating color space RGB\n");
        return NULL;
    }

    // Allocate memory for image data
    bitmapData = (uint32_t *)malloc(bufferLength);

    if (!bitmapData) {
        // NSLog(@"Error allocating memory for bitmap\n");
        CGColorSpaceRelease(colorSpace);
        return NULL;
    }

    // Create bitmap context

    context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    bitsPerComponent,
                                    bytesPerRow,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);    // RGBA
    if (!context) {
        free(bitmapData);
        // NSLog(@"Bitmap context not created");
    }

    CGColorSpaceRelease(colorSpace);

    return context;
}

+ (UIImage *)convertBitmapRGBA8ToUIImage:(unsigned char *)buffer
                               withWidth:(int)width
                              withHeight:(int)height {
    size_t            bufferLength = width * height * 4;
    CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, buffer, bufferLength, NULL);
    size_t            bitsPerComponent = 8;
    size_t            bitsPerPixel = 32;
    size_t            bytesPerRow = 4 * width;

    CGColorSpaceRef   colorSpaceRef = CGColorSpaceCreateDeviceRGB();

    if (colorSpaceRef == NULL) {
        // NSLog(@"Error allocating color space");
        CGDataProviderRelease(provider);
        return nil;
    }

    CGBitmapInfo           bitmapInfo = kCGBitmapByteOrderDefault;
    CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;

    CGImageRef             iref = CGImageCreate(width,
                                                height,
                                                bitsPerComponent,
                                                bitsPerPixel,
                                                bytesPerRow,
                                                colorSpaceRef,
                                                bitmapInfo,
                                                provider, // data provider
                                                NULL,     // decode
                                                YES,      // should interpolate
                                                renderingIntent);

    uint32_t * pixels = (uint32_t *)malloc(bufferLength);

    if (pixels == NULL) {
        // NSLog(@"Error: Memory not allocated for bitmap");
        CGDataProviderRelease(provider);
        CGColorSpaceRelease(colorSpaceRef);
        CGImageRelease(iref);
        return nil;
    }

    CGContextRef context = CGBitmapContextCreate(pixels,
                                                 width,
                                                 height,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpaceRef,
                                                 kCGImageAlphaPremultipliedLast);

    if (context == NULL) {
        // NSLog(@"Error context not created");
        free(pixels);
    }

    UIImage * image = nil;
    if (context) {
        CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, width, height), iref);

        CGImageRef imageRef = CGBitmapContextCreateImage(context);

        // Support both iPad 3.2 and iPhone 4 Retina displays with the correct scale
        if ([UIImage respondsToSelector:@selector(imageWithCGImage:scale:orientation:)]) {
            float scale = [[UIScreen mainScreen] scale];
            image = [UIImage imageWithCGImage:imageRef scale:scale orientation:UIImageOrientationUp];
        } else
            image = [UIImage imageWithCGImage:imageRef];

        CGImageRelease(imageRef);
        CGContextRelease(context);
    }

    CGColorSpaceRelease(colorSpaceRef);
    CGImageRelease(iref);
    CGDataProviderRelease(provider);

    if (pixels)
        free(pixels);
    return image;
}

+ (UIImage *)gradientPatternImageOfSize:(CGSize)size
                             withColors:(NSArray *)colors
                              locations:(CGFloat *)locations
                             startPoint:(CGPoint)startPoint
                               endPoint:(CGPoint)endPoint {
    UIGraphicsBeginImageContextWithOptions(size, YES, [UIScreen mainScreen].scale);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(context, 1, -1);
    CGContextTranslateCTM(context, 0, -size.height);
    CGGradientRef   gradient;
    CGColorSpaceRef colorspace;
    size_t          num_locations = [colors count];
    CGFloat         components[num_locations * 4];
    int             i = 0;
    for (UIColor * color in colors) {
        //
        const CGFloat * colorComponents;
        size_t          numberOfComponents = CGColorGetNumberOfComponents(color.CGColor);
        colorComponents = CGColorGetComponents(color.CGColor);
        if (numberOfComponents == 2) {
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[1];
        } else {
            components[i++] = colorComponents[0];
            components[i++] = colorComponents[1];
            components[i++] = colorComponents[2];
            components[i++] = colorComponents[3];
        }
    }

    colorspace = CGColorSpaceCreateDeviceRGB();

    gradient = CGGradientCreateWithColorComponents(colorspace, components,
                                                   locations, num_locations);

    CGContextDrawLinearGradient(context, gradient, startPoint, endPoint, 0);

    UIImage * patternImage = UIGraphicsGetImageFromCurrentImageContext ();
    UIGraphicsEndImageContext();

    CGGradientRelease(gradient);
    CGColorSpaceRelease(colorspace);

    return patternImage;
}



*/

@end

