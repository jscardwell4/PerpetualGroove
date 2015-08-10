//: Playground - noun: a place where people can play

import UIKit
import Chameleon
import XCPlayground

let bankColor1 = rgb(59, 60, 64)

bankColor1.flatColor

let lilyWhite = UIColor(red: 0.92, green: 0.92, blue: 0.92, alpha: 1)
XCPCaptureValue("lilyWhite", value: lilyWhite)
XCPCaptureValue("lilyWhiteFlat", value: lilyWhite.flatColor)
let lilyWhiteLAB = lilyWhite.LAB
let lilyWhiteDarkLAB = (lilyWhiteLAB.l - 10, lilyWhiteLAB.a, lilyWhiteLAB.b)
let lilyWhiteDarkRGB = labToRGB(lilyWhiteDarkLAB.0, lilyWhiteDarkLAB.1, lilyWhiteDarkLAB.2)
let lilyWhiteDark = rgb(Int(lilyWhiteDarkRGB.r * 255), Int(lilyWhiteDarkRGB.g * 255), Int(lilyWhiteDarkRGB.b * 255))
XCPCaptureValue("lilyWhiteDark", value: lilyWhiteDark)
XCPCaptureValue("lilyWhiteDarkFlat", value: lilyWhiteDark.flatColor)
let charcoal = UIColor(red: 0.26, green: 0.26, blue: 0.26, alpha: 1)
XCPCaptureValue("charcoal", value: charcoal)
XCPCaptureValue("charcoalFlat", value: charcoal.flatColor)
let charcoalLAB = charcoal.LAB
let charcoalDarkLAB = (charcoalLAB.l - 10, charcoalLAB.a, charcoalLAB.b)
let charcoalDarkRGB = labToRGB(charcoalDarkLAB.0, charcoalDarkLAB.1, charcoalDarkLAB.2)
let charcoalDark = rgb(Int(charcoalDarkRGB.r * 255), Int(charcoalDarkRGB.g * 255), Int(charcoalDarkRGB.b * 255))
XCPCaptureValue("charcoalDark", value: charcoalDark)
XCPCaptureValue("charcoalDarkFlat", value: charcoalDark.flatColor)
let gray = UIColor(red: 0.56, green: 0.56, blue: 0.56, alpha: 1)
XCPCaptureValue("gray", value: gray)
XCPCaptureValue("grayFlat", value: gray.flatColor)
let grayLAB = gray.LAB
let grayDarkLAB = (grayLAB.l - 10, grayLAB.a, grayLAB.b)
let grayDarkRGB = labToRGB(grayDarkLAB.0, grayDarkLAB.1, grayDarkLAB.2)
let grayDark = rgb(Int(grayDarkRGB.r * 255), Int(grayDarkRGB.g * 255), Int(grayDarkRGB.b * 255))
XCPCaptureValue("grayDark", value: grayDark)
XCPCaptureValue("grayDarkFlat", value: grayDark.flatColor)
let loblolly = UIColor(red: 0.73, green: 0.73, blue: 0.73, alpha: 1)
XCPCaptureValue("loblolly", value: loblolly)
XCPCaptureValue("loblollyFlat", value: loblolly.flatColor)
let loblollyLAB = loblolly.LAB
let loblollyDarkLAB = (loblollyLAB.l - 10, loblollyLAB.a, loblollyLAB.b)
let loblollyDarkRGB = labToRGB(loblollyDarkLAB.0, loblollyDarkLAB.1, loblollyDarkLAB.2)
let loblollyDark = rgb(Int(loblollyDarkRGB.r * 255), Int(loblollyDarkRGB.g * 255), Int(loblollyDarkRGB.b * 255))
XCPCaptureValue("loblollyDark", value: loblollyDark)
XCPCaptureValue("loblollyDarkFlat", value: loblollyDark.flatColor)
let apple = UIColor(red: 0.33, green: 0.6, blue: 0.23, alpha: 1)
XCPCaptureValue("apple", value: apple)
XCPCaptureValue("appleFlat", value: apple.flatColor)
let appleLAB = apple.LAB
let appleDarkLAB = (appleLAB.l - 10, appleLAB.a, appleLAB.b)
let appleDarkRGB = labToRGB(appleDarkLAB.0, appleDarkLAB.1, appleDarkLAB.2)
let appleDark = rgb(Int(appleDarkRGB.r * 255), Int(appleDarkRGB.g * 255), Int(appleDarkRGB.b * 255))
XCPCaptureValue("appleDark", value: appleDark)
XCPCaptureValue("appleDarkFlat", value: appleDark.flatColor)
let copper = UIColor(red: 0.73, green: 0.47, blue: 0.22, alpha: 1)
XCPCaptureValue("copper", value: copper)
XCPCaptureValue("copperFlat", value: copper.flatColor)
let copperLAB = copper.LAB
let copperDarkLAB = (copperLAB.l - 10, copperLAB.a, copperLAB.b)
let copperDarkRGB = labToRGB(copperDarkLAB.0, copperDarkLAB.1, copperDarkLAB.2)
let copperDark = rgb(Int(copperDarkRGB.r * 255), Int(copperDarkRGB.g * 255), Int(copperDarkRGB.b * 255))
XCPCaptureValue("copperDark", value: copperDark)
XCPCaptureValue("copperDarkFlat", value: copperDark.flatColor)
let danube = UIColor(red: 0.37, green: 0.6, blue: 0.83, alpha: 1)
XCPCaptureValue("danube", value: danube)
XCPCaptureValue("danubeFlat", value: danube.flatColor)
let danubeLAB = danube.LAB
let danubeDarkLAB = (danubeLAB.l - 10, danubeLAB.a, danubeLAB.b)
let danubeDarkRGB = labToRGB(danubeDarkLAB.0, danubeDarkLAB.1, danubeDarkLAB.2)
let danubeDark = rgb(Int(danubeDarkRGB.r * 255), Int(danubeDarkRGB.g * 255), Int(danubeDarkRGB.b * 255))
XCPCaptureValue("danubeDark", value: danubeDark)
XCPCaptureValue("danubeDarkFlat", value: danubeDark.flatColor)
let paleCerulean = UIColor(red: 0.64, green: 0.76, blue: 0.9, alpha: 1)
XCPCaptureValue("paleCerulean", value: paleCerulean)
XCPCaptureValue("paleCeruleanFlat", value: paleCerulean.flatColor)
let paleCeruleanLAB = paleCerulean.LAB
let paleCeruleanDarkLAB = (paleCeruleanLAB.l - 10, paleCeruleanLAB.a, paleCeruleanLAB.b)
let paleCeruleanDarkRGB = labToRGB(paleCeruleanDarkLAB.0, paleCeruleanDarkLAB.1, paleCeruleanDarkLAB.2)
let paleCeruleanDark = rgb(Int(paleCeruleanDarkRGB.r * 255), Int(paleCeruleanDarkRGB.g * 255), Int(paleCeruleanDarkRGB.b * 255))
XCPCaptureValue("paleCeruleanDark", value: paleCeruleanDark)
XCPCaptureValue("paleCeruleanDarkFlat", value: paleCeruleanDark.flatColor)
let crayonPurple = UIColor(red: 0.55, green: 0.35, blue: 0.67, alpha: 1)
XCPCaptureValue("crayonPurple", value: crayonPurple)
XCPCaptureValue("crayonPurpleFlat", value: crayonPurple.flatColor)
let crayonPurpleLAB = crayonPurple.LAB
let crayonPurpleDarkLAB = (crayonPurpleLAB.l - 10, crayonPurpleLAB.a, crayonPurpleLAB.b)
let crayonPurpleDarkRGB = labToRGB(crayonPurpleDarkLAB.0, crayonPurpleDarkLAB.1, crayonPurpleDarkLAB.2)
let crayonPurpleDark = rgb(Int(crayonPurpleDarkRGB.r * 255), Int(crayonPurpleDarkRGB.g * 255), Int(crayonPurpleDarkRGB.b * 255))
XCPCaptureValue("crayonPurpleDark", value: crayonPurpleDark)
XCPCaptureValue("crayonPurpleDarkFlat", value: crayonPurpleDark.flatColor)
let deepChestnut = UIColor(red: 0.72, green: 0.3, blue: 0.26, alpha: 1)
XCPCaptureValue("deepChestnut", value: deepChestnut)
XCPCaptureValue("deepChestnutFlat", value: deepChestnut.flatColor)
let deepChestnutLAB = deepChestnut.LAB
let deepChestnutDarkLAB = (deepChestnutLAB.l - 10, deepChestnutLAB.a, deepChestnutLAB.b)
let deepChestnutDarkRGB = labToRGB(deepChestnutDarkLAB.0, deepChestnutDarkLAB.1, deepChestnutDarkLAB.2)
let deepChestnutDark = rgb(Int(deepChestnutDarkRGB.r * 255), Int(deepChestnutDarkRGB.g * 255), Int(deepChestnutDarkRGB.b * 255))
XCPCaptureValue("deepChestnutDark", value: deepChestnutDark)
XCPCaptureValue("deepChestnutDarkFlat", value: deepChestnutDark.flatColor)
let mauve = UIColor(red: 0.88, green: 0.65, blue: 0.99, alpha: 1)
XCPCaptureValue("mauve", value: mauve)
XCPCaptureValue("mauveFlat", value: mauve.flatColor)
let mauveLAB = mauve.LAB
let mauveDarkLAB = (mauveLAB.l - 10, mauveLAB.a, mauveLAB.b)
let mauveDarkRGB = labToRGB(mauveDarkLAB.0, mauveDarkLAB.1, mauveDarkLAB.2)
let mauveDark = rgb(Int(mauveDarkRGB.r * 255), Int(mauveDarkRGB.g * 255), Int(mauveDarkRGB.b * 255))
XCPCaptureValue("mauveDark", value: mauveDark)
XCPCaptureValue("mauveDarkFlat", value: mauveDark.flatColor)
let athensGray = UIColor(red: 0.88, green: 0.87, blue: 0.88, alpha: 1)
XCPCaptureValue("athensGray", value: athensGray)
XCPCaptureValue("athensGrayFlat", value: athensGray.flatColor)
let athensGrayLAB = athensGray.LAB
let athensGrayDarkLAB = (athensGrayLAB.l - 10, athensGrayLAB.a, athensGrayLAB.b)
let athensGrayDarkRGB = labToRGB(athensGrayDarkLAB.0, athensGrayDarkLAB.1, athensGrayDarkLAB.2)
let athensGrayDark = rgb(Int(athensGrayDarkRGB.r * 255), Int(athensGrayDarkRGB.g * 255), Int(athensGrayDarkRGB.b * 255))
XCPCaptureValue("athensGrayDark", value: athensGrayDark)
XCPCaptureValue("athensGrayDarkFlat", value: athensGrayDark.flatColor)
let mountainMist = UIColor(red: 0.57, green: 0.57, blue: 0.57, alpha: 1)
XCPCaptureValue("mountainMist", value: mountainMist)
XCPCaptureValue("mountainMistFlat", value: mountainMist.flatColor)
let mountainMistLAB = mountainMist.LAB
let mountainMistDarkLAB = (mountainMistLAB.l - 10, mountainMistLAB.a, mountainMistLAB.b)
let mountainMistDarkRGB = labToRGB(mountainMistDarkLAB.0, mountainMistDarkLAB.1, mountainMistDarkLAB.2)
let mountainMistDark = rgb(Int(mountainMistDarkRGB.r * 255), Int(mountainMistDarkRGB.g * 255), Int(mountainMistDarkRGB.b * 255))
XCPCaptureValue("mountainMistDark", value: mountainMistDark)
XCPCaptureValue("mountainMistDarkFlat", value: mountainMistDark.flatColor)
let hippieGreen = UIColor(red: 0.39, green: 0.59, blue: 0.35, alpha: 1)
XCPCaptureValue("hippieGreen", value: hippieGreen)
XCPCaptureValue("hippieGreenFlat", value: hippieGreen.flatColor)
let hippieGreenLAB = hippieGreen.LAB
let hippieGreenDarkLAB = (hippieGreenLAB.l - 10, hippieGreenLAB.a, hippieGreenLAB.b)
let hippieGreenDarkRGB = labToRGB(hippieGreenDarkLAB.0, hippieGreenDarkLAB.1, hippieGreenDarkLAB.2)
let hippieGreenDark = rgb(Int(hippieGreenDarkRGB.r * 255), Int(hippieGreenDarkRGB.g * 255), Int(hippieGreenDarkRGB.b * 255))
XCPCaptureValue("hippieGreenDark", value: hippieGreenDark)
XCPCaptureValue("hippieGreenDarkFlat", value: hippieGreenDark.flatColor)
let axolotl = UIColor(red: 0.33, green: 0.42, blue: 0.29, alpha: 1)
XCPCaptureValue("axolotl", value: axolotl)
XCPCaptureValue("axolotlFlat", value: axolotl.flatColor)
let axolotlLAB = axolotl.LAB
let axolotlDarkLAB = (axolotlLAB.l - 10, axolotlLAB.a, axolotlLAB.b)
let axolotlDarkRGB = labToRGB(axolotlDarkLAB.0, axolotlDarkLAB.1, axolotlDarkLAB.2)
let axolotlDark = rgb(Int(axolotlDarkRGB.r * 255), Int(axolotlDarkRGB.g * 255), Int(axolotlDarkRGB.b * 255))
XCPCaptureValue("axolotlDark", value: axolotlDark)
XCPCaptureValue("axolotlDarkFlat", value: axolotlDark.flatColor)
let celery = UIColor(red: 0.65, green: 0.76, blue: 0.38, alpha: 1)
XCPCaptureValue("celery", value: celery)
XCPCaptureValue("celeryFlat", value: celery.flatColor)
let celeryLAB = celery.LAB
let celeryDarkLAB = (celeryLAB.l - 10, celeryLAB.a, celeryLAB.b)
let celeryDarkRGB = labToRGB(celeryDarkLAB.0, celeryDarkLAB.1, celeryDarkLAB.2)
let celeryDark = rgb(Int(celeryDarkRGB.r * 255), Int(celeryDarkRGB.g * 255), Int(celeryDarkRGB.b * 255))
XCPCaptureValue("celeryDark", value: celeryDark)
XCPCaptureValue("celeryDarkFlat", value: celeryDark.flatColor)
let moonstoneBlue = UIColor(red: 0.49, green: 0.66, blue: 0.78, alpha: 1)
XCPCaptureValue("moonstoneBlue", value: moonstoneBlue)
XCPCaptureValue("moonstoneBlueFlat", value: moonstoneBlue.flatColor)
let moonstoneBlueLAB = moonstoneBlue.LAB
let moonstoneBlueDarkLAB = (moonstoneBlueLAB.l - 10, moonstoneBlueLAB.a, moonstoneBlueLAB.b)
let moonstoneBlueDarkRGB = labToRGB(moonstoneBlueDarkLAB.0, moonstoneBlueDarkLAB.1, moonstoneBlueDarkLAB.2)
let moonstoneBlueDark = rgb(Int(moonstoneBlueDarkRGB.r * 255), Int(moonstoneBlueDarkRGB.g * 255), Int(moonstoneBlueDarkRGB.b * 255))
XCPCaptureValue("moonstoneBlueDark", value: moonstoneBlueDark)
XCPCaptureValue("moonstoneBlueDarkFlat", value: moonstoneBlueDark.flatColor)
let flamenco = UIColor(red: 0.89, green: 0.53, blue: 0.26, alpha: 1)
XCPCaptureValue("flamenco", value: flamenco)
XCPCaptureValue("flamencoFlat", value: flamenco.flatColor)
let flamencoLAB = flamenco.LAB
let flamencoDarkLAB = (flamencoLAB.l - 10, flamencoLAB.a, flamencoLAB.b)
let flamencoDarkRGB = labToRGB(flamencoDarkLAB.0, flamencoDarkLAB.1, flamencoDarkLAB.2)
let flamencoDark = rgb(Int(flamencoDarkRGB.r * 255), Int(flamencoDarkRGB.g * 255), Int(flamencoDarkRGB.b * 255))
XCPCaptureValue("flamencoDark", value: flamencoDark)
XCPCaptureValue("flamencoDarkFlat", value: flamencoDark.flatColor)
let limerick = UIColor(red: 0.56, green: 0.73, blue: 0.13, alpha: 1)
XCPCaptureValue("limerick", value: limerick)
XCPCaptureValue("limerickFlat", value: limerick.flatColor)
let limerickLAB = limerick.LAB
let limerickDarkLAB = (limerickLAB.l - 10, limerickLAB.a, limerickLAB.b)
let limerickDarkRGB = labToRGB(limerickDarkLAB.0, limerickDarkLAB.1, limerickDarkLAB.2)
let limerickDark = rgb(Int(limerickDarkRGB.r * 255), Int(limerickDarkRGB.g * 255), Int(limerickDarkRGB.b * 255))
XCPCaptureValue("limerickDark", value: limerickDark)
XCPCaptureValue("limerickDarkFlat", value: limerickDark.flatColor)
let mayaBlue = UIColor(red: 0.42, green: 0.69, blue: 0.96, alpha: 1)
XCPCaptureValue("mayaBlue", value: mayaBlue)
XCPCaptureValue("mayaBlueFlat", value: mayaBlue.flatColor)
let mayaBlueLAB = mayaBlue.LAB
let mayaBlueDarkLAB = (mayaBlueLAB.l - 10, mayaBlueLAB.a, mayaBlueLAB.b)
let mayaBlueDarkRGB = labToRGB(mayaBlueDarkLAB.0, mayaBlueDarkLAB.1, mayaBlueDarkLAB.2)
let mayaBlueDark = rgb(Int(mayaBlueDarkRGB.r * 255), Int(mayaBlueDarkRGB.g * 255), Int(mayaBlueDarkRGB.b * 255))
XCPCaptureValue("mayaBlueDark", value: mayaBlueDark)
XCPCaptureValue("mayaBlueDarkFlat", value: mayaBlueDark.flatColor)
let eastSide1 = UIColor(red: 0.64, green: 0.54, blue: 0.7, alpha: 1)
XCPCaptureValue("eastSide1", value: eastSide1)
XCPCaptureValue("eastSide1Flat", value: eastSide1.flatColor)
let eastSide1LAB = eastSide1.LAB
let eastSide1DarkLAB = (eastSide1LAB.l - 10, eastSide1LAB.a, eastSide1LAB.b)
let eastSide1DarkRGB = labToRGB(eastSide1DarkLAB.0, eastSide1DarkLAB.1, eastSide1DarkLAB.2)
let eastSide1Dark = rgb(Int(eastSide1DarkRGB.r * 255), Int(eastSide1DarkRGB.g * 255), Int(eastSide1DarkRGB.b * 255))
XCPCaptureValue("eastSide1Dark", value: eastSide1Dark)
XCPCaptureValue("eastSide1DarkFlat", value: eastSide1Dark.flatColor)
let seaNymph = UIColor(red: 0.53, green: 0.71, blue: 0.64, alpha: 1)
XCPCaptureValue("seaNymph", value: seaNymph)
XCPCaptureValue("seaNymphFlat", value: seaNymph.flatColor)
let seaNymphLAB = seaNymph.LAB
let seaNymphDarkLAB = (seaNymphLAB.l - 10, seaNymphLAB.a, seaNymphLAB.b)
let seaNymphDarkRGB = labToRGB(seaNymphDarkLAB.0, seaNymphDarkLAB.1, seaNymphDarkLAB.2)
let seaNymphDark = rgb(Int(seaNymphDarkRGB.r * 255), Int(seaNymphDarkRGB.g * 255), Int(seaNymphDarkRGB.b * 255))
XCPCaptureValue("seaNymphDark", value: seaNymphDark)
XCPCaptureValue("seaNymphDarkFlat", value: seaNymphDark.flatColor)
let eastSide2 = UIColor(red: 0.71, green: 0.56, blue: 0.79, alpha: 1)
XCPCaptureValue("eastSide2", value: eastSide2)
XCPCaptureValue("eastSide2Flat", value: eastSide2.flatColor)
let eastSide2LAB = eastSide2.LAB
let eastSide2DarkLAB = (eastSide2LAB.l - 10, eastSide2LAB.a, eastSide2LAB.b)
let eastSide2DarkRGB = labToRGB(eastSide2DarkLAB.0, eastSide2DarkLAB.1, eastSide2DarkLAB.2)
let eastSide2Dark = rgb(Int(eastSide2DarkRGB.r * 255), Int(eastSide2DarkRGB.g * 255), Int(eastSide2DarkRGB.b * 255))
XCPCaptureValue("eastSide2Dark", value: eastSide2Dark)
XCPCaptureValue("eastSide2DarkFlat", value: eastSide2Dark.flatColor)
let reefGold = UIColor(red: 0.64, green: 0.53, blue: 0.23, alpha: 1)
XCPCaptureValue("reefGold", value: reefGold)
XCPCaptureValue("reefGoldFlat", value: reefGold.flatColor)
let reefGoldLAB = reefGold.LAB
let reefGoldDarkLAB = (reefGoldLAB.l - 10, reefGoldLAB.a, reefGoldLAB.b)
let reefGoldDarkRGB = labToRGB(reefGoldDarkLAB.0, reefGoldDarkLAB.1, reefGoldDarkLAB.2)
let reefGoldDark = rgb(Int(reefGoldDarkRGB.r * 255), Int(reefGoldDarkRGB.g * 255), Int(reefGoldDarkRGB.b * 255))
XCPCaptureValue("reefGoldDark", value: reefGoldDark)
XCPCaptureValue("reefGoldDarkFlat", value: reefGoldDark.flatColor)
let indianYellow = UIColor(red: 0.88, green: 0.65, blue: 0.35, alpha: 1)
XCPCaptureValue("indianYellow", value: indianYellow)
XCPCaptureValue("indianYellowFlat", value: indianYellow.flatColor)
let indianYellowLAB = indianYellow.LAB
let indianYellowDarkLAB = (indianYellowLAB.l - 10, indianYellowLAB.a, indianYellowLAB.b)
let indianYellowDarkRGB = labToRGB(indianYellowDarkLAB.0, indianYellowDarkLAB.1, indianYellowDarkLAB.2)
let indianYellowDark = rgb(Int(indianYellowDarkRGB.r * 255), Int(indianYellowDarkRGB.g * 255), Int(indianYellowDarkRGB.b * 255))
XCPCaptureValue("indianYellowDark", value: indianYellowDark)
XCPCaptureValue("indianYellowDarkFlat", value: indianYellowDark.flatColor)
let moonRaker = UIColor(red: 0.82, green: 0.83, blue: 0.96, alpha: 1)
XCPCaptureValue("moonRaker", value: moonRaker)
XCPCaptureValue("moonRakerFlat", value: moonRaker.flatColor)
let moonRakerLAB = moonRaker.LAB
let moonRakerDarkLAB = (moonRakerLAB.l - 10, moonRakerLAB.a, moonRakerLAB.b)
let moonRakerDarkRGB = labToRGB(moonRakerDarkLAB.0, moonRakerDarkLAB.1, moonRakerDarkLAB.2)
let moonRakerDark = rgb(Int(moonRakerDarkRGB.r * 255), Int(moonRakerDarkRGB.g * 255), Int(moonRakerDarkRGB.b * 255))
XCPCaptureValue("moonRakerDark", value: moonRakerDark)
XCPCaptureValue("moonRakerDarkFlat", value: moonRakerDark.flatColor)
let montana = UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1)
XCPCaptureValue("montana", value: montana)
XCPCaptureValue("montanaFlat", value: montana.flatColor)
let montanaLAB = montana.LAB
let montanaDarkLAB = (montanaLAB.l - 10, montanaLAB.a, montanaLAB.b)
let montanaDarkRGB = labToRGB(montanaDarkLAB.0, montanaDarkLAB.1, montanaDarkLAB.2)
let montanaDark = rgb(Int(montanaDarkRGB.r * 255), Int(montanaDarkRGB.g * 255), Int(montanaDarkRGB.b * 255))
XCPCaptureValue("montanaDark", value: montanaDark)
XCPCaptureValue("montanaDarkFlat", value: montanaDark.flatColor)
let solitude = UIColor(red: 0.91, green: 0.95, blue: 1, alpha: 1)
XCPCaptureValue("solitude", value: solitude)
XCPCaptureValue("solitudeFlat", value: solitude.flatColor)
let solitudeLAB = solitude.LAB
let solitudeDarkLAB = (solitudeLAB.l - 10, solitudeLAB.a, solitudeLAB.b)
let solitudeDarkRGB = labToRGB(solitudeDarkLAB.0, solitudeDarkLAB.1, solitudeDarkLAB.2)
let solitudeDark = rgb(Int(solitudeDarkRGB.r * 255), Int(solitudeDarkRGB.g * 255), Int(solitudeDarkRGB.b * 255))
XCPCaptureValue("solitudeDark", value: solitudeDark)
XCPCaptureValue("solitudeDarkFlat", value: solitudeDark.flatColor)
let silverChalice = UIColor(red: 0.66, green: 0.71, blue: 0.65, alpha: 1)
XCPCaptureValue("silverChalice", value: silverChalice)
XCPCaptureValue("silverChaliceFlat", value: silverChalice.flatColor)
let silverChaliceLAB = silverChalice.LAB
let silverChaliceDarkLAB = (silverChaliceLAB.l - 10, silverChaliceLAB.a, silverChaliceLAB.b)
let silverChaliceDarkRGB = labToRGB(silverChaliceDarkLAB.0, silverChaliceDarkLAB.1, silverChaliceDarkLAB.2)
let silverChaliceDark = rgb(Int(silverChaliceDarkRGB.r * 255), Int(silverChaliceDarkRGB.g * 255), Int(silverChaliceDarkRGB.b * 255))
XCPCaptureValue("silverChaliceDark", value: silverChaliceDark)
XCPCaptureValue("silverChaliceDarkFlat", value: silverChaliceDark.flatColor)
let (r, g, b) = (CGFloat(40)/255, CGFloat(180)/255, CGFloat(190)/255)
r
g
b
let (r2, g2, b2) = rgbTosRGB(r, g, b)
r2
g2
b2
let (x, y, z) = sRGBToXYZ(r2, g2, b2)
x
y
z
let (l, a, bb) = xyzToLAB(x, y, z)
l
a
bb

let color = rgb(40, 180, 190)
let (l2, a2, bb2) = color.LAB
l2
a2
bb2


let (x2, y2, z2) = labToXYZ(l2, a2, bb2)
x2
y2
z2

let (r3, g3, b3) = xyzTosRGB(x2, y2, z2)
r3
g3
b3

let (r4, g4, b4) = sRGBToRGB(r3, g3, b3)
r4
g4
b4
Int(r4 * 255)
Int(g4 * 255)
Int(b4 * 255)


let (lll, aaa, bbb) = rgbToLAB(r, g, b)
lll
aaa
bbb

let (rrr, ggg, bbbb) = labToRGB(lll, aaa, bbb)
Int(rrr * 255)
Int(ggg * 255)
Int(bbbb * 255)


let lighterColor = Chameleon.flatYellow
let (lighterL, lighterA, lighterB) = lighterColor.LAB
lighterL
lighterA
lighterB

let (darkerL, darkerA, darkerB) = (lighterL - 28, lighterA, lighterB)
darkerL
darkerA
darkerB

//let (darkerRed, darkerGree
