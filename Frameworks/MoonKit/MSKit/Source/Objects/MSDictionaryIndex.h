//
//  MSDictionaryIndex.h
//  MSKit
//
//  Created by Jason Cardwell on 10/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//
@import Foundation;
#import "MSDictionary.h"

// should return array of two items: @[key, value]
typedef NSArray *(^MSDictionaryIndexKeyMapHandler)(MSDictionary * dictionary, id key);

@interface MSDictionaryIndex : MSDictionary

@property (nonatomic, strong) MSDictionaryIndexKeyMapHandler handler;

+ (MSDictionaryIndex *)dictionaryIndexForDictionary:(MSDictionary *)dictionary
                                            handler:(MSDictionaryIndexKeyMapHandler)handler;

@end
