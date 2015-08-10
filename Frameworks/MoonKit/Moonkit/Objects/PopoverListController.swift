//
//  PopoverListController.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/22/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit

@available(iOS 9.0, *)
public class PopoverListController: UIViewController {

  /**
  Designated initializer

  - parameter listData: [LabelData]
  */
  public init(listData: [LabelData]) {
    data = listData
    super.init(nibName: nil, bundle: nil)
    modalPresentationStyle = .Popover
  }

  /**
  Initialize with coder unsupported

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { fatalError("init(coder:) has not been implemented") }

  /** Typealias for the action performed when the user touches a `LabelButton` in the list */
  public typealias Action = (PopoverListController) -> Void

  /** Struct for holding the data associated with a single label in the list */
  public struct LabelData {
    public let text: String
    public let action: Action
    public init(text t: String, action a: Action) { text = t; action = a }
  }

  /** The data used to generate `LabelButton` instances */
  private let data: [LabelData]

  /** Stack view used to arrange the label buttons */
  private weak var stackView: UIStackView!

  /** Convenience accessor for the view's subviews as `UILabel` objects */
  private var labels: [LabelButton] { return stackView.arrangedSubviews as! [LabelButton] }

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

  /** loadView */
  public override func loadView() {
    view = UIView(autolayout: true)
    let stackView = UIStackView(arrangedSubviews: data.enumerate().map {
      idx, labelData in
      let label = LabelButton(autolayout: true)
      label.tag = idx
      label.font = self.font
      label.textColor = self.textColor
      label.text = labelData.text
      label.highlightedTextColor = self.highlightedTextColor
      label.backgroundColor = UIColor.clearColor()
      label.userInteractionEnabled = true
      label.actions.append {[unowned self] _ in labelData.action(self)}
      return label
    })
    stackView.translatesAutoresizingMaskIntoConstraints = false
    stackView.axis = .Vertical
    stackView.alignment = .Center
    stackView.distribution = .EqualSpacing
    stackView.baselineRelativeArrangement = true
    view.addSubview(stackView)
    self.stackView = stackView
    view.setNeedsUpdateConstraints()
  }

  /** updateViewConstraints */
  public override func updateViewConstraints() {
    super.updateViewConstraints()
    let id = Identifier(self, "View")
    guard view.constraintsWithIdentifier(id).count == 0 else { return }
    view.constrain(𝗛|stackView|𝗛 --> id, 𝗩|stackView|𝗩 --> id)
    let intrinsicSizes = stackView.arrangedSubviews.map { $0.intrinsicContentSize() }
    let w = intrinsicSizes.reduce(0) { max($0, $1.width) }
    let h = intrinsicSizes.reduce(0) { [spacing = stackView.spacing] in $0 + $1.height + spacing }
    view.constrain(stackView.width => w --> id, stackView.height => h --> id)
  }

  /**
  Generate a new `LabelButton` with the specified data

  - parameter labelData: LabelData

  - returns: LabelButton
  */
//  private func labelWithData(labelData: LabelData) -> LabelButton {
//    let label = LabelButton(autolayout: true)
//    label.tag = labels.count
//    label.font = font
//    label.textColor = textColor
//    label.text = labelData.text
//    label.highlightedTextColor = highlightedTextColor
//    label.backgroundColor = UIColor.clearColor()
//    label.userInteractionEnabled = true
//    label.actions.append {[unowned self] _ in labelData.action(self)}
//    return label
//  }

  /**
  Method to add a new label with the specified text and action

  - parameter labelData: LabelData
  */
//  public func addLabelWithData(labelData: LabelData) {
//    data.append(labelData)
//    if isViewLoaded() { stackView.addArrangedSubview(labelWithData(labelData)) }
//  }
}
