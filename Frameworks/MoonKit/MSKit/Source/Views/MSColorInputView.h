//
//  MSColorInputView.h
//  Remote
//
//  Created by Jason Cardwell on 5/3/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

#import "MSView.h"

@protocol MSColorInput <NSObject>

- (void)setColor:(UIColor *)color;

@end

@interface MSColorInputView : MSView

+ (MSColorInputView *)colorInputView;

@property (nonatomic, strong) UIColor * initialColor;

@end
