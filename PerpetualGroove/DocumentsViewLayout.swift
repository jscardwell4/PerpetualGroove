//
//  DocumentsViewLayout.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

final class DocumentsViewLayout: UICollectionViewLayout {

  private typealias AttributesIndex = OrderedDictionary<NSIndexPath, UICollectionViewLayoutAttributes>

  private var storedAttributes: AttributesIndex = [:]

  weak var controller: DocumentsViewController?

  private var itemSize: CGSize {
    assert(controller != nil)
    return controller?.itemSize ?? CGSize(width: 250, height: 40)
  }
  
  /** prepareLayout */
  override func prepareLayout() {
    super.prepareLayout()
    guard let collectionView = collectionView else { storedAttributes = [:]; return }
    storedAttributes.removeAll(keepCapacity: true)
      for (k, v) in
        (0 ..< collectionView.numberOfSections()).flatMap({
          s in (0 ..< collectionView.numberOfItemsInSection(s)).map({
            r in NSIndexPath(forRow: r, inSection: s)
          })
        }).map({
          ($0, self.layoutAttributesForItemAtIndexPath($0)!)
        })
      {
        storedAttributes[k] = v
    }
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

  /**
  layoutAttributesForElementsInRect:

  - parameter rect: CGRect

  - returns: [AnyObject]?
  */
  override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return storedAttributes.values.filter { $0.frame.intersects(rect) }
  }

  

  /**
  layoutAttributesForItemAtIndexPath:

  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewLayoutAttributes!
  */
  override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    let attributesClass = self.dynamicType.layoutAttributesClass() as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWithIndexPath: indexPath)

    let size = itemSize

    switch indexPath.section {
      case 0:
        attributes.frame = CGRect(origin: .zero, size: size)
      default:
        attributes.frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(indexPath.row + 1) * size.height), size: size)
    }

    return attributes
  }

}