//: Playground - noun: a place where people can play

import UIKit

import CoreImage

print("\n".join(CIFilter.filterNamesInCategories(nil)))

let filter = CIFilter(name: "CIMotionBlur")
filter?.inputKeys
filter?.outputKeys
filter?.attributes

import Chameleon

//dsf34t
// QuietLight, Analagous, Dark, Copper, Flat
let colors1 = Chameleon.colorsForScheme(.Analogous, with: Chameleon.QuietLightColor.Dark(.Copper).color, flat: true, unique: true)
for color in colors1 { color }

// CSS, Complimentary, Light, Gray, NoFlat
let colors2 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.CSSColor.Light(.Gray).color, flat: false, unique: true)
for color in colors2 { color }

// CSS, Complimentary, Dark, OrangeRed, Flat
let colors3 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.CSSColor.Dark(.OrangeRed).color, flat: true, unique: true)
for color in colors3 { color }

// CSS, Complimentary, Dark, Tomato, NoFlat
let colors4 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.CSSColor.Dark(.Tomato).color, flat: false, unique: true)
for color in colors4 { color }

// CSS, Complimentary, Dark, RosyBrown, Flat
let colors5 = Chameleon.colorsForScheme(.Complementary, with: Chameleon.CSSColor.Dark(.RosyBrown).color, flat: true, unique: true)
for color in colors5 { color }


