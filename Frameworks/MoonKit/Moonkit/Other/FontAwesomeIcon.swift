//
//  FontAwesomeIcon.swift
//  HomeRemote
//
//  Created by Jason Cardwell on 8/17/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation

enum FontAwesomeIcon: Character {
  case Space                   = "\u{0020}"
  case SpaceNoBreak            = "\u{00A0}"
  case Dieresis                = "\u{00A8}"
  case Copyright               = "\u{00A9}"
  case Registered              = "\u{00AE}"
  case Acute                   = "\u{00B4}"
  case AE                      = "\u{00C6}"
  case EnQuad                  = "\u{2000}"
  case EmQuad                  = "\u{2001}"
  case EnSpace                 = "\u{2002}"
  case EmSpace                 = "\u{2003}"
  case ThreePerEmSpace         = "\u{2004}"
  case FourPerEmSpace          = "\u{2005}"
  case SixPerEmSpace           = "\u{2006}"
  case FigureSpace             = "\u{2007}"
  case PunctuationSpace        = "\u{2008}"
  case ThinSpace               = "\u{2009}"
  case HairSpace               = "\u{200A}"
  case NarrowNoBreakSpace      = "\u{202F}"
  case MediumMathematicalSpace = "\u{205F}"
  case Trademark               = "\u{2122}"
  case Infinity                = "\u{221E}"
  case NotEqual                = "\u{2260}"
  case UniE000                 = "\u{E000}"
  case Glass                   = "\u{F000}"
  case Music                   = "\u{F001}"
  case Search                  = "\u{F002}"
  case Envelope                = "\u{F003}"
  case Heart                   = "\u{F004}"
  case Star                    = "\u{F005}"
  case StarEmpty               = "\u{F006}"
  case User                    = "\u{F007}"
  case Film                    = "\u{F008}"
  case ThLarge                 = "\u{F009}"
  case Th                      = "\u{F00A}"
  case ThList                  = "\u{F00B}"
  case Ok                      = "\u{F00C}"
  case Remove                  = "\u{F00D}"
  case ZoomIn                  = "\u{F00E}"
  case ZoomOut                 = "\u{F010}"
  case Off                     = "\u{F011}"
  case Signal                  = "\u{F012}"
  case Cog                     = "\u{F013}"
  case Trash                   = "\u{F014}"
  case Home                    = "\u{F015}"
  case File                    = "\u{F016}"
  case Time                    = "\u{F017}"
  case Road                    = "\u{F018}"
  case DownloadAlt             = "\u{F019}"
  case Download                = "\u{F01A}"
  case Upload                  = "\u{F01B}"
  case Inbox                   = "\u{F01C}"
  case PlayCircle              = "\u{F01D}"
  case Repeat                  = "\u{F01E}"
  case Refresh                 = "\u{F021}"
  case ListAlt                 = "\u{F022}"
  case Lock                    = "\u{F023}"
  case Flag                    = "\u{F024}"
  case Headphones              = "\u{F025}"
  case VolumeOff               = "\u{F026}"
  case VolumeDown              = "\u{F027}"
  case VolumeUp                = "\u{F028}"
  case Qrcode                  = "\u{F029}"
  case Barcode                 = "\u{F02A}"
  case Tag                     = "\u{F02B}"
  case Tags                    = "\u{F02C}"
  case Book                    = "\u{F02D}"
  case Bookmark                = "\u{F02E}"
  case Print                   = "\u{F02F}"
  case Camera                  = "\u{F030}"
  case Font                    = "\u{F031}"
  case Bold                    = "\u{F032}"
  case Italic                  = "\u{F033}"
  case TextHeight              = "\u{F034}"
  case TextWidth               = "\u{F035}"
  case AlignLeft               = "\u{F036}"
  case AlignCenter             = "\u{F037}"
  case AlignRight              = "\u{F038}"
  case AlignJustify            = "\u{F039}"
  case List                    = "\u{F03A}"
  case IndentLeft              = "\u{F03B}"
  case IndentRight             = "\u{F03C}"
  case FacetimeVideo           = "\u{F03D}"
  case Picture                 = "\u{F03E}"
  case Pencil                  = "\u{F040}"
  case MapMarker               = "\u{F041}"
  case Adjust                  = "\u{F042}"
  case Tint                    = "\u{F043}"
  case Edit                    = "\u{F044}"
  case Share                   = "\u{F045}"
  case Check                   = "\u{F046}"
  case Move                    = "\u{F047}"
  case StepBackward            = "\u{F048}"
  case FastBackward            = "\u{F049}"
  case Backward                = "\u{F04A}"
  case Play                    = "\u{F04B}"
  case Pause                   = "\u{F04C}"
  case Stop                    = "\u{F04D}"
  case Forward                 = "\u{F04E}"
  case FastForward             = "\u{F050}"
  case StepForward             = "\u{F051}"
  case Eject                   = "\u{F052}"
  case ChevronLeft             = "\u{F053}"
  case ChevronRight            = "\u{F054}"
  case PlusSign                = "\u{F055}"
  case MinusSign               = "\u{F056}"
  case RemoveSign              = "\u{F057}"
  case OkSign                  = "\u{F058}"
  case QuestionSign            = "\u{F059}"
  case InfoSign                = "\u{F05A}"
  case Screenshot              = "\u{F05B}"
  case RemoveCircle            = "\u{F05C}"
  case OkCircle                = "\u{F05D}"
  case BanCircle               = "\u{F05E}"
  case ArrowLeft               = "\u{F060}"
  case ArrowRight              = "\u{F061}"
  case ArrowUp                 = "\u{F062}"
  case ArrowDown               = "\u{F063}"
  case ShareAlt                = "\u{F064}"
  case ResizeFull              = "\u{F065}"
  case ResizeSmall             = "\u{F066}"
  case Plus                    = "\u{F067}"
  case Minus                   = "\u{F068}"
  case Asterisk                = "\u{F069}"
  case ExclamationSign         = "\u{F06A}"
  case Gift                    = "\u{F06B}"
  case Leaf                    = "\u{F06C}"
  case Fire                    = "\u{F06D}"
  case EyeOpen                 = "\u{F06E}"
  case EyeClose                = "\u{F070}"
  case WarningSign             = "\u{F071}"
  case Plane                   = "\u{F072}"
  case Calendar                = "\u{F073}"
  case Random                  = "\u{F074}"
  case Comment                 = "\u{F075}"
  case Magnet                  = "\u{F076}"
  case ChevronUp               = "\u{F077}"
  case ChevronDown             = "\u{F078}"
  case Retweet                 = "\u{F079}"
  case ShoppingCart            = "\u{F07A}"
  case FolderClose             = "\u{F07B}"
  case FolderOpen              = "\u{F07C}"
  case ResizeVertical          = "\u{F07D}"
  case ResizeHorizontal        = "\u{F07E}"
  case BarChart                = "\u{F080}"
  case TwitterSign             = "\u{F081}"
  case FacebookSign            = "\u{F082}"
  case CameraRetro             = "\u{F083}"
  case Key                     = "\u{F084}"
  case Cogs                    = "\u{F085}"
  case Comments                = "\u{F086}"
  case ThumbsUp                = "\u{F087}"
  case ThumbsDown              = "\u{F088}"
  case StarHalf                = "\u{F089}"
  case HeartEmpty              = "\u{F08A}"
  case Signout                 = "\u{F08B}"
  case LinkedinSign            = "\u{F08C}"
  case Pushpin                 = "\u{F08D}"
  case ExternalLink            = "\u{F08E}"
  case Signin                  = "\u{F090}"
  case Trophy                  = "\u{F091}"
  case GithubSign              = "\u{F092}"
  case UploadAlt               = "\u{F093}"
  case Lemon                   = "\u{F094}"
  case Phone                   = "\u{F095}"
  case CheckEmpty              = "\u{F096}"
  case BookmarkEmpty           = "\u{F097}"
  case PhoneSign               = "\u{F098}"
  case Twitter                 = "\u{F099}"
  case Facebook                = "\u{F09A}"
  case Github                  = "\u{F09B}"
  case Unlock                  = "\u{F09C}"
  case CreditCard              = "\u{F09D}"
  case Rss                     = "\u{F09E}"
  case Hdd                     = "\u{F0A0}"
  case Bullhorn                = "\u{F0A1}"
  case Bell                    = "\u{F0A2}"
  case Certificate             = "\u{F0A3}"
  case HandRight               = "\u{F0A4}"
  case HandLeft                = "\u{F0A5}"
  case HandUp                  = "\u{F0A6}"
  case HandDown                = "\u{F0A7}"
  case CircleArrowLeft         = "\u{F0A8}"
  case CircleArrowRight        = "\u{F0A9}"
  case CircleArrowUp           = "\u{F0AA}"
  case CircleArrowDown         = "\u{F0AB}"
  case Globe                   = "\u{F0AC}"
  case Wrench                  = "\u{F0AD}"
  case Tasks                   = "\u{F0AE}"
  case Filter                  = "\u{F0B0}"
  case Briefcase               = "\u{F0B1}"
  case Fullscreen              = "\u{F0B2}"
  case Group                   = "\u{F0C0}"
  case Link                    = "\u{F0C1}"
  case Cloud                   = "\u{F0C2}"
  case Beaker                  = "\u{F0C3}"
  case Cut                     = "\u{F0C4}"
  case Copy                    = "\u{F0C5}"
  case PaperClip               = "\u{F0C6}"
  case Save                    = "\u{F0C7}"
  case SignBlank               = "\u{F0C8}"
  case Reorder                 = "\u{F0C9}"
  case Ul                      = "\u{F0CA}"
  case Ol                      = "\u{F0CB}"
  case Strikethrough           = "\u{F0CC}"
  case Underline               = "\u{F0CD}"
  case Table                   = "\u{F0CE}"
  case Magic                   = "\u{F0D0}"
  case Truck                   = "\u{F0D1}"
  case Pinterest               = "\u{F0D2}"
  case PinterestSign           = "\u{F0D3}"
  case GooglePlusSign          = "\u{F0D4}"
  case GooglePlus              = "\u{F0D5}"
  case Money                   = "\u{F0D6}"
  case CaretDown               = "\u{F0D7}"
  case CaretUp                 = "\u{F0D8}"
  case CaretLeft               = "\u{F0D9}"
  case CaretRight              = "\u{F0DA}"
  case Columns                 = "\u{F0DB}"
  case Sort                    = "\u{F0DC}"
  case SortDown                = "\u{F0DD}"
  case SortUp                  = "\u{F0DE}"
  case EnvelopeAlt             = "\u{F0E0}"
  case Linkedin                = "\u{F0E1}"
  case Undo                    = "\u{F0E2}"
  case Legal                   = "\u{F0E3}"
  case Dashboard               = "\u{F0E4}"
  case CommentAlt              = "\u{F0E5}"
  case CommentsAlt             = "\u{F0E6}"
  case Bolt                    = "\u{F0E7}"
  case Sitemap                 = "\u{F0E8}"
  case Umbrella                = "\u{F0E9}"
  case Paste                   = "\u{F0EA}"
  case LightBulb               = "\u{F0EB}"
  case Exchange                = "\u{F0EC}"
  case CloudDownload           = "\u{F0ED}"
  case CloudUpload             = "\u{F0EE}"
  case UserMd                  = "\u{F0F0}"
  case Stethoscope             = "\u{F0F1}"
  case Suitcase                = "\u{F0F2}"
  case BellAlt                 = "\u{F0F3}"
  case Coffee                  = "\u{F0F4}"
  case Food                    = "\u{F0F5}"
  case FileAlt                 = "\u{F0F6}"
  case Building                = "\u{F0F7}"
  case Hospital                = "\u{F0F8}"
  case Ambulance               = "\u{F0F9}"
  case Medkit                  = "\u{F0FA}"
  case FighterJet              = "\u{F0FB}"
  case Beer                    = "\u{F0FC}"
  case HSign                   = "\u{F0FD}"
  case F0fe                    = "\u{F0FE}"
  case DoubleAngleLeft         = "\u{F100}"
  case DoubleAngleRight        = "\u{F101}"
  case DoubleAngleUp           = "\u{F102}"
  case DoubleAngleDown         = "\u{F103}"
  case AngleLeft               = "\u{F104}"
  case AngleRight              = "\u{F105}"
  case AngleUp                 = "\u{F106}"
  case AngleDown               = "\u{F107}"
  case Desktop                 = "\u{F108}"
  case Laptop                  = "\u{F109}"
  case Tablet                  = "\u{F10A}"
  case MobilePhone             = "\u{F10B}"
  case CircleBlank             = "\u{F10C}"
  case QuoteLeft               = "\u{F10D}"
  case QuoteRight              = "\u{F10E}"
  case Spinner                 = "\u{F110}"
  case Circle                  = "\u{F111}"
  case Reply                   = "\u{F112}"
  case GithubAlt               = "\u{F113}"
  case FolderCloseAlt          = "\u{F114}"
  case FolderOpenAlt           = "\u{F115}"
  case AlignEdges              = "\u{F116}"
  case AlignLeftEdges          = "\u{F117}"
  case AlignRightEdges         = "\u{F118}"
  case AlignTopEdges           = "\u{F119}"
  case AlignBottomEdges        = "\u{F11A}"
  case AlignCenterX            = "\u{F11B}"
  case AlignCenterY            = "\u{F11C}"
  case AlignSize               = "\u{F11D}"
  case AlignVerticalSize       = "\u{F11E}"
  case AlignHorizontalSize     = "\u{F11F}"
  case AlignSizeExact          = "\u{F120}"
  case Bounds                  = "\u{F121}"
  case None                    = "\u{0000}"

