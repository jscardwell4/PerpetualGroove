//
//  MSBitVector.m
//  MSKit
//
//  Created by Jason Cardwell on 10/23/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

#import "MSBitVector.h"
#import "NSString+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"

@implementation MSBitVector {
    MSBitVectorSize _size;
    union {
        uint64_t vector64;
        uint32_t vector32;
        uint16_t vector16;
        uint8_t  vector8;
    } _vector;
}

+ (MSBitVector *)bitVectorWithSize:(MSBitVectorSize)size value:(uint64_t)value {
    return [[MSBitVector alloc] initWithSize:size value:value];
}

+ (MSBitVector *)bitVectorWithSize:(MSBitVectorSize)size {
    return [[MSBitVector alloc] initWithSize:size];
}

+ (MSBitVector *)bitVectorWithBytes:(void *)bytes {
    return [[MSBitVector alloc] initWithBytes:bytes];
}

- (void)encodeWithCoder:(NSCoder *)coder {
    assert([coder isKindOfClass:[NSKeyedArchiver class]]);
    [coder encodeInt:_size forKey:@"size"];
    switch (_size) {
        case MSBitVectorSize64:
            [coder encodeInt64:_vector.vector64 forKey:@"vector"];
            break;
        case MSBitVectorSize32:
            [coder encodeInt32:_vector.vector32 forKey:@"vector"];
            break;
        case MSBitVectorSize16:
            [coder encodeInt:_vector.vector16 forKey:@"vector"];
            break;
        case MSBitVectorSize8:
            [coder encodeInt:_vector.vector8 forKey:@"vector"];
            break;
    }

}

- (id)initWithCoder:(NSCoder *)decoder {
        assert([decoder isKindOfClass:[NSKeyedUnarchiver class]]);
    if (self = [super init]) {
        _size = [decoder decodeIntForKey:@"size"];
        switch (_size) {
            case MSBitVectorSize64:
                _vector.vector64 = [decoder decodeInt64ForKey:@"vector"];
                break;
            case MSBitVectorSize32:
                _vector.vector32 = [decoder decodeInt32ForKey:@"vector"];
                break;
            case MSBitVectorSize16:
                _vector.vector16 = [decoder decodeIntForKey:@"vector"];
                break;
            case MSBitVectorSize8:
                _vector.vector8  = [decoder decodeIntForKey:@"vector"];
                break;
        }
    }
        return self;
}

- (id)initWithBytes:(void *)bytes {
    if (self = [super init]) {
        switch (sizeof(*bytes)) {
            case 8:
                _size = MSBitVectorSize64;
                _vector.vector64 = *(uint64_t *)bytes;
                break;
            case 4:
                _size = MSBitVectorSize32;
                _vector.vector32 = *(uint32_t *)bytes;
                break;
            case 2:
                _size = MSBitVectorSize16;
                _vector.vector16 = *(uint16_t *)bytes;
                break;
            default:
                _size = MSBitVectorSize8;
                _vector.vector8  = *(uint8_t *)bytes;
                break;
        }
    }
    return self;
}

- (id)initWithSize:(MSBitVectorSize)size value:(uint64_t)value {
    if (self = [super init]) {
        _size = size;
        switch (_size) {
            case MSBitVectorSize32:
                _vector.vector32 = (uint32_t)value;
            case MSBitVectorSize16:
                _vector.vector16 = (uint16_t)value;
            case MSBitVectorSize8:
                _vector.vector8  = (uint8_t)value;
            default:
                _vector.vector64 = value;
        }
    }
    return self;
}

- (id)initWithSize:(MSBitVectorSize)size {
    return [self initWithSize:size value:0ULL];
}

- (NSNumber *)bits {
    switch (_size) {
        case MSBitVectorSize32:
            return @(_vector.vector32);
        case MSBitVectorSize16:
            return @(_vector.vector16);
        case MSBitVectorSize8:
            return @(_vector.vector8);
        default:
            return @(_vector.vector64);
    }
}

- (void)setBits:(NSNumber *)bits {
    switch (_size) {
        case MSBitVectorSize32:
            _vector.vector32 = [bits unsignedIntValue];
            break;
        case MSBitVectorSize16:
            _vector.vector16 = [bits unsignedIntValue];
            break;
        case MSBitVectorSize8:
            _vector.vector8 = [bits unsignedShortValue];
            break;
        default:
            _vector.vector64 = [bits unsignedLongLongValue];
            break;
    }
}

- (void)setBitsFromArray:(NSArray *)bits {
    assert(bits.count <= _size);
    for (NSUInteger i = 0; i < bits.count; i++) {
        self[i] = bits[i];
    }
}

- (void)setBitsFromDictionary:(NSDictionary *)bits {
    assert(_bitKeys && [[_bitKeys set] intersectsSet:[[bits allKeys] set]]);
    [bits enumerateKeysAndObjectsUsingBlock:^(id key, NSNumber * obj, BOOL *stop) {
        self[key] = obj;
    }];
}

