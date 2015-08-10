//
//  Chameleon.DarculaColor.swift
//  Chameleon
//
//  Created by Jason Cardwell on 5/14/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

extension Chameleon {

  // MARK: - Light Shades

  public static var darculaMauve:         UIColor { return DarculaColor.Light(.Mauve).color         }
  public static var darculaAthensGray:    UIColor { return DarculaColor.Light(.AthensGray).color    }
  public static var darculaMountainMist:  UIColor { return DarculaColor.Light(.MountainMist).color  }
  public static var darculaHippieGreen:   UIColor { return DarculaColor.Light(.HippieGreen).color   }
  public static var darculaAxolotl:       UIColor { return DarculaColor.Light(.Axolotl).color       }
  public static var darculaCelery:        UIColor { return DarculaColor.Light(.Celery).color        }
  public static var darculaMoonstoneBlue: UIColor { return DarculaColor.Light(.MoonstoneBlue).color }
  public static var darculaFlamenco:      UIColor { return DarculaColor.Light(.Flamenco).color      }
  public static var darculaLimerick:      UIColor { return DarculaColor.Light(.Limerick).color      }
  public static var darculaMayaBlue:      UIColor { return DarculaColor.Light(.MayaBlue).color      }
  public static var darculaEastSide:      UIColor { return DarculaColor.Light(.EastSide).color      }
  public static var darculaSeaNymph:      UIColor { return DarculaColor.Light(.SeaNymph).color      }
  public static var darculaReefGold:      UIColor { return DarculaColor.Light(.ReefGold).color      }
  public static var darculaIndianYellow:  UIColor { return DarculaColor.Light(.IndianYellow).color  }
  public static var darculaMoonRaker:     UIColor { return DarculaColor.Light(.MoonRaker).color     }
  public static var darculaMontana:       UIColor { return DarculaColor.Light(.Montana).color       }
  public static var darculaSolitude:      UIColor { return DarculaColor.Light(.Solitude).color      }
  public static var darculaSilverChalice: UIColor { return DarculaColor.Light(.SilverChalice).color }

  // MARK: - Dark Shades

  public static var darculaMauveDark:         UIColor { return DarculaColor.Dark(.Mauve).color         }
  public static var darculaAthensGrayDark:    UIColor { return DarculaColor.Dark(.AthensGray).color    }
  public static var darculaMountainMistDark:  UIColor { return DarculaColor.Dark(.MountainMist).color  }
  public static var darculaHippieGreenDark:   UIColor { return DarculaColor.Dark(.HippieGreen).color   }
  public static var darculaAxolotlDark:       UIColor { return DarculaColor.Dark(.Axolotl).color       }
  public static var darculaCeleryDark:        UIColor { return DarculaColor.Dark(.Celery).color        }
  public static var darculaMoonstoneBlueDark: UIColor { return DarculaColor.Dark(.MoonstoneBlue).color }
  public static var darculaFlamencoDark:      UIColor { return DarculaColor.Dark(.Flamenco).color      }
  public static var darculaLimerickDark:      UIColor { return DarculaColor.Dark(.Limerick).color      }
  public static var darculaMayaBlueDark:      UIColor { return DarculaColor.Dark(.MayaBlue).color      }
  public static var darculaEastSideDark:      UIColor { return DarculaColor.Dark(.EastSide).color      }
  public static var darculaSeaNymphDark:      UIColor { return DarculaColor.Dark(.SeaNymph).color      }
  public static var darculaReefGoldDark:      UIColor { return DarculaColor.Dark(.ReefGold).color      }
  public static var darculaIndianYellowDark:  UIColor { return DarculaColor.Dark(.IndianYellow).color  }
  public static var darculaMoonRakerDark:     UIColor { return DarculaColor.Dark(.MoonRaker).color     }
  public static var darculaMontanaDark:       UIColor { return DarculaColor.Dark(.Montana).color       }
  public static var darculaSolitudeDark:      UIColor { return DarculaColor.Dark(.Solitude).color      }
  public static var darculaSilverChaliceDark: UIColor { return DarculaColor.Dark(.SilverChalice).color }

