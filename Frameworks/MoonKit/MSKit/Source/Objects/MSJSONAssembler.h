//
//  MSJSONAssembler.h
//  MSKit
//
//  Created by Jason Cardwell on 10/20/13.
//  Copyright (c) 2013 Jason Cardwell. All rights reserved.
//
#import "MSJSONSerialization.h"

////////////////////////////////////////////////////////////////////////////////
#pragma mark - MSJSONAssembler
////////////////////////////////////////////////////////////////////////////////

@interface MSJSONAssembler : NSObject

+ (MSJSONAssembler *)assemblerWithOptions:(MSJSONFormatOptions)options;

@property (nonatomic, assign, readwrite) MSJSONFormatOptions options;
@property (nonatomic, strong, readonly ) id         assembledObject;

@end

