import Foundation
import MoonKit


class WTFClass: NonObjectiveCBase {}

var wtf = WTFClass()
isUniquelyReferenced(&wtf)

weak var wtf2 = wtf
isUniquelyReferenced(&wtf2!)