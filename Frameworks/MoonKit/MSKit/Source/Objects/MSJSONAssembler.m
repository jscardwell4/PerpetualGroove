//
//  MSJSONAssembler.m
//  MSKit
//
//  Created by Jason Cardwell on 10/20/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//

#import "MSJSONAssembler.h"
#import <PEGKit/PEGKit.h>
#import "MSStack.h"
#import "MSDictionary.h"
#import "NSArray+MSKitAdditions.h"
#import "MSJSONParser.h"
#import <objc/runtime.h>
#import "NSObject+MSKitAdditions.h"
#import "MSLog.h"

static int ddLogLevel = LOG_LEVEL_DEBUG;
static int msLogContext = LOG_CONTEXT_CONSOLE;
#pragma unused(ddLogLevel,msLogContext)

@interface PKAssembly (MSKitAdditions)

- (id)MS_peek;

@end

@implementation PKAssembly (MSKitAdditions)

- (id)MS_peek { return ([self isStackEmpty] ? nil : [self.stack lastObject]); }

@end


typedef NS_ENUM(uint8_t, MSJSONAssemblerValueType)
{
    MSJSONAssemblerStringValueType = 0,
    MSJSONAssemblerNumberValueType,
    MSJSONAssemblerBooleanValueType,
    MSJSONAssemblerNullValueType,
    MSJSONAssemblerArrayValueType,
    MSJSONAssemblerObjectValueType
};



@interface MSJSONAssembler ()

@property (nonatomic, strong, readwrite) id         assembledObject;
@property (nonatomic, strong, readwrite) id         pendingValue;
@property (nonatomic, strong, readwrite) NSString * pendingKey;
@property (nonatomic, strong, readwrite) NSString * pendingValueKey;

@end

@implementation MSJSONAssembler
{
    MSStack         * _activeObjects;
    MSStack         * _pendingKeys;
    BOOL              _splitKeyPaths;
    MSDictionary    * _commentIndex;
    id                _commentTarget;
}

+ (MSJSONAssembler *)assemblerWithOptions:(MSJSONFormatOptions)options
{
    MSJSONAssembler * assembler = [self new];
    assembler.options = options;
    return assembler;
}

- (id)init { if (self = [super init]) _splitKeyPaths = YES; return self; }

- (void)setOptions:(MSJSONFormatOptions)options
{
    _options = options;
    _splitKeyPaths = !((options & MSJSONFormatKeepKeyPaths) == MSJSONFormatKeepKeyPaths);
}

- (void)setPendingValue:(id)pendingValue
{
    _pendingValue = pendingValue;
    self.pendingValueKey = _pendingKey;
}

/*
- (void)setPendingKey:(NSString *)pendingKey
{
    _pendingKey = pendingKey;
}

- (void)setPendingValueKey:(NSString *)pendingValueKey
{
    _pendingValueKey = pendingValueKey;
}
*/

- (void)popKey { self.pendingKey = [_pendingKeys pop]; }

////////////////////////////////////////////////////////////////////////////////
#pragma mark Helpers
////////////////////////////////////////////////////////////////////////////////

- (void)processValue:(id)value ofType:(MSJSONAssemblerValueType)type
{
    switch (type)
    {
        case MSJSONAssemblerArrayValueType:
        {
            if (!_assembledObject) self.assembledObject = value;
            else if ([_pendingKeys isEmpty]) [self addObjectToActiveObject:value];
            else if (!_pendingValue) self.pendingValue = value;
            else assert(NO);
            [_activeObjects push:value];

            break;
        }

        case MSJSONAssemblerObjectValueType:
        {
            if (!_assembledObject) self.assembledObject = value;
            else if ([_pendingKeys isEmpty]) [self addObjectToActiveObject:value];
            else if (!_pendingValue) self.pendingValue = value;
            else
            {
                id activeObject = [_activeObjects peek];
                if (isDictionaryKind(activeObject) && _pendingKey)
                {
                    activeObject[_pendingKey] = value;
                    [self popKey];
                }
            }
            
            [_activeObjects push:value];
            break;
        }

        case MSJSONAssemblerBooleanValueType:
        case MSJSONAssemblerNullValueType:
        case MSJSONAssemblerNumberValueType:
        case MSJSONAssemblerStringValueType:
        default:
        {
            if ([_pendingKeys isEmpty])
                [self addObjectToActiveObject:value];

            else if (_pendingValue)
            {
                id pendingValueChild = value;
                
                while (   isMSDictionary(_pendingValue)
                       && _pendingKey
                       && [_pendingKeys peek] != _pendingValueKey)
                {
                    pendingValueChild = [MSDictionary dictionaryWithObject:pendingValueChild
                                                                    forKey:_pendingKey];
                    [self popKey];
                }
                [self addObjectToActiveObject:pendingValueChild];
            }
            else
            {
                self.pendingValue = value;
                [self resolveKeyPathsForPendingValue];
            }
            break;
        }
    }

    _commentTarget = value;
}

