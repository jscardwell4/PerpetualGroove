//
//  SettingsManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/9/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit


final class SettingsManager {

  private static var settingsCache: [Setting:Any] = [:]
  private(set) static var initialized = false

  /** updateCache */
  static private func updateCache() {
    let changedSettings: [Setting] = Setting.allCases.filter {
      let currentValue = $0.currentValue
      let cachedValue = SettingsManager.settingsCache[$0]
      switch (currentValue, cachedValue) {
        case let (current?, previous?):
          if let currentNumber = current as? NSNumber, previousNumber = previous as? NSNumber {
            return currentNumber != previousNumber
          } else if let currentData = current as? NSData, previousData = previous as? NSData {
            return currentData != previousData
          } else {
            return false
          }
        case (.Some, .None), (.None, .Some): return true
        default: return false
      }
    }

    guard changedSettings.count > 0 else { return }

    logDebug("changed settings: \(changedSettings.map({$0.rawValue}))")

    for setting in changedSettings {
      Notification(setting).post()
      settingsCache[setting] = setting.currentValue
    }
  }

  /**
  userDefaultsDidChange:

  - parameter notification: NSNotification
  */
  private static func userDefaultsDidChange(notification: NSNotification) {
    logDebug("")
    updateCache()
  }

  /**
   willEnterForeground:

   - parameter notification: NSNotification
   */
  static private func willEnterForeground(notification: NSNotification) {
    logDebug("iCloudStorage: \(NSUserDefaults.standardUserDefaults().boolForKey("iCloudStorage"))")
    guard NSUserDefaults.standardUserDefaults().synchronize() else {
      logWarning("failed to synchronize user defaults")
      return
    }
    updateCache()
  }

  static var iCloudStorage: Bool {
    get { return (settingsCache[Setting.iCloudStorage] as? Bool) ?? Setting.iCloudStorage.defaultValue as? Bool == true }
    set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Setting.iCloudStorage.key) }
  }

  static var confirmDeleteDocument: Bool {
    get { return (settingsCache[Setting.ConfirmDeleteDocument] as? Bool) ?? Setting.ConfirmDeleteDocument.defaultValue as? Bool == true }
    set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Setting.ConfirmDeleteDocument.key) }
  }

  static var confirmDeleteTrack: Bool {
    get { return (settingsCache[Setting.ConfirmDeleteTrack] as? Bool) ?? Setting.ConfirmDeleteTrack.defaultValue as? Bool == true }
    set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Setting.ConfirmDeleteTrack.key) }
  }

  static var scrollTrackLabels: Bool {
    get { return (settingsCache[Setting.ScrollTrackLabels] as? Bool) ?? Setting.ScrollTrackLabels.defaultValue as? Bool == true }
    set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Setting.ScrollTrackLabels.key) }
  }

  static var currentDocument: NSData? {
    get { return settingsCache[Setting.CurrentDocument] as? NSData }
    set { NSUserDefaults.standardUserDefaults().setObject(newValue, forKey: Setting.CurrentDocument.key) }
  }

  static var makeNewTrackCurrent: Bool {
    get { return (settingsCache[Setting.MakeNewTrackCurrent] as? Bool) ?? Setting.MakeNewTrackCurrent.defaultValue as? Bool == true }
    set { NSUserDefaults.standardUserDefaults().setBool(newValue, forKey: Setting.MakeNewTrackCurrent.key) }
  }

  private static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()

    receptionist.observe(NSUserDefaultsDidChangeNotification,
                    from: NSUserDefaults.standardUserDefaults(),
                   queue: NSOperationQueue.mainQueue(),
                callback: SettingsManager.userDefaultsDidChange)

    receptionist.observe(UIApplicationWillEnterForegroundNotification,
                callback: SettingsManager.willEnterForeground)

    return receptionist
    }()

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    NSUserDefaults.standardUserDefaults().registerDefaults(Setting.boolSettings.reduce([String:AnyObject]()) {
      (var dict: [String:AnyObject], setting: Setting) in

      dict[setting.key] = setting.defaultValue as? AnyObject
      return dict

      })

    Setting.allCases.forEach { SettingsManager.settingsCache[$0] = $0.currentValue }

    let _ = receptionist

    initialized = true
  }
  
}

