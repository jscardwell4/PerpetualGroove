import Foundation
import MoonKit

let url = NSBundle.mainBundle().URLForResource("E7ECBB95-CFB8-46BF-AA31-4CC62230D817_TestSummaries", withExtension: "plist")!
let dictionary = NSDictionary(contentsOfURL: url) as! Dictionary<String, AnyObject>


print(dictionary)

