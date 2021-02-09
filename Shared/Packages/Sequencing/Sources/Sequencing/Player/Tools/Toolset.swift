//
//  Toolset.swift
//  Sequencing
//
//  Created by Jason Cardwell on 2/8/21.
//
import SwiftUI

/// A type for encapsulating all the available editing tools.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
final class Toolset: ObservableObject
{
  /// A tool for adding new `MIDINode` instances.
  let addNode = AddTool()

  /// A tool for removing an existing `MIDINode` instance.
  let removeNode = RemoveTool(delete: false)

  /// A tool for permanently deleting an existing `MIDINode` instance.
  let deleteNode = RemoveTool(delete: true)

  /// A tool for configuring a new generator.
  let newGenerator = GeneratorTool(mode: .new)

  /// A tool for configuring an existing generator.
  let existingGenerator = GeneratorTool(mode: .existing)

  /// A tool for modifying the trajectory of a `MIDINode` instance.
  let rotate = RotateTool()

  @Published var currentTool: Tool? = nil
}