  public enum DarculaColor: ColorType {
    case Light (DarculaColorBase)
    case Dark (DarculaColorBase)

    public enum DarculaColorBase: ColorBaseType {
      case Mauve, AthensGray, MountainMist, HippieGreen, Axolotl, Celery, MoonstoneBlue, Flamenco, Limerick,
           MayaBlue, EastSide, SeaNymph, ReefGold, IndianYellow, MoonRaker, Montana, Solitude, SilverChalice

      public static var all: [DarculaColorBase] {
        return [.Mauve, .AthensGray, .MountainMist, .HippieGreen, .Axolotl, .Celery, .MoonstoneBlue, .Flamenco, .Limerick,
                .MayaBlue, .EastSide, .SeaNymph, .ReefGold, .IndianYellow, .MoonRaker, .Montana, .Solitude, .SilverChalice]
      }

      public var name: String {
        switch self {
          case .Mauve:         return "Mauve"
          case .AthensGray:    return "AthensGray"
          case .MountainMist:  return "MountainMist"
          case .HippieGreen:   return "HippieGreen"
          case .Axolotl:       return "Axolotl"
          case .Celery:        return "Celery"
          case .MoonstoneBlue: return "MoonstoneBlue"
          case .Flamenco:      return "Flamenco"
          case .Limerick:      return "Limerick"
          case .MayaBlue:      return "MayaBlue"
          case .EastSide:      return "EastSide"
          case .SeaNymph:      return "SeaNymph"
          case .ReefGold:      return "ReefGold"
          case .IndianYellow:  return "IndianYellow"
          case .MoonRaker:     return "MoonRaker"
          case .Montana:       return "Montana"
          case .Solitude:      return "Solitude"
          case .SilverChalice: return "SilverChalice"
        }
      }
    }

    static var all:      [DarculaColor] { return allLight + allDark                 }
    static var allLight: [DarculaColor] { return DarculaColorBase.all.map {DarculaColor.Light($0)} }
    static var allDark:  [DarculaColor] { return DarculaColorBase.all.map {DarculaColor.Dark($0)}  }

    public var name: String { switch self { case .Light(let b): return b.name; case .Dark(let b):  return b.name + "Dark"} }
    public var base: DarculaColorBase { switch self { case .Light(let b): return b; case .Dark(let b): return b } }
    public var shade: Chameleon.Shade { switch self { case .Light: return .Light; case .Dark:  return .Dark } }

    public static let lightColors = [
      DarculaColorBase.Mauve.name:         UIColor(red: 0.88, green: 0.65, blue: 0.99, alpha: 1),
      DarculaColorBase.AthensGray.name:    UIColor(red: 0.88, green: 0.87, blue: 0.88, alpha: 1),
      DarculaColorBase.MountainMist.name:  UIColor(red: 0.57, green: 0.57, blue: 0.57, alpha: 1),
      DarculaColorBase.HippieGreen.name:   UIColor(red: 0.39, green: 0.59, blue: 0.35, alpha: 1),
      DarculaColorBase.Axolotl.name:       UIColor(red: 0.33, green: 0.42, blue: 0.29, alpha: 1),
      DarculaColorBase.Celery.name:        UIColor(red: 0.65, green: 0.76, blue: 0.38, alpha: 1),
      DarculaColorBase.MoonstoneBlue.name: UIColor(red: 0.49, green: 0.66, blue: 0.78, alpha: 1),
      DarculaColorBase.Flamenco.name:      UIColor(red: 0.89, green: 0.53, blue: 0.26, alpha: 1),
      DarculaColorBase.Limerick.name:      UIColor(red: 0.56, green: 0.73, blue: 0.13, alpha: 1),
      DarculaColorBase.MayaBlue.name:      UIColor(red: 0.42, green: 0.69, blue: 0.96, alpha: 1),
      DarculaColorBase.EastSide.name:      UIColor(red: 0.64, green: 0.54, blue: 0.7, alpha: 1),
      DarculaColorBase.SeaNymph.name:      UIColor(red: 0.53, green: 0.71, blue: 0.64, alpha: 1),
      DarculaColorBase.ReefGold.name:      UIColor(red: 0.64, green: 0.53, blue: 0.23, alpha: 1),
      DarculaColorBase.IndianYellow.name:  UIColor(red: 0.88, green: 0.65, blue: 0.35, alpha: 1),
      DarculaColorBase.MoonRaker.name:     UIColor(red: 0.82, green: 0.83, blue: 0.96, alpha: 1),
      DarculaColorBase.Montana.name:       UIColor(red: 0.22, green: 0.22, blue: 0.22, alpha: 1),
      DarculaColorBase.Solitude.name:      UIColor(red: 0.91, green: 0.95, blue: 1, alpha: 1),
      DarculaColorBase.SilverChalice.name: UIColor(red: 0.66, green: 0.71, blue: 0.65, alpha: 1)
    ]

