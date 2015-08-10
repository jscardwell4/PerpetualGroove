//
//  NSUserDefaults+MSKitAdditions.h
//  MSKit
//
//  Created by Jason Cardwell on 9/14/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;

#define UserDefaults          [NSUserDefaults standardUserDefaults]


@interface NSUserDefaults (MSKitAdditions)

- (id)objectForKeyedSubscript:(NSString *)key;
- (void)setObject:(id)object forKeyedSubscript:(NSString *)key;

@end
