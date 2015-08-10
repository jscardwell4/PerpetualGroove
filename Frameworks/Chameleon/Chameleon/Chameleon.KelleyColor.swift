//
//  Chameleon.KelleyColor.swift
//  Chameleon
//
//  Created by Jason Cardwell on 5/14/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

extension Chameleon {

  // MARK: - Light Shades

  public static var kelleyBlackMarlin:     UIColor { return KelleyColor.Light(.BlackMarlin).color     }
  public static var kelleyBrownTumbleweed: UIColor { return KelleyColor.Light(.BrownTumbleweed).color }
  public static var kelleyKaraka:          UIColor { return KelleyColor.Light(.Karaka).color          }
  public static var kelleyPineTree:        UIColor { return KelleyColor.Light(.PineTree).color        }
  public static var kelleyMarshland:       UIColor { return KelleyColor.Light(.Marshland).color       }
  public static var kelleyPearlBush:       UIColor { return KelleyColor.Light(.PearlBush).color       }
  public static var kelleyTapestry:        UIColor { return KelleyColor.Light(.Tapestry).color        }
  public static var kelleyMalachiteGreen:  UIColor { return KelleyColor.Light(.MalachiteGreen).color  }
  public static var kelleyArrowtown:       UIColor { return KelleyColor.Light(.Arrowtown).color       }
  public static var kelleyMetallicBronze:  UIColor { return KelleyColor.Light(.MetallicBronze).color  }
  public static var kelleyCocoaBrown:      UIColor { return KelleyColor.Light(.CocoaBrown).color      }
  public static var kelleyMikado:          UIColor { return KelleyColor.Light(.Mikado).color          }
  public static var kelleyElPaso:          UIColor { return KelleyColor.Light(.ElPaso).color          }
  public static var kelleyNero:            UIColor { return KelleyColor.Light(.Nero).color            }
  public static var kelleyDarkTan:         UIColor { return KelleyColor.Light(.DarkTan).color         }
  public static var kelleyShadow:          UIColor { return KelleyColor.Light(.Shadow).color          }
  public static var kelleyBracken:         UIColor { return KelleyColor.Light(.Bracken).color         }
  public static var kelleyCork:            UIColor { return KelleyColor.Light(.Cork).color            }
  public static var kelleyCannonBlack:     UIColor { return KelleyColor.Light(.CannonBlack).color     }
  public static var kelleyPaleBrown:       UIColor { return KelleyColor.Light(.PaleBrown).color       }
  public static var kelleyDarkWood:        UIColor { return KelleyColor.Light(.DarkWood).color        }
  public static var kelleyClinker:         UIColor { return KelleyColor.Light(.Clinker).color         }

  // MARK: - Dark Shades

  public static var kelleyBlackMarlinDark:     UIColor { return KelleyColor.Dark(.BlackMarlin).color     }
  public static var kelleyBrownTumbleweedDark: UIColor { return KelleyColor.Dark(.BrownTumbleweed).color }
  public static var kelleyKarakaDark:          UIColor { return KelleyColor.Dark(.Karaka).color          }
  public static var kelleyPineTreeDark:        UIColor { return KelleyColor.Dark(.PineTree).color        }
  public static var kelleyMarshlandDark:       UIColor { return KelleyColor.Dark(.Marshland).color       }
  public static var kelleyPearlBushDark:       UIColor { return KelleyColor.Dark(.PearlBush).color       }
  public static var kelleyTapestryDark:        UIColor { return KelleyColor.Dark(.Tapestry).color        }
  public static var kelleyMalachiteGreenDark:  UIColor { return KelleyColor.Dark(.MalachiteGreen).color  }
  public static var kelleyArrowtownDark:       UIColor { return KelleyColor.Dark(.Arrowtown).color       }
  public static var kelleyMetallicBronzeDark:  UIColor { return KelleyColor.Dark(.MetallicBronze).color  }
  public static var kelleyCocoaBrownDark:      UIColor { return KelleyColor.Dark(.CocoaBrown).color      }
  public static var kelleyMikadoDark:          UIColor { return KelleyColor.Dark(.Mikado).color          }
  public static var kelleyElPasoDark:          UIColor { return KelleyColor.Dark(.ElPaso).color          }
  public static var kelleyNeroDark:            UIColor { return KelleyColor.Dark(.Nero).color            }
  public static var kelleyDarkTanDark:         UIColor { return KelleyColor.Dark(.DarkTan).color         }
  public static var kelleyShadowDark:          UIColor { return KelleyColor.Dark(.Shadow).color          }
  public static var kelleyBrackenDark:         UIColor { return KelleyColor.Dark(.Bracken).color         }
  public static var kelleyCorkDark:            UIColor { return KelleyColor.Dark(.Cork).color            }
  public static var kelleyCannonBlackDark:     UIColor { return KelleyColor.Dark(.CannonBlack).color     }
  public static var kelleyPaleBrownDark:       UIColor { return KelleyColor.Dark(.PaleBrown).color       }
  public static var kelleyDarkWoodDark:        UIColor { return KelleyColor.Dark(.DarkWood).color        }
  public static var kelleyClinkerDark:         UIColor { return KelleyColor.Dark(.Clinker).color         }