    public static let darkColors: [String:UIColor] = {
      var darkColors: [String:UIColor] = [:]
      for (name, color) in Chameleon.DarculaColor.lightColors {
        var (l, a, b) = color.LAB
        l -= 10
        let(red, green, blue) = labToRGB(l, a, b)
        darkColors[name] = UIColor(red: red, green: green, blue: blue, alpha: 1)
      }
      return darkColors
    } ()

    public var color: UIColor {
      switch self {
        case .Light(let b): return DarculaColor.lightColors[b.name]!
        case .Dark(let b):  return DarculaColor.darkColors[b.name]!
      }
    }

    public init(base: DarculaColorBase, shade: Chameleon.Shade = .Light) {
      switch shade {
        case .Dark: self = .Dark(base)
        default: self = .Light(base)
      }
    }

    public init?(name: String, shade: Chameleon.Shade = .Light) {
      switch name.lowercaseString {
        case DarculaColorBase.Mauve.name.lowercaseString:         self = DarculaColor(base: .Mauve,         shade: shade)
        case DarculaColorBase.AthensGray.name.lowercaseString:    self = DarculaColor(base: .AthensGray,    shade: shade)
        case DarculaColorBase.MountainMist.name.lowercaseString:  self = DarculaColor(base: .MountainMist,  shade: shade)
        case DarculaColorBase.HippieGreen.name.lowercaseString:   self = DarculaColor(base: .HippieGreen,   shade: shade)
        case DarculaColorBase.Axolotl.name.lowercaseString:       self = DarculaColor(base: .Axolotl,       shade: shade)
        case DarculaColorBase.Celery.name.lowercaseString:        self = DarculaColor(base: .Celery,        shade: shade)
        case DarculaColorBase.MoonstoneBlue.name.lowercaseString: self = DarculaColor(base: .MoonstoneBlue, shade: shade)
        case DarculaColorBase.Flamenco.name.lowercaseString:      self = DarculaColor(base: .Flamenco,      shade: shade)
        case DarculaColorBase.Limerick.name.lowercaseString:      self = DarculaColor(base: .Limerick,      shade: shade)
        case DarculaColorBase.MayaBlue.name.lowercaseString:      self = DarculaColor(base: .MayaBlue,      shade: shade)
        case DarculaColorBase.EastSide.name.lowercaseString:      self = DarculaColor(base: .EastSide,      shade: shade)
        case DarculaColorBase.SeaNymph.name.lowercaseString:      self = DarculaColor(base: .SeaNymph,      shade: shade)
        case DarculaColorBase.ReefGold.name.lowercaseString:      self = DarculaColor(base: .ReefGold,      shade: shade)
        case DarculaColorBase.IndianYellow.name.lowercaseString:  self = DarculaColor(base: .IndianYellow,  shade: shade)
        case DarculaColorBase.MoonRaker.name.lowercaseString:     self = DarculaColor(base: .MoonRaker,     shade: shade)
        case DarculaColorBase.Montana.name.lowercaseString:       self = DarculaColor(base: .Montana,       shade: shade)
        case DarculaColorBase.Solitude.name.lowercaseString:      self = DarculaColor(base: .Solitude,      shade: shade)
        case DarculaColorBase.SilverChalice.name.lowercaseString: self = DarculaColor(base: .SilverChalice, shade: shade)
        default: return nil
      }
  }
}

}