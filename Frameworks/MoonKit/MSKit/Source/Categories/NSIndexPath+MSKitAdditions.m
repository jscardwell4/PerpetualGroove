//
//  NSIndexPath+MSKitAdditions.m
//  MSKit
//
//  Created by Jason Cardwell on 9/12/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "NSIndexPath+MSKitAdditions.h"
@import UIKit;

@implementation NSIndexPath (MSKitAdditions)

- (NSString *)prettyDescription { return [NSString stringWithFormat:@"row: %lu section: %lu", (long)self.row, (long)self.section]; }

@end
