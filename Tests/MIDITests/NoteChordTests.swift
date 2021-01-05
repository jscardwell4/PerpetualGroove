//
//  NoteChordTests.swift
//  NoteChordTests
//
//  Created by Jason Cardwell on 11/22/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import XCTest
import MoonKit
import Nimble
@testable import Groove
@testable import MIDI

final class NoteChordTests: XCTestCase {

  func testNoteCreation() {
    expect(Note(rawValue: "A")) == Note.natural(.a)
    expect(Note(rawValue: "A♭")) == Note.accidental(.a, .flat)
    expect(Note(rawValue: "A♯")) == Note.accidental(.a, .sharp)
  }

//  func testFlattened() {
//    expect(Note.natural(.a).flattened()) == Note.accidental(.a, .flat)
//  }

//  func testSharpened() {
//    expect(Note.natural(.a).sharpened()) == Note.accidental(.a, .sharp)
//  }

  func testEquatable() {
    expect(Note.natural(.a)) == Note.natural(.a)
    expect(Note.natural(.a)) != Note.accidental(.a, .flat)
    expect(Note.natural(.b)) == Note.accidental(.c, .flat)
    expect(Note.natural(.f)) == Note.accidental(.e, .sharp)
  }

  func testComparable() {
    expect(Note.natural(.a)) < Note.natural(.b)
    expect(Note.natural(.a)) < Note.accidental(.a, .sharp)
    expect(Note.accidental(.a, .flat)) < Note.natural(.a)
    expect(Note.natural(.b)).toNot(beLessThan(Note.natural(.a)))
    expect(Note.accidental(.b, .sharp)).toNot(beLessThan(Note.natural(.c)))
    expect(Note.natural(.e)).toNot(beLessThan(Note.accidental(.f, .flat)))

  }

  func testChord() {
    expect(Chord.Pattern(.major).bass) == Chord.Pattern.Degree.default(.one)
    expect(Chord.Pattern(.major).components) == [Chord.Pattern.Degree.default(.three), Chord.Pattern.Degree.default(.five)]
    expect(Chord(root:.natural(.c), pattern: Chord.Pattern(.major)).notes) == [Note.natural(.c), Note.natural(.e), Note.natural(.g)]
    expect(Chord(root:.natural(.c), pattern: Chord.Pattern(.minor)).notes) == [Note.natural(.c), Note.accidental(.e, .flat), Note.natural(.g)]
    expect(Chord(rawValue: "C:(3,5)")) == Chord(root:.natural(.c), pattern: Chord.Pattern(.major))
    expect(Chord(rawValue: "C:(♭3,5)")) == Chord(root:.natural(.c), pattern: Chord.Pattern(.minor))
    expect(Chord()) == Chord()
  }

