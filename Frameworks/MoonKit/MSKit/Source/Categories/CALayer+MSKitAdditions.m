//
//  CALayer+MSKitAdditions.m
//  Remote
//
//  Created by Jason Cardwell on 4/12/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "CALayer+MSKitAdditions.h"

@implementation CALayer (MSKitAdditions)

- (UIImage *)renderedImage {
    UIGraphicsBeginImageContextWithOptions(self.bounds.size, 
                                           NO, 
                                           self.contentsScale);
    [self renderInContext:UIGraphicsGetCurrentContext()];
    UIImage * image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return image;
}

- (void)setValue:(id)value 
      forKeyPath:(NSString *)keyPath 
        duration:(CFTimeInterval)duration 
           delay:(CFTimeInterval)delay
{
    
    [CATransaction begin];
    [CATransaction setDisableActions:YES];
    [self setValue:value forKeyPath:keyPath];
    CABasicAnimation * anim;
    anim = [CABasicAnimation animationWithKeyPath:keyPath];
    anim.duration = duration;
    anim.beginTime = CACurrentMediaTime() + delay;
    anim.fillMode = kCAFillModeBoth;
    anim.fromValue = [[self presentationLayer] valueForKeyPath:keyPath];
    anim.toValue = value;
    [self addAnimation:anim forKey:keyPath];
    [CATransaction commit];
    
}

@end

