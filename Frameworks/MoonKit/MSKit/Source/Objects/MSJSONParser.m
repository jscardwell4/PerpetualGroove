//
//  MSJSONParser.m
//  MSKit
//
//  Created by Jason Cardwell on 5/2/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSJSONParser.h"
#import "MSJSONAssembler.h"
@import PEGKit;

// start
// @before {
//     PKTokenizer *t = self.tokenizer;
//     t.commentState.reportsCommentTokens = YES;
//     [t setTokenizerState:t.commentState from:'/' to:'/'];
//     [t.commentState addSingleLineStartMarker:@"//"];
//     [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];
// }
//                    = array | object;

//  object            = openCurly (Empty | keyPath colon value (comma keyPath colon value)*) closeCurly;
//  keyPath           = quote key (dot key)* quote;
//  key               = Word;

//  array             = openBracket (Empty | value (comma value)*) closeBracket;

//  value             = (nullLiteral | trueLiteral | falseLiteral | number | string | array | object);

//  string            = QuotedString;
//  number            = Number;
//  nullLiteral       = 'null';
//  trueLiteral       = 'true';
//  falseLiteral      = 'false';

//  openCurly         = '{';
//  closeCurly        = '}';
//  openBracket       = '[';
//  closeBracket      = ']';
//  comma             = ',';
//  colon             = ':';
//  quote             = '"';
//  dot               = '.';

@interface MSJSONParser ()

@property (nonatomic, strong) NSMutableDictionary * start_memo;
@property (nonatomic, strong) NSMutableDictionary * object_memo;
@property (nonatomic, strong) NSMutableDictionary * keyPath_memo;
@property (nonatomic, strong) NSMutableDictionary * key_memo;
@property (nonatomic, strong) NSMutableDictionary * array_memo;
@property (nonatomic, strong) NSMutableDictionary * value_memo;
@property (nonatomic, strong) NSMutableDictionary * string_memo;
@property (nonatomic, strong) NSMutableDictionary * number_memo;
@property (nonatomic, strong) NSMutableDictionary * nullLiteral_memo;
@property (nonatomic, strong) NSMutableDictionary * trueLiteral_memo;
@property (nonatomic, strong) NSMutableDictionary * falseLiteral_memo;
@property (nonatomic, strong) NSMutableDictionary * openCurly_memo;
@property (nonatomic, strong) NSMutableDictionary * closeCurly_memo;
@property (nonatomic, strong) NSMutableDictionary * openBracket_memo;
@property (nonatomic, strong) NSMutableDictionary * closeBracket_memo;
@property (nonatomic, strong) NSMutableDictionary * comma_memo;
@property (nonatomic, strong) NSMutableDictionary * colon_memo;
@property (nonatomic, strong) NSMutableDictionary * quote_memo;
@property (nonatomic, strong) NSMutableDictionary * dot_memo;
@end

@implementation MSJSONParser

/// parserWithOptions:delegate:
/// @param options description
/// @param delegate description
/// @return MSJSONParser *
+ (MSJSONParser *)parserWithOptions:(MSJSONFormatOptions)options delegate:(id)delegate {
  MSJSONParser * parser = [[self alloc] initWithDelegate:delegate];
  parser.options = options;
  return parser;
}

