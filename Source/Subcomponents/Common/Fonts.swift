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
  ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.light)
private let _largeDisplayFont = UIFont(name: "EvelethLight", size: 36)
  ?? UIFont.systemFont(ofSize: 36, weight: UIFont.Weight.light)
private let _controlFont = UIFont(name: "EvelethThin", size: 14)
  ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.thin)
private let _largeControlFont = UIFont(name: "EvelethThin", size: 20)
  ?? UIFont.systemFont(ofSize: 20, weight: UIFont.Weight.thin)
private let _compressedControlFont = UIFont(name: "EvelethThin", size: 12)
  ?? UIFont.systemFont(ofSize: 12, weight: UIFont.Weight.thin)
private let _compressedControlFontEditing = UIFont(name: "Triump-Rg-Rock-02", size: 17)
  ?? UIFont.systemFont(ofSize: 17, weight: UIFont.Weight.medium)
private let _controlSelectedFont = UIFont(name: "EvelethRegular", size: 14)
  ?? UIFont.systemFont(ofSize: 14, weight: UIFont.Weight.regular)
private let _largeControlSelectedFont = UIFont(name: "EvelethRegular", size: 22)
  ?? UIFont.systemFont(ofSize: 22, weight: UIFont.Weight.regular)

/// Extend `UIFont` with class derived properties for fonts used within the application.
extension UIFont {

  public static var labelFont:                    UIFont { _labelFont                    }
  public static var largeDisplayFont:             UIFont { _largeDisplayFont             }
  public static var controlFont:                  UIFont { _controlFont                  }
  public static var largeControlFont:             UIFont { _largeControlFont             }
  public static var compressedControlFont:        UIFont { _compressedControlFont        }
  public static var compressedControlFontEditing: UIFont { _compressedControlFontEditing }
  public static var controlSelectedFont:          UIFont { _controlSelectedFont          }
  public static var largeControlSelectedFont:     UIFont { _largeControlSelectedFont     }

}


