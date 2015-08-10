//
//  ToggleImageSegmentedControl.swift
//  MSKit
//
//  Created by Jason Cardwell on 10/6/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit

public class ToggleImageSegmentedControl: UISegmentedControl {

  private var defaultImages:  [UIImage] = []
  private var selectedImages: [UIImage] = []
  private var previouslySelectedSegmentIndex = UISegmentedControlNoSegment


  private var disableImageToggle = false {
    didSet {
      if !disableImageToggle { super.setImage(selectedImages[selectedSegmentIndex], forSegmentAtIndex: selectedSegmentIndex) }
    }
  }

  /**
  removeSegmentAtIndex:animated:

  - parameter segment: Int
  - parameter animated: Bool
  */
  public override func removeSegmentAtIndex(segment: Int, animated: Bool) {
    super.removeSegmentAtIndex(segment, animated: animated)
    defaultImages.removeAtIndex(segment)
    if !disableImageToggle { selectedImages.removeAtIndex(segment) }
  }

  /** removeAllSegments */
  public override func removeAllSegments() {
    super.removeAllSegments()
    defaultImages.removeAll(keepCapacity: false)
    selectedImages.removeAll(keepCapacity: false)
  }

  /**
  insertSegmentWithImage:selectedImage:atIndex:animated:

  - parameter image: UIImage
  - parameter selectedImage: UIImage
  - parameter segment: Int
  - parameter animated: Bool
  */
  public func insertSegmentWithImage(image: UIImage, selectedImage: UIImage, atIndex segment: Int, animated: Bool) {
    super.insertSegmentWithImage(image, atIndex: segment, animated: animated)
    defaultImages.insert(image, atIndex: segment)
    selectedImages.insert(selectedImage, atIndex: segment)
  }

  /**
  Overridden to suppress inserting segment unless `disableImageToggle` is true

  - parameter image: UIImage
  - parameter segment: Int
  - parameter animated: Bool
  */
  public override func insertSegmentWithImage(image: UIImage?, atIndex segment: Int, animated: Bool) {
    if disableImageToggle {
      super.insertSegmentWithImage(image, atIndex: segment, animated: animated)
      if let image = image { defaultImages[segment] = image }
    }
  }

  /**
  insertSegmentWithTitle:atIndex:animated:

  - parameter title: String!
  - parameter segment: Int
  - parameter animated: Bool
  */
  public override func insertSegmentWithTitle(title: String?, atIndex segment: Int, animated: Bool) {
    // Disallow segments with titles for now
  }

  private func setup() {
    UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    setBackgroundImage(image, forState: .Normal, barMetrics: .Default)
    addTarget(self, action: "toggleImage:", forControlEvents: .ValueChanged)
  }

  /**
  initWithFrame:

  - parameter frame: CGRect
  */
  override init(frame: CGRect) {
    super.init(frame: frame)
    setup()
  }

  /**
  initWithItems:

  - parameter items: [AnyObject]!
  */
  override public init(items: [AnyObject]?) {
    let defaultImages: [UIImage]?
    let selectedImages: [UIImage]?

    if let images = items as? [UIImage] {
      if images.count % 2 == 0  {
        defaultImages = stride(from: 0, to: images.count, by: 2).map({images[$0]})
        selectedImages = stride(from: 1, to: images.count, by: 2).map({images[$0]})
      } else {
        defaultImages = images
        selectedImages = nil
      }
    } else {
      defaultImages = nil
      selectedImages = nil
    }

    super.init(items: defaultImages ?? [])

    if let images = defaultImages { self.defaultImages = images; disableImageToggle = selectedImages == nil }
    if let images = selectedImages { self.selectedImages = images }

    // Generate an empty background image
    UIGraphicsBeginImageContextWithOptions(frame.size, false, 0.0)
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    setBackgroundImage(image, forState: .Normal, barMetrics: .Default)

    addTarget(self, action: "toggleImage:", forControlEvents: .ValueChanged)

  }

  /** Optional action to execute when user changes the selected segment */
  public var toggleAction: ((ToggleImageSegmentedControl) -> Void)?

  /**
  initWithCoder:

  - parameter aDecoder: NSCoder
  */
  required public init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    disableImageToggle = true
    setup()
  }

  /**
  Toggles the image used for selected and previously selected segments when `disableImageToggle` is false. If `sender` is not
  nil, the method also invokes `toggleAction`

  - parameter sender: ToggleImageSegmentedControl?
  */
  func toggleImage() {
    if !disableImageToggle {
      if previouslySelectedSegmentIndex != UISegmentedControlNoSegment {
        super.setImage(defaultImages[previouslySelectedSegmentIndex], forSegmentAtIndex: previouslySelectedSegmentIndex)
      }
      previouslySelectedSegmentIndex = selectedSegmentIndex
      if selectedSegmentIndex != UISegmentedControlNoSegment {
        super.setImage(selectedImages[selectedSegmentIndex], forSegmentAtIndex: selectedSegmentIndex)
      }
    }
  }

  @IBAction func toggleImage(sender: ToggleImageSegmentedControl) {
    toggleImage()
    toggleAction?(self)
  }

  /**
  setImage:selectedImage:forSegmentAtIndex:

  - parameter image: UIImage?
  - parameter selectedImage: UIImage?
  - parameter segment: Int
  */
  public func setImage(image: UIImage, selectedImage: UIImage, forSegmentAtIndex segment: Int) {
    if segment < numberOfSegments {
      if defaultImages.count > segment { defaultImages[segment] = image }
      else if defaultImages.count == segment { defaultImages.append(image) }
      else { assert(false) }

      if selectedImages.count > segment { selectedImages[segment] = selectedImage }
      else if selectedImages.count == segment { selectedImages.append(selectedImage) }
      else { assert(false) }

      if disableImageToggle && defaultImages.count == selectedImages.count { disableImageToggle = false }
      else if disableImageToggle { super.setImage(image, forSegmentAtIndex: segment) }
      if !disableImageToggle {
        super.setImage(segment == selectedSegmentIndex ? selectedImage : image, forSegmentAtIndex: segment)
      }
    }
  }

  /** Overridden to add `didSet` observer to invoke `toggleImage` with `sender` equal to nil */
  override public var selectedSegmentIndex: Int { didSet { toggleImage() } }
  
}
