//
//  NoteChordTests.swift
//  NoteChordTests
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import XCTest
@testable import Groove

class NoteChordTests: XCTestCase {

  override func setUp() {
    super.setUp()
    // Put setup code here. This method is called before the invocation of each test method in the class.
  }

  override func tearDown() {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    super.tearDown()
  }

  func testNoteCreation() {
    XCTAssert(Note(rawValue: "A") == .Default(.A))
    XCTAssert(Note(rawValue: "A♭") == .Modified(.A, .Flat))
    XCTAssert(Note(rawValue: "A♯") == .Modified(.A, .Sharp))
  }

  func testFlattened() {
    XCTAssert(Note.Default(.A).flattened() == .Modified(.A, .Flat))
  }

  func testSharpened() {
    XCTAssert(Note.Default(.A).sharpened() == .Modified(.A, .Sharp))
  }

  func testEquatable() {
    XCTAssert(Note.Default(.A) == .Default(.A))
    XCTAssertFalse(Note.Default(.A) == .Modified(.A, .Flat))
    XCTAssert(Note.Default(.B) == .Modified(.C, .Flat))
    XCTAssert(Note.Default(.F) == .Modified(.E, .Sharp))
  }

  func testComparable() {
    XCTAssert(Note.Default(.A) < .Default(.B))
    XCTAssert(Note.Default(.A) < .Modified(.A, .Sharp))
    XCTAssert(Note.Modified(.A, .Flat) < .Default(.A))
    XCTAssertFalse(Note.Default(.B) < .Default(.A))
    XCTAssertFalse(Note.Modified(.B, .Sharp) < .Default(.C))
    XCTAssertFalse(Note.Default(.E) < .Modified(.F, .Flat))

  }

  func testChord() {
    XCTAssert(Chord.ChordPattern(.Major).bass == .Default(.One))
    XCTAssert(Chord.ChordPattern(.Major).components.elementsEqual([.Default(.Three), .Default(.Five)]))
    XCTAssert(Chord(.Default(.C), Chord.ChordPattern(.Major)).notes.elementsEqual([.Default(.C), .Default(.E), .Default(.G)]))
    XCTAssert(Chord(.Default(.C), Chord.ChordPattern(.Minor)).notes.elementsEqual([.Default(.C), .Modified(.E, .Flat), .Default(.G)]))
    XCTAssert(Chord(rawValue: "C:(3,5)") == Chord(.Default(.C), Chord.ChordPattern(.Major)))
    XCTAssert(Chord(rawValue: "C:(♭3,5)") == Chord(.Default(.C), Chord.ChordPattern(.Minor)))
    XCTAssert(Chord() == Chord())
  }

  func testChordGenerator() {
    XCTAssert(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Major)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes
                .elementsEqual([
                  MIDINote(tone: MIDINote.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  MIDINote(tone: MIDINote.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  MIDINote(tone: MIDINote.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                  ]))
    XCTAssert(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Minor)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes
                .elementsEqual([
                  MIDINote(tone: MIDINote.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  MIDINote(tone: MIDINote.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  MIDINote(tone: MIDINote.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                  ]))
    XCTAssert(ChordGenerator() == ChordGenerator())
  }

  func testStandardChordPattern() {
    print("\n")
    for pattern in Chord.ChordPattern.StandardChordPattern.allCases {
      let chord = Chord(.Default(.C), Chord.ChordPattern(pattern))
      print("\(pattern):  \(chord.description)")
    }
    print("\n")
  }

/*
  func testPerformanceExample() {
    // This is an example of a performance test case.
    self.measureBlock {
      // Put the code you want to measure the time of here.
    }
  }
*/
  
}
