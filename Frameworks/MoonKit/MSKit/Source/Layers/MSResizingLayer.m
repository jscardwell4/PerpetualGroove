//
//  MSResizingLayer.m
//  Remote
//
//  Created by Jason Cardwell on 4/17/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSResizingLayer.h"
#import "MSKitGeometryFunctions.h"
#import "MSKitMacros.h"

@implementation MSResizingLayer

- (id)initWithSuperlayer:(CALayer *)layer {
    self = [super init];
    if (self) {
        [layer addObserver:self 
               forKeyPath:@"bounds" 
                  options:NSKeyValueObservingOptionNew 
                  context:NULL];
        self.needsDisplayOnBoundsChange = YES;
        self.bounds = layer.bounds;
        self.position = CGRectGetCenter(self.bounds);
//        self.contentsGravity = kCAGravityCenter;
//        // NSLog(@"%@ edgeAntialiasingMask = %i",
//                   ClassTagSelectorString, self.edgeAntialiasingMask);
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{
    if (object == self.superlayer && [@"bounds" isEqualToString:keyPath]) {
        BOOL resizeMask = ValueIsNotNil(self.mask);
        
        [CATransaction begin];
        [CATransaction setDisableActions:YES];
        self.bounds = self.superlayer.bounds;
        self.position = CGRectGetCenter(self.bounds);
        if (resizeMask) {
            self.mask.bounds = self.bounds;
            self.mask.position = CGRectGetCenter(self.bounds);
        }
        [CATransaction commit];
    } 
    
    else 
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}
@end
