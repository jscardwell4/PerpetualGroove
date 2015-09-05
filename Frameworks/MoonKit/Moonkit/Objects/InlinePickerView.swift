//
//  InlinePickerView.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/14/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit


@IBDesignable public class InlinePickerView: UIView {

  private enum CellType: String { case Label, Image }

  private var cellType = CellType.Label { didSet { reloadData() } }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override public init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

  /**
  init:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeIVARs() }

  /**
  initWithLabels:

  - parameter labels: [String]
  */
  public init(labels: [String]) { super.init(frame: .zero); self.labels = labels; cellType = .Label; initializeIVARs() }

  /**
  initWithImages:

  - parameter images: [UIImage]
  */
  public init(images: [UIImage]) { super.init(frame: .zero); self.images = images; cellType = .Image; initializeIVARs() }

  /** initializeIVARs */
  private func initializeIVARs() {

    setContentCompressionResistancePriority(750, forAxis: .Horizontal)
    setContentCompressionResistancePriority(1000, forAxis: .Vertical)
    translatesAutoresizingMaskIntoConstraints = false
    nametag = "picker"

    addSubview(collectionView)
    collectionView.nametag = "collectionView"
    layout.delegate = self
    collectionView.scrollEnabled = false
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.bounces = false
    collectionView.backgroundColor = UIColor.clearColor()
    collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    updatePerspective()
    collectionView.registerClass(InlinePickerViewLabelCell.self, forCellWithReuseIdentifier: CellType.Label.rawValue)
    collectionView.registerClass(InlinePickerViewImageCell.self, forCellWithReuseIdentifier: CellType.Image.rawValue)
    collectionView.reloadData()
  }

  /** updatePerspective */
  private func updatePerspective() {
    collectionView.layer.sublayerTransform =
      usePerspective
      ? CATransform3D(
        m11: 1, m12: 0, m13: 0, m14: 0,
        m21: 0, m22: 1, m23: 0, m24: 0,
        m31: 0, m32: 0, m33: 0, m34: CGFloat(-1.0/1000.0),
        m41: 0, m42: 0, m43: 0, m44: 1
        )
      : CATransform3DIdentity
  }

  /** updateConstraints */
  override public func updateConstraints() {
    removeAllConstraints()
    super.updateConstraints()
    constrain(𝗛|collectionView|𝗛, 𝗩|collectionView|𝗩)
    constrain(height ≥ (itemHeight ?? defaultItemHeight))
  }

  private let collectionView = UICollectionView(frame: .zero, collectionViewLayout: InlinePickerViewLayout())
  private var layout: InlinePickerViewLayout { return collectionView.collectionViewLayout as! InlinePickerViewLayout }

  /**
  requiresConstraintBasedLayout

  - returns: Bool
  */
  override public class func requiresConstraintBasedLayout() -> Bool { return true }

  /**
  intrinsicContentSize

  - returns: CGSize
  */
  override public func intrinsicContentSize() -> CGSize {
    guard let maxItemWidth = itemWidths.maxElement() else {
      return CGSize(width: UIViewNoIntrinsicMetric, height: itemHeight ?? defaultItemHeight)
    }
    return CGSize(width: maxItemWidth * 3, height: itemHeight ?? defaultItemHeight)
  }

  override public var description: String {
    return super.description + "\n\t" + "\n\t".join(
      "count = \(count)",
      "cellType = \(cellType)",
      "collectionView = \(collectionView.description)",
      "collectionViewLayout = \(collectionView.collectionViewLayout.description)"
    )
  }

