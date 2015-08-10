//
//  MSTouchReporterView.h
//  Remote
//
//  Created by Jason Cardwell on 4/3/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;

#import "MSView.h"

@class MSTouchReporterView;

@protocol MSTouchReporterViewDelegate <NSObject>

@optional

- (void)touchReporter:(MSTouchReporterView *)reporter 
		 touchesBegan:(NSSet *)touches
			withEvent:(UIEvent *)event;

- (void)touchReporter:(MSTouchReporterView *)reporter 
		 touchesMoved:(NSSet *)touches
			withEvent:(UIEvent *)event;

- (void)touchReporter:(MSTouchReporterView *)reporter
	 touchesCancelled:(NSSet *)touches
			withEvent:(UIEvent *)event;

- (void)touchReporter:(MSTouchReporterView *)reporter 
		 touchesEnded:(NSSet *)touches
			withEvent:(UIEvent *)event;

@end

@interface MSTouchReporterView : MSView

@property (nonatomic, weak) IBOutlet id<MSTouchReporterViewDelegate> delegate;

@end