  func testChordGenerator() {
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.major)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minor)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.augmented)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.diminished)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.suspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.flatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.suspendedSecond)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.sixth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.addTwo)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.majorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.majorSeventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.majorSeventhSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.seventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.seventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.seventhSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.seventhSuspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minorAddTwo)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minorSixth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minorMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.minorSeventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.diminishedSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.diminishedMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.fifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root:.natural(.c), pattern: Chord.Pattern(.sixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorSixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorSeventhSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorNinthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorNinthSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorThirteenthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.majorThirteenthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatFifthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpFifthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatNinthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhAddThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatNinthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpNinthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhSharpEleventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhFlatNinthSharpNinthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninthSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninthFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.ninthSharpEleventhFlatThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.eleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenthSharpNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenthSharpEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.thirteenthSuspendedFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorSharpFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .sharp), .four), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorSixthNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorSeventhAddFourth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorSeventhAddEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorSeventhFlatFifthFlatNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorNinthMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorNinthFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorEleventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorThirteenth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.diminishedSeventhAddNinth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.a), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorEleventhFlatFifth)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.g, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.minorEleventhMajorSeventh)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.e, .flat), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.b), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.d), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.f), .five), duration: .eighth, velocity: .𝑚𝑓)
                ]
    expect(ChordGenerator(chord: Chord(root: Note.natural(.c), pattern: Chord.Pattern(.seventhAltered)), octave: .four, duration: .eighth, velocity: .𝑚𝑓).midiNotes) == [
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.c), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.e), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.natural(.g), .four), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.b, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .flat), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.d, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.f, .sharp), .five), duration: .eighth, velocity: .𝑚𝑓),
                  NoteGenerator(tone: NoteGenerator.Tone(.accidental(.a, .flat), .six), duration: .eighth, velocity: .𝑚𝑓)
                ]
  }

  func testStandardPattern() {
    expect(Chord.Pattern(.major).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.minor).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.augmented).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp)
      ]
    expect(Chord.Pattern(.diminished).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat)
      ]
    expect(Chord.Pattern(.suspendedFourth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.f),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.flatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat)
      ]
    expect(Chord.Pattern(.suspendedSecond).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.d),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.sixth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.addTwo).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.d),
        Note.natural(.e),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.majorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b)
      ]
    expect(Chord.Pattern(.majorSeventhFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.natural(.b)
      ]
    expect(Chord.Pattern(.majorSeventhSharpFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.natural(.b)
      ]
    expect(Chord.Pattern(.seventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.seventhFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.seventhSharpFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.seventhSuspendedFourth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.f),
        Note.natural(.g),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.minorAddTwo).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.d),
        Note.accidental(.e, .flat),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.minorSixth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.minorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.minorMajorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.natural(.b)
      ]
    expect(Chord.Pattern(.minorSeventhFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.diminishedSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.diminishedMajorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.natural(.b)
      ]
    expect(Chord.Pattern(.fifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.g)
      ]
    expect(Chord.Pattern(.sixthNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.a),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.majorSixthNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.a),
        Note.natural(.b),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.majorSeventhSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.majorNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.majorNinthFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.natural(.b),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.majorNinthSharpFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.natural(.b),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.majorNinthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.majorThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.majorThirteenthFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.natural(.b),
        Note.natural(.d),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.majorThirteenthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d),
        Note.accidental(.f, .sharp),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.seventhFlatNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat)
      ]
    expect(Chord.Pattern(.seventhSharpNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp)
      ]
    expect(Chord.Pattern(.seventhSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.seventhFlatFifthFlatNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat)
      ]
    expect(Chord.Pattern(.seventhFlatFifthSharpNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp)
      ]
    expect(Chord.Pattern(.seventhSharpFifthFlatNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat)
      ]
    expect(Chord.Pattern(.seventhSharpFifthSharpNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp)
      ]
    expect(Chord.Pattern(.seventhFlatNinthSharpNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.accidental(.d, .sharp)
      ]
    expect(Chord.Pattern(.seventhAddThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.seventhFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.seventhFlatNinthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.seventhSharpNinthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.seventhFlatNinthFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.seventhSharpNinthFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.seventhSharpEleventhFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.f, .sharp),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.seventhFlatNinthSharpNinthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.accidental(.d, .sharp),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.ninth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.ninthFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.ninthSharpFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .sharp),
        Note.accidental(.b, .flat),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.ninthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.accidental(.f, .sharp)
      ]
    expect(Chord.Pattern(.ninthFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.ninthSharpEleventhFlatThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.accidental(.f, .sharp),
        Note.accidental(.a, .flat)
      ]
    expect(Chord.Pattern(.eleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.f)
      ]
    expect(Chord.Pattern(.thirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.thirteenthFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.thirteenthFlatNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.thirteenthSharpNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .sharp),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.thirteenthSharpEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.accidental(.f, .sharp),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.thirteenthSuspendedFourth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.f),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.minorSharpFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .sharp)
      ]
    expect(Chord.Pattern(.minorSixthNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.natural(.a),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.minorSeventhAddFourth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.f),
        Note.natural(.g),
        Note.accidental(.b, .flat)
      ]
    expect(Chord.Pattern(.minorSeventhAddEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.f)
      ]
    expect(Chord.Pattern(.minorSeventhFlatFifthFlatNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat)
      ]
    expect(Chord.Pattern(.minorNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.minorNinthMajorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.minorNinthFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.minorEleventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.f)
      ]
    expect(Chord.Pattern(.minorThirteenth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.f),
        Note.natural(.a)
      ]
    expect(Chord.Pattern(.diminishedSeventhAddNinth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.natural(.a),
        Note.natural(.d)
      ]
    expect(Chord.Pattern(.minorEleventhFlatFifth).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.accidental(.g, .flat),
        Note.accidental(.b, .flat),
        Note.natural(.d),
        Note.natural(.f)
      ]
    expect(Chord.Pattern(.minorEleventhMajorSeventh).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.accidental(.e, .flat),
        Note.natural(.g),
        Note.natural(.b),
        Note.natural(.d),
        Note.natural(.f)
      ]
    expect(Chord.Pattern(.seventhAltered).notes(withRoot: Note.natural(.c))) == [
        Note.natural(.c),
        Note.natural(.e),
        Note.natural(.g),
        Note.accidental(.b, .flat),
        Note.accidental(.d, .flat),
        Note.accidental(.d, .sharp),
        Note.accidental(.f, .sharp),
        Note.accidental(.a, .flat)
      ]
  }

}
