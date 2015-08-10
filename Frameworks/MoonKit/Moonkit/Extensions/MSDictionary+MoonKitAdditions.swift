//
//  MSDictionary+MoonKitAdditions.swift
//  MSKit
//
//  Created by Jason Cardwell on 9/18/14.
//  Copyright (c) 2014 Jason Cardwell. All rights reserved.
//

import Foundation

extension MSKeyPath: SequenceType {
  public func generate() -> IndexingGenerator<[String]> {
    return (keys as! [String]!).generate()
  }
}

//extension MSDictionary: JSONExport {
//  public var JSONString: String { return JSONSerialization.JSONFromObject(JSONObject) ?? "" }
//  public var JSONObject: AnyObject { return self }
//}

//extension MSDictionary: DictionaryLiteralConvertible {
//
//  /**
//  init:AnyObject)...:
//
//  :param: elements (NSObject
//  :param: AnyObject)...
//  */
//  public convenience init(dictionaryLiteral elements: (NSObject, AnyObject)...) {
//    self.init()
//
//    for (key, value) in elements {
//      keys.append(key)
//      values.append(value)
//      dictionary[key] = value
//    }
//
//  }
//}

extension MSDictionary {

  /**
  initWithOrderedDictionary:AnyObject>:

  - parameter orderedDictionary: OrderedDictionary<NSObject
  - parameter AnyObject>:
  */
  public convenience init<K:Hashable, V:AnyObject where K:AnyObject>(_ orderedDictionary: OrderedDictionary<K,V>) {
    self.init(values: Array(orderedDictionary.values), forKeys: Array(orderedDictionary.keys))
  }
  
//  public convenience init(_ orderedDictionary: OrderedDictionary<String,AnyObject>) {
//    self.init(values: Array(orderedDictionary.values), forKeys: Array(orderedDictionary.keys))
//  }

  /** inflate */
  @objc public func inflate() {

    // First gather a list of keys to inflate
    let inflatableKeys = allKeys.filter {(key) in
      if let k = key as? String { if k.numberOfMatchesForRegEx("(?:\\w\\.)+\\w") > 0 { return true } }
      return false
    } as! [NSString] as! [String]

    // Enumerate the list inflating each key
    for key in inflatableKeys {

      let keypath = MSKeyPath(fromString:key)  // Create a keypath from the inflatable key
      let first = keypath.popFirst()!          // This will become our key
      let last = keypath.popLast()!            // This will become the deepest key in our value



      var value: AnyObject = self[key]!  // Get the value we are embedding

      // If our value is an array, we embed each value in the array and keep our value as an array
      if let valueArray = value as? [AnyObject] {

        value = NSArray(array: valueArray.map{(obj) in

          let dict = MSDictionary()  // Create a dictionary within which to embed our value
          var subdict = dict         // This will reference the dictionary to which our value entered

          // If there are stops along the way from first to last, recursively embed in dictionaries
          if !keypath.isEmpty {
            for subkey in keypath {
              subdict[subkey] = MSDictionary()
              let subsubdict = subdict[subkey] as! MSDictionary
              subdict = subsubdict
            }
          }

          subdict[last] = obj
          return dict

        })

      }

      // Otherwise we embed the value
      else {

        let dict = MSDictionary()  // Create a dictionary within which to embed our value
        var subdict = dict         // This will reference the dictionary to which our value entered

        // If there are stops along the way from first to last, recursively embed in dictionaries
        if !keypath.isEmpty {
          for subkey in keypath {
            subdict[subkey] = MSDictionary()
            let subsubdict = subdict[subkey] as! MSDictionary
            subdict = subsubdict
          }
        }

        subdict[last] = value
        value = dict

      }

      let keyIndex = indexForKey(key)                      // Get the key's index so we can respect the order of our entries
      removeObjectForKey(key)                              // Remove the compressed key-value entry
      insertObject(value, forKey:first, atIndex:keyIndex)  // Insert the inflated key-value entry

    }

  }

}
