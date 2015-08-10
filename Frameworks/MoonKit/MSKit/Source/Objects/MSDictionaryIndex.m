//
//  MSDictionaryIndex.m
//  MSKit
//
//  Created by Jason Cardwell on 10/3/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSDictionaryIndex.h"
#import "MSKitMacros.h"

@interface MSDictionaryIndex ()

@property (nonatomic, weak) MSDictionary * dictionary;

@end

@implementation MSDictionaryIndex
{
  NSMutableDictionary * _keyMap;
}

+ (MSDictionaryIndex *)dictionaryIndexForDictionary:(MSDictionary *)dictionary
                                            handler:(MSDictionaryIndexKeyMapHandler)handler {
  MSDictionaryIndex * index = [self new];
  index.dictionary = dictionary;
  index.handler    = handler;
  return index;
}

- (void)setDictionary:(MSDictionary *)dictionary {
  _dictionary = dictionary;

  if (_dictionary)
    [_dictionary addObserver:self
                  forKeyPath:NSStringFromSelector(@selector(allKeys))
                     options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld
                     context:NULL];
}

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context
{

  if(object == _dictionary && [keyPath isEqualToString:NSStringFromSelector(@selector(allKeys))] && _handler) {

    switch ([change[NSKeyValueChangeKindKey] unsignedIntegerValue]) {

      case NSKeyValueChangeInsertion: {

        id newValue = nil;

        for (NSString * key in change) {
          if (![key isEqualToString:@"kind"])
            newValue = change[key];
        }

        if (newValue) {

          NSArray * keyMap = _handler(_dictionary, newValue);

          if ([keyMap count] == 2) {

            self.keyMap[newValue] = keyMap[0];
            self[keyMap[0]]  = keyMap[1];

          }

        }

      } break;

      case NSKeyValueChangeRemoval: {

        id newValue = change[NSKeyValueChangeOldKey];
        id key = nil;
        if ([newValue isKindOfClass:[NSArray class]])
          key = ((NSArray *)newValue)[0];
        else if (newValue != NullObject)
          key = newValue;

        if (key) {

          assert(_keyMap[key]);

          [self removeObjectForKey:_keyMap[key]];
          [_keyMap removeObjectForKey:key];

        }

      } break;

      default:
        break;
    }

  }

}

- (NSMutableDictionary *)keyMap {
  if (!_keyMap) _keyMap = [@{} mutableCopy];

  return _keyMap;
}

- (void)dealloc {
  [_dictionary removeObserver:self forKeyPath:@"allKeys" context:NULL];
}

@end