// MARK: - Notification
extension SettingsManager {

  struct Notification: NotificationType {

    enum Name: String, NotificationNameType {
      case iCloudStorageChanged
      case ConfirmDeleteDocumentChanged, ConfirmDeleteTrackChanged
      case ScrollTrackLabelsChanged
      case CurrentDocumentChanged
      case MakeNewTrackCurrentChanged
    }

    enum Key: String, KeyType { case SettingValue }

    var object: AnyObject? { return SettingsManager.self }
    let name: Name
    let userInfo: [Key:AnyObject?]?

    /**
    init:

    - parameter setting: Setting
    */
    init(_ setting: Setting) {
      userInfo = [.SettingValue: SettingsManager.settingsCache[setting] as? AnyObject]
      switch setting {
        case .iCloudStorage:         name = .iCloudStorageChanged
        case .ConfirmDeleteDocument: name = .ConfirmDeleteDocumentChanged
        case .ConfirmDeleteTrack:    name = .ConfirmDeleteTrackChanged
        case .ScrollTrackLabels:     name = .ScrollTrackLabelsChanged
        case .CurrentDocument:       name = .CurrentDocumentChanged
        case .MakeNewTrackCurrent:   name = .MakeNewTrackCurrentChanged
      }
    }

  }

}

extension NSNotification {
  typealias  Key = SettingsManager.Notification.Key
  var iCloudStorageSetting:         Bool?   { return (userInfo?[Key.SettingValue.key] as? NSNumber)?.boolValue }
  var confirmDeleteDocumentSetting: Bool?   { return (userInfo?[Key.SettingValue.key] as? NSNumber)?.boolValue }
  var confirmDeleteTrackSetting:    Bool?   { return (userInfo?[Key.SettingValue.key] as? NSNumber)?.boolValue }
  var scrollTrackLabelsSetting:     Bool?   { return (userInfo?[Key.SettingValue.key] as? NSNumber)?.boolValue }
  var makeNewTrackCurrentSetting:   Bool?   { return (userInfo?[Key.SettingValue.key] as? NSNumber)?.boolValue }
  var currentDocumentSetting:       NSData? { return  userInfo?[Key.SettingValue.key] as? NSData               }
}

// MARK: - Setting
extension SettingsManager {

  enum Setting: String, KeyType, EnumerableType {
    case iCloudStorage         = "iCloudStorage"
    case ConfirmDeleteDocument = "confirmDeleteDocument"
    case ConfirmDeleteTrack    = "confirmDeleteTrack"
    case ScrollTrackLabels     = "scrollTrackLabels"
    case CurrentDocument       = "currentDocument"
    case MakeNewTrackCurrent   = "makeNewTrackCurrent"

    var currentValue: Any? {
      guard let value = NSUserDefaults.standardUserDefaults().objectForKey(rawValue) else { return nil }

           if let number = value as? NSNumber { return number }
      else if let data   = value as? NSData   { return data   }
      else                                    { return nil    }
    }

    var defaultValue: Any? {
      switch self {
        case .iCloudStorage:         return true
        case .ConfirmDeleteDocument: return true
        case .ConfirmDeleteTrack:    return true
        case .ScrollTrackLabels:     return true
        case .CurrentDocument:       return nil
        case .MakeNewTrackCurrent:   return true
      }
    }

    static var boolSettings: [Setting] {
      return [.iCloudStorage, .ConfirmDeleteDocument, .ConfirmDeleteTrack, .ScrollTrackLabels, .MakeNewTrackCurrent]
    }
    static var allCases: [Setting] { return boolSettings + [.CurrentDocument] }
  }

}