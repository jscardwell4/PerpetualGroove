import UIKit
//import MoonKit

func hex(_ value: UInt8) -> String {
  String(value, radix: 16, uppercase: true) + "(\(value))"
}

func consume4CharacterCode(_ data: Data.SubSequence) -> (String, Data.SubSequence) {
  let code = String(unsafeUninitializedCapacity: 4) {
    _ = $0.initialize(from: data.prefix(4))
    return 4
  }
  let remainingData = data.dropFirst(4)
  return (code, remainingData)
}

func consumeSize(_ data: Data.SubSequence) -> (UInt32, Data.SubSequence) {
  let byte1 = UInt32(data[data.startIndex].byteSwapped)
  let byte2 = UInt32(data[data.startIndex + 1].byteSwapped)
  let byte3 = UInt32(data[data.startIndex + 2].byteSwapped)
  let byte4 = UInt32(data[data.startIndex + 3].byteSwapped)

  let size = byte4 << 24 | byte3 << 16 | byte2 << 8 | byte1

  let remainingData = data.dropFirst(4)
  return (size, remainingData)
}

let sf2File = "/Users/Moondeer/Projects/PerpetualGroove/SoundFont/SoundFont.playground/Resources/SPYRO's Pure Oscillators.sf2"
let sf2FileURL = URL(fileURLWithPath: sf2File)
let data = try Data(contentsOf: sf2FileURL)

var remainingData = data[data.startIndex...]
remainingData.count

var code: String = ""
(code, remainingData) = consume4CharacterCode(remainingData)
code
remainingData.count

hex(remainingData[remainingData.startIndex])
hex(remainingData[remainingData.startIndex + 1])
hex(remainingData[remainingData.startIndex + 2])
hex(remainingData[remainingData.startIndex + 3])
(0xE6_80_13_00 as UInt32).byteSwapped
0b1110_0110_1000_0000_0001_0011_0000_0000 as UInt32
0b0000_0000_1100_1000_0000_0001_0110_0111 as UInt32
var size: UInt32 = 0

(size, remainingData) = consumeSize(remainingData)
size
remainingData.count
//String(data[0..<1])

//String(data[0 ..< 4])
//String(data[8 ..< 16])

hex(data[16])
hex(data[17])
//Int(UInt32(data[16 ..< 18]).bigEndian)
