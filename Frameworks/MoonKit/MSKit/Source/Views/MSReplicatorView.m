//
//  MSReplicatorView.m
//  Remote
//
//  Created by Jason Cardwell on 4/11/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSReplicatorView.h"
#import <QuartzCore/QuartzCore.h>
@implementation MSReplicatorView


+ (Class)layerClass {
    return [CAReplicatorLayer class];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self setupReplicator];
    }
    return self;
}

- (void)setupReplicator {
    CGFloat height = self.bounds.size.height;
    CGFloat shrinkFactor = 0.25f;
    
    CATransform3D t = CATransform3DMakeScale(1.0, -shrinkFactor, 1.0);
    
    float offsetFromBottom = height * ((1.0f - shrinkFactor) / 2.0f);
    float inverse = 1.0 / shrinkFactor;
    float desiredGap = 10.0f;
    t = CATransform3DTranslate(t,
                               0.0,
                               -offsetFromBottom * inverse - height - inverse * desiredGap, 
                               0.0f);
    CAReplicatorLayer * layer = (CAReplicatorLayer *) self.layer;
    layer.instanceTransform = t;
    layer.instanceCount = 2;
    layer.instanceRedOffset = -0.75;
    layer.instanceGreenOffset = -0.75;
    layer.instanceBlueOffset = -0.75;
}

@end

