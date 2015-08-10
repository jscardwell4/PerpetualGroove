//
// MSPopupBarButtonView.m
// MSKit
//
// Created by Jason Cardwell on 1/18/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSPopupBarButton_Private.h"

@implementation MSPopupBarButtonView {
    BOOL   _removalRequested;
}

+ (MSPopupBarButtonView *)popupViewForBarButton:(MSPopupBarButton *)popupBarButton {
    MSPopupBarButtonView * v = [MSPopupBarButtonView new];

    v.popupBarButton = popupBarButton;

    return v;
}

- (id)init {
    if (self = [super init]) {
        self.translatesAutoresizingMaskIntoConstraints = NO;
        self.opaque                                    = NO;
        self.userInteractionEnabled                    = YES;
        self.exclusiveTouch                            = YES;
    }

    return self;
}

- (void)generateButtons {
  //TODO: Fixme
//    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//
//    NSMutableArray  * buttonNames = [@[] mutableCopy];
//    NSMutableString * constraints = [@"V:|" mutableCopy];
//    int               itemNumber  = 0;
//
//    for (MSPopupBarButtonItem * item in _popupBarButton.items) {
//
//        UIButton * button = [UIButton buttonWithType:UIButtonTypeCustom];
//
//        button.translatesAutoresizingMaskIntoConstraints = NO;
//        [button addConstraints:
//         [NSLayoutConstraint constraintsByParsingString:@"b.width = 44\nb.height = 44"
//                                                  views:@{@"b" : button}]];
//
//        [button addTarget:item.target
//                   action:item.action
//         forControlEvents:UIControlEventTouchUpInside];
//        [button addTarget:_popupBarButton
//                   action:@selector(hidePopover)
//         forControlEvents:UIControlEventTouchUpInside];
//
//        if (item.image) [button setImage:[UIImage imageFromAlphaOfImage:item.image color:WhiteColor]
//                                forState:UIControlStateNormal];
//
//        if (item.attributedTitle) [button setAttributedTitle:item.attributedTitle
//                                                    forState:UIControlStateNormal];
//        
//        else if (item.title) [button setTitle:item.title forState:UIControlStateNormal];
//
//        [self addSubview:button];
//        [self addConstraints:
//         [NSLayoutConstraint constraintsByParsingString:@"b.centerX = self.centerX"
//                                                  views:@{@"self" : self, @"b" : button}]];
//
//        NSString * k = [NSString stringWithFormat:@"b%i", itemNumber++];
//        
//        [constraints appendFormat:@"[%@]", k];
//
//        [buttonNames addObject:k];
//    }
//
//    [constraints appendString:@"|"];
//
//    NSDictionary * views = [NSDictionary dictionaryWithObjects:self.subviews forKeys:buttonNames];
//
//    [self addConstraints:[NSLayoutConstraint constraintsByParsingString:constraints views:views]];
}

- (void)didMoveToWindow {
  // TODO: Fixme
    if (self.window) {
        [self generateButtons];
        assert([_popupBarButton.button isDescendantOfView:self.window]);
//        [self.window
//         addConstraints:
//         [NSLayoutConstraint constraintsByParsingFormat:[NSString stringWithFormat:
//                                                         @"self.width = 54\n"
//                                                         "self.height = %u\n"
//                                                         "self.centerX = base.centerX\n"
//                                                         "self.bottom = base.top - 18",
//                                                         (unsigned int)_popupBarButton.items.count * 44]
//                                                  views:@{@"self" : self,
//                                                          @"base" : _popupBarButton.customView}]];
        [self becomeFirstResponder];
    }
}

- (UIEdgeInsets)alignmentRectInsets {return UIEdgeInsetsMake(0, 0, 10, 0); }

- (void)drawRect:(CGRect)rect {
    UIGraphicsPushContext(UIGraphicsGetCurrentContext());
    rect = self.bounds;
    UIRectFillUsingBlendMode(rect, kCGBlendModeClear);
    [[BlackColor colorWithAlphaComponent:0.75] setFill];
    UIRectFill(CGRectMake(0, 0, rect.size.width, rect.size.height - 10));
    UIBezierPath * path = [UIBezierPath bezierPath];
    [path moveToPoint:CGPointMake(CGRectGetMidX(rect) - 10, rect.size.height - 10)];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(rect), rect.size.height)];
    [path addLineToPoint:CGPointMake(CGRectGetMidX(rect) + 10, rect.size.height - 10)];
    [path closePath];
    [path fill];
    UIGraphicsPopContext();
}

- (BOOL)canBecomeFirstResponder {return YES; }

- (BOOL)resignFirstResponder {
    BOOL resign = [super resignFirstResponder];
    if (resign) [_popupBarButton hidePopover];
    return resign;
}

@end