/// initWithDelegate:
/// @param delegate description
/// @return instancetype
- (instancetype)initWithDelegate:(id)delegate {

  if ((self = [super initWithDelegate:delegate])) {

    self.startRuleName          = @"start";
    self.tokenKindTab[@"false"] = @(MSJSONPARSER_TOKEN_KIND_FALSELITERAL);
    self.tokenKindTab[@"."]     = @(MSJSONPARSER_TOKEN_KIND_DOT);
    self.tokenKindTab[@"}"]     = @(MSJSONPARSER_TOKEN_KIND_CLOSECURLY);
    self.tokenKindTab[@"\""]    = @(MSJSONPARSER_TOKEN_KIND_QUOTE);
    self.tokenKindTab[@"["]     = @(MSJSONPARSER_TOKEN_KIND_OPENBRACKET);
    self.tokenKindTab[@"null"]  = @(MSJSONPARSER_TOKEN_KIND_NULLLITERAL);
    self.tokenKindTab[@","]     = @(MSJSONPARSER_TOKEN_KIND_COMMA);
    self.tokenKindTab[@"true"]  = @(MSJSONPARSER_TOKEN_KIND_TRUELITERAL);
    self.tokenKindTab[@"]"]     = @(MSJSONPARSER_TOKEN_KIND_CLOSEBRACKET);
    self.tokenKindTab[@"{"]     = @(MSJSONPARSER_TOKEN_KIND_OPENCURLY);
    self.tokenKindTab[@":"]     = @(MSJSONPARSER_TOKEN_KIND_COLON);

    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_FALSELITERAL] = @"false";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_DOT]          = @".";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_CLOSECURLY]   = @"}";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_QUOTE]        = @"\"";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_OPENBRACKET]  = @"[";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_NULLLITERAL]  = @"null";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_COMMA]        = @",";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_TRUELITERAL]  = @"true";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_CLOSEBRACKET] = @"]";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_OPENCURLY]    = @"{";
    self.tokenKindNameTab[MSJSONPARSER_TOKEN_KIND_COLON]        = @":";

    self.start_memo        = [@{} mutableCopy];
    self.object_memo       = [@{} mutableCopy];
    self.keyPath_memo      = [@{} mutableCopy];
    self.key_memo          = [@{} mutableCopy];
    self.array_memo        = [@{} mutableCopy];
    self.value_memo        = [@{} mutableCopy];
    self.string_memo       = [@{} mutableCopy];
    self.number_memo       = [@{} mutableCopy];
    self.nullLiteral_memo  = [@{} mutableCopy];
    self.trueLiteral_memo  = [@{} mutableCopy];
    self.falseLiteral_memo = [@{} mutableCopy];
    self.openCurly_memo    = [@{} mutableCopy];
    self.closeCurly_memo   = [@{} mutableCopy];
    self.openBracket_memo  = [@{} mutableCopy];
    self.closeBracket_memo = [@{} mutableCopy];
    self.comma_memo        = [@{} mutableCopy];
    self.colon_memo        = [@{} mutableCopy];
    self.quote_memo        = [@{} mutableCopy];
    self.dot_memo          = [@{} mutableCopy];

  }

  return self;

}

/// clearMemo
- (void)clearMemo {

  [_start_memo        removeAllObjects];
  [_object_memo       removeAllObjects];
  [_keyPath_memo      removeAllObjects];
  [_key_memo          removeAllObjects];
  [_array_memo        removeAllObjects];
  [_value_memo        removeAllObjects];
  [_string_memo       removeAllObjects];
  [_number_memo       removeAllObjects];
  [_nullLiteral_memo  removeAllObjects];
  [_trueLiteral_memo  removeAllObjects];
  [_falseLiteral_memo removeAllObjects];
  [_openCurly_memo    removeAllObjects];
  [_closeCurly_memo   removeAllObjects];
  [_openBracket_memo  removeAllObjects];
  [_closeBracket_memo removeAllObjects];
  [_comma_memo        removeAllObjects];
  [_colon_memo        removeAllObjects];
  [_quote_memo        removeAllObjects];
  [_dot_memo          removeAllObjects];

}

- (void)start {

    [self tryAndRecover:TOKEN_KIND_BUILTIN_EOF block:^{
        [self start_];
        [self matchEOF:YES];
    } completion:^{
        [self matchEOF:YES];
    }];

}

