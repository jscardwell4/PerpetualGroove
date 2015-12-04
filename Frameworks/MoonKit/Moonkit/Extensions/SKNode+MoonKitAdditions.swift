//
//  SKNode+MoonKitAdditions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 12/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import SpriteKit

extension SKNode {

  public var nodeTreeDescription: String {
    var result = ""

    func dumpNode(node: SKNode, indent: Int) {
      result += "-" * (indent * 2)
      let depthString = "[" + String(indent).pad(" ", count: 2, type: .Prefix) + "] "
      let classString = "\(node.dynamicType.self)"
      let addressString = "(\(unsafeAddressOf(node)))"
      var nodeString = depthString + classString + addressString
      if let name = node.name { nodeString += "<'\(name)'>" }
      nodeString += "\n"
      result += nodeString
      for childNode in node.children { dumpNode(childNode, indent: indent + 1) }
    }
    dumpNode(self, indent: 0)
    return result
  }

}