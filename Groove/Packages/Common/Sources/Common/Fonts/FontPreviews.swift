//
//  FontPreviews.swift
//
//
//  Created by Jason Cardwell on 1/18/21.
//
import MoonDev
import SwiftUI

// MARK: - FontPreview
@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct FontPreview: View
{
  let name: String
  let size: CGFloat

  var body: some View
  {
    HStack
    {
      Text("\(name):")
        .multilineTextAlignment(.leading)
      Spacer()
      Text("Preview")
        .multilineTextAlignment(.trailing)
        .font(Font.custom(name, size: size))
    }
  }

  init(postscriptName: String, size: CGFloat)
  {
    name = postscriptName
    self.size = size
  }

  init(font: EvelethFont, size: CGFloat)
  {
    name = font.postscriptName
    self.size = size
  }

  init(font: TriumpFont, size: CGFloat)
  {
    name = font.postscriptName
    self.size = size
  }
}

// MARK: - Previews

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct Previews: PreviewProvider
{
  static var previews: some View
  {
    Group
    {
      VStack
      {
        FontPreview(font: EvelethFont.cleanRegular, size: 64)
        FontPreview(font: EvelethFont.cleanShadow, size: 64)
        FontPreview(font: EvelethFont.cleanThin, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.dotLight, size: 64)
        FontPreview(font: EvelethFont.dotRegularBold, size: 64)
        FontPreview(font: EvelethFont.dotRegular, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.icons, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.light, size: 64)
        FontPreview(font: EvelethFont.regularBold, size: 64)
        FontPreview(font: EvelethFont.regular, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.shadow, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.slantLight, size: 64)
        FontPreview(font: EvelethFont.slantRegularBold, size: 64)
        FontPreview(font: EvelethFont.slantRegular, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: EvelethFont.thin, size: 64)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
    }
    .previewLayout(.sizeThatFits)
    .preferredColorScheme(.dark)
    .fixedSize()
    Group
    {
      VStack
      {
        Group
        {
          FontPreview(font: TriumpFont.blur01, size: 64)
          FontPreview(font: TriumpFont.blur02, size: 64)
          FontPreview(font: TriumpFont.blur03, size: 64)
          FontPreview(font: TriumpFont.blur04, size: 64)
          FontPreview(font: TriumpFont.blur05, size: 64)
          FontPreview(font: TriumpFont.blur06, size: 64)
          FontPreview(font: TriumpFont.blur07, size: 64)
          FontPreview(font: TriumpFont.blur08, size: 64)
          FontPreview(font: TriumpFont.blur09, size: 64)
          FontPreview(font: TriumpFont.blur10, size: 64)
        }
        Group
        {
          FontPreview(font: TriumpFont.blur11, size: 64)
          FontPreview(font: TriumpFont.blur12, size: 64)
        }
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        FontPreview(font: TriumpFont.extras, size: 32)
        FontPreview(font: TriumpFont.ornaments, size: 32)
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
      VStack
      {
        Group
        {
          FontPreview(font: TriumpFont.rock01, size: 64)
          FontPreview(font: TriumpFont.rock02, size: 64)
          FontPreview(font: TriumpFont.rock03, size: 64)
          FontPreview(font: TriumpFont.rock04, size: 64)
          FontPreview(font: TriumpFont.rock05, size: 64)
          FontPreview(font: TriumpFont.rock06, size: 64)
          FontPreview(font: TriumpFont.rock07, size: 64)
          FontPreview(font: TriumpFont.rock08, size: 64)
          FontPreview(font: TriumpFont.rock09, size: 64)
          FontPreview(font: TriumpFont.rock10, size: 64)
        }
        Group
        {
          FontPreview(font: TriumpFont.rock11, size: 64)
          FontPreview(font: TriumpFont.rock12, size: 64)
        }
      }
      .previewLayout(.sizeThatFits)
      .preferredColorScheme(.dark)
      .padding()
      .fixedSize()
    }
    .previewLayout(.sizeThatFits)
    .preferredColorScheme(.dark)
    .fixedSize()
  }
}
