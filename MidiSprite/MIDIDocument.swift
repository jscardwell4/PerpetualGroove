//
//  MIDIDocument.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 9/28/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

final class MIDIDocument: UIDocument {

  enum Error: String, ErrorType {
    case InvalidContentType, NoContent
  }

  private var file: MIDIFile?
  private(set) var sequence = MIDISequence()

  /**
  loadFromContents:ofType:

  - parameter contents: AnyObject
  - parameter typeName: String?
  */
  override func loadFromContents(contents: AnyObject, ofType typeName: String?) throws {
    guard let data = contents as? NSData else { throw Error.InvalidContentType }
    sequence = MIDISequence(file: try MIDIFile(data: data))
  }

  /**
  contentsForType:

  - parameter typeName: String
  */
  override func contentsForType(typeName: String) throws -> AnyObject {
    let bytes = sequence.file.bytes
    return NSData(bytes: bytes, length: bytes.count)
  }

  /**
  fileAttributesToWriteToURL:forSaveOperation:

  - parameter url: NSURL
  - parameter saveOperation: UIDocumentSaveOperation
  */
  override func fileAttributesToWriteToURL(url: NSURL,
                          forSaveOperation saveOperation: UIDocumentSaveOperation) throws -> [NSObject: AnyObject]
  {

    // TODO: Generate thumbnail
    let image = UIImage()

    return [NSURLHasHiddenExtensionKey: true, NSURLThumbnailDictionaryKey: [NSThumbnail1024x1024SizeKey: image]]
  }


}
