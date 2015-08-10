//
//  LayerProxy.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/27/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit

public class LayerProxy {
  let callback: (CGContext) -> Void
  public init(callback: (CGContext) -> Void) { self.callback = callback }
  func drawLayer(layer: CALayer, inContext ctx: CGContext) { callback(ctx) }
}
