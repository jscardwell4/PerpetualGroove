//
//  MSScrollWheel.h
//  Remote
//
//  Created by Jason Cardwell on 5/4/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;


typedef NSString * (^ValueToLabelTextConverter)(CGFloat);

@interface MSScrollWheel : UIControl

@property (nonatomic, assign) float theta;
@property (nonatomic, assign) float value;
@property (nonatomic, strong) UILabel * label;
@property (nonatomic, copy) ValueToLabelTextConverter labelTextGenerator;

+ (id) scrollWheel;

@end
