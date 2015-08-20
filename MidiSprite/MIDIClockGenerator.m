//
//  MidiClockGenerator.m
//  MoxxxClock
//
//  Created by Rob Keeris on 17/05/15.
//  Copyright (c) 2015 Connector. All rights reserved.
//    
#import "MidiClockGenerator.h"
#import <CoreMIDI/CoreMIDI.h>

@implementation MidiClockGenerator

dispatch_source_t timer;
uint64_t nTicks,bTicks,ticks_per_second;
MIDITimeStamp clockTimeStamp;

bool timerStarted;

dispatch_source_t CreateDispatchTimer(uint64_t interval,
                                      uint64_t leeway,
                                      dispatch_queue_t queue,
                                      dispatch_block_t block)
{
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER,
                                                     0, 0, queue);
    if (timer)
    {
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, interval, leeway);
        dispatch_source_set_event_handler(timer, block);
        dispatch_resume(timer);
    }
    return timer;
}

- (void) initTemo{
    nTicks = ticks_per_second / (_BPM * 24 / 60);  // number of ticks between clock's.
    nTicks = nTicks/100;  // round the nTicks to avoid 'jitter' in the sound
    nTicks = nTicks*100;
    bTicks = nTicks * _listSize;
}

- (void) setBPM:(float)BPM{
    _BPM = BPM;
    // calculate new values for nTicks and bTicks
    [self initTemo];
    // Set the interval of the timer to the new calculated bTicks
    if (timer)
        dispatch_source_set_timer(timer, DISPATCH_TIME_NOW, bTicks, 0);
}

- (void) startTimer{

    [self initTemo];
    clockTimeStamp = mach_absolute_time();

    // default queu is good enough on my iMac.
    dispatch_queue_t q = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    timer = CreateDispatchTimer(bTicks,
                                0,
                                q,
                                ^{

                                    // avoid to much blocks send in the future to avoid latency in tempo changes
                                    // just skip on block when the clockTimeStamp is ahead of the mach_absolute_time()
                                    MIDITimeStamp now = mach_absolute_time();
                                    if (clockTimeStamp > now && (clockTimeStamp - now)/(bTicks) > 0) return;

                                    // setup packetlist
                                    Byte clock = 0xF8;
                                    uint32 packetListSize = sizeof(uint32)+ (_listSize *sizeof(MIDIPacket));
                                    MIDIPacketList *packetList= malloc((uint32)packetListSize);
                                    MIDIPacket *packet = MIDIPacketListInit( packetList );

                                    // Set the time stamps
                                    for( int i = 0; i < _listSize; i++ )
                                    {
                                        packet = MIDIPacketListAdd( packetList, packetListSize, packet, clockTimeStamp, 1, &clock );
                                        clockTimeStamp+= nTicks;
                                    }

                                    MIDISend(_outPort, _destination, packetList );
                                    free(packetList);
                                });
    _started = true;
}


- (id) init{
    return [self initWithBPM:0 outPort:0 destination:0];
}

- (id) initWithBPM:(float)BPM outPort:(MIDIPortRef) outPort destination:(MIDIEndpointRef) destination{
    self = [super init];
    if (self) {

        _listSize = 4;  // nr of clock's send in each packetlist. Should be big enough to deal with instability of the timer
                        // higher values will slowdown responce to tempochanges
        _outPort = outPort;
        _destination = destination;
        _BPM = BPM;

        // find out how many machtime ticks are in one second
        mach_timebase_info_data_t mach_timebase_info_data_t;
        mach_timebase_info( &mach_timebase_info_data_t );  //denum and numer are always 1 on my system???
        ticks_per_second = mach_timebase_info_data_t.denom * NSEC_PER_SEC / mach_timebase_info_data_t.numer;

        [self start];
    }
    return self;
}


- (void) start{
    if (_BPM > 0 && _outPort && _destination){
        if (!timer) {
            [self startTimer];
        } else {
            if (!_started) {
                dispatch_resume(timer);
                _started = true;
            }
        }
    }
}

- (void) stop{
    if (_started && timer){
        dispatch_suspend(timer);
        _started = false;
    }
}

@end
