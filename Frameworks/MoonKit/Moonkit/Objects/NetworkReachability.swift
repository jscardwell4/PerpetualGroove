//
//  NetworkReachability.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/7/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import SystemConfiguration

// typealias SCNetworkReachabilityCallback = (SCNetworkReachability, SCNetworkReachabilityFlags, UnsafeMutablePointer<Void>) -> Void

private let IN_LINKLOCALNETNUM = UInt32(0xA9FE000)

final public class NetworkReachability: NSObject {

  public typealias Flags = SCNetworkReachabilityFlags
  public typealias Callback = (Flags) -> Void

  private let callback: Callback
  private static let queue = dispatch_queue_create("com.moondeerstudios.moonkit.reachability", DISPATCH_QUEUE_SERIAL)
  private static var clientIndex: [NetworkReachability:SCNetworkReachability] = [:]

  public private(set) var flags: Flags = []

  /** refreshFlags */
  public func refreshFlags() {
    var flags = SCNetworkReachabilityFlags()
    SCNetworkReachabilityGetFlags(reachability, &flags)
    self.flags = flags
    callback(flags)
  }

  private static let handler: @convention(c) (SCNetworkReachability, SCNetworkReachabilityFlags, UnsafeMutablePointer<Void>) -> Void = {
    reachability, flags, context in

    print("reachability = \(String(reflecting: reachability)), flags = \(flags), info = \(context)")

    for (client, address) in NetworkReachability.clientIndex where String(reflecting: address) == String(reflecting: reachability) {
      print("client = \(client)")
      client.callback(flags)
    }

  }


  public var wifiAvailable: Bool { return flags.contains(.Reachable) }
  
  /**
  initWithCallout:

  - parameter callout: Callback
  */
  public init(callout: Callback) {
    callback = callout

    var addrIn = sockaddr_in()
    addrIn.sin_len = UInt8(sizeof(sockaddr_in.self))
    addrIn.sin_family = sa_family_t(AF_INET)
    addrIn.sin_addr.s_addr = IN_LINKLOCALNETNUM

    var addr = unsafeBitCast(addrIn, sockaddr.self)

    reachability = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, &addr)!
    print("reachability = \(String(reflecting: reachability))")

    super.init()
    NetworkReachability.clientIndex[self] = reachability

    guard SCNetworkReachabilitySetCallback(reachability, NetworkReachability.handler, nil) else {
      fatalError("failed to set reachability callback")
    }

    guard SCNetworkReachabilitySetDispatchQueue(reachability, NetworkReachability.queue) else {
      fatalError("failed to set reachability queue")
    }
  }

  deinit {
    NetworkReachability.clientIndex[self] = nil
  }

  private let reachability: SCNetworkReachability
}