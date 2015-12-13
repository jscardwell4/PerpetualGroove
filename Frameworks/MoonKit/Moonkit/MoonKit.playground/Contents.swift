import Foundation
import UIKit
import MoonKit

let imageSize = CGSize(width: 3, height: 4)
var rectSize = CGSize(width: 6, height: 5)

var ratio = imageSize.ratioForFittingSize(rectSize)

//rectSize.width = 3

ratio = imageSize.ratioForFittingSize(rectSize)


imageSize.aspectMappedToWidth(3)
imageSize.aspectMappedToHeight(6)
imageSize.aspectMappedToWidth(6)
imageSize.aspectMappedToSize(rectSize, binding: true)
imageSize.aspectMappedToSize(rectSize, binding: false)