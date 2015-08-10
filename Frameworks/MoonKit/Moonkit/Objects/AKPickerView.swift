//
//  AKPickerView.swift
//  AKPickerView
//
//  Created by Akio Yasui on 1/29/15.
//  Copyright (c) 2015 Akkyie Y. All rights reserved.
//

import UIKit

/**
Styles of AKPickerView.
- Wheel: Style with 3D appearance like UIPickerView.
- Flat:  Flat style.
*/
public enum AKPickerViewStyle { case Wheel, Flat }

// MARK: - Protocols
// MARK: AKPickerViewDataSource
/**
Protocols to specify the number and type of contents.
*/
@objc public protocol AKPickerViewDataSource {
  func numberOfItemsInPickerView(pickerView: AKPickerView) -> Int
  optional func pickerView(pickerView: AKPickerView, titleForItem item: Int) -> String
  optional func pickerView(pickerView: AKPickerView, imageForItem item: Int) -> UIImage
}

// MARK: AKPickerViewDelegate
/**
Protocols to specify the attitude when user selected an item,
and customize the appearance of labels.
*/
@objc public protocol AKPickerViewDelegate: UIScrollViewDelegate {
  optional func pickerView(pickerView: AKPickerView, didSelectItem item: Int)
  optional func pickerView(pickerView: AKPickerView, marginForItem item: Int) -> CGSize
  optional func pickerView(pickerView: AKPickerView, configureLabel label: UILabel, forItem item: Int)
}

// MARK: - Private Classes and Protocols
// MARK: AKCollectionViewLayoutDelegate
/**
Private. Used to deliver the style of the picker.
*/
private protocol AKCollectionViewLayoutDelegate {
  func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle
}

// MARK: AKCollectionViewCell
/**
Private. A subclass of UICollectionViewCell used in AKPickerView's collection view.
*/
private class AKCollectionViewCell: UICollectionViewCell {
  var label: UILabel!
  var imageView: UIImageView!
  var font = UIFont.systemFontOfSize(UIFont.systemFontSize())
  var highlightedFont = UIFont.systemFontOfSize(UIFont.systemFontSize())
  var _selected: Bool = false {
    didSet(selected) {
      let animation = CATransition()
      animation.type = kCATransitionFade
      animation.duration = 0.15
      label.layer.addAnimation(animation, forKey: "")
      label.font = selected ? highlightedFont : font
    }
  }

  func initialize() {
    layer.doubleSided = false
    layer.shouldRasterize = true
    layer.rasterizationScale = UIScreen.mainScreen().scale

    label = UILabel(frame: contentView.bounds)
    label.backgroundColor = UIColor.clearColor()
    label.textAlignment = .Center
    label.textColor = UIColor.grayColor()
    label.numberOfLines = 1
    label.lineBreakMode = .ByTruncatingTail
    label.highlightedTextColor = UIColor.blackColor()
    label.font = font
    label.autoresizingMask = [.FlexibleTopMargin, .FlexibleLeftMargin, .FlexibleBottomMargin, .FlexibleRightMargin];
    contentView.addSubview(label)

    imageView = UIImageView(frame: contentView.bounds)
    imageView.backgroundColor = UIColor.clearColor()
    imageView.contentMode = .Center
    imageView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight];
    contentView.addSubview(imageView)
  }

  init() { super.init(frame: CGRectZero); initialize() }
  override init(frame: CGRect) { super.init(frame: frame); initialize() }
  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initialize() }
}

// MARK: AKCollectionViewLayout
/**
Private. A subclass of UICollectionViewFlowLayout used in the collection view.
*/
private class AKCollectionViewLayout: UICollectionViewFlowLayout {
  var delegate: AKCollectionViewLayoutDelegate!
  var width: CGFloat!
  var midX: CGFloat!
  var maxAngle: CGFloat!

  func initialize() { sectionInset = UIEdgeInsets.zeroInsets; scrollDirection = .Horizontal; minimumLineSpacing = 0.0 }

