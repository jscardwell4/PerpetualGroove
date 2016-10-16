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

  private var storedAttributes: OrderedDictionary<IndexPath, UICollectionViewLayoutAttributes> = [:]

  weak var controller: DocumentsViewController?

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

  override var collectionViewContentSize: CGSize {
    let w = storedAttributes.values.reduce(0, {max($0, $1.frame.maxX)})
    let h = storedAttributes.values.reduce(0, {max($0, $1.frame.maxY)})
    return CGSize(width: w, height: h)
  }

  override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    return storedAttributes.values.filter { $0.frame.intersects(rect) }
  }

  override func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
    let attributesClass = type(of: self).layoutAttributesClass as! UICollectionViewLayoutAttributes.Type
    let attributes = attributesClass.init(forCellWith: indexPath)

    let size = controller?.itemSize ?? CGSize(width: 250, height: 40)

    switch indexPath.section {
      case 0:
        attributes.frame = CGRect(origin: .zero, size: size)
      default:
        attributes.frame = CGRect(origin: CGPoint(x: 0, y: CGFloat(indexPath.row + 1) * size.height), size: size)
    }

    return attributes
  }

}
