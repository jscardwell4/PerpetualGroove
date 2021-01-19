//
//  DocumentRow.swift
//  Documents
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - DocumentRow

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
struct DocumentRow: View
{
  var name: String

  var body: some View
  {
    Text(name)
      .font(.listItem)
      .foregroundColor(.primaryColor2)
  }

}

// MARK: - DocumentRow_Previews

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
struct DocumentRow_Previews: PreviewProvider
{
  static var previews: some View
  {
    DocumentRow(name: "Awesomesauce")
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()

  }
}
