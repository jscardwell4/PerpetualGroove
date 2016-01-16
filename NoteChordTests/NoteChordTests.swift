//
//  NoteChordTests.swift
//  NoteChordTests
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import XCTest
@testable import Groove

func AssertEqualElements<S1:SequenceType, S2:SequenceType
  where S1.Generator.Element:Equatable,
        S1.Generator.Element == S2.Generator.Element>(s1: S1, _ s2: S2, file: String = __FILE__, line: UInt = __LINE__)
{
  XCTAssert(s1.elementsEqual(s2), "the elements in \(s1) are not equal to the elements in \(s2)", file: file, line: line)
}

final class NoteChordTests: XCTestCase {

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
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Major)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Minor)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Augmented)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Diminished)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SuspendedFourth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.FlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SuspendedSecond)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Sixth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.AddTwo)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorSeventhFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorSeventhSharpFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Seventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSuspendedFourth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorAddTwo)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSixth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorMajorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSeventhFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.DiminishedSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.DiminishedMajorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Fifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SixthNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorSixthNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorSeventhSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorNinthFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorNinthSharpFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorNinthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorThirteenthFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MajorThirteenthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatFifthFlatNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatFifthSharpNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpFifthFlatNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpFifthSharpNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatNinthSharpNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhAddThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatNinthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpNinthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatNinthFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpNinthFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhSharpEleventhFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhFlatNinthSharpNinthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Ninth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.NinthFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.NinthSharpFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.NinthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.NinthFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.NinthSharpEleventhFlatThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Eleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.Thirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.ThirteenthFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.ThirteenthFlatNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.ThirteenthSharpNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.ThirteenthSharpEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.ThirteenthSuspendedFourth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSharpFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Sharp), .Four), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSixthNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSeventhAddFourth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSeventhAddEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorSeventhFlatFifthFlatNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorNinthMajorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorNinthFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorEleventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorThirteenth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.DiminishedSeventhAddNinth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.A), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorEleventhFlatFifth)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.G, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.MinorEleventhMajorSeventh)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.E, .Flat), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.B), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.D), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.F), .Five), duration: .Eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.Default(.C), Chord.ChordPattern(.SeventhAltered)), octave: .Four, duration: .Eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.C), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.E), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Default(.G), .Four), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.B, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Flat), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.D, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.F, .Sharp), .Five), duration: .Eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.Modified(.A, .Flat), .Six), duration: .Eighth, velocity: .𝑚𝑓)
                ])
  }

  func testStandardChordPattern() {
    XCTAssert(Chord.ChordPattern(.Major).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.Minor).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.Augmented).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.Diminished).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SuspendedFourth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.F),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.FlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SuspendedSecond).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.D),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.Sixth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.AddTwo).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.D),
        .Default(.E),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorSeventhFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Default(.B)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorSeventhSharpFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Default(.B)
      ]))
    XCTAssert(Chord.ChordPattern(.Seventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSuspendedFourth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.F),
        .Default(.G),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorAddTwo).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.D),
        .Modified(.E, .Flat),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSixth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorMajorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Default(.B)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSeventhFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.DiminishedSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.DiminishedMajorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Default(.B)
      ]))
    XCTAssert(Chord.ChordPattern(.Fifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.G)
      ]))
    XCTAssert(Chord.ChordPattern(.SixthNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.A),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorSixthNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.A),
        .Default(.B),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorSeventhSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorNinthFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Default(.B),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorNinthSharpFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Default(.B),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorNinthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B),
        .Default(.D),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B),
        .Default(.D),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorThirteenthFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Default(.B),
        .Default(.D),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.MajorThirteenthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Default(.B),
        .Default(.D),
        .Modified(.F, .Sharp),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatFifthFlatNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatFifthSharpNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpFifthFlatNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpFifthSharpNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatNinthSharpNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Modified(.D, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhAddThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatNinthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpNinthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatNinthFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpNinthFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhSharpEleventhFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.F, .Sharp),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhFlatNinthSharpNinthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Modified(.D, .Sharp),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.Ninth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.NinthFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.NinthSharpFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Sharp),
        .Modified(.B, .Flat),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.NinthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Modified(.F, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.NinthFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.NinthSharpEleventhFlatThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Modified(.F, .Sharp),
        .Modified(.A, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.Eleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.F)
      ]))
    XCTAssert(Chord.ChordPattern(.Thirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.ThirteenthFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.ThirteenthFlatNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.ThirteenthSharpNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Sharp),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.ThirteenthSharpEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Modified(.F, .Sharp),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.ThirteenthSuspendedFourth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.F),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSharpFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSixthNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Default(.A),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSeventhAddFourth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.F),
        .Default(.G),
        .Modified(.B, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSeventhAddEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.F)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorSeventhFlatFifthFlatNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorNinthMajorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Default(.B),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorNinthFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorEleventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.F)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorThirteenth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.F),
        .Default(.A)
      ]))
    XCTAssert(Chord.ChordPattern(.DiminishedSeventhAddNinth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Default(.A),
        .Default(.D)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorEleventhFlatFifth).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Modified(.G, .Flat),
        .Modified(.B, .Flat),
        .Default(.D),
        .Default(.F)
      ]))
    XCTAssert(Chord.ChordPattern(.MinorEleventhMajorSeventh).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Modified(.E, .Flat),
        .Default(.G),
        .Default(.B),
        .Default(.D),
        .Default(.F)
      ]))
    XCTAssert(Chord.ChordPattern(.SeventhAltered).notesWithRoot(.Default(.C)).elementsEqual([
        .Default(.C),
        .Default(.E),
        .Default(.G),
        .Modified(.B, .Flat),
        .Modified(.D, .Flat),
        .Modified(.D, .Sharp),
        .Modified(.F, .Sharp),
        .Modified(.A, .Flat)
      ]))
  }

}
