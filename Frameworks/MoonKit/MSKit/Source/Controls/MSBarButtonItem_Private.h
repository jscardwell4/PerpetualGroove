//
//  MSBarButtonItem_Private.h
//  MSKit
//
//  Created by Jason Cardwell on 2/16/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//


#import "MSBarButtonItem.h"

@interface MSBarButtonItem ()

- (void)initializeIVARs;

@property (nonatomic, strong, readwrite) UIButton * button;

@end

#import "UIColor+MSKitAdditions.h"
#import "NSValue+MSKitAdditions.h"