- (NSNumber *)objectAtIndexedSubscript:(NSUInteger)index {
    assert(index < _size);
    switch (_size) {
        case MSBitVectorSize32:
            return (_vector.vector32 & (1 << index)) ? @YES : nil; //@NO;
        case MSBitVectorSize16:
            return (_vector.vector16 & (1 << index)) ? @YES : nil; //@NO;
        case MSBitVectorSize8:
            return (_vector.vector8 & (1 << index)) ? @YES : nil; //@NO;
        default:
            return (_vector.vector64 & (1 << index)) ? @YES : nil; //@NO;
    }
}

- (void)setObject:(NSNumber *)object atIndexedSubscript:(NSUInteger)index {
    assert(index < _size);
    MSBit bit = [object boolValue];
    switch (_size) {
        case MSBitVectorSize32:
            _vector.vector32 = (bit ? _vector.vector32 | (1 << index) : _vector.vector32 & ~(1 << index));
            break;
        case MSBitVectorSize16:
            _vector.vector16 = (bit ? _vector.vector16 | (1 << index) : _vector.vector16 & ~(1 << index));
            break;
        case MSBitVectorSize8:
            _vector.vector8 = (bit ? _vector.vector8 | (1 << index) : _vector.vector8 & ~(1 << index));
            break;
        default:
            _vector.vector64 = (bit ? _vector.vector64 | (1 << index) : _vector.vector64 & ~(1 << index));
            break;
    }
}

- (NSNumber *)objectForKeyedSubscript:(id)key {
    if (!_bitKeys || ![_bitKeys containsObject:key]) return nil;

    NSUInteger index = [_bitKeys indexOfObject:key];
    return (index < _size ? self[index] : nil);
}

- (void)setObject:(NSNumber *)object forKeyedSubscript:(id<NSCopying>)key {
    if (!_bitKeys || ![_bitKeys containsObject:key]) return;

    NSUInteger index = [_bitKeys indexOfObject:key];
    if (index >= _size) return;

    self[index] = object;
}

- (NSString *)description {
    switch (_size) {
        case MSBitVectorSize32:
            return $(@"0x%2$.*1$X",16,_vector.vector32);
        case MSBitVectorSize16:
            return $(@"0x%2$.*1$hX",16,_vector.vector16);
        case MSBitVectorSize8:
            return $(@"0x%2$.*1$hhX",16,_vector.vector8);
        default:
            return $(@"0x%2$.*1$llX",16,_vector.vector64);
    }
}

- (NSString *)binaryDescription {
    return [self binaryDescriptionFromRange:NSMakeRange(0,_size)];
}

- (NSString *)binaryDescriptionFromRange:(NSRange)range {
    NSMutableString * binary = [@"" mutableCopy];
    switch (_size) {
        case MSBitVectorSize32: {
            uint32_t i = 1 << (31 - range.location);
            uint32_t iMin = i >> range.length;
            int c = range.location % 4 + 1;
            while (i && i > iMin) {
                [binary appendString:(_vector.vector32 & i) ? @"1" : @"0"];
                if (c++%4 == 0) [binary appendString:@" "];
                i >>= 1;
            }

        } break;

        case MSBitVectorSize16: {
            uint16_t i = 1 << (15 - range.location);
            uint16_t iMin = i >> range.length;
            int c = range.location % 4 + 1;
            while (i && i > iMin) {
                [binary appendString:(_vector.vector16 & i) ? @"1" : @"0"];
                if (c++%4 == 0) [binary appendString:@" "];
                i >>= 1;
            }
        } break;

        case MSBitVectorSize8: {
            uint8_t i = 1 << (7 - range.location);
            uint8_t iMin = i >> range.length;
            int c = range.location % 4 + 1;
            while (i && i > iMin) {
                [binary appendString:(_vector.vector8 & i) ? @"1" : @"0"];
                if (c++%4 == 0) [binary appendString:@" "];
                i >>= 1;
            }
        } break;

        default: {
            uint64_t i = (uint64_t)1 << (63 - range.location);
            uint64_t iMin = i >> range.length;
            int c = range.location % 4 + 1;
            while (i && i > iMin) {
                [binary appendString:(_vector.vector64 & i) ? @"1" : @"0"];
                if (c++%4 == 0) [binary appendString:@" "];
                i >>= 1;
            }
        } break;

    }

    return binary;
}

- (NSString *)binaryDescriptionFromIndex:(NSUInteger)index {
    return [self binaryDescriptionFromRange:NSMakeRange(index, _size - index)];
}

- (BOOL)isEqual:(MSBitVector *)object {
    return (self.bits == object.bits ? YES : NO);
}

@end
