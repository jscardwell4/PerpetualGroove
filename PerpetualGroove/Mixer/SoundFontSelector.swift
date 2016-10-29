//
//  SoundFontSelector.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/24/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

@IBDesignable
final class SoundFontSelector: UIControl {

  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }

  private let picker = InlineLabelPicker(autolayout: true)

  @objc private func valueChanged() {
    sendActions(for: .valueChanged)
  }

  func refreshLabels() {
    picker.labels = Sequencer.soundSets.map { $0.displayName }
  }

  private func setup() {

    picker.font = .controlFont
    picker.selectedFont = .controlSelectedFont
    picker.itemColor = #colorLiteral(red: 0.7302821875, green: 0.7035630345, blue: 0.6637413502, alpha: 1)
    picker.selectedItemColor = #colorLiteral(red: 0.7608990073, green: 0.2564961016, blue: 0, alpha: 1)
    picker.addTarget(self, action: #selector(valueChanged), for: .valueChanged)

    #if TARGET_INTERFACE_BUILDER
      picker.labels = [
        "Emax Volume 1",
        "Emax Volume 2",
        "Emax Volume 3",
        "Emax Volume 4",
        "Emax Volume 5",
        "Emax Volume 6",
        "SPYRO's Pure Oscillators"
      ]
    #else
      refreshLabels()
    #endif

    addSubview(picker)
    constrain(𝗛|picker|𝗛, 𝗩|picker|𝗩)

  }

  var selection: Int { get { return picker.selection } set { picker.selection = newValue } }

  func selectItem(_ item: Int, animated: Bool) {
    picker.selectItem(item, animated: animated)
  }

}
