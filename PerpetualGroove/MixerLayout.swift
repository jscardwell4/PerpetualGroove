//
//  MixerLayout.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/10/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class MixerLayout: UICollectionViewLayout {

  static let itemSize = CGSize(width: 100, height: 575)
  static let magnifiedItemSize = CGSize(width: 104.347826086957, height: 600)

  static private let SecondaryControllerKind = "SecondaryController"
  static private let secondaryControllerIndexPath = NSIndexPath(forItem: 0, inSection: 3)

  @IBOutlet weak var delegate: MixerViewController!

  private var previouslyMagnifiedItem: NSIndexPath?
  var magnifiedItem: NSIndexPath? {
    didSet {
      guard magnifiedItem != oldValue else { return }
//      if magnifiedItem == nil { magnifiedItemOffset = 0 }
      invalidateLayout()
    }
  }

//  var magnifiedItemOffset: CGFloat = 0 { didSet { guard magnifiedItemOffset != oldValue && magnifiedItem != nil else { return }; invalidateLayout() } }

  var presentingSecondaryController: Bool = false {
    didSet {
      guard presentingSecondaryController != oldValue else { return }
      invalidateLayout()
    }
  }

  private typealias AttributesIndex = OrderedDictionary<NSIndexPath, UICollectionViewLayoutAttributes>
  private var storedAttributes: AttributesIndex = [:]

  /** prepareLayout */
  override func prepareLayout() {
    super.prepareLayout()

    guard let collectionView = collectionView else { storedAttributes = [:]; return }

    storedAttributes = AttributesIndex(
      (0 ..< collectionView.numberOfSections()).flatMap {
        s in (0 ..< collectionView.numberOfItemsInSection(s)).map { r in NSIndexPath(forRow: r, inSection: s) }
      } .map { ($0, self.layoutAttributesForItemAtIndexPath($0)!) }
    )
  }

  /**
  layoutAttributesForElementsInRect:

  - parameter rect: CGRect

  - returns: [UICollectionViewLayoutAttributes]?
  */
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    var result = Array(storedAttributes.values.filter({ $0.frame.intersects(rect) }))
    if presentingSecondaryController,
      let attributes = layoutAttributesForSupplementaryViewOfKind(MixerLayout.SecondaryControllerKind,
                                                      atIndexPath: MixerLayout.secondaryControllerIndexPath)
    {
      result.append(attributes)
    }
    return result
  }

  /**
  layoutAttributesForItemAtIndexPath:

  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewLayoutAttributes!
  */
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    guard collectionView != nil else { return nil }
    return attributesForItem(indexPath, magnified: magnifiedItem == indexPath)
  }

  /**
   attributesForItem:

   - parameter indexPath: NSIndexPath

    - returns: UICollectionViewLayoutAttributes
  */
  private func attributesForItem(indexPath: NSIndexPath, magnified: Bool = false) -> UICollectionViewLayoutAttributes {
    let attributesClass = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWithIndexPath: indexPath)

    let origin: CGPoint
    switch indexPath.section {
      case 0:
        origin = .zero
      case 1:
        origin = CGPoint(x: MixerLayout.itemSize.width * CGFloat(indexPath.item + 1), y: 0)
      case 2: fallthrough
      default:
        origin = CGPoint(x: MixerLayout.itemSize.width * CGFloat((collectionView?.numberOfItemsInSection(1) ?? 0 ) + 1), y: 0)
    }
    attributes.frame = CGRect(origin: origin, size: MixerLayout.itemSize)
    if magnified {
      var transform = CGAffineTransform(sx: 1.1, sy: 1.1)
      transform.translate(0, half(MixerLayout.itemSize.height * 1.1 - MixerLayout.itemSize.height))
      attributes.transform = transform
//      magnifyAttributes(attributes)
    }
    return attributes
  }

  /**
   magnifyAttributes:

   - parameter attributes: UICollectionViewLayoutAttributes
  */
//  private func magnifyAttributes(attributes: UICollectionViewLayoutAttributes) {
//    attributes.transform = CGAffineTransform(sx: 1.1, sy: 1.1).translated(0, half(MixerLayout.itemSize.height * 1.1 - MixerLayout.itemSize.height))
//    let 𝝙size = MixerLayout.magnifiedItemSize - MixerLayout.itemSize
//    attributes.frame.origin.x += magnifiedItemOffset - half(𝝙size.width)
//    attributes.frame.origin.y += 𝝙size.height
//    attributes.frame.size = MixerLayout.magnifiedItemSize
//  }

  /**
   prepareForCollectionViewUpdates:

   - parameter updateItems: [UICollectionViewUpdateItem]
  */
  override func prepareForCollectionViewUpdates(updateItems: [UICollectionViewUpdateItem]) {
    defer { super.prepareForCollectionViewUpdates(updateItems) }
    guard updateItems.count == 1,
      let updateItem = updateItems.first,
          beforePath = updateItem.indexPathBeforeUpdate where magnifiedItem == beforePath,
      let afterPath = updateItem.indexPathAfterUpdate else { return }
    previouslyMagnifiedItem = beforePath
    magnifiedItem = afterPath
//    if previouslyMagnifiedItem < magnifiedItem { magnifiedItemOffset = -half(MixerLayout.itemSize.width) }
//    else { magnifiedItemOffset = half(MixerLayout.itemSize.width) }
  }

//  override func initialLayoutAttributesForAppearingItemAtIndexPath(path: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//    let attributes = attributesForItem(path)
//    if magnifiedItem == path {
//      magnifyAttributes(attributes)
//      attributes.hidden = true
//    }
//    return attributes
//  }

//  override func finalLayoutAttributesForDisappearingItemAtIndexPath(path: NSIndexPath) -> UICollectionViewLayoutAttributes? {
//    switch (previouslyMagnifiedItem, magnifiedItem) {
//    case let (previous?, current?) where path == previous: return attributesForItem(current, magnified: true)
//    default:                                               return attributesForItem(path)
//    }
//  }

  /**
   layoutAttributesForSupplementaryViewOfKind:atIndexPath:

   - parameter elementKind: String
   - parameter indexPath: NSIndexPath

    - returns: UICollectionViewLayoutAttributes?
  */
  override func layoutAttributesForSupplementaryViewOfKind(elementKind: String,
    atIndexPath indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes?
  {
    guard let collectionView = collectionView else { return nil }

    let attributesClass = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forSupplementaryViewOfKind: elementKind, withIndexPath: indexPath)
    attributes.frame = collectionView.bounds
    attributes.zIndex = 100
    return attributes
  }

  /**
  collectionViewContentSize

  - returns: CGSize
  */
  override func collectionViewContentSize() -> CGSize {
    let w = storedAttributes.values.reduce(0, combine: {max($0, $1.frame.maxX)})
    let h = storedAttributes.values.reduce(0, combine: {max($0, $1.frame.maxY)})
    return CGSize(width: w, height: h)
  }

}