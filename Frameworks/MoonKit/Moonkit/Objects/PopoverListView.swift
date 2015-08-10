//
//  PopoverListView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/9/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
public class PopoverListView: PopoverView {

  public typealias Action = (PopoverListView) -> Void

  /** Struct for holding the data associated with a single label in the list */
  public struct LabelData {
    public let text: String
    public let action: Action
    public init(text t: String, action a: Action) { text = t; action = a }
  }

  /** Storage for the color passed through to labels for property of the same name */
  public var font: UIFont = UIFont.preferredFontForTextStyle(UIFontTextStyleHeadline) {
    didSet { labels.apply {[font = font] in $0.font = font} }
  }

  /** Storage for the color passed through to labels for property of the same name */
  public var textColor: UIColor = UIColor.whiteColor() {
    didSet { labels.apply {[color = textColor] in $0.textColor = color} }
  }

  /** Storage for the color passed through to labels for property of the same name */
  public var highlightedTextColor: UIColor = UIColor(name: "dodger-blue")! {
    didSet { labels.apply {[color = highlightedTextColor] in $0.highlightedTextColor = color} }
  }

  /** The data used to generate `LabelButton` instances */
  private let data: [LabelData]

  /** Stack view used to arrange the label buttons */
  private weak var stackView: UIStackView!

  /** updateConstraints */
  public override func updateConstraints() {
    super.updateConstraints()

    let id = Identifier(self, "Internal")

    guard constraintsWithIdentifier(id).count == 0 else { return }

    var topOffset:    CGFloat = location == .Top    ? arrowHeight : 0
    var bottomOffset: CGFloat = location == .Bottom ? arrowHeight : 0

    guard let effect = contentView?.superview as? UIVisualEffectView else { return }

    constrain(
      𝗛|effect|𝗛 --> id, // Shouldn't this throw an exception for hierarchy?
      [
        effect.top => top - topOffset,
        effect.bottom => bottom + bottomOffset
      ] --> id
    )

    if location == .Top { bottomOffset += arrowHeight } else { topOffset += bottomOffset }

    constrain(𝗛|--8--stackView--8--|𝗛 --> id, 𝗩|--topOffset--stackView--bottomOffset--|𝗩 --> id)
  }

    /** Convenience accessor for the view's `LabelButton` objects */
  private var labels: [LabelButton] { return stackView.arrangedSubviews as! [LabelButton] }

  /** initializeIVARs */
  override func initializeIVARs() {
    super.initializeIVARs()

    let stackView = UIStackView(arrangedSubviews: data.enumerate().map {
      idx, labelData in
      let label = LabelButton(action: { [unowned self] _ in
        self.touchBarrier?.removeFromSuperview()
        self.removeFromSuperview()
        labelData.action(self)
      })
      label.tag = idx
      label.font = self.font
      label.textColor = self.textColor
      label.text = labelData.text
      label.highlightedTextColor = self.highlightedTextColor
      label.backgroundColor = UIColor.clearColor()
      return label
      })
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .Vertical
    stackView.alignment = .Center
    stackView.distribution = .EqualSpacing
    stackView.baselineRelativeArrangement = true
    contentView.addSubview(stackView)
    self.stackView = stackView
  }

  /**
  initWithLabelData:dismissal:

  - parameter labelData: [LabelData]
  - parameter callback: ((PopoverView) -> Void
  */
  public init(labelData: [LabelData], dismissal callback: ((PopoverView) -> Void)?) {
    data = labelData
    super.init(dismissal: callback)
  }

  /**
  Initialization with coder is unsupported

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /**
  Overridden to return a size composed of the stacked `labels`

  - returns: CGSize
  */
  public override func intrinsicContentSize() -> CGSize {
    let labelSizes = labels.map {$0.intrinsicContentSize()}
    let w = min(labelSizes.map {$0.width}.maxElement()! + 16, UIScreen.mainScreen().bounds.width - 16)
    let h = sum(labelSizes.map {$0.height}) + arrowHeight + 16
    return CGSize(width: w, height: h)
  }

}
