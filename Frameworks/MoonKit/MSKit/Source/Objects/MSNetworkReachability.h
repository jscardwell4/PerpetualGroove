//
//  MSNetworkReachability.h
//  MSKit
//
//  Created by Jason Cardwell on 3/28/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import UIKit;
@import SystemConfiguration;

typedef void(^MSNetworkReachabilityCallback)(SCNetworkReachabilityFlags);

@interface MSNetworkReachability : NSObject

+ (MSNetworkReachability *)reachabilityWithCallback:(MSNetworkReachabilityCallback)callback;

- (void)refreshFlags;

@property (nonatomic, readonly) SCNetworkReachabilityFlags flags;

@end
