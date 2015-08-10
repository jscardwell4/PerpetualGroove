//
// MSPopupBarButton_Private.h
// MSKit
//
// Created by Jason Cardwell on 2/16/13.
// Copyright (c) 2013 Moondeer Studios. All rights reserved.
//


#import "MSPopupBarButton.h"
#import "MSBarButtonItem_Private.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Popup Items
////////////////////////////////////////////////////////////////////////////////

@interface MSPopupBarButtonItem : NSObject

@property (nonatomic, assign) SEL                  action;
@property (nonatomic, weak)   id                   target;
@property (nonatomic, strong) UIImage            * image;
@property (nonatomic, copy)   NSString           * title;
@property (nonatomic, copy)   NSAttributedString * attributedTitle;

+ (MSPopupBarButtonItem *)itemWithTitle:(NSString *)title
                                  image:(UIImage *)image
                                 target:(id)target
                                 action:(SEL)action;

+ (MSPopupBarButtonItem *)itemWithAttributedTitle:(NSAttributedString *)title
                                            image:(UIImage *)image
                                           target:(id)target
                                           action:(SEL)action;
@end

////////////////////////////////////////////////////////////////////////////////
#pragma mark - Popup View
////////////////////////////////////////////////////////////////////////////////

@interface MSPopupBarButtonView : UIView

@property (nonatomic, weak) MSPopupBarButton * popupBarButton;

+ (MSPopupBarButtonView *)popupViewForBarButton:(MSPopupBarButton *)popupBarButton;

@end

/*
@interface MSBarButtonCustomView : UIView

@property (nonatomic, strong)   UIButton         * button;
@property (nonatomic, weak)     MSPopupBarButton * popupBarButton;
@property (nonatomic, assign)   BOOL               selected;
@property (nonatomic, readonly) UILabel          * titleLabel;

+ (MSBarButtonCustomView *)customViewForPopup:(MSPopupBarButton *)popup;

@end
*/

@interface MSPopupBarButton () <UIGestureRecognizerDelegate>

@property (nonatomic, strong) NSMutableArray        * items;
@property (nonatomic, weak)   UIWindow              * window;
@property (nonatomic, strong) MSPopupBarButtonView  * popupView;

@end

#import "MSKitDefines.h"
#import "MSKitMacros.h"
#import "UIColor+MSKitAdditions.h"
#import "MSKitGeometryFunctions.h"
#import "MSKitLoggingFunctions.h"
#import "MSKitMiscellaneousFunctions.h"
//#import "NSLayoutConstraint+MSKitAdditions.h"
#import "UIImage+MSKitAdditions.h"
