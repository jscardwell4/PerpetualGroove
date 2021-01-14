//
//  DocumentsView.swift
//  Documents
//
//  Created by Jason Cardwell on 1/13/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import MoonKit
import SwiftUI

/// The `Documents` bundle.
internal let bundle = unwrapOrDie(Bundle(identifier: "com.moondeerstudios.Documents"))

// MARK: - DocumentsView

public struct DocumentsView: View
{
  private let names: [String] = [
    "Funk and the Philly",
    "Freakin' Like We Leakin'",
    "Can I Get Some Fitness?",
    "Surely Shirley She Shimmies",
    "Tomato Tortoise",
    "Awesomesauce"
  ]
  public var body: some View
  {
    VStack
    {
      Spacer()
      ScrollView
      {
        ForEach(names, id: \.self)
        {
          DocumentRow(name: $0)
            .frame(height: 24)
        }
      }
      Divider()
      CreateDocumentRow().frame(height: 24)
    }
    .fixedSize()
  }
}

// MARK: - DocumentsView_Previews

struct DocumentsView_Previews: PreviewProvider
{
  static var previews: some View
  {
    DocumentsView()
      .preferredColorScheme(.dark)
      .previewLayout(.sizeThatFits)
      .padding()
  }
}
