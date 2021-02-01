//
//  KeyboardResponse.swift
//  Common
//
//  Created by Jason Cardwell on 1/31/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation
import SwiftUI

// MARK: - KeyboardPreferenceKey

public struct KeyboardPreferenceKey: PreferenceKey
{
  public typealias Value = [KeyboardRequest]

  public static var defaultValue: Value = []

  public static func reduce(value: inout Value, nextValue: () -> Value)
  {
    value.append(contentsOf: nextValue())
  }
}

// MARK: - KeyboardRequest

public struct KeyboardRequest: Hashable, Comparable, CustomStringConvertible
{
  public static func < (lhs: KeyboardRequest, rhs: KeyboardRequest) -> Bool
  {
    lhs.timestamp < rhs.timestamp
  }

  public let id: UUID
  public let frame: CGRect
  public let timestamp: Date

  public init(id: UUID, frame: CGRect, timestamp: Date = .now)
  {
    self.id = id
    self.frame = frame
    self.timestamp = timestamp
  }

  public func hash(into hasher: inout Hasher)
  {
    id.hash(into: &hasher)
  }

  public var description: String
  {
    let uuid = id.uuidString
    let uuid_0_1 = uuid[...uuid.index(after: uuid.startIndex)]
    let uuid_14_15 = uuid[uuid.index(before: uuid.index(before: uuid.endIndex))...]
    let id = "\(uuid_0_1)…\(uuid_14_15)"

    let origin = "(\(Int(frame.x)),\(Int(frame.y)))"
    let size = "\(Int(frame.width))x\(Int(frame.height))"

    let stamp = "\(timestamp)"

    return "{ \(id) \(origin) \(size) \(stamp) }"
  }
}

extension Array where Element == KeyboardRequest
{
  public var nextKeyboardRequest: KeyboardRequest? { self.max() }
}

extension Set where Element == KeyboardRequest
{
  public var nextKeyboardRequest: KeyboardRequest? { self.max() }
}

// MARK: - KeyboardActiveEnvironmentKey

private struct KeyboardActiveEnvironmentKey: EnvironmentKey
{
  static let defaultValue: Bool = false
}

extension EnvironmentValues
{
  public var keyboardIsActive: Bool
  {
    get { self[KeyboardActiveEnvironmentKey.self] }
    set { self[KeyboardActiveEnvironmentKey.self] = newValue }
  }
}
