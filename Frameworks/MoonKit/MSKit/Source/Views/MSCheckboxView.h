//
//  MSCheckboxView.h
//  Remote
//
//  Created by Jason Cardwell on 3/22/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;
@import UIKit;

#import "MSView.h"


@class MSCheckboxView;
@protocol MSCheckboxViewDelegate <NSObject>

@optional
- (void)checkboxValueDidChange:(MSCheckboxView *)checkbox checked:(BOOL)checked;

@end

@interface MSCheckboxView : MSView


@property (nonatomic, weak) IBOutlet id<MSCheckboxViewDelegate>  delegate;
@property (nonatomic, copy) NSString                  * checkmarkText;
@property (nonatomic, strong) UIColor                 * boxFrameColor;
@property (nonatomic, strong) UIColor                 * checkmarkColor;
@property (nonatomic, strong, readonly) UIFont        * checkmarkFont;
@property (nonatomic, assign) BOOL                      checked;
@property (nonatomic, assign) CGRect                    boxFrame;
@property (nonatomic, assign) CGPoint                   checkmarkCenter;
@property (nonatomic, copy)   NSString                * checkmarkFontName;
@property (nonatomic, assign) CGFloat                   checkmarkPointSize;

@end
