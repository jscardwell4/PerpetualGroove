//
//  UIViewController+Chameleon.swift
//  Chameleon
//
//  Created by Jason Cardwell on 5/11/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

/*

The MIT License (MIT)

Copyright (c) 2014-2015 Vicc Alexander.

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

*/

import Foundation
import UIKit

extension UIViewController {

  // MARK:  - Public Methods

  public func flatify(contrast: Bool = false) {
    flatifyNavigationBarItems()
    for v in view.subviews as [UIView] { UIViewController.flatifyView(v, contrast: contrast) }
  }


  // MARK:  - Internal Methods

  func flatifyNavigationBarItems() {
    if let nav = navigationController {
      //Quick solution to flatifying navigation bars in view controllers (could be implemented better)
      nav.navigationBar.barTintColor = nav.navigationBar.barTintColor?.flatColor
      nav.navigationBar.tintColor = nav.navigationBar.barTintColor?.contrastingFlatColor
    }
  }

  private static func flatifyView(view: UIActivityIndicatorView, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.color = view.color?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UIBarButtonItem, contrast: Bool = false) {
    view.tintColor = view.tintColor?.flatColor
  }

  private static func flatifyView(view: UIButton, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.setTitleShadowColor(view.titleLabel?.shadowColor?.flatColor, forState: .Normal)

      //Check if backgroundColor exists
      if view.backgroundColor == nil {
          view.tintColor = view.tintColor?.flatColor
          view.setTitleColor(view.titleLabel?.textColor?.flatColor, forState: .Normal)
      } else {
        view.tintColor = view.backgroundColor?.contrastingFlatColor
        view.setTitleColor(view.backgroundColor?.contrastingFlatColor, forState: .Normal)
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.tintColor = view.tintColor?.flatColor
      view.setTitleColor(view.titleLabel?.textColor?.flatColor, forState: .Normal)
      view.setTitleShadowColor(view.titleLabel?.shadowColor?.flatColor, forState: .Normal)
    }
  }

