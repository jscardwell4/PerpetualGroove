import Foundation
import UIKit
import MoonKit
import CoreImage

let underscore = [#Image(imageLiteral: "MidiSprite-Controls_underscore.png")#]
setenv("CG_CONTEXT_SHOW_BACKTRACE", "YES", 0)
let context = CIContext(options: nil)
UIGraphicsBeginImageContext(underscore.size)
let wrappedImage = CIImage(image: underscore)!//.imageByCompositingOverImage(CIImage(color: CIColor(color: .whiteColor())))
let whiteImage = CIImage(color: CIColor(color: .whiteColor()))
let filter = CIFilter(name: "CISourceInCompositing", withInputParameters: ["inputImage": wrappedImage, "inputBackgroundImage": whiteImage])
UIGraphicsBeginImageContext(underscore.size)
let image = filter!.outputImage! //wrappedImage.imageByClampingToExtent()
UIGraphicsEndImageContext()

let backgroundSize = CGSize(width: 400, height: 64) * 2
let imageSize = underscore.size * 2
let deltaSize = backgroundSize - imageSize
let horizontalPad = half(deltaSize.width)
let cgImage = context.createCGImage(image, fromRect: CGRect(x: -horizontalPad - half(half(imageSize.width)), y: 0, width: backgroundSize.width, height: backgroundSize.height))
let extendedImage = UIImage(CGImage: cgImage, scale: UIScreen.mainScreen().scale, orientation: .Up)
