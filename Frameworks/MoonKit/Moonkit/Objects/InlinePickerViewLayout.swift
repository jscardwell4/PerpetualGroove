//
//  InlinePickerViewLayout.swift
//  MoonKit
//
//  Created by Jason Cardwell on 7/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

class InlinePickerViewLayout: UICollectionViewLayout {

  class Attributes: UICollectionViewLayoutAttributes {

    var zPosition: CGFloat = 0

    /**
    isEqual:

    - parameter object: AnyObject?

    - returns: Bool
    */
    override func isEqual(object: AnyObject?) -> Bool {
      return super.isEqual(object) && (object as? Attributes)?.zPosition == zPosition
    }

    /**
    copyWithZone:

    - parameter zone: NSZone

    - returns: AnyObject
    */
    override func copyWithZone(zone: NSZone) -> AnyObject {
      let result: Attributes = super.copyWithZone(zone) as! Attributes
      result.zPosition = zPosition
      return result
    }

    override var description: String {
      return "{\n\t" + "\n\t".join(
        "item: \(indexPath.item)",
        "frame: \(frame)",
        "transform: \(transform)",
        "transform3D: {\n\(NSStringFromCATransform3D(transform3D).indentedBy(8))\n\t\t}",
        "alpha: \(alpha)",
        "hidden: \(hidden)",
        "zPosition: \(zPosition)"
        ) + "\n}"
    }
  }

  // MARK: - Typealiases
  private typealias AttributesIndex = OrderedDictionary<NSIndexPath, Attributes>

  // MARK: - Exposed properties and methods

  weak var delegate: InlinePickerView?

  var flat = true { didSet { invalidateLayout() } }

  /// A private struct for use as a cache of the values necessary to perform layout-related calculations
  private struct LayoutValues: CustomStringConvertible {
    var widths: [CGFloat] = []              /// Cache of widths provided by `delegate`
    var height: CGFloat = 0                 /// Caches `itemHeight` provided by `delegate`
    var padding: CGFloat = 8                /// Padding value provided by `delegate`
    var selection = -1                      /// Caches the `selection` property of `delegate`
    var rect = CGRect.zero                  /// Frame used during calculations
    var count = 0                           /// The total item count

    var description: String {
      return "{rect: \(rect); height: \(height); padding: \(padding); selection: \(selection); widths: \(widths)}"
    }

    var complete: Bool {
      return height > 0 && widths.count == count && (0 ..< count).contains(selection) && !rect.isEmpty
    }

    static let zeroValues = LayoutValues()
  }

  // MARK: - Internally used properties
  private var storedAttributes: AttributesIndex = [:] /// Holds all the calculated layout attributes
  private var contentSize = CGSize.zero           /// Size calculated for the content
  private var rawFrames: [CGRect] = []                /// Cache of cell frames without any transforms applied
  private var contentPadding: CGFloat = 0             /// Space before and after the first and last cells
  private var values: LayoutValues = .zeroValues      /// Current set of values cached from `delegate`

  // MARK: - UICollectionViewLayout method overrides

  var attributesDescription: String {
    return "{\n\t" + ",\n".join(storedAttributes.values.map {$0.description.indentedBy(8)}) + "\n}"
  }

  override var description: String {
    var result = super.description + "\n"
    result += "values = \(values)\n"
    result += "contentSize = \(contentSize)\n"
    result += "rawFrames = \(rawFrames)\n"
    result += "contentPadding = \(contentPadding)\n"
    result += "storedAttributes = \(attributesDescription.indentedBy(4, preserveFirst: true))"
    return result
  }

  /** clearCache */
  private func clearCache() {
    values = .zeroValues
    contentSize = CGSize.zero
    rawFrames.removeAll(keepCapacity: true)
    contentPadding = 0
  }

  /**
  shouldInvalidateLayoutForBoundsChange:

  - parameter newBounds: CGRect

  - returns: Bool
  */
  override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool { return true }

  /**
  layoutAttributesClass

  - returns: AnyClass
  */
  override class func layoutAttributesClass() -> AnyClass { return Attributes.self }