  override init() { super.init(); initialize() }

  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initialize() }

  private override func prepareLayout() {
    let visibleRect = CGRect(origin: collectionView!.contentOffset, size: collectionView!.bounds.size)
    midX = visibleRect.midX
    width = visibleRect.width / 2
    maxAngle = CGFloat(M_PI_2)
  }

  private override func shouldInvalidateLayoutForBoundsChange(newBounds: CGRect) -> Bool { return true }

  private override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath) -> UICollectionViewLayoutAttributes? {
    let attributes = super.layoutAttributesForItemAtIndexPath(indexPath)
    switch delegate.pickerViewStyleForCollectionViewLayout(self) {
    case .Flat:
      return attributes
    case .Wheel:
      if attributes != nil {
        let distance = CGRectGetMidX(attributes!.frame) - midX
        let currentAngle = maxAngle * distance / width / CGFloat(M_PI_2)
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, -distance, 0, -width)
        transform = CATransform3DRotate(transform, currentAngle, 0, 1, 0)
        transform = CATransform3DTranslate(transform, 0, 0, width)
        attributes!.transform3D = transform
        attributes!.alpha = fabs(currentAngle) < maxAngle ? 1.0 : 0.0
      }
      return attributes
    }
  }

  private override func layoutAttributesForElementsInRect(rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
    switch delegate.pickerViewStyleForCollectionViewLayout(self) {
    case .Flat:
      return super.layoutAttributesForElementsInRect(rect)
    case .Wheel:
      var attributes: [UICollectionViewLayoutAttributes] = []
      for i in 0 ..< collectionView!.numberOfItemsInSection(0) {
        let indexPath = NSIndexPath(forItem: i, inSection: 0)
        attributes.append(layoutAttributesForItemAtIndexPath(indexPath)!)
      }
      return attributes
    }
  }

}

// MARK: AKPickerViewDelegateIntercepter
/**
Private. Used to hook UICollectionViewDelegate and throw it AKPickerView,
and if it conforms to UIScrollViewDelegate, also throw it to AKPickerView's delegate.
*/
private class AKPickerViewDelegateIntercepter: NSObject, UICollectionViewDelegate {
  weak var pickerView: AKPickerView?
  weak var delegate: UIScrollViewDelegate?

  init(pickerView: AKPickerView, delegate: UIScrollViewDelegate?) { self.pickerView = pickerView; self.delegate = delegate }

  private override func forwardingTargetForSelector(aSelector: Selector) -> AnyObject? {
    if pickerView!.respondsToSelector(aSelector) { return pickerView }
    else if delegate != nil && delegate!.respondsToSelector(aSelector) { return delegate }
    else { return nil }
  }

  private override func respondsToSelector(aSelector: Selector) -> Bool {
    if pickerView!.respondsToSelector(aSelector) { return true }
    else if delegate != nil && delegate!.respondsToSelector(aSelector) { return true }
    else { return super.respondsToSelector(aSelector) }
  }

}

// MARK: - AKPickerView
// TODO: Make these delegate conformation private
/**
Horizontal picker view. This is just a subclass of UIView, contains a UICollectionView.
*/
public class AKPickerView: UIView, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, AKCollectionViewLayoutDelegate {

