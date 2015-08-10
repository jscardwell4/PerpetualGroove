//
//  MSXMLParserDelegate.h
//  MSKit
//
//  Created by Jason Cardwell on 9/3/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

@import Foundation;

@interface MSXMLParserDelegate : NSObject <NSXMLParserDelegate>

/// Creates a parser delegate with handlers specified in a dictionary of form "selector-string: block"
/// @param handlers Dictionary of handlers keyed by their selector as a string
/// @return instancetype
+ (instancetype)parserDelegateWithHandlers:(NSDictionary *)handlers;



/// parserDidStartDocument:
@property (nonatomic, copy) void (^didStart)(NSXMLParser*);

/// parserDidEndDocument:
@property (nonatomic, copy) void (^didEnd)(NSXMLParser*);

/// parser:foundNotationDeclarationWithName:publicID:systemID:
@property (nonatomic, copy) void (^foundNotation)(NSXMLParser*, NSString*, NSString*, NSString*);

/// parser:foundUnparsedEntityDeclarationWithName:publicID:systemID:notationName:
@property (nonatomic, copy) void (^foundUnparsed)(NSXMLParser*, NSString*, NSString*, NSString*, NSString*);

/// parser:foundAttributeDeclarationWithName:forElement:type:defaultValue:
@property (nonatomic, copy) void (^foundAttribute)(NSXMLParser*, NSString*, NSString*, NSString*, NSString*);

/// parser:foundElementDeclarationWithName:model:
@property (nonatomic, copy) void (^foundElement)(NSXMLParser*, NSString*, NSString*);

/// parser:foundInternalEntityDeclarationWithName:value:
@property (nonatomic, copy) void (^foundInternal)(NSXMLParser*, NSString*, NSString*);

/// parser:foundExternalEntityDeclarationWithName:publicID:systemID:
@property (nonatomic, copy) void (^foundExternal)(NSXMLParser*, NSString*, NSString*, NSString*);

/// parser:didStartElement:namespaceURI:qualifiedName:attributes:
@property (nonatomic, copy) void (^startElement)(NSXMLParser*, NSString*, NSString*, NSString*, NSDictionary*);

/// parser:didEndElement:namespaceURI:qualifiedName:
@property (nonatomic, copy) void (^endElement)(NSXMLParser*, NSString*, NSString*, NSString*);

/// parser:didStartMappingPrefix:toURI:
@property (nonatomic, copy) void (^startMapping)(NSXMLParser*, NSString*, NSString*);

/// parser:didEndMappingPrefix:
@property (nonatomic, copy) void (^endMapping)(NSXMLParser*, NSString*);

/// parser:foundCharacters:
@property (nonatomic, copy) void (^foundCharacters)(NSXMLParser*, NSString*);

/// parser:foundIgnorableWhitespace:
@property (nonatomic, copy) void (^foundIgnorable)(NSXMLParser*, NSString*);

/// parser:foundProcessingInstructionWithTarget:data:
@property (nonatomic, copy) void (^foundProcessing)(NSXMLParser*, NSString*, NSString*);

/// parser:foundComment:
@property (nonatomic, copy) void (^foundComment)(NSXMLParser*, NSString*);

/// parser:foundCDATA:
@property (nonatomic, copy) void (^foundCData)(NSXMLParser*, NSData*);

/// parser:resolveExternalEntityName:systemID:
@property (nonatomic, copy) NSData* (^resolveExternal)(NSXMLParser*, NSString*, NSString*);

/// parser:parseErrorOccurred:
@property (nonatomic, copy) void (^parseErrorOccurred)(NSXMLParser*, NSError*);

/// parser:validationErrorOccurred:
@property (nonatomic, copy) void (^validationErrorOccurred)(NSXMLParser*, NSError*);

@end
