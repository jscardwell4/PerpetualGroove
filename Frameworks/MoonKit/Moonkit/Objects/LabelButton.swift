//
//  LabelButton.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/23/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import UIKit

public class LabelButton: UILabel {

  private var trackingTouch: UITouch? { didSet { _highlighted = trackingTouch != nil } }

  private var _highlighted = false { didSet { super.highlighted = _highlighted; setNeedsDisplay() } }

  public override var highlighted: Bool { get { return super.highlighted } set {} }

  public typealias Action = (LabelButton) -> Void

  private func initializeIVARs() {
    userInteractionEnabled = true
    highlightedTextColor = tintColor // Store initial tintColor into highlightedTextColor
    opaque = false
  }

  public override init(frame: CGRect) { super.init(frame: frame); initializeIVARs() }

  public required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); initializeIVARs() }

  public var actions: [Action] = []

  public convenience init(action: Action) {
    self.init(frame: CGRect.zeroRect)
    actions.append(action)
    translatesAutoresizingMaskIntoConstraints = false
    initializeIVARs()
  }

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
      if pointInside(trackingTouch.locationInView(self), withEvent: event) { actions.apply {[unowned self] in $0(self)} }
      self.trackingTouch = nil
    }
  }

  public override func touchesCancelled(touches: Set<UITouch>?, withEvent event: UIEvent?) {
    if let touches = touches, trackingTouch = trackingTouch where touches.contains(trackingTouch) {
      self.trackingTouch = nil
    }
  }
}
