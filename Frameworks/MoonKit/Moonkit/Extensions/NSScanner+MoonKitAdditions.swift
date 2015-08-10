//
//  NSScanner+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/17/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

extension NSScanner {

  /**
  scanCharacter:

  - parameter character: Character

  - returns: Bool
  */
  func scanCharacter(character:Character) -> Bool {

    return self.scanString(String(character), intoString: nil)
  }

  /**
  scanUpToCharacter:intoString:

  - parameter character: Character
  - parameter stringValue: AutoreleasingUnsafeMutablePointer<NSString?>

  - returns: Bool
  */
  func scanUpToCharacter(character:Character,
              intoString stringValue: AutoreleasingUnsafeMutablePointer<NSString?>) -> Bool

  {
    return self.scanUpToString(String(character), intoString: stringValue)
  }

}