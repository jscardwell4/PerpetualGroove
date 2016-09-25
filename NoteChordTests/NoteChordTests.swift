//
//  NoteChordTests.swift
//  NoteChordTests
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import XCTest
import MoonKitTest
@testable import Groove

func AssertEqualElements<S1:Swift.Sequence, S2:Swift.Sequence>(_ s1: S1, _ s2: S2, file: StaticString = #file, line: UInt = #line)
  where S1.Iterator.Element:Equatable,
        S1.Iterator.Element == S2.Iterator.Element
{
  XCTAssert(s1.elementsEqual(s2), "the elements in \(s1) are not equal to the elements in \(s2)", file: file, line: line)
}

final class NoteChordTests: XCTestCase {

  func testNoteCreation() {
    XCTAssert(Note(rawValue: "A") == .default(.a))
    XCTAssert(Note(rawValue: "A♭") == .modified(.a, .flat))
    XCTAssert(Note(rawValue: "A♯") == .modified(.a, .sharp))
  }

  func testFlattened() {
    XCTAssert(Note.default(.a).flattened() == .modified(.a, .flat))
  }

  func testSharpened() {
    XCTAssert(Note.default(.a).sharpened() == .modified(.a, .sharp))
  }

  func testEquatable() {
    XCTAssert(Note.default(.a) == .default(.a))
    XCTAssertFalse(Note.default(.a) == .modified(.a, .flat))
    XCTAssert(Note.default(.b) == .modified(.c, .flat))
    XCTAssert(Note.default(.f) == .modified(.e, .sharp))
  }

  func testComparable() {
    XCTAssert(Note.default(.a) < .default(.b))
    XCTAssert(Note.default(.a) < .modified(.a, .sharp))
    XCTAssert(Note.modified(.a, .flat) < .default(.a))
    XCTAssertFalse(Note.default(.b) < .default(.a))
    XCTAssertFalse(Note.modified(.b, .sharp) < .default(.c))
    XCTAssertFalse(Note.default(.e) < .modified(.f, .flat))

  }

  func testChord() {
    XCTAssert(Chord.ChordPattern(.major).bass == .default(.one))
    XCTAssert(Chord.ChordPattern(.major).components.elementsEqual([.default(.three), .default(.five)]))
    XCTAssert(Chord(.default(.c), Chord.ChordPattern(.major)).notes.elementsEqual([.default(.c), .default(.e), .default(.g)]))
    XCTAssert(Chord(.default(.c), Chord.ChordPattern(.minor)).notes.elementsEqual([.default(.c), .modified(.e, .flat), .default(.g)]))
    XCTAssert(Chord(rawValue: "C:(3,5)") == Chord(.default(.c), Chord.ChordPattern(.major)))
    XCTAssert(Chord(rawValue: "C:(♭3,5)") == Chord(.default(.c), Chord.ChordPattern(.minor)))
    XCTAssert(Chord() == Chord())
  }

  func testChordGenerator() {
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.major)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minor)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.augmented)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.diminished)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.suspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.flatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.suspendedSecond)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.sixth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.addTwo)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorSeventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorSeventhSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSuspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorAddTwo)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSixth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSeventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.diminishedSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.diminishedMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.fifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.sixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorSixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorSeventhSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorNinthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorNinthSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorThirteenthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.majorThirteenthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatFifthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpFifthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatNinthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhAddThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatNinthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpNinthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhSharpEleventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhFlatNinthSharpNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninthSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.ninthSharpEleventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.eleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.thirteenthSuspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSeventhAddFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSeventhAddEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorSeventhFlatFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorNinthMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorNinthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.diminishedSeventhAddNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorEleventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.minorEleventhMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ])
    AssertEqualElements(ChordGenerator(chord: Chord(.default(.c), Chord.ChordPattern(.seventhAltered)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes, [
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.default(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.modified(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ])
  }

  func testStandardChordPattern() {
    XCTAssert(Chord.ChordPattern(.major).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.minor).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.augmented).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.diminished).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.suspendedFourth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.f),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.flatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.suspendedSecond).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.d),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.sixth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.addTwo).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.d),
        .default(.e),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.majorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b)
      ]))
    XCTAssert(Chord.ChordPattern(.majorSeventhFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .default(.b)
      ]))
    XCTAssert(Chord.ChordPattern(.majorSeventhSharpFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .default(.b)
      ]))
    XCTAssert(Chord.ChordPattern(.seventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSuspendedFourth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.f),
        .default(.g),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.minorAddTwo).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.d),
        .modified(.e, .flat),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSixth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.minorMajorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .default(.b)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSeventhFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.diminishedSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.diminishedMajorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .default(.b)
      ]))
    XCTAssert(Chord.ChordPattern(.fifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.g)
      ]))
    XCTAssert(Chord.ChordPattern(.sixthNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.a),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.majorSixthNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.a),
        .default(.b),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.majorSeventhSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.majorNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.majorNinthFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .default(.b),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.majorNinthSharpFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .default(.b),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.majorNinthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b),
        .default(.d),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.majorThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b),
        .default(.d),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.majorThirteenthFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .default(.b),
        .default(.d),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.majorThirteenthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .default(.b),
        .default(.d),
        .modified(.f, .sharp),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatFifthFlatNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .modified(.d, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatFifthSharpNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .modified(.d, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpFifthFlatNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .modified(.b, .flat),
        .modified(.d, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpFifthSharpNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .modified(.b, .flat),
        .modified(.d, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatNinthSharpNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .modified(.d, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhAddThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatNinthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpNinthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .sharp),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatNinthFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpNinthFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .sharp),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhSharpEleventhFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.f, .sharp),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhFlatNinthSharpNinthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .modified(.d, .sharp),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.ninth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.ninthFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.ninthSharpFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .sharp),
        .modified(.b, .flat),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.ninthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .modified(.f, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.ninthFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.ninthSharpEleventhFlatThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .modified(.f, .sharp),
        .modified(.a, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.eleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .default(.f)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenthFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .default(.d),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenthFlatNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenthSharpNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .sharp),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenthSharpEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .modified(.f, .sharp),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.thirteenthSuspendedFourth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.f),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSharpFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .sharp)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSixthNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .default(.a),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSeventhAddFourth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.f),
        .default(.g),
        .modified(.b, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSeventhAddEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .modified(.b, .flat),
        .default(.f)
      ]))
    XCTAssert(Chord.ChordPattern(.minorSeventhFlatFifthFlatNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .modified(.d, .flat)
      ]))
    XCTAssert(Chord.ChordPattern(.minorNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .modified(.b, .flat),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.minorNinthMajorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .default(.b),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.minorNinthFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.minorEleventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .default(.f)
      ]))
    XCTAssert(Chord.ChordPattern(.minorThirteenth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .modified(.b, .flat),
        .default(.d),
        .default(.f),
        .default(.a)
      ]))
    XCTAssert(Chord.ChordPattern(.diminishedSeventhAddNinth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .default(.a),
        .default(.d)
      ]))
    XCTAssert(Chord.ChordPattern(.minorEleventhFlatFifth).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .modified(.g, .flat),
        .modified(.b, .flat),
        .default(.d),
        .default(.f)
      ]))
    XCTAssert(Chord.ChordPattern(.minorEleventhMajorSeventh).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .modified(.e, .flat),
        .default(.g),
        .default(.b),
        .default(.d),
        .default(.f)
      ]))
    XCTAssert(Chord.ChordPattern(.seventhAltered).notesWithRoot(.default(.c)).elementsEqual([
        .default(.c),
        .default(.e),
        .default(.g),
        .modified(.b, .flat),
        .modified(.d, .flat),
        .modified(.d, .sharp),
        .modified(.f, .sharp),
        .modified(.a, .flat)
      ]))
  }

}
