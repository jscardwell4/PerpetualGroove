//
//  Colors.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonDev
import struct SwiftUI.Color

#if os(iOS)
import class UIKit.UIColor
#endif

@available(OSX 10.15, *)
public extension Color
{
  static let backgroundColor1 = Color("backgroundColor1", bundle: Bundle.module)
  static let backgroundColor2 = Color("backgroundColor2", bundle: Bundle.module)
  static let highlightColor = Color("highlightColor", bundle: Bundle.module)
  static let deleteColor = Color("deleteColor", bundle: Bundle.module)
  static let deleteHighlightedColor = Color("deleteHighlightedColor", bundle: Bundle.module)
  static let primaryColor1 = Color("primaryColor1", bundle: Bundle.module)
  static let primaryColor2 = Color("primaryColor2", bundle: Bundle.module)
  static let secondaryColor1 = Color("secondaryColor1", bundle: Bundle.module)
  static let secondaryColor2 = Color("secondaryColor2", bundle: Bundle.module)
  static let tertiaryColor1 = Color("tertiaryColor1", bundle: Bundle.module)
  static let tertiaryColor2 = Color("tertiaryColor2", bundle: Bundle.module)
  static let quaternaryColor1 = Color("quaternaryColor1", bundle: Bundle.module)
  static let quaternaryColor2 = Color("quaternaryColor2", bundle: Bundle.module)
  static let donkeyBrown = Color("donkeyBrown", bundle: Bundle.module)
  static let gravel = Color("gravel", bundle: Bundle.module)
  static let ironsideGray = Color("ironsideGray", bundle: Bundle.module)
  static let judgeGray = Color("judgeGray", bundle: Bundle.module)
  static let montana = Color("montana", bundle: Bundle.module)
  static let disabledColor = Color("disabledColor", bundle: Bundle.module)
  static let paleSlate = Color("paleSlate", bundle: Bundle.module)
}

#if os(iOS)
/// Extend `UIColor` with derived class properties for colors used within the application.
public extension UIColor
{
  static let backgroundColor1 =
    unwrapOrDie(UIColor(named: "backgroundColor1", in: Bundle.module, compatibleWith: nil))
  static let backgroundColor2 =
    unwrapOrDie(UIColor(named: "backgroundColor2", in: Bundle.module, compatibleWith: nil))
  static let highlightColor =
    unwrapOrDie(UIColor(named: "highlightColor", in: Bundle.module, compatibleWith: nil))
  static let deleteColor =
    unwrapOrDie(UIColor(named: "deleteColor", in: Bundle.module, compatibleWith: nil))
  static let deleteHighlightedColor =
    unwrapOrDie(UIColor(named: "deleteHighlightedColor", in: Bundle.module, compatibleWith: nil))
  static let primaryColor1 =
    unwrapOrDie(UIColor(named: "primaryColor1", in: Bundle.module, compatibleWith: nil))
  static let primaryColor2 =
    unwrapOrDie(UIColor(named: "primaryColor2", in: Bundle.module, compatibleWith: nil))
  static let secondaryColor1 =
    unwrapOrDie(UIColor(named: "secondaryColor1", in: Bundle.module, compatibleWith: nil))
  static let secondaryColor2 =
    unwrapOrDie(UIColor(named: "secondaryColor2", in: Bundle.module, compatibleWith: nil))
  static let tertiaryColor1 =
    unwrapOrDie(UIColor(named: "tertiaryColor1", in: Bundle.module, compatibleWith: nil))
  static let tertiaryColor2 =
    unwrapOrDie(UIColor(named: "tertiaryColor2", in: Bundle.module, compatibleWith: nil))
  static let quaternaryColor1 =
    unwrapOrDie(UIColor(named: "quaternaryColor1", in: Bundle.module, compatibleWith: nil))
  static let quaternaryColor2 =
    unwrapOrDie(UIColor(named: "quaternaryColor2", in: Bundle.module, compatibleWith: nil))
  static let donkeyBrown =
    unwrapOrDie(UIColor(named: "donkeyBrown", in: Bundle.module, compatibleWith: nil))
  static let gravel =
    unwrapOrDie(UIColor(named: "gravel", in: Bundle.module, compatibleWith: nil))
  static let ironsideGray =
    unwrapOrDie(UIColor(named: "ironsideGray", in: Bundle.module, compatibleWith: nil))
  static let judgeGray =
    unwrapOrDie(UIColor(named: "judgeGray", in: Bundle.module, compatibleWith: nil))
  static let montana =
    unwrapOrDie(UIColor(named: "montana", in: Bundle.module, compatibleWith: nil))
  static let disabledColor =
    unwrapOrDie(UIColor(named: "disabledColor", in: Bundle.module, compatibleWith: nil))
  static let paleSlate =
    unwrapOrDie(UIColor(named: "paleSlate", in: Bundle.module, compatibleWith: nil))
}
#endif

