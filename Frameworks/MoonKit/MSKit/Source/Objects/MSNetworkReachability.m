//
//  MSNetworkReachability.m
//  MSKit
//
//  Created by Jason Cardwell on 3/28/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
#import "MSNetworkReachability.h"
#import <netinet/in.h>

static void MSNetworkReachabilityCallbackHandler(SCNetworkReachabilityRef target,
                                                 SCNetworkReachabilityFlags flags,
                                                 void * info);

@interface MSNetworkReachability ()
@property (nonatomic, readwrite) SCNetworkReachabilityFlags flags;
@end

@implementation MSNetworkReachability {
  SCNetworkReachabilityRef      _reachability;
  MSNetworkReachabilityCallback _callback;
}

+ (MSNetworkReachability *)reachabilityWithCallback:(MSNetworkReachabilityCallback)callback {
  MSNetworkReachability * reachability = [self new];

  if (callback) reachability->_callback = [callback copy];

  return reachability;
}

- (void)dispatchCallbackBlockWithFlags:(SCNetworkReachabilityFlags)flags {
  if (_callback) _callback(flags);
}

- (id)init {
  if (self = [super init]) {
    SCNetworkReachabilityContext context = { 0, (__bridge void *)(self), NULL, NULL, NULL };
    struct sockaddr_in           addr;
    memset(&addr, 0, sizeof(addr));
    addr.sin_len         = sizeof(addr);
    addr.sin_family      = AF_INET;
    addr.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
    _reachability        = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault,
                                                                  (struct sockaddr *)&addr);

    if (!SCNetworkReachabilitySetCallback(_reachability,
                                          MSNetworkReachabilityCallbackHandler,
                                          &context)) return nil;

    dispatch_queue_t queue =  dispatch_queue_create("com.moondeerstudios.mskit.reachability",
                                                    DISPATCH_QUEUE_SERIAL);

    if (!SCNetworkReachabilitySetDispatchQueue(_reachability, queue)) return nil;

  }

  return self;
}


- (void)refreshFlags {
  SCNetworkReachabilityFlags r_flags;
  SCNetworkReachabilityGetFlags(_reachability, &r_flags);
  self.flags = r_flags;
  MSNetworkReachabilityCallbackHandler(_reachability, r_flags, (__bridge void *)self);
}

@end

static void MSNetworkReachabilityCallbackHandler(SCNetworkReachabilityRef target,
                                                 SCNetworkReachabilityFlags flags,
                                                 void * info) {
  MSNetworkReachability * reachability = (__bridge MSNetworkReachability *)info;

  if (reachability) [reachability dispatchCallbackBlockWithFlags:flags];
}
