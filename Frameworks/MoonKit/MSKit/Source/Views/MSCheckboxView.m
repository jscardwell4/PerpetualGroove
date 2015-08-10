//
//  MSCheckboxView.m
//  Remote
//
//  Created by Jason Cardwell on 3/22/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//
#import "MSKitMacros.h"
#import "MSCheckboxView.h"

static NSString * defaultCheckmarkText;
static NSString * defaultCheckmarkFontName;
static UIColor  * defaultBoxFrameColor;
static UIColor  * defaultCheckmarkColor;
static UIColor  * defaultBoxBGColor;



@interface MSCheckboxView ()

- (void)initializeView;
- (void)handleTap:(UITapGestureRecognizer *)tapGesture;
//- (void)drawLineBorderStyleInContext:(CGContextRef)context;
//- (void)drawRoundedRectBorderStyleInContext:(CGContextRef)context;

@property (nonatomic, strong, readwrite) UIFont * checkmarkFont;

@end


@implementation MSCheckboxView

@synthesize checkmarkText, checkmarkFont, checkmarkFontName, boxFrameColor, checkmarkColor, checked,
delegate, boxFrame, checkmarkCenter, checkmarkPointSize;

+ (void)initialize {
	if (self == [MSCheckboxView class]) {
		// Set class defaults
		defaultCheckmarkFontName = @"iconSweets";
		defaultCheckmarkText = @"=";
		defaultBoxFrameColor = [UIColor whiteColor];
		defaultCheckmarkColor = [UIColor darkGrayColor];
		defaultBoxBGColor = [UIColor whiteColor];
	}
}

- (void)initializeView {
	if (checkmarkPointSize == 0.0)
		checkmarkPointSize = self.frame.size.height - self.frame.size.height * 0.25;
	if (ValueIsNil(checkmarkText))
		self.checkmarkText = defaultCheckmarkText;
	if (ValueIsNil(checkmarkFont))
		self.checkmarkFont = [UIFont fontWithName:defaultCheckmarkFontName size:checkmarkPointSize];
	if (ValueIsNil(boxFrameColor))
		self.boxFrameColor = defaultBoxFrameColor;
	if (ValueIsNil(checkmarkColor))
		self.checkmarkColor = defaultCheckmarkColor;
	if (CGPointEqualToPoint(checkmarkCenter, CGPointZero))
		self.checkmarkCenter = CGPointMake(0.5, 0.5);
	
	[self addGestureRecognizer:
	 	[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTap:)]];
}


- (void)awakeFromNib {
	[super awakeFromNib];
	[self initializeView];
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
		self.backgroundColor = [UIColor clearColor];
		[self initializeView];
    }
    return self;
}

- (void)handleTap:(UITapGestureRecognizer *)tapGesture {
	if (tapGesture.state == UIGestureRecognizerStateEnded) {
		self.checked = !checked;
		if (  self.delegate
            && [self.delegate respondsToSelector:@selector(checkboxValueDidChange:checked:)])
		{
			[self.delegate checkboxValueDidChange:self checked:checked];
		}
	}
}

- (void)setCheckmarkFontName:(NSString *)fontName {
	checkmarkFontName = [fontName copy];
	self.checkmarkFont = [UIFont fontWithName:fontName size:checkmarkPointSize];
	[self setNeedsDisplay];
}

- (void)setCheckmarkPointSize:(CGFloat)pointSize {
	checkmarkPointSize = pointSize;
	self.checkmarkFont = [checkmarkFont fontWithSize:checkmarkPointSize];
	[self setNeedsDisplay];
}

- (void)setChecked:(BOOL)newValue {
	checked = newValue;
	[self setNeedsDisplay];
}

- (void)setCheckmarkColor:(UIColor *)color {
	checkmarkColor = color;
	[self setNeedsDisplay];
}

- (void)setCheckmarkText:(NSString *)text {
	checkmarkText = text;
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {

    [super drawRect:rect];
    		
	if (checked) {
		CGSize fontSize = [checkmarkText sizeWithAttributes:@{NSFontAttributeName:checkmarkFont}];
		
		CGRect markRect;
		markRect.size = fontSize;
		markRect.origin.x = (self.bounds.size.width * checkmarkCenter.x) - (fontSize.width / 2.0);
		markRect.origin.y = (self.bounds.size.height * checkmarkCenter.y) - (fontSize.height / 2.0);
		
		[checkmarkColor setFill];
		[checkmarkText drawInRect:markRect withAttributes:@{NSFontAttributeName:checkmarkFont}];
	}
}

///*
- (void)drawLineBorderStyleInContext:(CGContextRef)context {

	CGContextSaveGState(context);

	CGRect boxPathFrame = boxFrame;
	if (CGRectIsEmpty(boxPathFrame)) {
		boxPathFrame = self.bounds;
	}
	
	UIBezierPath *boxPath = [UIBezierPath bezierPathWithRect:boxPathFrame];
	
	[self.backgroundColor setFill];
	[boxFrameColor setStroke];
	
	[boxPath fill];
	[boxPath stroke];
	
	CGContextRestoreGState(context);
}

//*/
///*
- (void)drawRoundedRectBorderStyleInContext:(CGContextRef)context {
	CGRect bounds = self.bounds;
	CGRect outerRect = CGRectMake(bounds.origin.x - 1.25,
								  bounds.origin.y - 1.5,
								  bounds.size.width + 2.5,
								  bounds.size.height + 5.0);
	CGSize cornerRadii = CGSizeMake(5, 5);
	
	CGContextSaveGState(context);
	
	CGContextClearRect(context, bounds);
	
	
	UIBezierPath *shadowPath = [UIBezierPath bezierPathWithRoundedRect:outerRect 
													 byRoundingCorners:UIRectCornerAllCorners
														   cornerRadii:cornerRadii];
	
	UIBezierPath *innerPath = [UIBezierPath bezierPathWithRoundedRect:bounds 
													byRoundingCorners:UIRectCornerAllCorners
														  cornerRadii:cornerRadii];
	
	[[UIColor whiteColor] setFill];
	[innerPath fill];
	CGContextClipToRect(context, CGRectMake(0, 0, bounds.size.width, 10.0));
	[innerPath addClip];
	
	[[UIColor whiteColor] setStroke];
	CGContextSetShadow(context, CGSizeMake(0, 1.5), 1.5);
	[shadowPath setLineWidth:2.0];
	[shadowPath stroke];
	
	CGContextRestoreGState(context);
}

//*/
@end

