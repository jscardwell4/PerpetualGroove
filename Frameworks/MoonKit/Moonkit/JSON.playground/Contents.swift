//: Playground - noun: a place where people can play
import UIKit
import MoonKit
import XCPlayground
let presetFilePath = NSBundle.mainBundle().pathForResource("Preset", ofType: "json")!
var presetUnprocessedJSON = try! String(contentsOfFile: presetFilePath, encoding: NSUTF8StringEncoding)
//println(presetUnprocessedJSON)



class IncludeDirective {
  let location: Range<Int>
  let file: IncludeFile!
  private let _parameters: String?
  var parameters: [String:String]? {
    if let p = _parameters {
      let kvArray = ",".split(p)
      var d: [String:String] = [:]
      for kvString in kvArray {
        let kv = "=".split(kvString)
        if kv.count == 2 {
          d[kv[0]] = kv[1]
        }
      }
      return d
    } else { return nil }
  }

  let subdirectives: [IncludeDirective]

  init?(_ string: String, location loc: Range<Int>, directory: String) {
    location = loc
    let captures = string.matchFirst("<@include\\s+([^>]+\\.json)(?:,([^>]+))?>")
    assert(captures.count == 2, "unexpected number of capture groups for regular expression")
    _parameters = captures[1]
    if let fileName = captures[0], includeFile = IncludeFile("\(directory)/\(fileName)") {
      file = includeFile
      subdirectives = IncludeDirective.parseDirectives(file.content, directory: directory)
    } else { file = nil; subdirectives = []; return nil }
  }

  static func stringByParsingDirectivesInString(string: String, directory: String) -> String {
    var result = ""
    var i = 0
    for directive in parseDirectives(string, directory: directory) {
      result += string[i..<directive.location.startIndex]
      result += directive.content
      i = directive.location.endIndex
    }
    if i < string.length { result += string[i..<string.length] }
    return result
  }

  static func parseDirectives(string: String, directory: String) -> [IncludeDirective] {
    return compressedMap(compressed(string.rangesForCapture(1, byMatching: ~/"(<@include[^>]+>)")),
                         {IncludeDirective(string[$0], location: $0, directory: directory)})
  }

  var description: String {
    var result = "\n".join(
      "location: \(location)",
      "parameters: \(String(parameters))",
      "file: \(file.path.lastPathComponent)"
      )
    if subdirectives.count == 0 { result += "\nsubdirectives: []" }
    else { result += "\nsubdirectives: {\n" + "\n\n".join(subdirectives.map({$0.description})).indentedBy(4) + "\n}" }
    return result
  }

  private var _content: String?

  var content: String {
    if let content = _content { return content }
    var result: String = ""
    var fileContent = file.content
    if subdirectives.count == 0 { result = fileContent }
    else {
      var i = 0
      for subdirective in subdirectives.sort({$0.location.startIndex < $1.location.startIndex}) {
        result += fileContent[i..<subdirective.location.startIndex]
        result += subdirective.content
        i = subdirective.location.endIndex
      }
      if i < fileContent.length { result += fileContent[i..<fileContent.length] }
    }
    if let p = parameters {
      result = p.reduce(result, combine: {$0.stringByReplacingOccurrencesOfString("<#\($1.0)#>", withString: $1.1)})
    }
    self._content = result
    return result
  }

  var allLocations: [(Range<Int>, IncludeDirective)] {
    return [(location,self)] + subdirectives.flatMap({$0.allLocations})
  }
}

struct IncludeFile {

  let path: String
  let content: String
  private(set) lazy var parameters: Set<String> = {
    return Set(flattened(self.content.matchAll(~/"<#([A-Z]+)#>").map({compressed($0)})))
    }()

  init?(_ p: String) {
    if let cached = IncludeFile.cache[p] { self = cached }
    else if NSFileManager.defaultManager().isReadableFileAtPath(p),
      let c = String(contentsOfFile: p, encoding: NSUTF8StringEncoding)
    {
      path = p; content = c; IncludeFile.cache[p] = self
    } else { path = ""; content = ""; return nil }
  }

  static var cache: [String:IncludeFile] = [:]
}

let directory = presetFilePath.stringByDeletingLastPathComponent
print(IncludeDirective.stringByParsingDirectivesInString(presetUnprocessedJSON, directory: directory))
