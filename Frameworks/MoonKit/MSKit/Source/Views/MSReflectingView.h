//
//  MSReflectingView.h
//  Remote
//
//  Created by Jason Cardwell on 3/22/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSView.h"
@import QuartzCore;

@interface MSReflectingView : MSView

@property (nonatomic, assign) CGFloat gap;
@property (nonatomic, strong) NSString * imageName;
@property (nonatomic, assign) BOOL hasReflection;
@property (nonatomic, assign) CGFloat angle;
@property (nonatomic, assign) CGFloat eyeDistance;
@property (nonatomic, assign) CGFloat imageYScale;
@property (nonatomic, assign) BOOL usesGradient;
@property (nonatomic, strong) UIImage * image;

@end
