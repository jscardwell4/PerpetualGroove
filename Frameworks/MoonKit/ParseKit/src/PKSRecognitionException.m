//
//  PKSRecognitionException.m
//  ParseKit
//
//  Created by Todd Ditchendorf on 3/28/13.
//
//

#import "PKSRecognitionException.h"
@implementation PKSRecognitionException

- (void)dealloc {
    self.currentReason = nil;
    [super dealloc];
}


- (NSString *)reason {
    return self.currentReason;
}

@end