- (void)resolveKeyPathsForPendingValue
{
    assert(_pendingKey);

    if ([_pendingValue isKindOfClass:[NSMutableArray class]])
    {
        [(NSMutableArray *)_pendingValue mapped:
         ^id(id obj, NSUInteger idx)
         {
             return [MSDictionary dictionaryWithObject:obj forKey:_pendingKey];
         }];
        
        [self popKey];
    }

    while (![_pendingKeys isEmpty])
    {
        _pendingValue = [MSDictionary dictionaryWithObject:_pendingValue forKey:_pendingKey];
        [self popKey];
        assert(_pendingKey);
    }

    assert(_pendingKey);

    [self addObjectToActiveObject:_pendingValue];
    _pendingValue = nil;
}

- (void)addObjectToActiveObject:(id)object
{
    id activeObject = [_activeObjects peek];

    if (isMSDictionary(activeObject))
    {
        assert(_pendingKey);

        [activeObject setObject:object forKey:_pendingKey];
        [self popKey];
    }

    else if (isMutableArrayKind(activeObject))
             [activeObject addObject:object];

    else
        assert(NO);
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Matching top level object
////////////////////////////////////////////////////////////////////////////////

- (void)parser:(PKParser *)parser willStart:(PKAssembly *)assembly
{
    self.assembledObject = nil;
    _commentIndex        = [MSDictionary dictionary];
    _activeObjects       = [MSStack stack];
    _pendingKeys         = [MSStack stack];
    _pendingKey          = nil;
    _pendingValueKey     = nil;
    _commentTarget       = nil;
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Matching object keys and keypaths
////////////////////////////////////////////////////////////////////////////////


- (void)parser:(PKParser *)parser didMatchKeyPath:(PKAssembly *)assembly
{
    if (!_splitKeyPaths)
        self.pendingKey = ((PKToken *)[assembly MS_peek]).quotedStringValue;

    else
    {
        NSString * keyPath = ((PKToken *)[assembly MS_peek]).quotedStringValue;
        NSArray * keys = [keyPath componentsSeparatedByString:@"."];
        if ([keys count] && _pendingKey) [_pendingKeys push:_pendingKey];
        [_pendingKeys pushObjectsFromArray:keys];
        [self popKey];
    }

    assert(_pendingKey);
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark Matching comments
////////////////////////////////////////////////////////////////////////////////

- (void)parser:(PKParser *)parser didMatchComment:(PKAssembly *)assembly
{
    NSString * comment = ((PKToken *)[assembly pop]).stringValue;

    if (![comment hasPrefix:@" // "])
        comment = MSSingleLineComment(comment);

    if (_commentTarget) [_commentTarget setComment:comment];
}


////////////////////////////////////////////////////////////////////////////////
#pragma mark Matching string, number, and boolean terminals
////////////////////////////////////////////////////////////////////////////////

- (void)parser:(PKParser *)parser didMatchString:(PKAssembly *)assembly
{
    [self processValue:((PKToken *)[assembly MS_peek]).quotedStringValue
                ofType:MSJSONAssemblerStringValueType];
}

- (void)parser:(PKParser *)parser didMatchNumber:(PKAssembly *)assembly
{
    [self processValue:((PKToken *)[assembly MS_peek]).value ofType:MSJSONAssemblerNumberValueType];
}

- (void)parser:(PKParser *)parser didMatchNullLiteral:(PKAssembly *)assembly
{
    [self processValue:NullObject ofType:MSJSONAssemblerNullValueType];
}

- (void)parser:(PKParser *)parser didMatchTrueLiteral:(PKAssembly *)assembly
{
    [self processValue:@YES ofType:MSJSONAssemblerBooleanValueType];
}

- (void)parser:(PKParser *)parser didMatchFalseLiteral:(PKAssembly *)assembly
{
    [self processValue:@NO ofType:MSJSONAssemblerBooleanValueType];
}

////////////////////////////////////////////////////////////////////////////////
#pragma mark Matching punction terminals - {}[],:
////////////////////////////////////////////////////////////////////////////////

- (void)parser:(PKParser *)parser didMatchOpenCurly:(PKAssembly *)assembly
{
    [self processValue:[MSDictionary dictionary] ofType:MSJSONAssemblerObjectValueType];
}

- (void)parser:(PKParser *)parser didMatchCloseCurly:(PKAssembly *)assembly
{
    if (_pendingValue == [_activeObjects pop]) [self resolveKeyPathsForPendingValue];

}

- (void)parser:(PKParser *)parser didMatchOpenBracket:(PKAssembly *)assembly
{
    [self processValue:[@[] mutableCopy] ofType:MSJSONAssemblerArrayValueType];
}

- (void)parser:(PKParser *)parser didMatchCloseBracket:(PKAssembly *)assembly
{
    if (_pendingValue == [_activeObjects pop]) [self resolveKeyPathsForPendingValue];
}

@end
