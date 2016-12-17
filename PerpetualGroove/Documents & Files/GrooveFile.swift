//
//  GrooveFile.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 12/30/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Struct that holds data for a 'Groove' sequence.
struct GrooveFile {

  var source: URL?

  var tracks: [Track] = []

  var tempoChanges = ObjectJSONValue([BarBeatTime.zero.rawValue: 120.0.jsonValue])

  var endOfFile: BarBeatTime = BarBeatTime.zero

  init(sequence: Sequence, source: URL?) {

    self.source = source

    tracks = sequence.instrumentTracks.map(Track.init)

    for event in sequence.tempoTrack.tempoEvents {
      switch event.data {
        case .tempo(let bpm): tempoChanges[event.time.rawValue] = bpm.jsonValue
        default: continue
      }
    }
    endOfFile = sequence.sequenceEnd
  }

}

extension GrooveFile: SequenceDataProvider {

  var storedData: Sequence.Data { return .groove(self) }

}

extension GrooveFile: DataConvertible {

  var data: Data { return jsonValue.prettyData }

  init?(data: Data) { self.init(JSONValue(data: data)) }

}

extension GrooveFile: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return [
      "source": source?.absoluteString,
      "tracks": tracks,
      "tempoChanges": tempoChanges,
      "endOfFile": endOfFile
    ]
  }

  init?(_ jsonValue: JSONValue?) {
    guard
      let dict = ObjectJSONValue(jsonValue),
      let tracks = ArrayJSONValue(dict["tracks"]),
      let tempoChanges = ObjectJSONValue(dict["tempoChanges"]),
      let endOfFile = BarBeatTime(dict["endOfFile"])
      else
    {
      return nil
    }

    self.tracks = tracks.flatMap({Track($0)})
    self.tempoChanges = tempoChanges
    self.endOfFile = endOfFile

    guard let sourceString = String(dict["source"]) else { return }

    source = URL(string: sourceString)
  }

}

extension GrooveFile: CustomStringConvertible {

  var description: String { return jsonValue.prettyRawValue }

}

extension GrooveFile {

  struct Track {

    var instrument: ObjectJSONValue
    var name: String
    var color: TrackColor

    var nodes: [Node.Identifier:Node] = [:]

    var loops: [UUID:Loop] = [:]

    init(track: InstrumentTrack) {

      name = track.name
      instrument = ObjectJSONValue(track.instrument.preset.jsonValue)!
      color = track.color

      var loops: [UUID:Loop] = [:]

      for event in track.eventContainer {

        switch event {

          case .meta(let event):

            switch event.data {

              case .marker(let text):

                switch text {
                  case ~/"^start.*":
                    guard let loop = Loop(event: event) else { continue }

                    loops[loop.identifier] = loop

                  case ~/"^end.*":
                    guard let id = UUID(uuidString: (text ~=> ~/"^end\\(([^)]+)\\)$")?.1 ?? "") else {
                      continue
                    }

                    loops[id]?.end = event.time

                  default:
                    continue

                }

              default:
                continue

            }

          case .node(let event):

            switch event.data {

              case .add:
                guard let node = Node(event: event) else { continue }

                if let loopIdentifier = event.loopIdentifier {

                  loops[loopIdentifier]?.nodes[event.identifier] = node

                } else {

                  nodes[event.identifier] = node

                }

              case .remove:
                if let loopIdentifier = event.loopIdentifier {

                  loops[loopIdentifier]?.nodes[event.identifier]?.removeTime = event.time

                } else {

                  nodes[event.identifier]?.removeTime = event.time

                }

            }

          default:
            continue

        }

      }

    }

  }


}

extension GrooveFile.Track: CustomStringConvertible {

  var description: String { return jsonValue.prettyRawValue }

}

