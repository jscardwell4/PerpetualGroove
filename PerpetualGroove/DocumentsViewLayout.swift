//
//  DocumentsViewLayout.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/2/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit

final class DocumentsViewLayout: UICollectionViewLayout {

  fileprivate typealias AttributesIndex = OrderedDictionary<IndexPath, UICollectionViewLayoutAttributes>

  fileprivate var storedAttributes: AttributesIndex = [:]

  weak var controller: DocumentsViewController?

  fileprivate var itemSize: CGSize {
    assert(controller != nil)
    return controller?.itemSize ?? CGSize(width: 250, height: 40)
  }
  
  /** prepareLayout */
  override func prepare() {
    super.prepare()
    guard let collectionView = collectionView else { storedAttributes = [:]; return }
    storedAttributes.removeAll(keepingCapacity: true)
      for (k, v) in
        (0 ..< collectionView.numberOfSections).flatMap({
          s in (0 ..< collectionView.numberOfItems(inSection: s)).map({
            r in IndexPath(row: r, section: s)
          })
        }).map({
          ($0, self.layoutAttributesForItem(at: $0)!)
        })
      {
        storedAttributes[k] = v
    }
  }


  /**
  collectionViewContentSize

  - returns: CGSize
  */
  override var collectionViewContentSize: CGSize {
    let w = storedAttributes.values.reduce(0, {max($0, $1.frame.maxX)})
    let h = storedAttributes.values.reduce(0, {max($0, $1.frame.maxY)})
    return CGSize(width: w, height: h)
  }

  /**
  layoutAttributesForElementsInRect:

  - parameter rect: CGRect

  - returns: [AnyObject]?
  */
  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return storedAttributes.values.filter { $0.frame.intersects(rect) }
  }

  

  /**
  layoutAttributesForItemAtIndexPath:

  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewLayoutAttributes!
  */
  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let attributesClass = type(of: self).layoutAttributesClass as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWith: indexPath)

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
