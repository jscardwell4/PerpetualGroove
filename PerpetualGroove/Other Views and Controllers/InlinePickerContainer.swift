//
//  InlinePickerContainer.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/26/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

class InlinePickerContainer: UIView {

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  var didSelectItem: ((InlinePickerContainer, Int) -> Void)?

  private func didSelectItem(_ picker: InlinePickerView, _ index: Int) {
    didSelectItem?(self, index)
  }

  override func layoutSubviews() {
    picker.reloadData()
    super.layoutSubviews()
  }

  class func decorate(picker: InlinePickerView) {
    picker.font = .controlFont
    picker.selectedFont = .controlSelectedFont
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
  }

  private let picker = InlinePickerView(autolayout: true)

  private func setup() {
    type(of: self).decorate(picker: picker)
    picker.didSelectItem = weakMethod(self, type(of: self).didSelectItem)
    addSubview(picker)
    constrain(𝗛|picker|𝗛, 𝗩|picker|𝗩)
  }

  override static var requiresConstraintBasedLayout: Bool { return true }

  override var intrinsicContentSize: CGSize { return picker.intrinsicContentSize }

}