  // MARK: - Properties
  // MARK: Readwrite Properties
  /// Readwrite. Data source of picker view.
  public weak var dataSource: AKPickerViewDataSource? = nil
  /// Readwrite. Delegate of picker view.
  public weak var delegate: AKPickerViewDelegate? = nil { didSet(delegate) { intercepter.delegate = delegate } }
  /// Readwrite. A font which used in NOT selected cells.
  public lazy var font = UIFont.systemFontOfSize(20)
  /// Readwrite. A font which used in selected cells.
  public lazy var highlightedFont = UIFont.boldSystemFontOfSize(20)
  /// Readwrite. A color of the text on NOT selected cells.
  public lazy var textColor = UIColor.darkGrayColor()
  /// Readwrite. A color of the text on selected cells.
  public lazy var highlightedTextColor = UIColor.blackColor()
  /// Readwrite. A float value which indicates the spacing between cells.
  public var interitemSpacing: CGFloat = 0.0
  /// Readwrite. The style of the picker view. See AKPickerViewStyle.
  public var pickerViewStyle = AKPickerViewStyle.Wheel
  /// Readwrite. A float value which determines the perspective representation which used when using AKPickerViewStyle.Wheel style.
  public var viewDepth: CGFloat = 1000.0 {
    didSet {
      collectionView.layer.sublayerTransform = viewDepth > 0.0 ? {
        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / self.viewDepth
        return transform
        }() : CATransform3DIdentity
    }
  }
  /// Readwrite. A boolean value indicates whether the mask is disabled.
  public var maskDisabled: Bool! = nil {
    didSet {
      collectionView.layer.mask = maskDisabled == true ? nil : {
        let maskLayer = CAGradientLayer()
        maskLayer.frame = self.collectionView.bounds
        maskLayer.colors = [
          UIColor.clearColor().CGColor,
          UIColor.blackColor().CGColor,
          UIColor.blackColor().CGColor,
          UIColor.clearColor().CGColor]
        maskLayer.locations = [0.0, 0.33, 0.66, 1.0]
        maskLayer.startPoint = CGPointMake(0.0, 0.0)
        maskLayer.endPoint = CGPointMake(1.0, 0.0)
        return maskLayer
        }()
    }
  }

  // MARK: Readonly Properties
  /// Readonly. Index of currently selected item.
  private(set) var selectedItem: Int = 0
  /// Readonly. The point at which the origin of the content view is offset from the origin of the picker view.
  public var contentOffset: CGPoint { return collectionView.contentOffset }

  // MARK: Private Properties
  /// Private. A UICollectionView which shows contents on cells.
  private var collectionView: UICollectionView!
  /// Private. An intercepter to hook UICollectionViewDelegate then throw it picker view and its delegate
  private var intercepter: AKPickerViewDelegateIntercepter!
  /// Private. A UICollectionViewFlowLayout used in picker view's collection view.
  private var collectionViewLayout: AKCollectionViewLayout {
    let layout = AKCollectionViewLayout()
    layout.delegate = self
    return layout
  }

  // MARK: - Functions
  // MARK: View Lifecycle
  /**
  Private. Initializes picker view's subviews and friends.
  */
  private func initialize() {
    collectionView?.removeFromSuperview()
    collectionView = UICollectionView(frame: bounds, collectionViewLayout: collectionViewLayout)
    collectionView.showsHorizontalScrollIndicator = false
    collectionView.backgroundColor = UIColor.clearColor()
    collectionView.decelerationRate = UIScrollViewDecelerationRateFast
    collectionView.autoresizingMask = [UIViewAutoresizing.FlexibleWidth, UIViewAutoresizing.FlexibleHeight]
    collectionView.dataSource = self
    collectionView.registerClass(AKCollectionViewCell.self,
      forCellWithReuseIdentifier: NSStringFromClass(AKCollectionViewCell.self))
    addSubview(collectionView)

    intercepter = AKPickerViewDelegateIntercepter(pickerView: self, delegate: delegate)
    collectionView.delegate = intercepter

    maskDisabled = maskDisabled == nil ? false : maskDisabled
  }

  public init() { super.init(frame: CGRectZero); initialize() }

