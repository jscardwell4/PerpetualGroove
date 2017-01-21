//
//  Fonts.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/12/16.
//  Copyright © 2016 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit

private let _labelFont = UIFont(name: "EvelethLight", size: 14)
                      ?? UIFont.systemFont(ofSize: 14, weight: UIFontWeightLight)
private let _largeDisplayFont = UIFont(name: "EvelethLight", size: 36)
                             ?? UIFont.systemFont(ofSize: 36, weight: UIFontWeightLight)
private let _controlFont = UIFont(name: "EvelethThin", size: 14)
                        ?? UIFont.systemFont(ofSize: 14, weight: UIFontWeightThin)
private let _largeControlFont = UIFont(name: "EvelethThin", size: 20)
                             ?? UIFont.systemFont(ofSize: 20, weight: UIFontWeightThin)
private let _compressedControlFont = UIFont(name: "EvelethThin", size: 12)
                                  ?? UIFont.systemFont(ofSize: 12, weight: UIFontWeightThin)
private let _compressedControlFontEditing = UIFont(name: "Triump-Rg-Rock-02", size: 17)
                                         ?? UIFont.systemFont(ofSize: 17, weight: UIFontWeightMedium)
private let _controlSelectedFont = UIFont(name: "EvelethRegular", size: 14)
                                ?? UIFont.systemFont(ofSize: 14, weight: UIFontWeightRegular)
private let _largeControlSelectedFont = UIFont(name: "EvelethRegular", size: 22)
                                     ?? UIFont.systemFont(ofSize: 22, weight: UIFontWeightRegular)

/// Extend `UIFont` with class derived properties for fonts used within the application.
extension UIFont {

  static var labelFont:                    UIFont { return _labelFont                    }
  static var largeDisplayFont:             UIFont { return _largeDisplayFont             }
  static var controlFont:                  UIFont { return _controlFont                  }
  static var largeControlFont:             UIFont { return _largeControlFont             }
  static var compressedControlFont:        UIFont { return _compressedControlFont        }
  static var compressedControlFontEditing: UIFont { return _compressedControlFontEditing }
  static var controlSelectedFont:          UIFont { return _controlSelectedFont          }
  static var largeControlSelectedFont:     UIFont { return _largeControlSelectedFont     }

}