  /** prepareLayout */
  override func prepareLayout() {
    super.prepareLayout()
    guard let delegate = delegate, collectionView = collectionView else {
      logVerbose("Missing delegate, collectionView or both … clearing cache and skipping prep")
      clearCache()
      return
    }

    let itemCount = collectionView.numberOfItemsInSection(0)

    guard itemCount > 0 else {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> collection is empty … clearing cache and skipping prep")
      clearCache()
      return
    }

    values.count = itemCount
    let itemWidths = delegate.itemWidths

    guard delegate.itemWidths.count == collectionView.numberOfItemsInSection(0) else {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> delegate.itemWidths.count != itemCount … clearing cache and skipping prep")
      clearCache()
      return
    }

    values.widths = itemWidths

    let selection = delegate.selection

    guard (0 ..< itemCount).contains(selection) else {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> no valid selection, really no point in performing calculations now … clearing cache and skipping prep")
      clearCache()
      return
    }
    values.selection = selection

    let rect = collectionView.bounds
    guard !rect.isEmpty else {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> visible rect is empty … clearing cache and skipping prep")
      clearCache()
      return
    }
    values.rect = rect

    values.padding = delegate.itemPadding
    values.height = delegate.itemHeight ?? delegate.defaultItemHeight

    performInitialCalculations()

    guard rawFrames.count == itemCount else {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> something went wrong performing initial calculations … clearning cache and skipping prep")
      clearCache()
      return
    }

    let interactiveSelectionInProgress = collectionView.decelerating || collectionView.tracking || collectionView.dragging
    let offsetXAlignment = rawFrames[selection].midX - rect.midX

    if !interactiveSelectionInProgress && offsetXAlignment != 0 {
      logVerbose("<\(ObjectIdentifier(collectionView).uintValue)> collection view is stationary and the collection view's x offset (\(rect.origin.x)) does not match " +
                   "selected item's x offset (\(rawFrames[selection].midX)) … adjusting by \(offsetXAlignment)")
      values.rect.origin.x += offsetXAlignment
      collectionView.setContentOffset(values.rect.origin, animated: false)
    }

    storedAttributes = AttributesIndex(
      (0 ..< itemCount).map { NSIndexPath(forItem: $0, inSection: 0) } .map {
        ($0, self.layoutAttributesForItemAtIndexPath($0)!)
      }
    )
  }

  /** performInitialCalculations */
  private func performInitialCalculations() {
    guard values.complete else {
      logVerbose("performInitialCalculations() should only be called when `values` is `complete`…skipping calculations")
      return
    }
    let padding = values.padding
    let widths = values.widths
    let height = values.height
    let visibleHeight = values.rect.height
    let visibleWidth = values.rect.width

    let sumOfWidths = widths.sum
    let sumOfCellPadding = CGFloat(widths.count - 1) * padding

    contentPadding = (sumOfWidths + sumOfCellPadding) / 2
    let contentWidth = sumOfWidths + sumOfCellPadding + contentPadding * 2

    contentSize = CGSize(width: max(contentWidth, visibleWidth * 2), height: height)

    if case let delta = contentSize.width - contentWidth where delta != 0 { contentPadding += delta / 2 }

    rawFrames.removeAll(keepCapacity: true)
    var x = contentPadding
    for width in values.widths {
      rawFrames.append(CGRect(x: x, y: (visibleHeight - height) / 2, width: width, height: height))
      x += width + padding
    }
  }

  /**
  collectionViewContentSize

  - returns: CGSize
  */
  override func collectionViewContentSize() -> CGSize { return contentSize }

