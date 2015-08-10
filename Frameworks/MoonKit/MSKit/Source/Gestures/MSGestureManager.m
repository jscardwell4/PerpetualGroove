//
//  MSGestureManager.m
//  MSKit
//
//  Created by Jason Cardwell on 2/22/13.
//  Copyright (c) 2013 Moondeer Studios. All rights reserved.
//

#import "MSGestureManager.h"
#import "NSNull+MSKitAdditions.h"
#import "NSArray+MSKitAdditions.h"

@implementation MSGestureManager {
  NSMapTable * _gestureMap;
}

+ (instancetype)gestureManagerForGestures:(NSArray *)gestures {
  return [self gestureManagerWithGestures:gestures blocks:nil];
}

+ (instancetype)gestureManagerForGestures:(NSArray *)gestures blocks:(NSArray *)blocks {
  return [self gestureManagerWithGestures:gestures blocks:blocks];
}

+ (instancetype)gestureManagerWithGestures:(NSArray *)gestures blocks:(NSArray *)blocks {
  return [[self alloc] initWithGestures:gestures blocks:blocks];
}

- (id)init {
  if (self = [super init]) {
    _gestureMap = [NSMapTable weakToStrongObjectsMapTable];
  }

  return self;
}

- (instancetype)initWithGestures:(NSArray *)gestures blocks:(NSArray *)blocks {
  if ((self = [self init])) {
    [gestures enumerateObjectsUsingBlock:^(UIGestureRecognizer * obj, NSUInteger idx, BOOL * stop) {
      [self addGesture:obj withBlocks:blocks[idx]];
    }];
  }
  return self;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
  MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeBegin)];

  BOOL answer = (block ? block(gestureRecognizer, nil) : YES);

  return answer;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
  MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeReceiveTouch)];
  BOOL answer = (block ? block(gestureRecognizer, touch) : YES);
  return answer;
}

- (BOOL)                           gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
  shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeRecognizeSimultaneously)];
  BOOL answer = (block ? block(gestureRecognizer, otherGestureRecognizer) : NO);
  return answer;
}

- (BOOL)                  gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
  shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeBeRequiredToFail)];
  BOOL answer = (block ? block(gestureRecognizer, otherGestureRecognizer) : YES);
  return answer;
}

- (BOOL)                gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer
  shouldRequireFailureOfGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
  MSGestureManagerBlock block =
    [_gestureMap objectForKey:gestureRecognizer][@(MSGestureManagerResponseTypeRequireFailureOf)];
  BOOL answer = (block ? block(gestureRecognizer, otherGestureRecognizer) : YES);
  return answer;
}

- (void)addGesture:(UIGestureRecognizer *)gesture {
  [self addGesture:gesture withBlocks:nil];
}

- (void)addGesture:(UIGestureRecognizer *)gesture withBlocks:(NSDictionary *)blocks {
  NSMutableDictionary * responseBlocks = [@{} mutableCopy];

  if (blocks)
    [responseBlocks addEntriesFromDictionary:blocks];

  [_gestureMap setObject:responseBlocks forKey:gesture];
}

- (void)removeGesture:(UIGestureRecognizer *)gesture {
  [_gestureMap removeObjectForKey:gesture];
}

- (void)registerBlock:(MSGestureManagerBlock)block
          forResponse:(MSGestureManagerResponseType)response
           forGesture:(UIGestureRecognizer *)gesture {
  if (block)
    [[_gestureMap objectForKey:gesture] setObject:block forKey:@(response)];
  else
    [[_gestureMap objectForKey:gesture] removeObjectForKey:@(response)];
}

@end
