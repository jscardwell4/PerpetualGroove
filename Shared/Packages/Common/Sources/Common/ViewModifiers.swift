//
//  ViewModifiers.swift
//  Common
//
//  Created by Jason Cardwell on 2/1/21.
//
import Foundation
import SwiftUI

struct CommonTextField: ViewModifier
{
  @Binding var isEditing: Bool

  func body(content: Content) -> some View {
    content
      .autocapitalization(.none)
      .disableAutocorrection(true)
      .allowsTightening(true)
      .foregroundColor(isEditing ? .highlightColor : .primaryColor1)
      .fixedSize(horizontal: true, vertical: false)
  }
}

extension View
{
  public func commonTextField(isEditing: Binding<Bool> = .constant(false)) -> some View
  {
    modifier(CommonTextField(isEditing: isEditing))
  }
}
