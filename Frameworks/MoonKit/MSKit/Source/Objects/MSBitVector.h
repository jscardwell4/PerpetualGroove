//
//  MSBitVector.h
//  MSKit
//
//  Created by Jason Cardwell on 10/23/12.
//  Copyright (c) 2012 Moondeer Studios. All rights reserved.
//

@import Foundation;

typedef NS_ENUM(BOOL, MSBit) {
    MSBit1 = YES,
    MSBit0 = NO
};

typedef NS_ENUM(uint8_t, MSBitVectorSize){
    MSBitVectorSize64 = 64,
    MSBitVectorSize32 = 32,
    MSBitVectorSize16 = 16,
    MSBitVectorSize8 = 8
};

@interface MSBitVector : NSObject <NSCoding>

+ (MSBitVector *)bitVectorWithSize:(MSBitVectorSize)size;
+ (MSBitVector *)bitVectorWithSize:(MSBitVectorSize)size value:(uint64_t)value;
+ (MSBitVector *)bitVectorWithBytes:(void *)bytes;
- (NSNumber *)objectAtIndexedSubscript:(NSUInteger)idx; // nil returned for bits set to 0
- (NSNumber *)objectForKeyedSubscript:(id)key; // nil returned for bits set to 0
- (void)setObject:(NSNumber *)object atIndexedSubscript:(NSUInteger)index;
- (void)setObject:(NSNumber *)object forKeyedSubscript:(id < NSCopying >)key;
- (void)setBitsFromArray:(NSArray *)bits;
- (void)setBitsFromDictionary:(NSDictionary *)bits;
- (NSString *)binaryDescriptionFromRange:(NSRange)range;
- (NSString *)binaryDescriptionFromIndex:(NSUInteger)idx;
- (NSString *)binaryDescription;

@property (nonatomic, weak)     NSNumber        * bits;
@property (nonatomic, strong)   NSArray         * bitKeys;
@property (nonatomic, readonly) MSBitVectorSize   size;

@end

#define BitVector8  [MSBitVector bitVectorWithSize:MSBitVectorSize8]
#define BitVector16 [MSBitVector bitVectorWithSize:MSBitVectorSize16]
#define BitVector32 [MSBitVector bitVectorWithSize:MSBitVectorSize32]
#define BitVector64 [MSBitVector bitVectorWithSize:MSBitVectorSize64]
