//
//  MSMultiselectView.m
//  MSKit
//
//  Created by Jason Cardwell on 2/18/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSMultiselectView.h"
#import "NSLayoutConstraint+MSKitAdditions.h"
#import "UIColor+MSKitAdditions.h"

@implementation MSMultiselectView {
    UILabel * _titleView;
    NSMutableArray * _callbacks;
}

- (id)init { return [self initWithFrame:(CGRect){0,0,280,320}];}

- (id)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        _callbacks = [@[] mutableCopy];
        _titleView = [[UILabel alloc] initWithFrame:(CGRect){0,0,frame.size.width,44.0f}];
        _titleView.backgroundColor = ClearColor;
        NSMutableParagraphStyle * paragraphStyle = [NSMutableParagraphStyle new];
        paragraphStyle.alignment = NSTextAlignmentCenter;
        NSAttributedString * title = [[NSAttributedString alloc]
                                      initWithString:@""
                                      attributes:@{
                                                  NSParagraphStyleAttributeName: paragraphStyle,
                                                  NSForegroundColorAttributeName: LightTextColor,
                                                  NSFontAttributeName:[UIFont boldSystemFontOfSize:17.0f]
                                      }];
        _titleView.attributedText = title;

        [self addSubview:_titleView];
        PrepConstraints(_titleView);
        ConstrainHeight(_titleView, 44);
        AlignViewTop(self, _titleView, 10.0f);
        AlignViewLeft(self, _titleView, 10.0f);
        AlignViewRight(self, _titleView, -10.0f);
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

@end