  /**
  layoutAttributesForElementsInRect:

  - parameter rect: CGRect

  - returns: [AnyObject]?
  */
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    let attributes = Array(storedAttributes.values.filter { $0.frame.intersects(rect) })
    return attributes.count > 0 ? attributes : nil
  }

  /**
  layoutAttributesForItemAtIndexPath:

  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewLayoutAttributes!
  */
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> Attributes? {
    guard indexPath.item < rawFrames.count else {
      logWarning("invalid index path: \(indexPath)")
      return nil
    }

    let attributes = Attributes(forCellWithIndexPath: indexPath)
    attributes.frame = rawFrames[indexPath.item]

    if !flat { applyTransformToAttributes(attributes) }

    return attributes
  }

  /**
  applyTransformToAttributes:

  - parameter attributes: UICollectionViewLayoutAttributes
  */
  private func applyTransformToAttributes(attributes: Attributes) {
    guard values.complete, let editing = delegate?.editing else { return }
    let item = attributes.indexPath.item
    let frame = attributes.frame
    let d = frame.midX - values.rect.midX
    let r = half(values.rect.width)

    let L = half(π) * r
    let l = d / r * L

    let alpha = l / r
    let sigma = CGFloat(M_PI_2) - alpha
    let theta = !editing && values.selection == item ? 0 : (half(π) - sigma)// * (values.rect.width / contentSize.width)

    let tx = !editing && values.selection == item ? values.rect.maxX - frame.maxX : 0
//    let tz = !editing ? 0 : (1 - abs((d % r) / r)) * r

    attributes.transform3D = CATransform3D(
      m11: cos(theta), m12: 0, m13: -sin(theta), m14: 0,
      m21: 0, m22: 1, m23: 0, m24: 0,
      m31: sin(theta), m32: 0, m33: cos(theta), m34: 0,
      m41: tx, m42: 0, m43: 0, m44: 1
    )

//    attributes.zPosition = !editing ? 0 : (1 - d / r) * r //sin(sigma) * r
    attributes.alpha = abs(theta) >= CGFloat(M_PI_2) ? 0 : 1
    attributes.hidden = !editing && values.selection != item
  }

  /**
  offsetForProposedOffset:

  - parameter offset: CGPoint

  - returns: CGPoint
  */
  private func offsetForProposedOffset(offset: CGPoint) -> CGPoint {
    guard let idx = indexOfItemAtOffset(offset) else {
      logVerbose("failed to get an index for offset, returning proposed value: \(offset)")
      return offset
    }
    guard let calculatedOffset = offsetForItemAtIndex(idx) else {
      logVerbose("failed to calculate an offset for item at index \(idx), returning proposed value: \(offset)")
      return offset
    }
    return calculatedOffset
  }

  /**
  Returns the content offset for the center of a given cell

  - parameter index: Int

  - returns: CGPoint
  */
  func offsetForItemAtIndex(index: Int) -> CGPoint? {
    guard let attributes = storedAttributes[NSIndexPath(forItem: index, inSection: 0)] where values.complete else {
      logVerbose("cannot generate an offset for an item which has no attributes stored")
      return nil
    }
    return CGPoint(x: attributes.frame.midX - values.rect.width / 2, y: 0)
  }

  /**
  indexOfItemAtOffset:

  - parameter offset: CGPoint

  - returns: Int?
  */
  func indexOfItemAtOffset(offset: CGPoint) -> Int? {
    guard storedAttributes.count > 0 else {
      logVerbose("storedAttributes.count = 0 … returning nil")
      return nil
    }

    let offsets = (0 ..< storedAttributes.count).flatMap {self.offsetForItemAtIndex($0)}
    guard offsets.count == storedAttributes.count else {
      logVerbose("storedAttributes.count = \(storedAttributes.count) but offsets.count = \(offsets.count) … returning nil")
      return nil
    }

    let result: Int

    // Check for an exact match
    if let idx = offsets.indexOf(offset) { result = idx }

    // Otherwise use a switch to rule out base cases
    else {
      switch offsets.count {
        case 1, _ where offsets[0].x > offset.x:      // Single-item array or the first item is greater than the offset
          result = 0
        case let c where offsets[c - 1].x < offset.x: // Offset is greater than the last item
          result = c - 1
        default:                                      // Could be one of two choices, return the nearest of the two to the offset
          guard let i = offsets.indexOf({$0.x > offset.x}) else { return nil }
          let d1 = abs(offsets[i].x - offset.x)
          let d2 = abs(offsets[i - 1].x - offset.x)
          result = d1 < d2 ? i : i - 1
      }
    }

    return result
  }

  /**
  targetContentOffsetForProposedContentOffset:

  - parameter proposedContentOffset: CGPoint

  - returns: CGPoint
  */
  override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint) -> CGPoint {
    return offsetForProposedOffset(proposedContentOffset)
  }

  /**
  targetContentOffsetForProposedContentOffset:withScrollingVelocity:

  - parameter proposedContentOffset: CGPoint
  - parameter velocity: CGPoint

  - returns: CGPoint
  */
  override func targetContentOffsetForProposedContentOffset(proposedContentOffset: CGPoint,
                                      withScrollingVelocity velocity: CGPoint) -> CGPoint
  {
    return offsetForProposedOffset(proposedContentOffset)
  }

}
