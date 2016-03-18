//
//  ImageSegmentedControl.swift
//  MoonKit
//
//  Created by Jason Cardwell on 11/30/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation

@available(iOS 9.0, *)
@IBDesignable public class ImageSegmentedControl: TintColorControl {

  private var segments: [ImageButtonView] { return stack?.arrangedSubviews.flatMap { $0 as? ImageButtonView } ?? [] }

  @IBOutlet private var stack: UIStackView! {
    didSet {
      segments.forEach {
        $0.addTarget(self, action: #selector(ImageSegmentedControl.touchUp(_:)), forControlEvents: .TouchUpInside)
        $0.normalTintColor = normalTintColor
        $0.highlightedTintColor = highlightedTintColor
        $0.disabledTintColor = disabledTintColor
        $0.selectedTintColor = selectedTintColor
      }
    }
  }

  /**
   touchUp:

   - parameter button: ImageButtonView
   */
  @objc private func touchUp(button: ImageButtonView) {
    guard let idx = segments.indexOf(button) else { return }
    guard allowsEmptySelection || idx != selectedSegmentIndex else { return }
    if !momentary { selectedSegmentIndex = idx }
    sendActionsForControlEvents(.ValueChanged)
  }

  override public var normalTintColor: UIColor? {
    didSet { segments.forEach { $0.normalTintColor = normalTintColor } }
  }
  override public var highlightedTintColor: UIColor? {
    didSet { segments.forEach { $0.highlightedTintColor = highlightedTintColor } }
  }
  override public var disabledTintColor: UIColor? {
    didSet { segments.forEach { $0.disabledTintColor = disabledTintColor } }
  }
  override public var selectedTintColor: UIColor? {
    didSet { segments.forEach { $0.selectedTintColor = selectedTintColor } }
  }

  override public class func requiresConstraintBasedLayout() -> Bool { return true }

  /**
   setEnabled:forSegmentAtIndex:

   - parameter enabled: Bool
   - parameter segment: Int
   */
  public func setEnabled(enabled: Bool, forSegmentAtIndex segment: Int) {
    let segments = self.segments
    guard segments.indices.contains(segment) else { fatalError("segment index \(segment) out of bounds") }
    segments[segment].enabled = enabled
  }

  /**
   isEnabledForSegmentAtIndex:

   - parameter segment: Int

   - returns: Bool
   */
  public func isEnabledForSegmentAtIndex(segment: Int) -> Bool {
    let segments = self.segments
    guard segments.indices.contains(segment) else {
      fatalError("segment index \(segment) out of bounds")
    }
    return segments[segment].enabled
  }

  /**
   setImage:forState:forSegmentAtIndex:

   - parameter image: UIImage?
   - parameter state: ImageButtonView.ImageState
   - parameter segment: Int
   */
  public func setImage(image: UIImage?,
              forState state: ImageButtonView.ImageState,
     forSegmentAtIndex segment: Int)
  {
    let segments = self.segments
    guard segments.indices.contains(segment) else { fatalError("segment index \(segment) out of bounds") }
    switch state {
      case .Default:     segments[segment].image = image
      case .Highlighted: segments[segment].highlightedImage = image
      case .Disabled:    segments[segment].disabledImage = image
      case .Selected:    segments[segment].selectedImage = image
    }
  }

  /**
   imageForSegmentAtIndex:forState:

   - parameter segment: Int
   - parameter state: ImageButtonView.ImageState

   - returns: UIImage?
   */
  public func imageForSegmentAtIndex(segment: Int,
                            forState state: ImageButtonView.ImageState) -> UIImage?
  {
    let segments = self.segments
    guard segments.indices.contains(segment) else { fatalError("segment index \(segment) out of bounds") }
    switch state {
      case .Default:     return segments[segment].image
      case .Highlighted: return segments[segment].highlightedImage
      case .Disabled:    return segments[segment].disabledImage
      case .Selected:    return segments[segment].selectedImage
    }
  }

  /**
   insertSegmentWithImage:atIndex:animated:

   - parameter image: UIImage?
   - parameter segment: Int
   */
  public func insertSegmentWithImage(image: UIImage?, atIndex segment: Int) {
    insertSegmentWithImages([.Default: image], atIndex: segment)
  }

  /**
   insertSegmentWithImages:atIndex:

   - parameter images: [ImageButtonView.ImageState
   - parameter segment: Int
   */
  public func insertSegmentWithImages(images: [ImageButtonView.ImageState: UIImage?]?,
                              atIndex segment: Int)
  {
    let segments = self.segments
    guard segment <= segments.count else { fatalError("segment index \(segment) out of bounds") }
    let imageButtonView = ImageButtonView(autolayout: true)
    images?.forEach {imageButtonView.setImage($1, forState: $0)}
    imageButtonView.normalTintColor = normalTintColor
    imageButtonView.highlightedTintColor = highlightedTintColor
    imageButtonView.disabledTintColor = disabledTintColor
    imageButtonView.selectedTintColor = selectedTintColor
    if segments.count == stack.arrangedSubviews.count {
      stack.insertArrangedSubview(imageButtonView, atIndex: segment)
    } else if segment == segments.count {
      stack.addArrangedSubview(imageButtonView)
    } else {
      guard let idx = stack.arrangedSubviews.indexOf(segments[segment]) else {
        fatalError("failed to resolve insertion point for new segment")
      }
      stack.insertArrangedSubview(imageButtonView, atIndex: idx)
    }
    if selectedSegmentIndex >= segment { selectedSegmentIndex += 1 }
  }

  /**
   removeSegmentAtIndex:animated:

   - parameter segment: Int
   */
  public func removeSegmentAtIndex(segment: Int) {
    let segments = self.segments
    guard segments.indices.contains(segment) else { fatalError("segment index \(segment) out of bounds") }
    let imageButtonView = segments[segment]
    stack.removeArrangedSubview(imageButtonView)
    imageButtonView.removeFromSuperview()
    if selectedSegmentIndex == segment { selectedSegmentIndex = ImageSegmentedControl.NoSegment }
  }

  /** removeAllSegments */
  public func removeAllSegments() {
    segments.forEach {
      stack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    selectedSegmentIndex = ImageSegmentedControl.NoSegment
  }

  public static let NoSegment = UISegmentedControlNoSegment

  @IBInspectable public var allowsEmptySelection: Bool = true

  @IBInspectable public var momentary: Bool = false {
    didSet {
      guard oldValue != momentary
         && momentary
         && selectedSegmentIndex != ImageSegmentedControl.NoSegment else { return }
      segments[selectedSegmentIndex].selected = false
    }
  }

  @IBInspectable public var selectedSegmentIndex: Int = ImageSegmentedControl.NoSegment {
    didSet {
      // Make sure we are not momentary
      guard !momentary else { return }

      // Make sure the index has changed
      guard oldValue != selectedSegmentIndex else {
        // If the index is the same, make sure we de-select the segment if flagged appropriately
        if selectedSegmentIndex != ImageSegmentedControl.NoSegment && allowsEmptySelection {
          segments[selectedSegmentIndex].selected = false
          selectedSegmentIndex = ImageSegmentedControl.NoSegment
        }
        return
      }

      switch (oldValue, selectedSegmentIndex) {
        case let (ImageSegmentedControl.NoSegment, newIndex) where segments.indices.contains(newIndex):
          segments[newIndex].selected = true
        case let (newIndex, ImageSegmentedControl.NoSegment) where segments.indices.contains(newIndex):
          segments[newIndex].selected = false
        case let (oldIndex, newIndex) where segments.indices.contains(newIndex):
          segments[oldIndex].selected = false
          segments[newIndex].selected = true
        default:
          break
      }
    }
  }

  public var numberOfSegments: Int { return segments.count }

  private func setup() {
    stack = UIStackView(autolayout: true)
    stack.axis = .Horizontal
    stack.distribution = .Fill
    stack.alignment = .Fill
    stack.spacing = 20
    addSubview(stack)
    constrain(𝗩|stack|𝗩, 𝗛|stack|𝗛)
  }

  /**
   intrinsicContentSize

   - returns: CGSize
   */
  public override func intrinsicContentSize() -> CGSize {
    return segments.reduce(CGSize.zero) {
      let size = $1.intrinsicContentSize()
      return CGSize(width: $0.width + size.width, height: max($0.height, size.height))
    }
  }

  /**
   initWithFrame:

   - parameter frame: CGRect
   */
  public override init(frame: CGRect) { super.init(frame: frame); setup() }

  /**
   init:

   - parameter aDecoder: NSCoder
   */
  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder) }

  /** awakeFromNib */
  public override func awakeFromNib() {
    super.awakeFromNib()
    if stack == nil { setup() }
    segments.enumerate().forEach { $1.selected = $0 == selectedSegmentIndex }
  }
}
