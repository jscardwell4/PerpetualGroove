//
//  MSView.h
//  Remote
//
//  Created by Jason Cardwell on 3/23/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

typedef NS_OPTIONS(uint8_t, MSViewStyle) {
    // drawing options
    MSViewStyleDefault                = 0b00000000,
	  MSViewStyleDrawShadow             = 0b00000010,
    MSViewStyleDrawGloss              = 0b00000100,

    // border styles
	  MSViewStyleBorderLine             = 0b00001000,
	  MSViewStyleBorderRoundedRect      = 0b00010000,
    MSViewStyleBorderMask             = 0b00011000,

    // preset styles
	  MSViewStyleCustom                 = 0b00000000,
	  MSViewStylePreset1                = 0b00100000,
	  MSViewStylePreset2                = 0b01000000,
	  MSViewStylePreset3                = 0b01100000,
	  MSViewStylePreset4                = 0b10000000,
    MSViewStylePresetMask             = 0b11100000

};



@interface MSView : UIView

@property (nonatomic, assign) MSViewStyle   style;
@property (nonatomic, strong) UIColor     * borderColor;
@property (nonatomic, strong) UIColor     * glossColor;
@property (nonatomic, assign) CGFloat       borderThickness;
@property (nonatomic, assign) CGSize        borderRadii;

@end
