//
//  MSXMLParserDelegate.m
//  MSKit
//
//  Created by Jason Cardwell on 9/3/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

#import "MSXMLParserDelegate.h"
#import "MSKitMacros.h"
#import <objc/runtime.h>


/*
 Code for extracting the block signature from
 http://stackoverflow.com/questions/9048305/checking-objective-c-block-type
 */
struct BlockDescriptor {
  unsigned long reserved;
  unsigned long size;
  void *rest[1];
};

struct Block {
  void *isa;
  int flags;
  int reserved;
  void *invoke;
  struct BlockDescriptor *descriptor;
};

static const char *BlockSig(id blockObj) {
  struct Block *block = (__bridge void *)blockObj;
  struct BlockDescriptor *descriptor = block->descriptor;

  int copyDisposeFlag = 1 << 25;
  int signatureFlag = 1 << 30;

  assert(block->flags & signatureFlag);

  int index = 0;
  if(block->flags & copyDisposeFlag)
    index += 2;

  return descriptor->rest[index];
}

@implementation MSXMLParserDelegate

/// Creates a parser delegate with handlers specified in a dictionary of form "selector-string: block"
/// @param handlers Dictionary of handlers keyed by their selector as a string
/// @return instancetype
+ (instancetype)parserDelegateWithHandlers:(NSDictionary *)handlers {

  MSXMLParserDelegate * parserDelegate = [self new];

  static dispatch_once_t onceToken;
  static NSDictionary  * index;       // Holds property names keyed by corresponding selector
  static NSDictionary  * signatures;  // Holds the valid signature of block properties

  dispatch_once(&onceToken, ^{
    SEL didStartSelector =
      @selector(parserDidStartDocument:);
    SEL didEndSelector =
      @selector(parserDidEndDocument:);
    SEL foundNotationSelector =
      @selector(parser:foundNotationDeclarationWithName:publicID:systemID:);
    SEL foundUnparsedSelector =
      @selector(parser:foundUnparsedEntityDeclarationWithName:publicID:systemID:notationName:);
    SEL foundAttributeSelector =
      @selector(parser:foundAttributeDeclarationWithName:forElement:type:defaultValue:);
    SEL foundElementSelector =
      @selector(parser:foundElementDeclarationWithName:model:);
    SEL foundInternalSelector =
      @selector(parser:foundInternalEntityDeclarationWithName:value:);
    SEL foundExternalSelector =
      @selector(parser:foundExternalEntityDeclarationWithName:publicID:systemID:);
    SEL startElementSelector =
      @selector(parser:didStartElement:namespaceURI:qualifiedName:attributes:);
    SEL endElementSelector =
      @selector(parser:didEndElement:namespaceURI:qualifiedName:);
    SEL startMappingSelector =
      @selector(parser:didStartMappingPrefix:toURI:);
    SEL endMappingSelector =
      @selector(parser:didEndMappingPrefix:);
    SEL foundCharactersSelector =
      @selector(parser:foundCharacters:);
    SEL foundIgnorableSelector =
      @selector(parser:foundIgnorableWhitespace:);
    SEL foundProcessingSelector =
      @selector(parser:foundProcessingInstructionWithTarget:data:);
    SEL foundCommentSelector =
      @selector(parser:foundComment:);
    SEL foundCDataSelector =
      @selector(parser:foundCDATA:);
    SEL resolveExternalSelector =
      @selector(parser:resolveExternalEntityName:systemID:);
    SEL parseErrorOccurredSelector =
      @selector(parser:parseErrorOccurred:);
    SEL validationErrorOccurredSelector =
      @selector(parser:validationErrorOccurred:);

    NSString * didStartProperty                = SelectorString(@selector(didStart));
    NSString * didEndProperty                  = SelectorString(@selector(didEnd));
    NSString * foundNotationProperty           = SelectorString(@selector(foundNotation));
    NSString * foundUnparsedProperty           = SelectorString(@selector(foundUnparsed));
    NSString * foundAttributeProperty          = SelectorString(@selector(foundAttribute));
    NSString * foundElementProperty            = SelectorString(@selector(foundElement));
    NSString * foundInternalProperty           = SelectorString(@selector(foundInternal));
    NSString * foundExternalProperty           = SelectorString(@selector(foundExternal));
    NSString * startElementProperty            = SelectorString(@selector(startElement));
    NSString * endElementProperty              = SelectorString(@selector(endElement));
    NSString * startMappingProperty            = SelectorString(@selector(startMapping));
    NSString * endMappingProperty              = SelectorString(@selector(endMapping));
    NSString * foundCharactersProperty         = SelectorString(@selector(foundCharacters));
    NSString * foundIgnorableProperty          = SelectorString(@selector(foundIgnorable));
    NSString * foundProcessingProperty         = SelectorString(@selector(foundProcessing));
    NSString * foundCommentProperty            = SelectorString(@selector(foundComment));
    NSString * foundCDataProperty              = SelectorString(@selector(foundCData));
    NSString * resolveExternalProperty         = SelectorString(@selector(resolveExternal));
    NSString * parseErrorOccurredProperty      = SelectorString(@selector(parseErrorOccurred));
    NSString * validationErrorOccurredProperty = SelectorString(@selector(validationErrorOccurred));

    index = @{ SelectorString(didStartSelector)               : didStartProperty,
               SelectorString(didEndSelector)                 : didEndProperty,
               SelectorString(foundNotationSelector)          : foundNotationProperty,
               SelectorString(foundUnparsedSelector)          : foundUnparsedProperty,
               SelectorString(foundAttributeSelector)         : foundAttributeProperty,
               SelectorString(foundElementSelector)           : foundElementProperty,
               SelectorString(foundInternalSelector)          : foundInternalProperty,
               SelectorString(foundExternalSelector)          : foundExternalProperty,
               SelectorString(startElementSelector)           : startElementProperty,
               SelectorString(endElementSelector)             : endElementProperty,
               SelectorString(startMappingSelector)           : startMappingProperty,
               SelectorString(endMappingSelector)             : endMappingProperty,
               SelectorString(foundCharactersSelector)        : foundCharactersProperty,
               SelectorString(foundIgnorableSelector)         : foundIgnorableProperty,
               SelectorString(foundProcessingSelector)        : foundProcessingProperty,
               SelectorString(foundCommentSelector)           : foundCommentProperty,
               SelectorString(foundCDataSelector)             : foundCDataProperty,
               SelectorString(resolveExternalSelector)        : resolveExternalProperty,
               SelectorString(parseErrorOccurredSelector)     : parseErrorOccurredProperty,
               SelectorString(validationErrorOccurredSelector): validationErrorOccurredProperty };

    signatures = @{ didStartProperty:
                      @"v@?@\"NSXMLParser\"",
                    didEndProperty:
                      @"v@?@\"NSXMLParser\"",
                    foundNotationProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"",
                    foundUnparsedProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"@\"NSString\"",
                    foundAttributeProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"@\"NSString\"",
                    foundElementProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"",
                    foundInternalProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"",
                    foundExternalProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"",
                    startElementProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"@\"NSDictionary\"",
                    endElementProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"@\"NSString\"",
                    startMappingProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"",
                    endMappingProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"",
                    foundCharactersProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"",
                    foundIgnorableProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"",
                    foundProcessingProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"",
                    foundCommentProperty:
                      @"v@?@\"NSXMLParser\"@\"NSString\"",
                    foundCDataProperty:
                      @"v@?@\"NSXMLParser\"@\"NSDATA\"",
                    resolveExternalProperty:
                      @"@\"NSData\"@?@\"NSXMLParser\"@\"NSString\"@\"NSString\"",
                    parseErrorOccurredProperty:
                      @"v@?@\"NSXMLParser\"@\"NSError\"",
                    validationErrorOccurredProperty:
                      @"v@?@\"NSXMLParser\"@\"NSError\"" };

  });

  [handlers enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
    NSString * property = index[key];
    if (property && obj) {
      NSString * signature = [@(BlockSig(obj)) stringByRemovingCharactersFromSet:NSDecimalDigitCharacters];
      if (isStringKind(signature) && [signature isEqualToString:signatures[property]])
        [parserDelegate setValue:obj forKey:property];
    }
  }];

  return parserDelegate;

}


