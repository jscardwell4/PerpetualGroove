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
import class UIKit.UIColor

private let bundle = unwrapOrDie(Bundle(identifier: "com.moondeerstudios.Common"))

public extension Color
{
  static let backgroundColor1 = Color("backgroundColor1", bundle: bundle)
  static let backgroundColor2 = Color("backgroundColor2", bundle: bundle)
  static let highlightColor = Color("highlightColor", bundle: bundle)
  static let deleteColor = Color("deleteColor", bundle: bundle)
  static let deleteHighlightedColor = Color("deleteHighlightedColor", bundle: bundle)
  static let primaryColor1 = Color("primaryColor1", bundle: bundle)
  static let primaryColor2 = Color("primaryColor2", bundle: bundle)
  static let secondaryColor1 = Color("secondaryColor1", bundle: bundle)
  static let secondaryColor2 = Color("secondaryColor2", bundle: bundle)
  static let tertiaryColor1 = Color("tertiaryColor1", bundle: bundle)
  static let tertiaryColor2 = Color("tertiaryColor2", bundle: bundle)
  static let quaternaryColor1 = Color("quaternaryColor1", bundle: bundle)
  static let quaternaryColor2 = Color("quaternaryColor2", bundle: bundle)
  static let donkeyBrown = Color("donkeyBrown", bundle: bundle)
  static let gravel = Color("gravel", bundle: bundle)
  static let ironsideGray = Color("ironsideGray", bundle: bundle)
  static let judgeGray = Color("judgeGray", bundle: bundle)
  static let montana = Color("montana", bundle: bundle)
  static let disabledColor = Color("disabledColor", bundle: bundle)
  static let paleSlate = Color("paleSlate", bundle: bundle)
}

/// Extend `UIColor` with derived class properties for colors used within the application.
public extension UIColor
{
  static let backgroundColor1 =
    unwrapOrDie(UIColor(named: "backgroundColor1", in: bundle, compatibleWith: nil))
  static let backgroundColor2 =
    unwrapOrDie(UIColor(named: "backgroundColor2", in: bundle, compatibleWith: nil))
  static let highlightColor =
    unwrapOrDie(UIColor(named: "highlightColor", in: bundle, compatibleWith: nil))
  static let deleteColor =
    unwrapOrDie(UIColor(named: "deleteColor", in: bundle, compatibleWith: nil))
  static let deleteHighlightedColor =
    unwrapOrDie(UIColor(named: "deleteHighlightedColor", in: bundle, compatibleWith: nil))
  static let primaryColor1 =
    unwrapOrDie(UIColor(named: "primaryColor1", in: bundle, compatibleWith: nil))
  static let primaryColor2 =
    unwrapOrDie(UIColor(named: "primaryColor2", in: bundle, compatibleWith: nil))
  static let secondaryColor1 =
    unwrapOrDie(UIColor(named: "secondaryColor1", in: bundle, compatibleWith: nil))
  static let secondaryColor2 =
    unwrapOrDie(UIColor(named: "secondaryColor2", in: bundle, compatibleWith: nil))
  static let tertiaryColor1 =
    unwrapOrDie(UIColor(named: "tertiaryColor1", in: bundle, compatibleWith: nil))
  static let tertiaryColor2 =
    unwrapOrDie(UIColor(named: "tertiaryColor2", in: bundle, compatibleWith: nil))
  static let quaternaryColor1 =
    unwrapOrDie(UIColor(named: "quaternaryColor1", in: bundle, compatibleWith: nil))
  static let quaternaryColor2 =
    unwrapOrDie(UIColor(named: "quaternaryColor2", in: bundle, compatibleWith: nil))
  static let donkeyBrown =
    unwrapOrDie(UIColor(named: "donkeyBrown", in: bundle, compatibleWith: nil))
  static let gravel =
    unwrapOrDie(UIColor(named: "gravel", in: bundle, compatibleWith: nil))
  static let ironsideGray =
    unwrapOrDie(UIColor(named: "ironsideGray", in: bundle, compatibleWith: nil))
  static let judgeGray =
    unwrapOrDie(UIColor(named: "judgeGray", in: bundle, compatibleWith: nil))
  static let montana =
    unwrapOrDie(UIColor(named: "montana", in: bundle, compatibleWith: nil))
  static let disabledColor =
    unwrapOrDie(UIColor(named: "disabledColor", in: bundle, compatibleWith: nil))
  static let paleSlate =
    unwrapOrDie(UIColor(named: "paleSlate", in: bundle, compatibleWith: nil))
}
