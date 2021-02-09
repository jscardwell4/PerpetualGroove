//
//  Tool.swift
//  Sequencing
// 
//  Created by Jason Cardwell on 2/9/21.
//
import SwiftUI

/// An enumeration of available editing tools. These values
/// mirror the tools held by an instance of `Toolset`.s
enum Tool: String, Hashable, Equatable, Identifiable, CaseIterable, CustomStringConvertible
{
  case addNode
  case removeNode
  case deleteNode
  case newGenerator
  case existingGenerator
  case rotate

  var id: String { rawValue }

  var image: Image { Image(rawValue, bundle: .module) }

  var description: String { rawValue }
}
