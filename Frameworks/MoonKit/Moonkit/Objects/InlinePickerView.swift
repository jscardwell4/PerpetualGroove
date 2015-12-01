//
//  InlinePickerView.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/14/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation
import UIKit

//@IBDesignable
public class InlinePickerView: UIControl {

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
    userInteractionEnabled = true
    addSubview(collectionView)
    collectionView.registerClass(InlinePickerViewLabelCell.self, forCellWithReuseIdentifier: CellType.Label.rawValue)
    collectionView.registerClass(InlinePickerViewImageCell.self, forCellWithReuseIdentifier: CellType.Image.rawValue)

    setContentCompressionResistancePriority(750, forAxis: .Horizontal)
    setContentCompressionResistancePriority(UILayoutPriorityRequired, forAxis: .Vertical)
    translatesAutoresizingMaskIntoConstraints = false
    identifier = "picker"

    collectionView.identifier = "collectionView"
    layout.delegate = self
    collectionView.scrollEnabled = editing
    collectionView.translatesAutoresizingMaskIntoConstraints = false
    collectionView.dataSource = self
    collectionView.delegate = self
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.bounces = false
    collectionView.backgroundColor = .clearColor()
    collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    updatePerspective()
    collectionView.reloadData()

    setNeedsUpdateConstraints()
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
    super.updateConstraints()

    let id = Identifier(self, "Internal")
    guard constraintsWithIdentifier(id).count == 0 else { return }