- (void)parserDidStartDocument:(NSXMLParser *)parser
{ if (self.didStart) self.didStart(parser); }

- (void)parserDidEndDocument:(NSXMLParser *)parser
{ if (self.didEnd) self.didEnd(parser); }

- (void)                    parser:(NSXMLParser *)parser
  foundNotationDeclarationWithName:(NSString *)name
                          publicID:(NSString *)publicID
                          systemID:(NSString *)systemID
{ if (self.foundNotation) self.foundNotation(parser, name, publicID, systemID); }

- (void)                          parser:(NSXMLParser *)parser
  foundUnparsedEntityDeclarationWithName:(NSString *)name
                                publicID:(NSString *)publicID
                                systemID:(NSString *)systemID
                            notationName:(NSString *)notationName
{ if (self.foundUnparsed) self.foundUnparsed(parser, name, publicID, systemID, notationName); }

- (void)                     parser:(NSXMLParser *)parser
  foundAttributeDeclarationWithName:(NSString *)attributeName
                         forElement:(NSString *)elementName
                               type:(NSString *)type
                       defaultValue:(NSString *)defaultValue
{ if (self.foundAttribute) self.foundAttribute(parser, attributeName, elementName, type, defaultValue); }

- (void)                   parser:(NSXMLParser *)parser
  foundElementDeclarationWithName:(NSString *)elementName
                            model:(NSString *)model
{ if (self.foundElement) self.foundElement(parser, elementName, model); }

