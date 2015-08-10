//
//  UIImageValueTransformer.m
//  Remote
//
//  Created by Jason Cardwell on 3/28/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import UIKit;
#import "MSValueTransformers.h"


@implementation MSUIImageValueTransformer

+ (Class)transformedValueClass {return [NSData class];}

+ (BOOL)allowsReverseTransformation {return YES;}

// Takes a UIImage and returns NSData
- (id)transformedValue:(id)value {return UIImagePNGRepresentation(value);}

// Takes NSData from Core Data and returns a UIImage
- (id)reverseTransformedValue:(id)value {return [UIImage imageWithData:value];}

@end