  public enum KelleyColor: ColorType {
    case Light (KelleyColorBase)
    case Dark (KelleyColorBase)

    public enum KelleyColorBase: ColorBaseType {
      case BlackMarlin, BrownTumbleweed, Karaka, PineTree, Marshland, PearlBush, Tapestry, MalachiteGreen,
           Arrowtown, MetallicBronze, CocoaBrown, Mikado, ElPaso, Nero, DarkTan, Shadow, Bracken, Cork,
           CannonBlack, PaleBrown, DarkWood, Clinker

      public static var all: [KelleyColorBase] {
        return [.BlackMarlin, .BrownTumbleweed, .Karaka, .PineTree, .Marshland, .PearlBush,
                .Tapestry, .MalachiteGreen, .Arrowtown, .MetallicBronze, .CocoaBrown, .Mikado, .ElPaso,
                .Nero, .DarkTan, .Shadow, .Bracken, .Cork, .CannonBlack, .PaleBrown, .DarkWood, .Clinker]
      }

      public var name: String {
        switch self {
          case .BlackMarlin:    return "BlackMarlin"
          case .BrownTumbleweed:return "BrownTumbleweed"
          case .Karaka:         return "Karaka"
          case .PineTree:       return "PineTree"
          case .Marshland:      return "Marshland"
          case .PearlBush:      return "PearlBush"
          case .Tapestry:       return "Tapestry"
          case .MalachiteGreen: return "MalachiteGreen"
          case .Arrowtown:      return "Arrowtown"
          case .MetallicBronze: return "MetallicBronze"
          case .CocoaBrown:     return "CocoaBrown"
          case .Mikado:         return "Mikado"
          case .ElPaso:         return "ElPaso"
          case .Nero:           return "Nero"
          case .DarkTan:        return "DarkTan"
          case .Shadow:         return "Shadow"
          case .Bracken:        return "Bracken"
          case .Cork:           return "Cork"
          case .CannonBlack:    return "CannonBlack"
          case .PaleBrown:      return "PaleBrown"
          case .DarkWood:       return "DarkWood"
          case .Clinker:        return "Clinker"
        }
      }
    }

    static var all:      [KelleyColor] { return allLight + allDark                 }
    static var allLight: [KelleyColor] { return KelleyColorBase.all.map {KelleyColor.Light($0)} }
    static var allDark:  [KelleyColor] { return KelleyColorBase.all.map {KelleyColor.Dark($0)}  }

    public var name: String { switch self { case .Light(let b): return b.name; case .Dark(let b):  return b.name + "Dark"} }
    public var base: KelleyColorBase { switch self { case .Light(let b): return b; case .Dark(let b): return b } }
    public var shade: Chameleon.Shade { switch self { case .Light: return .Light; case .Dark:  return .Dark } }

    public static let lightColors = [
      KelleyColorBase.BlackMarlin.name:     rgb(Int(0.24314 * 255), Int(0.17255 * 255), Int(0.09804 * 255)),
      KelleyColorBase.BrownTumbleweed.name: rgb(Int(0.21176 * 255), Int(0.19216 * 255), Int(0.04706 * 255)),
      KelleyColorBase.Karaka.name:          rgb(Int(0.12941 * 255), Int(0.08235 * 255), Int(0.03137 * 255)),
      KelleyColorBase.PineTree.name:        rgb(Int(0.07451 * 255), Int(0.12941 * 255), Int(0.02745 * 255)),
      KelleyColorBase.Marshland.name:       rgb(Int(0.04706 * 255), Int(0.04706 * 255), Int(0.00000 * 255)),
      KelleyColorBase.PearlBush.name:       rgb(Int(0.87451 * 255), Int(0.83137 * 255), Int(0.76471 * 255)),
      KelleyColorBase.Tapestry.name:        rgb(Int(0.73725 * 255), Int(0.40000 * 255), Int(0.54118 * 255)),
      KelleyColorBase.MalachiteGreen.name:  rgb(Int(0.61176 * 255), Int(0.59608 * 255), Int(0.45490 * 255)),
      KelleyColorBase.Arrowtown.name:       rgb(Int(0.51765 * 255), Int(0.47451 * 255), Int(0.40000 * 255)),
      KelleyColorBase.MetallicBronze.name:  rgb(Int(0.27059 * 255), Int(0.20784 * 255), Int(0.09020 * 255)),
      KelleyColorBase.CocoaBrown.name:      rgb(Int(0.22353 * 255), Int(0.16471 * 255), Int(0.10980 * 255)),
      KelleyColorBase.Mikado.name:          rgb(Int(0.17255 * 255), Int(0.14510 * 255), Int(0.06275 * 255)),
      KelleyColorBase.ElPaso.name:          rgb(Int(0.13333 * 255), Int(0.10588 * 255), Int(0.03137 * 255)),
      KelleyColorBase.Nero.name:            rgb(Int(0.04706 * 255), Int(0.03529 * 255), Int(0.00392 * 255)),
      KelleyColorBase.DarkTan.name:         rgb(Int(0.60392 * 255), Int(0.51765 * 255), Int(0.28627 * 255)),
      KelleyColorBase.Shadow.name:          rgb(Int(0.54902 * 255), Int(0.46275 * 255), Int(0.29020 * 255)),
      KelleyColorBase.Bracken.name:         rgb(Int(0.35686 * 255), Int(0.23922 * 255), Int(0.15686 * 255)),
      KelleyColorBase.Cork.name:            rgb(Int(0.26667 * 255), Int(0.14902 * 255), Int(0.12549 * 255)),
      KelleyColorBase.CannonBlack.name:     rgb(Int(0.15294 * 255), Int(0.13333 * 255), Int(0.03137 * 255)),
      KelleyColorBase.PaleBrown.name:       rgb(Int(0.57255 * 255), Int(0.46667 * 255), Int(0.32157 * 255)),
      KelleyColorBase.DarkWood.name:        rgb(Int(0.51373 * 255), Int(0.41176 * 255), Int(0.24314 * 255)),
      KelleyColorBase.Clinker.name:         rgb(Int(0.28235 * 255), Int(0.22745 * 255), Int(0.13725 * 255))
    ]