- (void)                          parser:(NSXMLParser *)parser
  foundInternalEntityDeclarationWithName:(NSString *)name
                                   value:(NSString *)value
{ if (self.foundInternal) self.foundInternal(parser, name, value); }

- (void)                          parser:(NSXMLParser *)parser
  foundExternalEntityDeclarationWithName:(NSString *)name
                                publicID:(NSString *)publicID
                                systemID:(NSString *)systemID
{ if (self.foundExternal) self.foundExternal(parser, name, publicID, systemID); }

- (void)   parser:(NSXMLParser *)parser
  didStartElement:(NSString *)elementName
     namespaceURI:(NSString *)namespaceURI
    qualifiedName:(NSString *)qName
       attributes:(NSDictionary *)attributeDict
{ if (self.startElement) self.startElement(parser, elementName, namespaceURI, qName, attributeDict); }

- (void) parser:(NSXMLParser *)parser
  didEndElement:(NSString *)elementName
   namespaceURI:(NSString *)namespaceURI
  qualifiedName:(NSString *)qName
{ if (self.endElement) self.endElement(parser, elementName, namespaceURI, qName); }

- (void)         parser:(NSXMLParser *)parser
  didStartMappingPrefix:(NSString *)prefix
                  toURI:(NSString *)namespaceURI
{ if (self.startMapping) self.startMapping(parser, prefix, namespaceURI); }

- (void)parser:(NSXMLParser *)parser didEndMappingPrefix:(NSString *)prefix
{ if (self.endMapping) self.endMapping(parser, prefix); }

- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string
{ if (self.foundCharacters) self.foundCharacters(parser, string); }

- (void)parser:(NSXMLParser *)parser foundIgnorableWhitespace:(NSString *)whitespaceString
{ if (self.foundIgnorable) self.foundIgnorable(parser, whitespaceString); }

- (void)                        parser:(NSXMLParser *)parser
  foundProcessingInstructionWithTarget:(NSString *)target
                                  data:(NSString *)data
{ if (self.foundProcessing) self.foundProcessing(parser, target, data); }

- (void)parser:(NSXMLParser *)parser foundComment:(NSString *)comment
{ if (self.foundComment) self.foundComment(parser, comment); }

- (void)parser:(NSXMLParser *)parser foundCDATA:(NSData *)CDATABlock
{ if (self.foundCData) self.foundCData(parser, CDATABlock); }

- (NSData *)         parser:(NSXMLParser *)parser
  resolveExternalEntityName:(NSString *)name
                   systemID:(NSString *)systemID
{ return self.resolveExternal ? self.resolveExternal(parser, name, systemID) : nil; }

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError
{ if (self.parseErrorOccurred) self.parseErrorOccurred(parser, parseError); }

- (void)parser:(NSXMLParser *)parser validationErrorOccurred:(NSError *)validationError
{ if (self.validationErrorOccurred) self.validationErrorOccurred(parser, validationError); }

@end