extension GrooveFile.Track: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return [
      "name": name,
      "color": color,
      "instrument": instrument,
      "nodes": Array(nodes.values)
    ]
  }

  init?(_ jsonValue: JSONValue?) {
    guard
      let dict = ObjectJSONValue(jsonValue),
      let name = String(dict["name"]),
      let color = TrackColor(dict["color"]),
      let instrument = ObjectJSONValue(dict["instrument"]),
      let nodes = ArrayJSONValue(dict["nodes"])
      else
    {
      return nil
    }

    self.name = name
    self.instrument = instrument
    self.color = color

    self.nodes = Dictionary(nodes.flatMap {
      guard let node = GrooveFile.Node($0) else { return nil }
      return (key: node.identifier, value: node)
    })
  }

}

extension GrooveFile {

  struct Loop {

    var identifier: UUID
    var repetitions: Int
    var repeatDelay: UInt64
    var start: BarBeatTime
    var nodes: [Node.Identifier:Node] = [:]
    var end: BarBeatTime

    init(identifier: UUID, repetitions: Int, repeatDelay: UInt64, start: BarBeatTime, end: BarBeatTime) {
      self.identifier = identifier
      self.repetitions = repetitions
      self.repeatDelay = repeatDelay
      self.start = start
      self.end = end
    }

    init?(event: MIDIEvent.MetaEvent) {
      guard
        case .marker(let text) = event.data,
        let captures = (text ~=> ~/"^start\\(([^)]+)\\):([0-9]+):([0-9]+)$"),
        let identifier = UUID(uuidString: captures.1 ?? ""),
        let repetitions = Int(captures.2 ?? ""),
        let repeatDelay = UInt64(captures.3 ?? "")
        else
      {
        return nil
      }

      self.init(identifier: identifier,
                repetitions: repetitions,
                repeatDelay: repeatDelay,
                start: event.time,
                end: event.time)

    }
    
  }

}

extension GrooveFile {

  struct Node {

    typealias Identifier = MIDIEvent.MIDINodeEvent.Identifier
    let identifier: Identifier
    var trajectory: MIDINode.Trajectory
    var generator: AnyMIDIGenerator
    var addTime: BarBeatTime
    var removeTime: BarBeatTime? {
      didSet { if let time = removeTime , time < addTime { removeTime = nil } }
    }

    var addEvent: MIDIEvent.MIDINodeEvent {
      return MIDIEvent.MIDINodeEvent(data: .add(identifier: identifier, trajectory: trajectory, generator: generator),
                                     time: addTime)
    }

    var removeEvent: MIDIEvent.MIDINodeEvent? {
      guard let removeTime = removeTime else { return nil }
      return MIDIEvent.MIDINodeEvent(data: .remove(identifier: identifier), time: removeTime)
    }

    init?(event: MIDIEvent.MIDINodeEvent) {
      guard case let .add(identifier, trajectory, generator) = event.data else { return nil }
      addTime = event.time
      self.identifier = identifier
      self.trajectory = trajectory
      self.generator = generator
    }

  }

}

extension GrooveFile.Node: LosslessJSONValueConvertible {

  var jsonValue: JSONValue {
    return [
      "identifier": identifier,
      "generator": generator,
      "trajectory": trajectory,
      "addTime": addTime,
      "removeTime": removeTime
    ]
  }

  init?(_ jsonValue: JSONValue?) {
    guard
      let dict = ObjectJSONValue(jsonValue),
      let identifier = Identifier(dict["identifier"]),
      let trajectory = MIDINode.Trajectory(dict["trajectory"]),
      let generator = AnyMIDIGenerator(dict["generator"]),
      let addTime = BarBeatTime(dict["addTime"])
      else
    {
      return nil
    }

    self.identifier = identifier
    self.generator = generator
    self.trajectory = trajectory
    self.addTime = addTime

    switch dict["removeTime"] {

      case .string(let s)?:
        removeTime = BarBeatTime(rawValue: s)

      case .null?:
        fallthrough

      default:
        removeTime = nil

    }

  }

}
