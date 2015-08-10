//
//  JSONIncludeDirective.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/17/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

internal class JSONIncludeDirective {
  let location: Range<String.UTF16Index>
  let file: IncludeFile!

  private let _parameters: String?
  var parameters: [String:String]? {
    if let p = _parameters {
      return Dictionary(",".split(p).map({disperse2("=".split($0))}))
    } else { return nil }
  }

  static func emptyCache() { cache = [:] }
  static var cacheSize: Int { return cache.count }
  private static var cache: [String:String] = [:]

  let subdirectives: [JSONIncludeDirective]

  init?(_ string: String.UTF16View, location loc: Range<String.UTF16Index>, directory: String) {
    location = loc
    let regex = ~/"<@include\\s+([^>]+\\.json)(?:,([^>]+))?>"
    let match = regex.firstMatch(String(string))

    assert(match?.captures.count == 3, "unexpected number of capture groups for regular expression")
    _parameters = match?.captures[2]?.string
    if let fileName = match?.captures[1]?.string, includeFile = IncludeFile("\(directory)/\(fileName)") {
      file = includeFile
      subdirectives = JSONIncludeDirective.parseDirectives(file.content.utf16, directory: directory)
    } else { file = nil; subdirectives = []; return nil }
  }

  static func stringByParsingDirectivesInString(string: String.UTF16View, directory: String) -> String {
    var result = ""
    var i = string.startIndex
    for directive in parseDirectives(string, directory: directory) {
      result += String(string[i..<directive.location.startIndex])
      result += directive.content
      i = directive.location.endIndex
    }
    if i < string.endIndex { result += String(string[i..<string.endIndex]) }
    return result
  }

  private static func parseDirectives(string: String.UTF16View, directory: String) -> [JSONIncludeDirective] {
    let regex = ~/"(<@include[^>]+>)"
    let matches = regex.match(String(string))
    let ranges = matches.flatMap { $0.captures[1]?.range }
    let directives = compressedMap(ranges, {JSONIncludeDirective(string[$0], location: $0, directory: directory)})
    return directives
  }

  var description: String {
    var result = "\n".join(
      "location: \(location)",
      "parameters: \(String(prettyNil: parameters))",
      "file: \((file.path as NSString).lastPathComponent)"
    )
    if subdirectives.count == 0 { result += "\nsubdirectives: []" }
    else { result += "\nsubdirectives: {\n" + "\n\n".join(subdirectives.map({$0.description})).indentedBy(4) + "\n}" }
    return result
  }

  var content: String {
    if let cachedContent = JSONIncludeDirective.cache["\(file.path),\(String(prettyNil: _parameters))"] {
      return cachedContent
    }
    var result: String = ""
    let fileContent = file.content.utf16
    if subdirectives.count == 0 { result = String(fileContent) }
    else {
      var i = fileContent.startIndex
      for subdirective in subdirectives.sort({$0.location.startIndex < $1.location.startIndex}) {
        result += String(fileContent[i..<subdirective.location.startIndex])
        result += subdirective.content
        i = subdirective.location.endIndex
      }
      if i < fileContent.endIndex { result += String(fileContent[i..<fileContent.endIndex]) }
    }
    if let p = parameters {
      result = p.reduce(result, combine: {$0.stringByReplacingOccurrencesOfString("<#\($1.0)#>", withString: $1.1)})
    }
    JSONIncludeDirective.cache["\(file.path),\(String(prettyNil: _parameters))"] = result
    return result
  }

  struct IncludeFile {

    let path: String
    let content: String
    private(set) lazy var parameters: Set<String> = {
      let regex = ~/"<#([A-Z]+)#>"
      let matches = regex.match(self.content)
      let strings = matches.flatMap { match in match.captures.flatMap { $0?.string } }
      return Set(strings)
      }()

    init?(_ p: String) {
      if let cached = IncludeFile.cache[p] { self = cached }
      else if NSFileManager.defaultManager().isReadableFileAtPath(p) {
        do {
        let c = try String(contentsOfFile: p, encoding: NSUTF8StringEncoding)
        path = p; content = c; IncludeFile.cache[p] = self
        } catch {
          path = ""; content = ""; return nil
        }
      } else { path = ""; content = ""; return nil }
    }

    private static var cache: [String:IncludeFile] = [:]
  }

}