  init(_ character:Character) { self = FontAwesomeIcon(rawValue: character) ?? .None }
  init(_ name: String) {
    switch name {
      case "space":                     self = .Space
      case "no-break-space":            self = .SpaceNoBreak
      case "dieresis":                  self = .Dieresis
      case "copyright":                 self = .Copyright
      case "registered":                self = .Registered
      case "acute":                     self = .Acute
      case "AE":                        self = .AE
      case "en-quad":                   self = .EnQuad
      case "em-quad":                   self = .EmQuad
      case "en-space":                  self = .EnSpace
      case "em-space":                  self = .EmSpace
      case "three-per-em-space":        self = .ThreePerEmSpace
      case "four-per-em-space":         self = .FourPerEmSpace
      case "six-per-em-space":          self = .SixPerEmSpace
      case "figure-space":              self = .FigureSpace
      case "punctuation-space":         self = .PunctuationSpace
      case "thin-space":                self = .ThinSpace
      case "hair-space":                self = .HairSpace
      case "narrow-no-break-space":     self = .NarrowNoBreakSpace
      case "medium-mathematical-space": self = .MediumMathematicalSpace
      case "trademark":                 self = .Trademark
      case "infinity":                  self = .Infinity
      case "notequal":                  self = .NotEqual
      case "uniE000":                   self = .UniE000
      case "glass":                     self = .Glass
      case "music":                     self = .Music
      case "search":                    self = .Search
      case "envelope":                  self = .Envelope
      case "heart":                     self = .Heart
      case "star":                      self = .Star
      case "star-empty":                self = .StarEmpty
      case "user":                      self = .User
      case "film":                      self = .Film
      case "th-large":                  self = .ThLarge
      case "th":                        self = .Th
      case "th-list":                   self = .ThList
      case "ok":                        self = .Ok
      case "remove":                    self = .Remove
      case "zoom-in":                   self = .ZoomIn
      case "zoom-out":                  self = .ZoomOut
      case "off":                       self = .Off
      case "signal":                    self = .Signal
      case "cog":                       self = .Cog
      case "trash":                     self = .Trash
      case "home":                      self = .Home
      case "file":                      self = .File
      case "time":                      self = .Time
      case "road":                      self = .Road
      case "download-alt":              self = .DownloadAlt
      case "download":                  self = .Download
      case "upload":                    self = .Upload
      case "inbox":                     self = .Inbox
      case "play-circle":               self = .PlayCircle
      case "repeat":                    self = .Repeat
      case "refresh":                   self = .Refresh
      case "list-alt":                  self = .ListAlt
      case "lock":                      self = .Lock
      case "flag":                      self = .Flag
      case "headphones":                self = .Headphones
      case "volume-off":                self = .VolumeOff
      case "volume-down":               self = .VolumeDown
      case "volume-up":                 self = .VolumeUp
      case "qrcode":                    self = .Qrcode
      case "barcode":                   self = .Barcode
      case "tag":                       self = .Tag
      case "tags":                      self = .Tags
      case "book":                      self = .Book
      case "bookmark":                  self = .Bookmark
      case "print":                     self = .Print
      case "camera":                    self = .Camera
      case "font":                      self = .Font
      case "bold":                      self = .Bold
      case "italic":                    self = .Italic
      case "text-height":               self = .TextHeight
      case "text-width":                self = .TextWidth
      case "align-left":                self = .AlignLeft
      case "align-center":              self = .AlignCenter
      case "align-right":               self = .AlignRight
      case "align-justify":             self = .AlignJustify
      case "list":                      self = .List
      case "indent-left":               self = .IndentLeft
      case "indent-right":              self = .IndentRight
      case "facetime-video":            self = .FacetimeVideo
      case "picture":                   self = .Picture
      case "pencil":                    self = .Pencil
      case "map-marker":                self = .MapMarker
      case "adjust":                    self = .Adjust
      case "tint":                      self = .Tint
      case "edit":                      self = .Edit
      case "share":                     self = .Share
      case "check":                     self = .Check
      case "move":                      self = .Move
      case "step-backward":             self = .StepBackward
      case "fast-backward":             self = .FastBackward
      case "backward":                  self = .Backward
      case "play":                      self = .Play
      case "pause":                     self = .Pause
      case "stop":                      self = .Stop
      case "forward":                   self = .Forward
      case "fast-forward":              self = .FastForward
      case "step-forward":              self = .StepForward
      case "eject":                     self = .Eject
      case "chevron-left":              self = .ChevronLeft
      case "chevron-right":             self = .ChevronRight
      case "plus-sign":                 self = .PlusSign
      case "minus-sign":                self = .MinusSign
      case "remove-sign":               self = .RemoveSign
      case "ok-sign":                   self = .OkSign
      case "question-sign":             self = .QuestionSign
      case "info-sign":                 self = .InfoSign
      case "screenshot":                self = .Screenshot
      case "remove-circle":             self = .RemoveCircle
      case "ok-circle":                 self = .OkCircle
      case "ban-circle":                self = .BanCircle
      case "arrow-left":                self = .ArrowLeft
      case "arrow-right":               self = .ArrowRight
      case "arrow-up":                  self = .ArrowUp
      case "arrow-down":                self = .ArrowDown
      case "share-alt":                 self = .ShareAlt
      case "resize-full":               self = .ResizeFull
      case "resize-small":              self = .ResizeSmall
      case "plus":                      self = .Plus
      case "minus":                     self = .Minus
      case "asterisk":                  self = .Asterisk
      case "exclamation-sign":          self = .ExclamationSign
      case "gift":                      self = .Gift
      case "leaf":                      self = .Leaf
      case "fire":                      self = .Fire
      case "eye-open":                  self = .EyeOpen
      case "eye-close":                 self = .EyeClose
      case "warning-sign":              self = .WarningSign
      case "plane":                     self = .Plane
      case "calendar":                  self = .Calendar
      case "random":                    self = .Random
      case "comment":                   self = .Comment
      case "magnet":                    self = .Magnet
      case "chevron-up":                self = .ChevronUp
      case "chevron-down":              self = .ChevronDown
      case "retweet":                   self = .Retweet
      case "shopping-cart":             self = .ShoppingCart
      case "folder-close":              self = .FolderClose
      case "folder-open":               self = .FolderOpen
      case "resize-vertical":           self = .ResizeVertical
      case "resize-horizontal":         self = .ResizeHorizontal
      case "bar-chart":                 self = .BarChart
      case "twitter-sign":              self = .TwitterSign
      case "facebook-sign":             self = .FacebookSign
      case "camera-retro":              self = .CameraRetro
      case "key":                       self = .Key
      case "cogs":                      self = .Cogs
      case "comments":                  self = .Comments
      case "thumbs-up":                 self = .ThumbsUp
      case "thumbs-down":               self = .ThumbsDown
      case "star-half":                 self = .StarHalf
      case "heart-empty":               self = .HeartEmpty
      case "signout":                   self = .Signout
      case "linkedin-sign":             self = .LinkedinSign
      case "pushpin":                   self = .Pushpin
      case "external-link":             self = .ExternalLink
      case "signin":                    self = .Signin
      case "trophy":                    self = .Trophy
      case "github-sign":               self = .GithubSign
      case "upload-alt":                self = .UploadAlt
      case "lemon":                     self = .Lemon
      case "phone":                     self = .Phone
      case "check-empty":               self = .CheckEmpty
      case "bookmark-empty":            self = .BookmarkEmpty
      case "phone-sign":                self = .PhoneSign
      case "twitter":                   self = .Twitter
      case "facebook":                  self = .Facebook
      case "github":                    self = .Github
      case "unlock":                    self = .Unlock
      case "credit-card":               self = .CreditCard
      case "rss":                       self = .Rss
      case "hdd":                       self = .Hdd
      case "bullhorn":                  self = .Bullhorn
      case "bell":                      self = .Bell
      case "certificate":               self = .Certificate
      case "hand-right":                self = .HandRight
      case "hand-left":                 self = .HandLeft
      case "hand-up":                   self = .HandUp
      case "hand-down":                 self = .HandDown
      case "circle-arrow-left":         self = .CircleArrowLeft
      case "circle-arrow-right":        self = .CircleArrowRight
      case "circle-arrow-up":           self = .CircleArrowUp
      case "circle-arrow-down":         self = .CircleArrowDown
      case "globe":                     self = .Globe
      case "wrench":                    self = .Wrench
      case "tasks":                     self = .Tasks
      case "filter":                    self = .Filter
      case "briefcase":                 self = .Briefcase
      case "fullscreen":                self = .Fullscreen
      case "group":                     self = .Group
      case "link":                      self = .Link
      case "cloud":                     self = .Cloud
      case "beaker":                    self = .Beaker
      case "cut":                       self = .Cut
      case "copy":                      self = .Copy
      case "paper-clip":                self = .PaperClip
      case "save":                      self = .Save
      case "sign-blank":                self = .SignBlank
      case "reorder":                   self = .Reorder
      case "ul":                        self = .Ul
      case "ol":                        self = .Ol
      case "strikethrough":             self = .Strikethrough
      case "underline":                 self = .Underline
      case "table":                     self = .Table
      case "magic":                     self = .Magic
      case "truck":                     self = .Truck
      case "pinterest":                 self = .Pinterest
      case "pinterest-sign":            self = .PinterestSign
      case "google-plus-sign":          self = .GooglePlusSign
      case "google-plus":               self = .GooglePlus
      case "money":                     self = .Money
      case "caret-down":                self = .CaretDown
      case "caret-up":                  self = .CaretUp
      case "caret-left":                self = .CaretLeft
      case "caret-right":               self = .CaretRight
      case "columns":                   self = .Columns
      case "sort":                      self = .Sort
      case "sort-down":                 self = .SortDown
      case "sort-up":                   self = .SortUp
      case "envelope-alt":              self = .EnvelopeAlt
      case "linkedin":                  self = .Linkedin
      case "undo":                      self = .Undo
      case "legal":                     self = .Legal
      case "dashboard":                 self = .Dashboard
      case "comment-alt":               self = .CommentAlt
      case "comments-alt":              self = .CommentsAlt
      case "bolt":                      self = .Bolt
      case "sitemap":                   self = .Sitemap
      case "umbrella":                  self = .Umbrella
      case "paste":                     self = .Paste
      case "light-bulb":                self = .LightBulb
      case "exchange":                  self = .Exchange
      case "cloud-download":            self = .CloudDownload
      case "cloud-upload":              self = .CloudUpload
      case "user-md":                   self = .UserMd
      case "stethoscope":               self = .Stethoscope
      case "suitcase":                  self = .Suitcase
      case "bell-alt":                  self = .BellAlt
      case "coffee":                    self = .Coffee
      case "food":                      self = .Food
      case "file-alt":                  self = .FileAlt
      case "building":                  self = .Building
      case "hospital":                  self = .Hospital
      case "ambulance":                 self = .Ambulance
      case "medkit":                    self = .Medkit
      case "fighter-jet":               self = .FighterJet
      case "beer":                      self = .Beer
      case "h-sign":                    self = .HSign
      case "f0fe":                      self = .F0fe
      case "double-angle-left":         self = .DoubleAngleLeft
      case "double-angle-right":        self = .DoubleAngleRight
      case "double-angle-up":           self = .DoubleAngleUp
      case "double-angle-down":         self = .DoubleAngleDown
      case "angle-left":                self = .AngleLeft
      case "angle-right":               self = .AngleRight
      case "angle-up":                  self = .AngleUp
      case "angle-down":                self = .AngleDown
      case "desktop":                   self = .Desktop
      case "laptop":                    self = .Laptop
      case "tablet":                    self = .Tablet
      case "mobile-phone":              self = .MobilePhone
      case "circle-blank":              self = .CircleBlank
      case "quote-left":                self = .QuoteLeft
      case "quote-right":               self = .QuoteRight
      case "spinner":                   self = .Spinner
      case "circle":                    self = .Circle
      case "reply":                     self = .Reply
      case "github-alt":                self = .GithubAlt
      case "folder-close-alt":          self = .FolderCloseAlt
      case "folder-open-alt":           self = .FolderOpenAlt
      case "align-edges":               self = .AlignEdges
      case "align-left-edges":          self = .AlignLeftEdges
      case "align-right-edges":         self = .AlignRightEdges
      case "align-top-edges":           self = .AlignTopEdges
      case "align-bottom-edges":        self = .AlignBottomEdges
      case "align-center-x":            self = .AlignCenterX
      case "align-center-y":            self = .AlignCenterY
      case "align-size":                self = .AlignSize
      case "align-vertical-size":       self = .AlignVerticalSize
      case "align-horizontal-size":     self = .AlignHorizontalSize
      case "align-size-exact":          self = .AlignSizeExact
      case "bounds":                    self = .Bounds
      default:                          self = .None
    }
  }

