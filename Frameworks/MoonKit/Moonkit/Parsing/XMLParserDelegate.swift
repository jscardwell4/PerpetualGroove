//
//  XMLParserDelegate.swift
//  Remote
//
//  Created by Jason Cardwell on 5/06/15.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

@objc public final class XMLParserDelegate: NSObject, NSXMLParserDelegate {

  public var didStart:                ((NSXMLParser) -> Void)?
  public var didEnd:                  ((NSXMLParser) -> Void)?
  public var foundNotation:           ((NSXMLParser, String, String?, String?) -> Void)?
  public var foundUnparsed:           ((NSXMLParser, String, String?, String?, String?) -> Void)?
  public var foundAttribute:          ((NSXMLParser, String, String, String?, String?) -> Void)?
  public var foundElement:            ((NSXMLParser, String, String) -> Void)?
  public var foundInternal:           ((NSXMLParser, String, String?) -> Void)?
  public var foundExternal:           ((NSXMLParser, String, String?, String?) -> Void)?
  public var startElement:            ((NSXMLParser, String, String?, String?, [String:String]) -> Void)?
  public var endElement:              ((NSXMLParser, String, String?, String?) -> Void)?
  public var startMapping:            ((NSXMLParser, String, String) -> Void)?
  public var endMapping:              ((NSXMLParser, String) -> Void)?
  public var foundCharacters:         ((NSXMLParser, String) -> Void)?
  public var foundIgnorable:          ((NSXMLParser, String) -> Void)?
  public var foundProcessing:         ((NSXMLParser, String, String?) -> Void)?
  public var foundComment:            ((NSXMLParser, String?) -> Void)?
  public var foundCData:              ((NSXMLParser, NSData) -> Void)?
  public var resolveExternal:         ((NSXMLParser, String, String?) -> NSData?)?
  public var parseErrorOccurred:      ((NSXMLParser, NSError) -> Void)?
  public var validationErrorOccurred: ((NSXMLParser, NSError) -> Void)?

  public func parserDidStartDocument(parser: NSXMLParser) { didStart?(parser) }

  public func parserDidEndDocument(parser: NSXMLParser) { didEnd?(parser) }

  public func                 parser(parser: NSXMLParser,
    foundNotationDeclarationWithName name: String,
                            publicID: String?,
                            systemID: String?)
  {
    foundNotation?(parser, name, publicID, systemID)
  }

  public func                       parser(parser: NSXMLParser,
    foundUnparsedEntityDeclarationWithName name: String,
                                  publicID: String?,
                                  systemID: String?,
                              notationName: String?)
  {
    foundUnparsed?(parser, name, publicID, systemID, notationName)
  }

  public func                  parser(parser: NSXMLParser,
    foundAttributeDeclarationWithName attributeName: String,
                           forElement elementName: String,
                                 type: String?,
                         defaultValue: String?)
  {
    foundAttribute?(parser, attributeName, elementName, type, defaultValue)
  }

  public func                parser(parser: NSXMLParser,
    foundElementDeclarationWithName elementName: String,
                              model: String)
  {
    foundElement?(parser, elementName, model)
  }

  public func                       parser(parser: NSXMLParser,
    foundInternalEntityDeclarationWithName name: String,
                                     value: String?)
  {
    foundInternal?(parser, name, value)
  }

  public func                       parser(parser: NSXMLParser,
    foundExternalEntityDeclarationWithName name: String,
                                  publicID: String?,
                                  systemID: String?)
  {
    foundExternal?(parser, name, publicID, systemID)
  }

  public func parser(parser: NSXMLParser,
     didStartElement elementName: String,
        namespaceURI: String?,
       qualifiedName qName: String?,
          attributes:[String: String])
  {
    startElement?(parser, elementName, namespaceURI, qName, attributes)
  }

  public func parser(parser: NSXMLParser,
       didEndElement elementName: String,
        namespaceURI: String?,
       qualifiedName qName: String?)
  {
    endElement?(parser, elementName, namespaceURI, qName)
  }

  public func      parser(parser: NSXMLParser,
    didStartMappingPrefix prefix: String,
                    toURI namespaceURI: String)
  {
    startMapping?(parser, prefix, namespaceURI)
  }

  public func parser(parser: NSXMLParser, didEndMappingPrefix prefix: String) {
    endMapping?(parser, prefix)
  }

  public func parser(parser: NSXMLParser, foundCharacters string: String) {
    foundCharacters?(parser, string)
  }

  public func parser(parser: NSXMLParser, foundIgnorableWhitespace whitespaceString: String) {
    foundIgnorable?(parser, whitespaceString)
  }

  public func                     parser(parser: NSXMLParser,
    foundProcessingInstructionWithTarget target: String,
                                    data: String?)
  {
    foundProcessing?(parser, target, data)
  }

  public func parser(parser: NSXMLParser, foundComment comment: String) {
    foundComment?(parser, comment)
  }

  public func parser(parser: NSXMLParser, foundCDATA CDATABlock: NSData) {
    foundCData?(parser, CDATABlock)
  }

  public func         parser(parser: NSXMLParser,
    resolveExternalEntityName name: String,
                     systemID: String?) -> NSData?
  {
    return resolveExternal?(parser, name, systemID) ?? nil
  }

  public func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
    parseErrorOccurred?(parser, parseError)
  }

  public func parser(parser: NSXMLParser, validationErrorOccurred validationError: NSError) {
    validationErrorOccurred?(parser, validationError)
  }
}