  public override init(frame: CGRect) { super.init(frame: frame); initialize() }

  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initialize() }

  deinit { collectionView.delegate = nil }

  // MARK: Layout

  public override func layoutSubviews() {
    super.layoutSubviews()
    collectionView.collectionViewLayout = collectionViewLayout
    scrollToItem(selectedItem, animated: false)
    collectionView.layer.mask?.frame = collectionView.bounds
  }

  public override func intrinsicContentSize() -> CGSize {
    return CGSize(width: UIViewNoIntrinsicMetric, height: max(font.lineHeight, highlightedFont.lineHeight))
  }

  // MARK: Calculation Functions

  /**
  Private. Used to calculate bounding size of given string with picker view's font and highlightedFont
  - parameter string: A NSString to calculate size
  - returns: A CGSize which contains given string just.
  */
  private func sizeForString(string: NSString) -> CGSize {
    let size = string.sizeWithAttributes([NSFontAttributeName: font])
    let highlightedSize = string.sizeWithAttributes([NSFontAttributeName: highlightedFont])
    return CGSize(width: ceil(max(size.width, highlightedSize.width)),
                  height: ceil(max(size.height, highlightedSize.height)))
  }

  /**
  Private. Used to calculate the x-coordinate of the content offset of specified item.
  - parameter item: An integer value which indicates the index of cell.
  - returns: An x-coordinate of the cell whose index is given one.
  */
  private func offsetForItem(item: Int) -> CGFloat {
    var offset: CGFloat = 0
    for i in 0 ..< item {
      let indexPath = NSIndexPath(forItem: i, inSection: 0)
      let cellSize = collectionView(collectionView,
                             layout: collectionView.collectionViewLayout,
             sizeForItemAtIndexPath: indexPath)
      offset += cellSize.width
    }

    let firstIndexPath = NSIndexPath(forItem: 0, inSection: 0)
    let firstSize = collectionView(collectionView,
                            layout: collectionView.collectionViewLayout,
            sizeForItemAtIndexPath: firstIndexPath)
    let selectedIndexPath = NSIndexPath(forItem: item, inSection: 0)
    let selectedSize = collectionView(collectionView,
                               layout: collectionView.collectionViewLayout,
               sizeForItemAtIndexPath: selectedIndexPath)
    offset -= (firstSize.width - selectedSize.width) / 2.0

    return offset
  }

  // MARK: View Controls
  /**
  Reload the picker view's contents and styles. Call this method always after any property is changed.
  */
  public func reloadData() {
    invalidateIntrinsicContentSize()
    collectionView.collectionViewLayout.invalidateLayout()
    collectionView.reloadData()
    selectItem(selectedItem, animated: false, notifySelection: false)
  }

  /**
  Move to the cell whose index is given one without selection change.
  - parameter item:     An integer value which indicates the index of cell.
  - parameter animated: True if the scrolling should be animated, false if it should be immediate.
  */
  public func scrollToItem(item: Int, animated: Bool = false) {
    switch pickerViewStyle {
    case .Flat:
      collectionView.scrollToItemAtIndexPath(NSIndexPath(forItem: item, inSection: 0),
                            atScrollPosition: .CenteredHorizontally,
                                    animated: animated)
    case .Wheel:
      collectionView.setContentOffset(CGPoint(x: offsetForItem(item), y: collectionView.contentOffset.y), animated: animated)
    }
  }

  /**
  Select a cell whose index is given one and move to it.
  - parameter item:     An integer value which indicates the index of cell.
  - parameter animated: True if the scrolling should be animated, false if it should be immediate.
  */
  public func selectItem(item: Int, animated: Bool = false) { selectItem(item, animated: animated, notifySelection: true) }

  /**
  Private. Select a cell whose index is given one and move to it, with specifying whether it calls delegate method.
  - parameter item:            An integer value which indicates the index of cell.
  - parameter animated:        True if the scrolling should be animated, false if it should be immediate.
  - parameter notifySelection: True if the delegate method should be called, false if not.
  */
  private func selectItem(item: Int, animated: Bool, notifySelection: Bool) {
    collectionView.selectItemAtIndexPath(NSIndexPath(forItem: item, inSection: 0), animated: animated, scrollPosition: .None)
    scrollToItem(item, animated: animated)
    selectedItem = item
    if notifySelection { delegate?.pickerView?(self, didSelectItem: item) }
  }

  // MARK: Delegate Handling
  /**
  Private.
  */
  private func didEndScrolling() {
    switch pickerViewStyle {
    case .Flat:
      let center = convertPoint(collectionView.center, toView: collectionView)
      if let indexPath = collectionView.indexPathForItemAtPoint(center) {
        selectItem(indexPath.item, animated: true, notifySelection: true)
      }
    case .Wheel:
      if let numberOfItems = dataSource?.numberOfItemsInPickerView(self) {
        for i in 0 ..< numberOfItems {
          let indexPath = NSIndexPath(forItem: i, inSection: 0)
          let cellSize = collectionView(collectionView,
                                 layout: collectionView.collectionViewLayout,
                 sizeForItemAtIndexPath: indexPath)
          if offsetForItem(i) + cellSize.width / 2 > collectionView.contentOffset.x {
            selectItem(i, animated: true, notifySelection: true)
            break
          }
        }
      }
    }
  }

  // MARK: UICollectionViewDataSource
  public func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int { return 1 }

  public func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return dataSource != nil ? dataSource!.numberOfItemsInPickerView(self) : 0
  }

  public func collectionView(collectionView: UICollectionView,
      cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell
  {
    let cell = collectionView.dequeueReusableCellWithReuseIdentifier(NSStringFromClass(AKCollectionViewCell.self),
                                                        forIndexPath: indexPath) as! AKCollectionViewCell
    if let title = dataSource?.pickerView?(self, titleForItem: indexPath.item) {
      cell.label.text = title
      cell.label.textColor = textColor
      cell.label.highlightedTextColor = highlightedTextColor
      cell.label.font = font
      cell.font = font
      cell.highlightedFont = highlightedFont
      cell.label.bounds = CGRect(origin: CGPointZero, size: sizeForString(title))
      if let delegate = delegate {
        delegate.pickerView?(self, configureLabel: cell.label, forItem: indexPath.item)
        if let margin = delegate.pickerView?(self, marginForItem: indexPath.item) {
          cell.label.frame = CGRectInset(cell.label.frame, -margin.width, -margin.height)
        }
      }
    } else if let image = dataSource?.pickerView?(self, imageForItem: indexPath.item) {
      cell.imageView.image = image
    }
    cell._selected = (indexPath.item == selectedItem)
    return cell
  }

  // MARK: UICollectionViewDelegateFlowLayout
  public func collectionView(collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
      sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
  {
    var size = CGSizeMake(interitemSpacing, collectionView.bounds.size.height)
    if let title = dataSource?.pickerView?(self, titleForItem: indexPath.item) {
      size.width += sizeForString(title).width
      if let margin = delegate?.pickerView?(self, marginForItem: indexPath.item) {
        size.width += margin.width * 2
      }
    } else if let image = dataSource?.pickerView?(self, imageForItem: indexPath.item) {
      size.width += image.size.width
    }
    return size
  }

  public func collectionView(collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumInteritemSpacingForSectionAtIndex section: Int) -> CGFloat
  {
    return 0.0
  }

  public func collectionView(collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      minimumLineSpacingForSectionAtIndex section: Int) -> CGFloat
  {
    return 0.0
  }

  public func collectionView(collectionView: UICollectionView,
                      layout collectionViewLayout: UICollectionViewLayout,
                      insetForSectionAtIndex section: Int) -> UIEdgeInsets
  {
    let number = self.collectionView(collectionView, numberOfItemsInSection: section)
    let firstIndexPath = NSIndexPath(forItem: 0, inSection: section)
    let firstSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: firstIndexPath)
    let lastIndexPath = NSIndexPath(forItem: number - 1, inSection: section)
    let lastSize = self.collectionView(collectionView, layout: collectionView.collectionViewLayout, sizeForItemAtIndexPath: lastIndexPath)
    return UIEdgeInsetsMake(
      0, (collectionView.bounds.size.width - firstSize.width) / 2,
      0, (collectionView.bounds.size.width - lastSize.width) / 2
    )
  }

  // MARK: UICollectionViewDelegate
  public func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
    selectItem(indexPath.item, animated: true)
  }

  // MARK: UIScrollViewDelegate
  public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
    delegate?.scrollViewDidEndDecelerating?(scrollView)
    didEndScrolling()
  }

  public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    delegate?.scrollViewDidEndDragging?(scrollView, willDecelerate: decelerate)
    if !decelerate {
      didEndScrolling()
    }
  }

  public func scrollViewDidScroll(scrollView: UIScrollView) {
    delegate?.scrollViewDidScroll?(scrollView)
    CATransaction.begin()
    CATransaction.setValue(kCFBooleanTrue, forKey: kCATransactionDisableActions)
    collectionView.layer.mask?.frame = collectionView.bounds
    CATransaction.commit()
  }

  // MARK: AKCollectionViewLayoutDelegate
  private func pickerViewStyleForCollectionViewLayout(layout: AKCollectionViewLayout) -> AKPickerViewStyle {
    return pickerViewStyle
  }

}