    constrain([𝗛|collectionView|𝗛, 𝗩|collectionView|𝗩] --> id)
    constrain([height ≥ (itemHeight ?? defaultItemHeight)] --> id)
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
      "labels = \(labels)",
      "images = \(images)",
      "collectionView = " + "collection view layout".split(collectionView.description)[0].sub("(?<!frame = \\(0 0); ", "\n").indentedBy(2, preserveFirst: true, useTabs: true),
      "collectionViewLayout = \(collectionView.collectionViewLayout.description.indentedBy(2, preserveFirst: true, useTabs: true))"
    )
  }

  /**
  selectItem:animated:

  - parameter item: Int
  - parameter animated: Bool
  */
  public func selectItem(item: Int, animated: Bool) {
    guard (0 ..< count).contains(item) else { logWarning("\(item) is not a valid item index"); return }

    selection = item
    if let offset = layout.offsetForItemAtIndex(selection) {
      collectionView.selectItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0),
                                  animated: false,
                            scrollPosition: .None)
      logVerbose("<\(ObjectIdentifier(self).uintValue)> selecting cell for item \(selection) where offset = \(offset)")
      collectionView.setContentOffset(offset, animated: animated)
    } else {
      logVerbose("<\(ObjectIdentifier(self).uintValue)> could not get an offset for item \(item), invalidating layout …")
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
  public var font = InlinePickerView.DefaultFont {
    didSet {
      guard cellType == .Label &&  collectionView.visibleCells().count > 0 else { return }
      reloadData()
    }
  }
  @IBInspectable public var fontName: String  {
    get { return font.fontName }
    set { if let font = UIFont(name: newValue, size: self.font.pointSize) { self.font = font } }
  }

  @IBInspectable public var flat: Bool {
    get { return layout.flat }
    set { layout.flat = newValue }
  }

  @IBInspectable public var fontSize: CGFloat  {
    get { return font.pointSize }
    set { font = font.fontWithSize(newValue) }
  }

  @IBInspectable public var itemColor: UIColor = .darkTextColor() //{ didSet { reloadData() } }

  public var selectedFont =  InlinePickerView.DefaultFont {
    didSet {
      guard cellType == .Label && collectionView.visibleCells().count > 0 else { return }
      reloadData()
    }
  }
  @IBInspectable public var selectedFontName: String  {
    get { return selectedFont.fontName }
    set { if let font = UIFont(name: newValue, size: selectedFont.pointSize) { selectedFont = font } }
  }

  @IBInspectable public var selectedFontSize: CGFloat  {
    get { return selectedFont.pointSize }
    set { selectedFont = selectedFont.fontWithSize(newValue) }
  }

  @IBInspectable public var labelsString: String = "" { didSet { labels = ", ".split(labelsString) } }
  @IBInspectable public var imagesString: String = "" { didSet { images = ", ".split(imagesString).flatMap({UIImage(named: $0)}) } }
  @IBInspectable public var selectedItemColor: UIColor = .darkTextColor() //{ didSet { reloadData() } }

  @IBInspectable public var marker: UIImage? {
    didSet {
      if let marker = marker?.imageWithRenderingMode(.AlwaysTemplate) {
        let imageView = UIImageView(image: marker)
        imageView.contentMode = .Bottom
        imageView.tintColor = selectedItemColor
        collectionView.backgroundView = imageView
      } else {
        collectionView.backgroundView = nil
      }
    }
  }

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
      case .Label: return ceil(max(font.lineHeight, selectedFont.lineHeight))
      case .Image: return 36 //ceil(images.map({$0.size.height}).maxElement() ?? 0)
    }
  }

  @IBInspectable public var itemHeight: CGFloat?
  @IBInspectable public var imageHeight: CGFloat = 0 { didSet { layout.invalidateLayout() } }
  @IBInspectable public var itemPadding: CGFloat = 8.0 { didSet { reloadData() } }
  @IBInspectable public var usePerspective: Bool = false { didSet { updatePerspective() } }

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

  @IBInspectable public var selection: Int = -1

  public var selectedItemFrame: CGRect? {
    guard selection > -1,
      let cell = collectionView.cellForItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0)) where cell.selected
    else { return nil }

    var frame = cell.frame
    frame.origin = frame.origin - collectionView.contentOffset
    return frame
  }

  @IBInspectable public var editing: Bool = true { didSet { collectionView.scrollEnabled = editing; reloadData() } }

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
        labelCell.text = text ¶| [font, itemColor]
        labelCell.selectedText = text ¶| [selectedFont, selectedItemColor]

      case let imageCell as InlinePickerViewImageCell:
        imageCell.image = images[indexPath.item]
        imageCell.imageColor = itemColor
        imageCell.imageSelectedColor = selectedItemColor
        imageCell.imageHeight = imageHeight > 0 ? imageHeight : nil

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
    return true
  }

  /**
  collectionView:shouldDeselectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath

  - returns: Bool
  */
  public func collectionView(collectionView: UICollectionView, shouldDeselectItemAtIndexPath indexPath: NSIndexPath) -> Bool {
    return true
  }

  /**
  collectionView:didSelectItemAtIndexPath:

  - parameter collectionView: UICollectionView
  - parameter indexPath: NSIndexPath
  */
  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    selection = indexPath.item
    sendActionsForControlEvents(.ValueChanged)
    didSelectItem?(self, selection)
    if let offset = layout.offsetForItemAtIndex(selection) {
      collectionView.setContentOffset(offset, animated: true)
    }
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
      logVerbose("<\(ObjectIdentifier(self).uintValue)> failed to get index path for selected cell")
      return
    }
    // invoke selection handler
    sendActionsForControlEvents(.ValueChanged)
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
    guard let item = layout.indexOfItemAtOffset(offset) else {
      logVerbose("<\(ObjectIdentifier(self).uintValue)> failed to get index path for cell at point \(offset)")
      return
    }

    guard item != selection else { logVerbose("<\(ObjectIdentifier(self).uintValue)> item already selected"); return }

    // update selection
    logVerbose("<\(ObjectIdentifier(self).uintValue)> selecting cell for item \(item) where offset = \(offset)")

    if selection > -1 { collectionView.deselectItemAtIndexPath(NSIndexPath(forItem: selection, inSection: 0), animated: true) }
    selection = item
    collectionView.selectItemAtIndexPath(NSIndexPath(forItem: item, inSection: 0), animated: true, scrollPosition:.None)
  }
}