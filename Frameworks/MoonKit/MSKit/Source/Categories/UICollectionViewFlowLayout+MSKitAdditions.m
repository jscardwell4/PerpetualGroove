//
//  UICollectionViewFlowLayout+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 4/2/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "UICollectionViewFlowLayout+MSKitAdditions.h"

@implementation UICollectionViewFlowLayout (MSKitAdditions)

+ (UICollectionViewFlowLayout *)layoutWithScrollDirection:(UICollectionViewScrollDirection)direction
{
    UICollectionViewFlowLayout * layout = [[UICollectionViewFlowLayout alloc] init];
    layout.scrollDirection = direction;
    return layout;
}

@end