  /**
  selectItem:animated:

  - parameter item: Int
  - parameter animated: Bool
  */
  public func selectItem(item: Int, animated: Bool) {
    guard (0 ..< count).contains(item) else { MSLogWarn("\(item) is not a valid item index"); return }

    selection = item
    if let offset = layout.offsetForItemAtIndex(selection) {
      collectionView.selectItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0),
                                  animated: false,
                            scrollPosition: .None)
      MSLogVerbose("selecting cell for item \(selection) where offset = \(offset)")
      collectionView.setContentOffset(offset, animated: animated)
    } else {
      MSLogVerbose("could not get an offset for item \(item), invalidating layout …")
      layout.invalidateLayout()
    }
  }

  /** layoutSubviews */
  public override func layoutSubviews() {
    super.layoutSubviews()
    if selection > -1 { selectItem(selection, animated: false) }
  }

  public var images: [UIImage] = [] { didSet { cellType = .Image } }
  public var labels: [String] = [] { didSet { cellType = .Label } }

  public var didSelectItem: ((InlinePickerView, Int) -> Void)?

  public static let DefaultFont = UIFont.preferredFontForTextStyle(UIFontTextStyleBody)
  public var font = InlinePickerView.DefaultFont
  @IBInspectable public var fontName: String =  InlinePickerView.DefaultFont.fontName {
    didSet {
      if let font = UIFont(name: fontName, size: font.pointSize) { self.font = font }
      else { fontName = oldValue }
    }
  }
  @IBInspectable public var fontSize: CGFloat =  InlinePickerView.DefaultFont.pointSize {
    didSet { font = font.fontWithSize(fontSize) }
  }

  @IBInspectable public var textColor: UIColor = .darkTextColor()

  public var selectedFont =  InlinePickerView.DefaultFont
  @IBInspectable public var selectedFontName: String =  InlinePickerView.DefaultFont.fontName {
    didSet {
      if let font = UIFont(name: selectedFontName, size: selectedFont.pointSize) { selectedFont = font }
      else { selectedFontName = oldValue }
    }
  }
  @IBInspectable public var selectedFontSize: CGFloat =  InlinePickerView.DefaultFont.pointSize {
    didSet { selectedFont = selectedFont.fontWithSize(selectedFontSize) }
  }

  @IBInspectable public var labelsString: String = "" { didSet { labels = ", ".split(labelsString) } }
  @IBInspectable public var imagesString: String = "" { didSet { images = ", ".split(imagesString).flatMap({UIImage(named: $0)}) } }
  @IBInspectable public var selectedTextColor: UIColor = .darkTextColor()
  @IBInspectable public var imageColor: UIColor = .darkTextColor()
  @IBInspectable public var imageSelectedColor: UIColor = .darkTextColor()

  /** reloadData */
  public func reloadData() {
    layout.invalidateLayout()
    setNeedsLayout()
    collectionView.setNeedsLayout()
    collectionView.reloadData()
    collectionView.layoutIfNeeded()
    layoutIfNeeded()
  }

  public var defaultItemHeight: CGFloat {
    switch cellType {
      case .Label: return ceil(max(font.lineHeight, selectedFont.lineHeight)) * 2
      case .Image: return 44
    }
  }

  @IBInspectable public var itemHeight: CGFloat?
  @IBInspectable public var itemPadding: CGFloat = 8.0 { didSet { reloadData() } }
  @IBInspectable public var usePerspective = false { didSet { updatePerspective() } }

  var itemWidths: [CGFloat] {
    switch cellType {
      case .Label: return labels.map {[a = [NSFontAttributeName:font]] in ceil($0.sizeWithAttributes(a).width)}
      case .Image:
        let h = itemHeight ?? defaultItemHeight
        return images.map {
        let size = $0.size
        let ratio = Ratio<CGFloat>(size.width / size.height)
        return ceil(ratio.numeratorForDenominator(h))
      }
    }
  }

  var selection: Int = -1

  public var selectedItemFrame: CGRect? {
    guard selection > -1,
      let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0)) where cell.selected
    else { return nil }

    var frame = cell.frame
    frame.origin = frame.origin - collectionView.contentOffset
    return frame
  }

  public var editing = false { didSet { collectionView.scrollEnabled = editing; reloadData() } }

  private var count: Int { switch cellType { case .Label: return labels.count; case .Image: return images.count } }
}

// MARK: - UICollectionViewDataSource
extension InlinePickerView: UICollectionViewDataSource {


  /**
  collectionView:numberOfItemsInSection:

  - parameter collectionView: UICollectionView
  - parameter section: Int

  - returns: Int
  */
  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int { return count }

  /**
  collectionView:cellForItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: UICollectionViewCell
  */
  public func collectionView(collectionView: UICollectionView,
      cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(cellType.rawValue,
                                                        forIndexPath: indexPath) as! InlinePickerViewCell

    switch cell {
      case let labelCell as InlinePickerViewLabelCell:
        let text = labels[indexPath.item]
        labelCell.text = text ¶| [font, textColor]
        labelCell.selectedText = text ¶| [selectedFont, selectedTextColor]

      case let imageCell as InlinePickerViewImageCell:
        imageCell.image = images[indexPath.item]
        imageCell.imageColor = imageColor
        imageCell.imageSelectedColor = imageSelectedColor

      default: break // Should be unreachable
    }
    return cell
  }
}

// MARK: - UICollectionViewDelegate
extension InlinePickerView: UICollectionViewDelegate {

  /**
  collectionView:shouldSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  public func collectionView(collectionView: UICollectionView, shouldSelectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
  }

  /**
  collectionView:shouldDeselectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return false
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    didSelectItem?(self, indexPath.item)
  }

  /**
  collectionView:willDisplayCell:forItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter cell: UICollectionViewCell
  - parameter indexPath: NSIndexPath
  */
  public func collectionView(collectionView: UICollectionView,
             willDisplayCell cell: UICollectionViewCell,
          forItemAtIndexPath indexPath: NSIndexPath)
  {
    if indexPath.item == selection {
      collectionView.selectItemAtIndexPath(indexPath, animated: false, scrollPosition: .None)
      cell.selected = true
    }
    if editing && cell.hidden { cell.hidden = false }
  }
}

extension InlinePickerView: UIScrollViewDelegate {
  /**
  scrollViewDidEndDecelerating:

  - parameter scrollView: UIScrollView
  */
  public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    guard let item = collectionView.indexPathsForSelectedItems()?.first?.item else {
      MSLogVerbose("failed to get index path for selected cell")
      return
    }
    // invoke selection handler
    didSelectItem?(self, item)
  }
  /**
  scrollViewWillEndDragging:withVelocity:targetContentOffset:

  - parameter scrollView: UIScrollView
  - parameter velocity: CGPoint
  - parameter targetContentOffset: UnsafeMutablePointer<CGPoint>
  */
  public func scrollViewWillEndDragging(scrollView: UIScrollView,
                          withVelocity velocity: CGPoint,
                   targetContentOffset: UnsafeMutablePointer<CGPoint>)
  {
    let offset = targetContentOffset.memory
    guard let item = (collectionView.collectionViewLayout as! InlinePickerViewLayout).indexOfItemAtOffset(offset) else {
      MSLogVerbose("failed to get index path for cell at point \(offset)")
      return
    }

    guard item != selection else { MSLogVerbose("item already selected"); return }

    // update selection
    MSLogVerbose("selecting cell for item \(item) where offset = \(offset)")

    if selection > -1 { collectionView.deselectItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0), animated: true) }
    selection = item
    collectionView.selectItemAtIndexPath(NSIndexPath(forItem: item, inSection: 0), animated: true, scrollPosition:.None)
  }
}