- (void)__start {

    [self execute:^{

    PKTokenizer *t = self.tokenizer;
    t.commentState.reportsCommentTokens = YES;
    [t setTokenizerState:t.commentState from:'/' to:'/'];
    [t.commentState addSingleLineStartMarker:@"//"];
    [t.commentState addMultiLineStartMarker:@"/*" endMarker:@"*/"];

    self.silentlyConsumesWhitespace = YES;
    t.whitespaceState.reportsWhitespaceTokens = YES;
    self.assembly.preservesWhitespaceTokens = YES;

    }];
    if ([self predicts:MSJSONPARSER_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array_];
    } else if ([self predicts:MSJSONPARSER_TOKEN_KIND_OPENCURLY, 0]) {
        [self object_];
    } else {
        [self raise:@"No viable alternative found in rule 'start'."];
    }

    [self fireDelegateSelector:@selector(parser:didMatchStart:)];
}

- (void)start_ {
    [self parseRule:@selector(__start) withMemo:_start_memo];
}

- (void)__object {

    [self openCurly_];
                [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_CLOSECURLY block:^{
        if ([self predicts:MSJSONPARSER_TOKEN_KIND_QUOTE, 0]) {
            [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_COLON block:^{
                [self keyPath_];
                [self colon_];
            } completion:^{
                [self colon_];
            }];
                [self value_];
                while ([self speculate:^{ [self comma_]; [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_COLON block:^{ [self keyPath_]; [self colon_]; } completion:^{ [self colon_]; }];[self value_]; }]) {
                        [self comma_];
                        [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_COLON block:^{
                            [self keyPath_];
                            [self colon_];
                        } completion:^{
                            [self colon_];
                        }];
                            [self value_];
                }
                    }
                    [self closeCurly_];
                } completion:^{
                    [self closeCurly_];
                }];

    [self fireDelegateSelector:@selector(parser:didMatchObject:)];
}

- (void)object_ {
    [self parseRule:@selector(__object) withMemo:_object_memo];
}

- (void)__keyPath {

    [self quote_];
    [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_QUOTE block:^{
        [self key_];
        while ([self speculate:^{ [self dot_]; [self key_]; }]) {
            [self dot_];
            [self key_];
        }
        [self quote_];
    } completion:^{
        [self quote_];
    }];

    [self fireDelegateSelector:@selector(parser:didMatchKeyPath:)];
}

- (void)keyPath_ {
    [self parseRule:@selector(__keyPath) withMemo:_keyPath_memo];
}

- (void)__key {

    [self matchWord:NO];

    [self fireDelegateSelector:@selector(parser:didMatchKey:)];
}

- (void)key_ {
    [self parseRule:@selector(__key) withMemo:_key_memo];
}

- (void)__array {

    [self openBracket_];
    [self tryAndRecover:MSJSONPARSER_TOKEN_KIND_CLOSEBRACKET block:^{
        if ([self predicts:MSJSONPARSER_TOKEN_KIND_FALSELITERAL, MSJSONPARSER_TOKEN_KIND_NULLLITERAL, MSJSONPARSER_TOKEN_KIND_OPENBRACKET, MSJSONPARSER_TOKEN_KIND_OPENCURLY, MSJSONPARSER_TOKEN_KIND_TRUELITERAL, TOKEN_KIND_BUILTIN_NUMBER, TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
            [self value_];
            while ([self speculate:^{ [self comma_]; [self value_]; }]) {
                [self comma_];
                [self value_];
            }
        }
        [self closeBracket_];
    } completion:^{
        [self closeBracket_];
    }];

    [self fireDelegateSelector:@selector(parser:didMatchArray:)];
}

- (void)array_ {
    [self parseRule:@selector(__array) withMemo:_array_memo];
}

- (void)__value {

    if ([self predicts:MSJSONPARSER_TOKEN_KIND_NULLLITERAL, 0]) {
        [self nullLiteral_];
    } else if ([self predicts:MSJSONPARSER_TOKEN_KIND_TRUELITERAL, 0]) {
        [self trueLiteral_];
    } else if ([self predicts:MSJSONPARSER_TOKEN_KIND_FALSELITERAL, 0]) {
        [self falseLiteral_];
    } else if ([self predicts:TOKEN_KIND_BUILTIN_NUMBER, 0]) {
        [self number_];
    } else if ([self predicts:TOKEN_KIND_BUILTIN_QUOTEDSTRING, 0]) {
        [self string_];
    } else if ([self predicts:MSJSONPARSER_TOKEN_KIND_OPENBRACKET, 0]) {
        [self array_];
    } else if ([self predicts:MSJSONPARSER_TOKEN_KIND_OPENCURLY, 0]) {
        [self object_];
    } else {
        [self raise:@"No viable alternative found in rule 'value'."];
    }

    [self fireDelegateSelector:@selector(parser:didMatchValue:)];
}

- (void)value_ {
    [self parseRule:@selector(__value) withMemo:_value_memo];
}

- (void)__string {

    [self matchQuotedString:NO];

    [self fireDelegateSelector:@selector(parser:didMatchString:)];
}

- (void)string_ {
    [self parseRule:@selector(__string) withMemo:_string_memo];
}

- (void)__number {

    [self matchNumber:NO];

    [self fireDelegateSelector:@selector(parser:didMatchNumber:)];
}

- (void)number_ {
    [self parseRule:@selector(__number) withMemo:_number_memo];
}

- (void)__nullLiteral {

    [self match:MSJSONPARSER_TOKEN_KIND_NULLLITERAL discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchNullLiteral:)];
}