    public static let darkColors: [String:UIColor] = {
      var darkColors: [String:UIColor] = [:]
      for (name, color) in Chameleon.KelleyColor.lightColors {
        var (l, a, b) = color.LAB
        l -= 10
        let(red, green, blue) = labToRGB(max(l, 0), a, b)
        darkColors[name] = UIColor(red: red, green: green, blue: blue, alpha: 1)
      }
      return darkColors
    } ()

    public var color: UIColor {
      switch self {
        case .Light(let b): return KelleyColor.lightColors[b.name]!
        case .Dark(let b):  return KelleyColor.darkColors[b.name]!
      }
    }

    public init(base: KelleyColorBase, shade: Chameleon.Shade = .Light) {
      switch shade {
        case .Dark: self = .Dark(base)
        default: self = .Light(base)
      }
    }

    public init?(name: String, shade: Chameleon.Shade = .Light) {
      switch name.lowercaseString {
        case KelleyColorBase.BlackMarlin.name.lowercaseString:     self = KelleyColor(base: .BlackMarlin,     shade: shade)
        case KelleyColorBase.BrownTumbleweed.name.lowercaseString: self = KelleyColor(base: .BrownTumbleweed, shade: shade)
        case KelleyColorBase.Karaka.name.lowercaseString:          self = KelleyColor(base: .Karaka,          shade: shade)
        case KelleyColorBase.PineTree.name.lowercaseString:        self = KelleyColor(base: .PineTree,        shade: shade)
        case KelleyColorBase.Marshland.name.lowercaseString:       self = KelleyColor(base: .Marshland,       shade: shade)
        case KelleyColorBase.PearlBush.name.lowercaseString:       self = KelleyColor(base: .PearlBush,       shade: shade)
        case KelleyColorBase.Tapestry.name.lowercaseString:        self = KelleyColor(base: .Tapestry,        shade: shade)
        case KelleyColorBase.MalachiteGreen.name.lowercaseString:  self = KelleyColor(base: .MalachiteGreen,  shade: shade)
        case KelleyColorBase.Arrowtown.name.lowercaseString:       self = KelleyColor(base: .Arrowtown,       shade: shade)
        case KelleyColorBase.MetallicBronze.name.lowercaseString:  self = KelleyColor(base: .MetallicBronze,  shade: shade)
        case KelleyColorBase.CocoaBrown.name.lowercaseString:      self = KelleyColor(base: .CocoaBrown,      shade: shade)
        case KelleyColorBase.Mikado.name.lowercaseString:          self = KelleyColor(base: .Mikado,          shade: shade)
        case KelleyColorBase.ElPaso.name.lowercaseString:          self = KelleyColor(base: .ElPaso,          shade: shade)
        case KelleyColorBase.Nero.name.lowercaseString:            self = KelleyColor(base: .Nero,            shade: shade)
        case KelleyColorBase.DarkTan.name.lowercaseString:         self = KelleyColor(base: .DarkTan,         shade: shade)
        case KelleyColorBase.Shadow.name.lowercaseString:          self = KelleyColor(base: .Shadow,          shade: shade)
        case KelleyColorBase.Bracken.name.lowercaseString:         self = KelleyColor(base: .Bracken,         shade: shade)
        case KelleyColorBase.Cork.name.lowercaseString:            self = KelleyColor(base: .Cork,            shade: shade)
        case KelleyColorBase.CannonBlack.name.lowercaseString:     self = KelleyColor(base: .CannonBlack,     shade: shade)
        case KelleyColorBase.PaleBrown.name.lowercaseString:       self = KelleyColor(base: .PaleBrown,       shade: shade)
        case KelleyColorBase.DarkWood.name.lowercaseString:        self = KelleyColor(base: .DarkWood,        shade: shade)
        case KelleyColorBase.Clinker.name.lowercaseString:         self = KelleyColor(base: .Clinker,         shade: shade)
        default: return nil
      }
  }
}

}