//
//  FileLogger.swift
//  MoonKit
//
//  Created by Jason Cardwell on 10/20/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import Lumberjack

public class FileLogger: DDFileLogger {

  public var reopenLastFile = true

  /**
  rollLogFileWithCompletionBlock:

  - parameter completionBlock: (() -> Void
  */
  public override func rollLogFileWithCompletionBlock(completionBlock: (() -> Void)!) {
    if reopenLastFile { reopenLastFile = false }
    else { super.rollLogFileWithCompletionBlock(completionBlock) }
  }

}