- (void)nullLiteral_ {
    [self parseRule:@selector(__nullLiteral) withMemo:_nullLiteral_memo];
}

- (void)__trueLiteral {

    [self match:MSJSONPARSER_TOKEN_KIND_TRUELITERAL discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchTrueLiteral:)];
}

- (void)trueLiteral_ {
    [self parseRule:@selector(__trueLiteral) withMemo:_trueLiteral_memo];
}

- (void)__falseLiteral {

    [self match:MSJSONPARSER_TOKEN_KIND_FALSELITERAL discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchFalseLiteral:)];
}

- (void)falseLiteral_ {
    [self parseRule:@selector(__falseLiteral) withMemo:_falseLiteral_memo];
}

- (void)__openCurly {

    [self match:MSJSONPARSER_TOKEN_KIND_OPENCURLY discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchOpenCurly:)];
}

- (void)openCurly_ {
    [self parseRule:@selector(__openCurly) withMemo:_openCurly_memo];
}

- (void)__closeCurly {

    [self match:MSJSONPARSER_TOKEN_KIND_CLOSECURLY discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchCloseCurly:)];
}

- (void)closeCurly_ {
    [self parseRule:@selector(__closeCurly) withMemo:_closeCurly_memo];
}

- (void)__openBracket {

    [self match:MSJSONPARSER_TOKEN_KIND_OPENBRACKET discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchOpenBracket:)];
}

- (void)openBracket_ {
    [self parseRule:@selector(__openBracket) withMemo:_openBracket_memo];
}

- (void)__closeBracket {

    [self match:MSJSONPARSER_TOKEN_KIND_CLOSEBRACKET discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchCloseBracket:)];
}

- (void)closeBracket_ {
    [self parseRule:@selector(__closeBracket) withMemo:_closeBracket_memo];
}

- (void)__comma {

    [self match:MSJSONPARSER_TOKEN_KIND_COMMA discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchComma:)];
}

- (void)comma_ {
    [self parseRule:@selector(__comma) withMemo:_comma_memo];
}

- (void)__colon {

    [self match:MSJSONPARSER_TOKEN_KIND_COLON discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchColon:)];
}

- (void)colon_ {
    [self parseRule:@selector(__colon) withMemo:_colon_memo];
}

- (void)__quote {

    [self match:MSJSONPARSER_TOKEN_KIND_QUOTE discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchQuote:)];
}

- (void)quote_ {
    [self parseRule:@selector(__quote) withMemo:_quote_memo];
}

- (void)__dot {

    [self match:MSJSONPARSER_TOKEN_KIND_DOT discard:NO];

    [self fireDelegateSelector:@selector(parser:didMatchDot:)];
}

- (void)dot_ {
    [self parseRule:@selector(__dot) withMemo:_dot_memo];
}

@end
