//
//  ImageButtonView.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/20/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public class ImageButtonView: UIImageView {

  private var trackingTouch: UITouch? { didSet { _highlighted = trackingTouch != nil } }

  private var _highlighted = false { didSet { super.highlighted = _highlighted } }

  public override var highlighted: Bool { get { return super.highlighted } set {} }

  public typealias Action = (ImageButtonView) -> Void

  private func initializeIVARs() { userInteractionEnabled = true }

  public override init(image: UIImage?) { super.init(image: image); initializeIVARs() }

  public override init(image: UIImage?, highlightedImage: UIImage?) {
    super.init(image: image, highlightedImage: highlightedImage)
    initializeIVARs()
  }

  public override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeIVARs() }

  public init(image: UIImage?, highlightedImage: UIImage?, action: Action? = nil) {
    super.init(image: image, highlightedImage: highlightedImage)
    initializeIVARs()
    if let action = action { actions.append(action) }
  }

  public var actions: [Action] = []

  public override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if trackingTouch == nil { trackingTouch = touches.first }
  }

  public override func touchesMoved(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let trackingTouch = trackingTouch
      where touches.contains(trackingTouch) && !pointInside(trackingTouch.locationInView(self), withEvent: event)
    {
      self.trackingTouch = nil
    }
  }

  public override func touchesEnded(touches: Set<UITouch>, withEvent event: UIEvent?) {
    if let trackingTouch = trackingTouch where touches.contains(trackingTouch) {
      if pointInside(trackingTouch.locationInView(self), withEvent: event) { apply(actions) {[unowned self] in $0(self)} }
      self.trackingTouch = nil
    }
  }

  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches, trackingTouch = trackingTouch where touches.contains(trackingTouch) {
      self.trackingTouch = nil
    }
  }
}
