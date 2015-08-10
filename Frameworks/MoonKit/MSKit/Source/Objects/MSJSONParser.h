//
//  MSJSONParser.h
//  MSKit
//
//  Created by Jason Cardwell on 5/2/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
@import PEGKit;
#import "MSJSONSerialization.h"

enum {
    MSJSONPARSER_TOKEN_KIND_FALSELITERAL = 14,
    MSJSONPARSER_TOKEN_KIND_DOT,
    MSJSONPARSER_TOKEN_KIND_CLOSECURLY,
    MSJSONPARSER_TOKEN_KIND_QUOTE,
    MSJSONPARSER_TOKEN_KIND_OPENBRACKET,
    MSJSONPARSER_TOKEN_KIND_NULLLITERAL,
    MSJSONPARSER_TOKEN_KIND_COMMA,
    MSJSONPARSER_TOKEN_KIND_TRUELITERAL,
    MSJSONPARSER_TOKEN_KIND_CLOSEBRACKET,
    MSJSONPARSER_TOKEN_KIND_OPENCURLY,
    MSJSONPARSER_TOKEN_KIND_COLON,
};

@interface MSJSONParser:PKParser

+ (MSJSONParser *)parserWithOptions:(MSJSONFormatOptions)options delegate:(id)delegate;

@property (nonatomic, assign) MSJSONFormatOptions options;

@end
