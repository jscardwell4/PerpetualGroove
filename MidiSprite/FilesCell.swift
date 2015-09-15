//
//  FilesCell.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class FilesCell: UITableViewCell {

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  override class func requiresConstraintBasedLayout() -> Bool { return true }

  /** updateConstraints */
  override func updateConstraints() {
    super.updateConstraints()
    guard let textLabel = textLabel else { fatalError("wtf") }
    let id = Identifier(self, "Internal")
    guard constraintsWithIdentifier(id).count == 0 else { return }
    constrain([𝗛|contentView|𝗛, 𝗩|contentView|𝗩, 𝗩|textLabel|𝗩, 𝗛|textLabel|𝗛, [width => 150, height => 44]] --> id)
  }

  private func setup() {
    translatesAutoresizingMaskIntoConstraints = false
    contentView.translatesAutoresizingMaskIntoConstraints = false
    guard let textLabel = textLabel else { fatalError("wtf") }
    textLabel.translatesAutoresizingMaskIntoConstraints = false
    setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    contentView.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
    textLabel.setContentHuggingPriority(UILayoutPriorityRequired, forAxis: .Horizontal)
  }

  /**
  initWithStyle:reuseIdentifier:

  - parameter style: UITableViewCellStyle
  - parameter reuseIdentifier: String?
  */
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    setup()
  }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    setup()
  }
}