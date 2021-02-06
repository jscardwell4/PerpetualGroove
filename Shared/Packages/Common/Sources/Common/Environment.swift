//
//  Environment.swift
//  Common
//
//  Created by Jason Cardwell on 2/5/21.
//
import Foundation
import SwiftUI

// MARK: - MockDataEnvironmentKey

private struct MockDataEnvironmentKey: EnvironmentKey
{
  static let defaultValue: Bool = ProcessInfo.processInfo
    .environment["ENABLE_MOCK_DATA"] == "true"
}

// MARK: - KeyboardActiveEnvironmentKey

private struct KeyboardActiveEnvironmentKey: EnvironmentKey
{
  static let defaultValue: Bool = false
}

extension EnvironmentValues
{
  public var enableMockData: Bool
  {
    get { self[MockDataEnvironmentKey.self] }
    set { self[MockDataEnvironmentKey.self] = newValue }
  }

  public var keyboardIsActive: Bool
  {
    get { self[KeyboardActiveEnvironmentKey.self] }
    set { self[KeyboardActiveEnvironmentKey.self] = newValue }
  }
}
