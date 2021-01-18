//
//  CreateDocumentRow.swift
//  Documents
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Common
import SwiftUI

// MARK: - CreateDocumentRow

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
struct CreateDocumentRow: View
{

  var body: some View
  {
    HStack {
    Image("add-selected", bundle: bundle)
      .resizable(resizingMode: .stretch)
      .aspectRatio(contentMode: .fit)
      .frame(width: FontStyle.listItem.size)
      .offset(x: 0, y: -2)
    Text("Create Document")
    }
    .font(.listItem)
    .foregroundColor(.primaryColor1)
  }

}

// MARK: - CreateDocumentRow_Previews

@available(macCatalyst 14.0, *)
@available(iOS 14.0, *)
struct CreateDocumentRow_Previews: PreviewProvider
{
  static var previews: some View
  {
    CreateDocumentRow()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()

  }
}