  private static func flatifyView(view: UIDatePicker, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UIPageControl, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.currentPageIndicatorTintColor = view.currentPageIndicatorTintColor?.flatColor
    view.pageIndicatorTintColor = view.pageIndicatorTintColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UISegmentedControl, contrast: Bool = false) {
    if contrast {
      if let bg = view.backgroundColor {
        view.backgroundColor = bg.flatColor
        view.tintColor = bg.contrastingFlatColor
      } else {
        view.tintColor = view.tintColor.flatColor
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.tintColor = view.tintColor.flatColor
    }
  }

  private static func flatifyView(view: UISlider, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.minimumTrackTintColor = view.minimumTrackTintColor?.flatColor
    view.maximumTrackTintColor = view.maximumTrackTintColor?.flatColor
  }

  private static func flatifyView(view: UIStepper, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor
      if view.backgroundColor == nil {
        view.tintColor = view.tintColor.flatColor
      } else {
        view.tintColor = view.backgroundColor?.contrastingFlatColor
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.tintColor = view.tintColor.flatColor
    }
  }

  private static func flatifyView(view: UISwitch, contrast: Bool = false) {
    view.thumbTintColor = view.thumbTintColor?.flatColor
    view.onTintColor = view.onTintColor?.flatColor
    view.backgroundColor = view.backgroundColor?.flatColor
    view.tintColor = view.tintColor?.flatColor
  }

  private static func flatifyView(view: UITextField, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.tintColor = view.tintColor.flatColor

      if view.backgroundColor == nil {
        view.textColor = view.textColor?.flatColor
      } else {
        view.textColor = view.backgroundColor?.contrastingFlatColor
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.textColor = view.textColor?.flatColor
      view.tintColor = view.tintColor.flatColor
    }
  }

  private static func flatifyView(view: UIImageView, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UILabel, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor

      if view.backgroundColor == nil {
        view.textColor = view.textColor.flatColor
        view.tintColor = view.tintColor.flatColor
        view.highlightedTextColor = view.highlightedTextColor?.flatColor

      } else {
        view.textColor = view.backgroundColor?.contrastingFlatColor
        view.tintColor = view.backgroundColor?.contrastingFlatColor
        view.highlightedTextColor = view.backgroundColor?.complementaryFlatColor
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.textColor = view.textColor.flatColor
      view.tintColor = view.tintColor.flatColor
      view.highlightedTextColor = view.highlightedTextColor?.flatColor
    }
  }

  private static func flatifyView(view: UINavigationBar, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.barTintColor = view.barTintColor?.flatColor
      view.tintColor = view.tintColor.flatColor
      view.topItem?.titleView?.backgroundColor = view.topItem?.titleView?.backgroundColor?.flatColor

      if view.barTintColor != nil {
        view.topItem?.titleView?.tintColor = view.barTintColor?.contrastingFlatColor
      } else {
        if view.backgroundColor != nil {
          view.topItem?.titleView?.tintColor = view.backgroundColor?.contrastingFlatColor
        } else {
          view.topItem?.titleView?.tintColor = view.topItem?.titleView?.tintColor.flatColor
        }
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.barTintColor = view.barTintColor?.flatColor
      view.tintColor = view.tintColor.flatColor
      view.topItem?.titleView?.backgroundColor = view.topItem?.titleView?.backgroundColor?.flatColor
      view.topItem?.titleView?.tintColor = view.topItem?.titleView?.tintColor.flatColor
    }
  }

  private static func flatifyView(view: UINavigationItem, contrast: Bool = false) {
    if contrast {
      if view.titleView?.backgroundColor != nil {
        view.backBarButtonItem?.tintColor = view.titleView?.backgroundColor?.contrastingFlatColor
        view.leftBarButtonItem?.tintColor = view.titleView?.backgroundColor?.contrastingFlatColor
        view.rightBarButtonItem?.tintColor = view.titleView?.backgroundColor?.contrastingFlatColor
        view.titleView?.backgroundColor = view.titleView?.backgroundColor?.flatColor
        view.titleView?.tintColor = view.titleView?.backgroundColor?.contrastingFlatColor
      } else {
        view.backBarButtonItem?.tintColor = view.backBarButtonItem?.tintColor?.flatColor
        view.leftBarButtonItem?.tintColor = view.leftBarButtonItem?.tintColor?.flatColor
        view.rightBarButtonItem?.tintColor = view.rightBarButtonItem?.tintColor?.flatColor
        view.titleView?.backgroundColor = view.titleView?.backgroundColor?.flatColor
        view.titleView?.tintColor = view.titleView?.tintColor.flatColor
      }
    } else {
      view.backBarButtonItem?.tintColor = view.backBarButtonItem?.tintColor?.flatColor
      view.leftBarButtonItem?.tintColor = view.leftBarButtonItem?.tintColor?.flatColor
      view.rightBarButtonItem?.tintColor = view.rightBarButtonItem?.tintColor?.flatColor
      view.titleView?.backgroundColor = view.titleView?.backgroundColor?.flatColor
      view.titleView?.tintColor = view.titleView?.tintColor.flatColor
    }
 }

  private static func flatifyView(view: UIProgressView, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.progressTintColor = view.progressTintColor?.flatColor
    view.tintColor = view.tintColor.flatColor
    view.trackTintColor = view.trackTintColor?.flatColor
  }

  private static func flatifyView(view: UISearchBar, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.barTintColor = view.barTintColor?.flatColor
    view.tintColor = view.tintColor?.flatColor
  }

  private static func flatifyView(view: UITabBar, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.barTintColor = view.barTintColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UITableView, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.sectionIndexBackgroundColor = view.sectionIndexBackgroundColor?.flatColor
    view.sectionIndexColor = view.sectionIndexColor?.flatColor
    view.sectionIndexTrackingBackgroundColor = view.sectionIndexTrackingBackgroundColor?.flatColor
    view.separatorColor = view.separatorColor?.flatColor
    view.tintColor = view.tintColor.flatColor
    view.backgroundView?.backgroundColor = view.backgroundView?.backgroundColor?.flatColor
    view.backgroundView?.tintColor = view.backgroundView?.tintColor.flatColor
    view.inputAccessoryView?.backgroundColor = view.inputAccessoryView?.backgroundColor?.flatColor
    view.inputAccessoryView?.tintColor = view.inputAccessoryView?.tintColor.flatColor
    view.inputView?.backgroundColor = view.inputView?.backgroundColor?.flatColor
    view.inputView?.tintColor = view.inputView?.tintColor.flatColor
    view.tableFooterView?.backgroundColor = view.tableFooterView?.backgroundColor?.flatColor
    view.tableFooterView?.tintColor = view.tableFooterView?.tintColor.flatColor
    view.tableHeaderView?.backgroundColor = view.tableHeaderView?.backgroundColor?.flatColor
    view.tableHeaderView?.tintColor = view.tableHeaderView?.tintColor.flatColor
    view.viewForBaselineLayout().backgroundColor = view.viewForBaselineLayout().backgroundColor?.flatColor
    view.viewForBaselineLayout().tintColor = view.viewForBaselineLayout().backgroundColor?.flatColor
  }

  private static func flatifyView(view: UITextView, contrast: Bool = false) {
    if contrast {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.tintColor = view.tintColor.flatColor

      if view.backgroundColor != nil {
        view.textColor = view.backgroundColor?.contrastingFlatColor
      } else {
        view.textColor = view.textColor?.flatColor
      }
    } else {
      view.backgroundColor = view.backgroundColor?.flatColor
      view.textColor = view.textColor?.flatColor
      view.tintColor = view.tintColor.flatColor
    }
  }

  private static func flatifyView(view: UIToolbar, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.barTintColor = view.barTintColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

  private static func flatifyView(view: UIView, contrast: Bool = false) {
    view.backgroundColor = view.backgroundColor?.flatColor
    view.tintColor = view.tintColor.flatColor
  }

}
