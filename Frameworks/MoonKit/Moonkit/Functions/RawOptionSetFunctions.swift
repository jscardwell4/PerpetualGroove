//
//  RawOptionSetFunctions.swift
//  MoonKit
//
//  Created by Jason Cardwell on 4/12/15.
//  Copyright (c) 2015 Jason Cardwell. All rights reserved.
//

import Foundation
import Swift

/**
setOption:s:

- parameter option: T The option
- parameter optionSet: T The option set
*/
//public func setOption<T:OptionSetType>(option: T, inout optionSet: T) { optionSet.insert(option) }

/**
unsetOption:optionSet:

- parameter option: T The option
- parameter optionSet: T The option set
*/
//public func unsetOption<T:OptionSetType>(option: T, inout optionSet: T) { optionSet.remove(option) }

/**
isOption:optionSet:

- parameter option: T The option
- parameter optionSet: T The option set

- returns: Bool
*/
//public func hasOption<T:OptionSetType>(option: T, optionSet: T) -> Bool { return optionSet.contains(option) }

/**
toggleOption:optionSet:

- parameter option: T The option
- parameter optionSet: T The option set
*/
//public func toggleOption<T:OptionSetType>(option: T, inout optionSet: T) {
//  if hasOption(option, optionSet: optionSet) { unsetOption(option, optionSet: &optionSet) } else { setOption(option, optionSet: &optionSet) }
//}


//public func ∪<T:OptionSetType>(lhs: T, rhs: T) -> T { return lhs.union(rhs) }
//public func ∪=<T:OptionSetType>(inout lhs: T, rhs: T) { lhs = lhs ∪ rhs }


//public func ∖<T:OptionSetType>(lhs: T, rhs: T) -> T { var result = lhs; unsetOption(lhs, rhs); return result }
//public func ∖=<T:OptionSetType>(inout lhs: T, rhs: T) { lhs = lhs ∖ rhs }
