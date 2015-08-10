//: Playground - noun: a place where people can play

import Foundation
import UIKit
import MoonKit


let indicator: UIImageView = {
  let view = UIImageView(autolayout: true)
  view.nametag = "indicator"
  return view
  }()

let deleteButton: UIButton = {
  let button = UIButton(autolayout: true)
  button.nametag = "delete"
  button.backgroundColor = UIColor(red: 1.0, green: 0.0, blue: 0.0, alpha: 0.75)
  button.setTitle("Delete", forState: .Normal)
  return button
  }()

let chevron: UIImageView = {
  let view = UIImageView(autolayout: true)
  view.nametag = "chevron"
  view.image = UIImage(named: "766-arrow-right")
  view.contentMode = .ScaleAspectFit
  return view
  }()

let label: UILabel = {
  let view = UILabel(autolayout: true)
  view.nametag = "label"
  view.text = "Backgrounds"
  view.backgroundColor = UIColor.orangeColor()
  view.opaque = false
  return view
  }()

let contentSize = CGSize(width: 320, height: 44)

let cellView = UIView(frame:  CGRect(x: 0, y: 0, width: 320, height: 44))
cellView.backgroundColor = UIColor.redColor()
cellView.nametag = "cell"

let identifierBase = createIdentifier(cellView, "Internal")
let identifier = createIdentifierGenerator(identifierBase)

let contentView = UIView(autolayout: true)
contentView.backgroundColor = UIColor.greenColor()
contentView.nametag = "contentView"
cellView.addSubview(contentView)
cellView.constrain(
  𝗛|-contentView-|𝗛 --> identifier("ContainContent", "Horizontal"),
  𝗩|contentView|𝗩 --> identifier("ContainContent", "Vertical")
)
cellView.constrain(
  contentView.width => contentSize.width   --> identifier("Content", "Width"),
  contentView.height => contentSize.height --> identifier("Content", "Height")
)

contentView.addSubview(label)
contentView.addSubview(indicator)
contentView.addSubview(chevron)

cellView.constrain(
  chevron.centerY => contentView.centerY --> identifier("Chevron", "Vertical"),
  chevron.right => cellView.right - 20   --> identifier("Chevron", "Right"),
  chevron.width ≤ chevron.height         --> identifier("Chevron", "Proportion"),
  chevron.height => 22                   --> identifier("Chevron", "Size")
)
cellView.constrain(
  indicator.width ≤ indicator.height --> identifier("Indicator", "Proportion"),
  indicator.height => 22             --> identifier("Indicator", "Size")
)
cellView.constrain(
  label.centerY => contentView.centerY --> identifier("Label", "Vertical"),
  indicator.centerY => contentView.centerY --> identifier("Indicator", "Vertical"),
  indicator.right => contentView.left --> identifier("Indicator", "Horizontal")
)
cellView.constrain(indicator--20--label--8--chevron --> identifier("Spacing", "Horizontal"))
print("\n".join(cellView.constraints.map {$0.prettyDescription}))
print("\n")
print("\n".join(cellView.constraints.map {$0.description}))
contentView.setNeedsLayout()
contentView.layoutIfNeeded()
cellView.setNeedsLayout()
cellView.layoutIfNeeded()
cellView
