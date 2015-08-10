//
//  MSNumberPadView.h
//  Remote
//
//  Created by Jason Cardwell on 3/30/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

#import "MSView.h"

@class MSNumberPadView;

@protocol MSNumberPadViewDelegate <NSObject>

- (void)numberPad:(MSNumberPadView *)numberPad receivedEntry:(NSString *)entry;

@end

@interface MSNumberPadView : MSView
+ (MSNumberPadView *)numberPadViewWithDelegate:(id<MSNumberPadViewDelegate>)delegate 
									 textField:(UITextField *)textField;

@property (nonatomic, weak) id<MSNumberPadViewDelegate> delegate;
@end
