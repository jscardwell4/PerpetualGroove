//
//  SoftwareKeyboardAdaptive.swift
//  Groove
//
//  Created by Jason Cardwell on 1/31/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Combine
import Common
import func MoonDev.logi
import SwiftUI

// MARK: - SoftwareKeyboardAdaptive

/// View modifier for handling software keyboard appearances.
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct SoftwareKeyboardAdaptive: ViewModifier
{
  @State private var yOffset: CGFloat = 0

  @State private var keyboardIsActive = false

  private let notifications = Publishers.Merge(
    NotificationCenter.default.publisher(for: .willShowKeyboard),
    NotificationCenter.default.publisher(for: .willHideKeyboard)
  )
  .subscribe(on: RunLoop.main)

  private let activeRequest = CurrentValueSubject<KeyboardRequest?, Never>(nil)

  func body(content: Content) -> some View
  {
    content
      .offset(y: yOffset)
      .animation(nil)
      .environment(\.keyboardIsActive, keyboardIsActive)
      .onPreferenceChange(KeyboardPreferenceKey.self)
      {
        activeRequest.send($0.nextKeyboardRequest)
      }
      .onAppear
      {
        _ = activeRequest
          .combineLatest(notifications)
          .subscribe(on: RunLoop.main)
          .sink
          {
            request, notification in

            if keyboardIsActive && notification.name == .willHideKeyboard
            {
              keyboardIsActive = false
            }
            else if !keyboardIsActive && notification.name == .willShowKeyboard
            {
              keyboardIsActive = true
            }

            if let request = request
            {
              let data = KeyboardData(notification: notification)
              let keyboardRange = data.endFrame.minY ... data.endFrame.maxY
              let viewRange = request.frame.minY ... request.frame.maxY
              if viewRange.overlaps(keyboardRange)
              {
                yOffset = 0
              }
              else
              {
                yOffset = (data.endFrame.height - 20) / 2
              }
            }
            else
            {
              yOffset = 0
            }
          }
      }
  }

  private struct KeyboardData: CustomStringConvertible
  {
    var beginFrame: CGRect
    var endFrame: CGRect
    var animationCurve: UIView.AnimationCurve
    var animationDuration: Double
    var notification: Notification.Name

    init(notification: Notification)
    {
      beginFrame = notification.beginFrame
      endFrame = notification.endFrame
      animationCurve = notification.animationCurve
      animationDuration = notification.animationDuration
      self.notification = notification.name
    }

    var description: String
    {
      """
      { \
      begin: \(beginFrame), \
      end: \(endFrame), \
      curve: \(animationCurve), \
      duration: \(animationDuration), \
      notification: \(notification.rawValue) }
      """
    }
  }
}

// MARK: CustomStringConvertible

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension SoftwareKeyboardAdaptive: CustomStringConvertible
{
  var description: String
  {
    """
    SoftwareKeyboardAdaptive(yOffset: \(yOffset))
    """
  }
}

extension Notification.Name
{
  fileprivate static var willShowKeyboard: Self
  {
    UIResponder.keyboardWillShowNotification
  }

  fileprivate static var didShowKeyboard: Self
  {
    UIResponder.keyboardDidShowNotification
  }

  fileprivate static var willHideKeyboard: Self
  {
    UIResponder.keyboardWillHideNotification
  }

  fileprivate static var didHideKeyboard: Self
  {
    UIResponder.keyboardDidHideNotification
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension Notification
{
  fileprivate var beginFrame: CGRect
  {
    userInfo![UIResponder.keyboardFrameBeginUserInfoKey] as! CGRect
  }

  fileprivate var endFrame: CGRect
  {
    userInfo![UIResponder.keyboardFrameEndUserInfoKey] as! CGRect
  }

  fileprivate var animationDuration: Double
  {
    userInfo![UIResponder.keyboardAnimationDurationUserInfoKey] as! Double
  }

  fileprivate var animationCurve: UIView.AnimationCurve
  {
    UIView.AnimationCurve(
      rawValue: userInfo![UIResponder.keyboardAnimationCurveUserInfoKey] as! Int
    )!
  }
}

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
extension View
{
  func softwareKeyboardAdaptive() -> some View
  {
    modifier(SoftwareKeyboardAdaptive())
  }
}