  var character: Character { return self.rawValue }
  var name: String {
    switch self {
      case .Space:                    return "space"
      case .SpaceNoBreak:             return "no-break-space"
      case .Dieresis:                 return "dieresis"
      case .Copyright:                return "copyright"
      case .Registered:               return "registered"
      case .Acute:                    return "acute"
      case .AE:                       return "AE"
      case .EnQuad:                   return "en-quad"
      case .EmQuad:                   return "em-quad"
      case .EnSpace:                  return "en-space"
      case .EmSpace:                  return "em-space"
      case .ThreePerEmSpace:          return "three-per-em-space"
      case .FourPerEmSpace:           return "four-per-em-space"
      case .SixPerEmSpace:            return "six-per-em-space"
      case .FigureSpace:              return "figure-space"
      case .PunctuationSpace:         return "punctuation-space"
      case .ThinSpace:                return "thin-space"
      case .HairSpace:                return "hair-space"
      case .NarrowNoBreakSpace:       return "narrow-no-break-space"
      case .MediumMathematicalSpace:  return "medium-mathematical-space"
      case .Trademark:                return "trademark"
      case .Infinity:                 return "infinity"
      case .NotEqual:                 return "notequal"
      case .UniE000:                  return "uniE000"
      case .Glass:                    return "glass"
      case .Music:                    return "music"
      case .Search:                   return "search"
      case .Envelope:                 return "envelope"
      case .Heart:                    return "heart"
      case .Star:                     return "star"
      case .StarEmpty:                return "star-empty"
      case .User:                     return "user"
      case .Film:                     return "film"
      case .ThLarge:                  return "th-large"
      case .Th:                       return "th"
      case .ThList:                   return "th-list"
      case .Ok:                       return "ok"
      case .Remove:                   return "remove"
      case .ZoomIn:                   return "zoom-in"
      case .ZoomOut:                  return "zoom-out"
      case .Off:                      return "off"
      case .Signal:                   return "signal"
      case .Cog:                      return "cog"
      case .Trash:                    return "trash"
      case .Home:                     return "home"
      case .File:                     return "file"
      case .Time:                     return "time"
      case .Road:                     return "road"
      case .DownloadAlt:              return "download-alt"
      case .Download:                 return "download"
      case .Upload:                   return "upload"
      case .Inbox:                    return "inbox"
      case .PlayCircle:               return "play-circle"
      case .Repeat:                   return "repeat"
      case .Refresh:                  return "refresh"
      case .ListAlt:                  return "list-alt"
      case .Lock:                     return "lock"
      case .Flag:                     return "flag"
      case .Headphones:               return "headphones"
      case .VolumeOff:                return "volume-off"
      case .VolumeDown:               return "volume-down"
      case .VolumeUp:                 return "volume-up"
      case .Qrcode:                   return "qrcode"
      case .Barcode:                  return "barcode"
      case .Tag:                      return "tag"
      case .Tags:                     return "tags"
      case .Book:                     return "book"
      case .Bookmark:                 return "bookmark"
      case .Print:                    return "print"
      case .Camera:                   return "camera"
      case .Font:                     return "font"
      case .Bold:                     return "bold"
      case .Italic:                   return "italic"
      case .TextHeight:               return "text-height"
      case .TextWidth:                return "text-width"
      case .AlignLeft:                return "align-left"
      case .AlignCenter:              return "align-center"
      case .AlignRight:               return "align-right"
      case .AlignJustify:             return "align-justify"
      case .List:                     return "list"
      case .IndentLeft:               return "indent-left"
      case .IndentRight:              return "indent-right"
      case .FacetimeVideo:            return "facetime-video"
      case .Picture:                  return "picture"
      case .Pencil:                   return "pencil"
      case .MapMarker:                return "map-marker"
      case .Adjust:                   return "adjust"
      case .Tint:                     return "tint"
      case .Edit:                     return "edit"
      case .Share:                    return "share"
      case .Check:                    return "check"
      case .Move:                     return "move"
      case .StepBackward:             return "step-backward"
      case .FastBackward:             return "fast-backward"
      case .Backward:                 return "backward"
      case .Play:                     return "play"
      case .Pause:                    return "pause"
      case .Stop:                     return "stop"
      case .Forward:                  return "forward"
      case .FastForward:              return "fast-forward"
      case .StepForward:              return "step-forward"
      case .Eject:                    return "eject"
      case .ChevronLeft:              return "chevron-left"
      case .ChevronRight:             return "chevron-right"
      case .PlusSign:                 return "plus-sign"
      case .MinusSign:                return "minus-sign"
      case .RemoveSign:               return "remove-sign"
      case .OkSign:                   return "ok-sign"
      case .QuestionSign:             return "question-sign"
      case .InfoSign:                 return "info-sign"
      case .Screenshot:               return "screenshot"
      case .RemoveCircle:             return "remove-circle"
      case .OkCircle:                 return "ok-circle"
      case .BanCircle:                return "ban-circle"
      case .ArrowLeft:                return "arrow-left"
      case .ArrowRight:               return "arrow-right"
      case .ArrowUp:                  return "arrow-up"
      case .ArrowDown:                return "arrow-down"
      case .ShareAlt:                 return "share-alt"
      case .ResizeFull:               return "resize-full"
      case .ResizeSmall:              return "resize-small"
      case .Plus:                     return "plus"
      case .Minus:                    return "minus"
      case .Asterisk:                 return "asterisk"
      case .ExclamationSign:          return "exclamation-sign"
      case .Gift:                     return "gift"
      case .Leaf:                     return "leaf"
      case .Fire:                     return "fire"
      case .EyeOpen:                  return "eye-open"
      case .EyeClose:                 return "eye-close"
      case .WarningSign:              return "warning-sign"
      case .Plane:                    return "plane"
      case .Calendar:                 return "calendar"
      case .Random:                   return "random"
      case .Comment:                  return "comment"
      case .Magnet:                   return "magnet"
      case .ChevronUp:                return "chevron-up"
      case .ChevronDown:              return "chevron-down"
      case .Retweet:                  return "retweet"
      case .ShoppingCart:             return "shopping-cart"
      case .FolderClose:              return "folder-close"
      case .FolderOpen:               return "folder-open"
      case .ResizeVertical:           return "resize-vertical"
      case .ResizeHorizontal:         return "resize-horizontal"
      case .BarChart:                 return "bar-chart"
      case .TwitterSign:              return "twitter-sign"
      case .FacebookSign:             return "facebook-sign"
      case .CameraRetro:              return "camera-retro"
      case .Key:                      return "key"
      case .Cogs:                     return "cogs"
      case .Comments:                 return "comments"
      case .ThumbsUp:                 return "thumbs-up"
      case .ThumbsDown:               return "thumbs-down"
      case .StarHalf:                 return "star-half"
      case .HeartEmpty:               return "heart-empty"
      case .Signout:                  return "signout"
      case .LinkedinSign:             return "linkedin-sign"
      case .Pushpin:                  return "pushpin"
      case .ExternalLink:             return "external-link"
      case .Signin:                   return "signin"
      case .Trophy:                   return "trophy"
      case .GithubSign:               return "github-sign"
      case .UploadAlt:                return "upload-alt"
      case .Lemon:                    return "lemon"
      case .Phone:                    return "phone"
      case .CheckEmpty:               return "check-empty"
      case .BookmarkEmpty:            return "bookmark-empty"
      case .PhoneSign:                return "phone-sign"
      case .Twitter:                  return "twitter"
      case .Facebook:                 return "facebook"
      case .Github:                   return "github"
      case .Unlock:                   return "unlock"
      case .CreditCard:               return "credit-card"
      case .Rss:                      return "rss"
      case .Hdd:                      return "hdd"
      case .Bullhorn:                 return "bullhorn"
      case .Bell:                     return "bell"
      case .Certificate:              return "certificate"
      case .HandRight:                return "hand-right"
      case .HandLeft:                 return "hand-left"
      case .HandUp:                   return "hand-up"
      case .HandDown:                 return "hand-down"
      case .CircleArrowLeft:          return "circle-arrow-left"
      case .CircleArrowRight:         return "circle-arrow-right"
      case .CircleArrowUp:            return "circle-arrow-up"
      case .CircleArrowDown:          return "circle-arrow-down"
      case .Globe:                    return "globe"
      case .Wrench:                   return "wrench"
      case .Tasks:                    return "tasks"
      case .Filter:                   return "filter"
      case .Briefcase:                return "briefcase"
      case .Fullscreen:               return "fullscreen"
      case .Group:                    return "group"
      case .Link:                     return "link"
      case .Cloud:                    return "cloud"
      case .Beaker:                   return "beaker"
      case .Cut:                      return "cut"
      case .Copy:                     return "copy"
      case .PaperClip:                return "paper-clip"
      case .Save:                     return "save"
      case .SignBlank:                return "sign-blank"
      case .Reorder:                  return "reorder"
      case .Ul:                       return "ul"
      case .Ol:                       return "ol"
      case .Strikethrough:            return "strikethrough"
      case .Underline:                return "underline"
      case .Table:                    return "table"
      case .Magic:                    return "magic"
      case .Truck:                    return "truck"
      case .Pinterest:                return "pinterest"
      case .PinterestSign:            return "pinterest-sign"
      case .GooglePlusSign:           return "google-plus-sign"
      case .GooglePlus:               return "google-plus"
      case .Money:                    return "money"
      case .CaretDown:                return "caret-down"
      case .CaretUp:                  return "caret-up"
      case .CaretLeft:                return "caret-left"
      case .CaretRight:               return "caret-right"
      case .Columns:                  return "columns"
      case .Sort:                     return "sort"
      case .SortDown:                 return "sort-down"
      case .SortUp:                   return "sort-up"
      case .EnvelopeAlt:              return "envelope-alt"
      case .Linkedin:                 return "linkedin"
      case .Undo:                     return "undo"
      case .Legal:                    return "legal"
      case .Dashboard:                return "dashboard"
      case .CommentAlt:               return "comment-alt"
      case .CommentsAlt:              return "comments-alt"
      case .Bolt:                     return "bolt"
      case .Sitemap:                  return "sitemap"
      case .Umbrella:                 return "umbrella"
      case .Paste:                    return "paste"
      case .LightBulb:                return "light-bulb"
      case .Exchange:                 return "exchange"
      case .CloudDownload:            return "cloud-download"
      case .CloudUpload:              return "cloud-upload"
      case .UserMd:                   return "user-md"
      case .Stethoscope:              return "stethoscope"
      case .Suitcase:                 return "suitcase"
      case .BellAlt:                  return "bell-alt"
      case .Coffee:                   return "coffee"
      case .Food:                     return "food"
      case .FileAlt:                  return "file-alt"
      case .Building:                 return "building"
      case .Hospital:                 return "hospital"
      case .Ambulance:                return "ambulance"
      case .Medkit:                   return "medkit"
      case .FighterJet:               return "fighter-jet"
      case .Beer:                     return "beer"
      case .HSign:                    return "h-sign"
      case .F0fe:                     return "f0fe"
      case .DoubleAngleLeft:          return "double-angle-left"
      case .DoubleAngleRight:         return "double-angle-right"
      case .DoubleAngleUp:            return "double-angle-up"
      case .DoubleAngleDown:          return "double-angle-down"
      case .AngleLeft:                return "angle-left"
      case .AngleRight:               return "angle-right"
      case .AngleUp:                  return "angle-up"
      case .AngleDown:                return "angle-down"
      case .Desktop:                  return "desktop"
      case .Laptop:                   return "laptop"
      case .Tablet:                   return "tablet"
      case .MobilePhone:              return "mobile-phone"
      case .CircleBlank:              return "circle-blank"
      case .QuoteLeft:                return "quote-left"
      case .QuoteRight:               return "quote-right"
      case .Spinner:                  return "spinner"
      case .Circle:                   return "circle"
      case .Reply:                    return "reply"
      case .GithubAlt:                return "github-alt"
      case .FolderCloseAlt:           return "folder-close-alt"
      case .FolderOpenAlt:            return "folder-open-alt"
      case .AlignEdges:               return "align-edges"
      case .AlignLeftEdges:           return "align-left-edges"
      case .AlignRightEdges:          return "align-right-edges"
      case .AlignTopEdges:            return "align-top-edges"
      case .AlignBottomEdges:         return "align-bottom-edges"
      case .AlignCenterX:             return "align-center-x"
      case .AlignCenterY:             return "align-center-y"
      case .AlignSize:                return "align-size"
      case .AlignVerticalSize:        return "align-vertical-size"
      case .AlignHorizontalSize:      return "align-horizontal-size"
      case .AlignSizeExact:           return "align-size-exact"
      case .Bounds:                   return "bounds"
      case .None:                     return ""
    }
  }

}

