import Foundation

//
// Provide the different implementations you want to test here. Doing this in
// the main playground would make things really slow compared to the "real world"
// so always do this in Sources

//Manually mapping an array
public let loopingImplementation = { (testData:[Double])->Void in
    var newArray = [Double]()
    
    for value in testData {
      var i = Int(value)
      var result = 0.0
      while i > 0 {
        result += value * value
        i--
      }
        newArray.append(result)
    }
}

//Just calling Swift map
public let builtinImplementation = { (testData:[Double])->Void in
  var newArray = [Double]()

  for value in testData {
    newArray.append(pow(value, value))
  }

}
