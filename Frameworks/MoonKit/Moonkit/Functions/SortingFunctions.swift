//
//  SortingFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 5/14/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation

/**
sortedByName:

- parameter seq: S

- returns: [S.Generator.Element]
*/
@available(*, unavailable, message = "sortedByName() is unavailable, use the sort() method on the sequence")
public func sortedByName<S:SequenceType where S.Generator.Element:Nameable>(seq: S) -> [S.Generator.Element] {
  return Array(seq).sort {$0.0.name < $0.1.name}
}

/**
sortedByName:

- parameter seq: S?

- returns: [S.Generator.Element]?
*/
@available(*, unavailable, message = "sortedByName() is unavailable, use the sort() method on the sequence")
public func sortedByName<S:SequenceType where S.Generator.Element:Nameable>(seq: S?) -> [S.Generator.Element]? {
  if seq != nil {  return Array(seq!).sort {$0.0.name < $0.1.name} } else { return nil }
}

/**
sortByName:

- parameter array: [T]
*/
@available(*, unavailable, message = "sortedByName() is unavailable, use the sort() method on the sequence")
public func sortByName<T: Nameable>(inout array: [T]) { array.sortInPlace {$0.0.name < $0.1.name} }

/**
sortByName:

- parameter array: [T]?
*/
@available(*, unavailable, message = "sortByName() is unavailable, use the sort() method on the sequence")
public func sortByName<T: Nameable>(inout array: [T]?) { array?.sortInPlace {$0.0.name < $0.1.name} }

/**
sortedByName:

- parameter seq: S

- returns: [S.Generator.Element]
*/
@available(*, unavailable, message = "sortByName() is unavailable, use the sort() method on the sequence")
public func sortedByName<S:SequenceType where S.Generator.Element:Named>(seq: S) -> [S.Generator.Element] {
  return Array(seq).sort {$0.0.name < $0.1.name}
}

/**
sortedByName:

- parameter seq: S?

- returns: [S.Generator.Element]?
*/
@available(*, unavailable, message = "sortByName() is unavailable, use the sort() method on the sequence")
public func sortedByName<S:SequenceType where S.Generator.Element:Named>(seq: S?) -> [S.Generator.Element]? {
  if seq != nil {  return Array(seq!).sort {$0.0.name < $0.1.name} } else { return nil }
}

/**
sortByName:

- parameter array: [T]
*/
@available(*, unavailable, message = "sortByName() is unavailable, use the sort() method on the sequence")
public func sortByName<T: Named>(inout array: [T]) { array.sortInPlace {$0.0.name < $0.1.name} }

/**
sortByName:

- parameter array: [T]?
*/
@available(*, unavailable, message = "sortByName() is unavailable, use the sort() method on the sequence")
public func sortByName<T: Named>(inout array: [T]?) { array?.sortInPlace {$0.0.name < $0.1.name} }
