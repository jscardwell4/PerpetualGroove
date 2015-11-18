//
//  MidiClockGenerator.h
//  MoxxxClock
//
//  Created by Rob Keeris on 17/05/15.
//  Copyright (c) 2015 Connector. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreMIDI/CoreMIDI.h>

@interface MidiClockGenerator : NSObject

@property MIDIPortRef outPort;
@property MIDIEndpointRef destination;
@property (nonatomic, setter=setBPM:) float BPM;
@property (readonly) bool started;
@property int listSize;

- (id) initWithBPM:(float)BPM outPort:(MIDIPortRef) outPort destination:(MIDIEndpointRef) destination;
- (void) start;
- (void) stop;

@end