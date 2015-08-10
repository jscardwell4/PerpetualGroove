//
//  MSTouchReporterView.m
//  Remote
//
//  Created by Jason Cardwell on 4/3/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSTouchReporterView.h"
#import "MSKitMacros.h"

@implementation MSTouchReporterView
{
    BOOL _reportTouchesBegan;
    BOOL _reportTouchesMoved;
    BOOL _reportTouchesCanceled;
    BOOL _reportTouchesEnded;
}

- (void)setDelegate:(id<MSTouchReporterViewDelegate>)delegate
{
	_delegate = delegate;
    _reportTouchesBegan    = [_delegate respondsToSelector:@selector(touchReporter:touchesBegan:withEvent:)];
    _reportTouchesMoved    = [_delegate respondsToSelector:@selector(touchReporter:touchesMoved:withEvent:)];
    _reportTouchesCanceled = [_delegate respondsToSelector:@selector(touchReporter:touchesCancelled:withEvent:)];
    _reportTouchesEnded    = [_delegate respondsToSelector:@selector(touchReporter:touchesEnded:withEvent:)];
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_reportTouchesBegan) [_delegate touchReporter:self touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_reportTouchesMoved) [_delegate touchReporter:self touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_reportTouchesEnded) [_delegate touchReporter:self touchesEnded:touches withEvent:event];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event
{
    if (_reportTouchesCanceled) [_delegate touchReporter:self touchesCancelled:touches withEvent:event];
}

@end

