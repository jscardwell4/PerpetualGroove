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

  fileprivate static let defaults = UserDefaults.standard

  fileprivate static var settingsCache: [Setting:Any] = [:]
  fileprivate(set) static var initialized = false {
    didSet {
      guard initialized else { return }
      postNotification(name: NotificationName(nil), object: self, userInfo: nil)
    }
  }

  /** updateCache */
  static fileprivate func updateCache() {
    logDebug("")
    let changedSettings: [Setting] = Setting.allCases.filter {
      switch ($0.currentValue, $0.cachedValue) {
        case let (current as NSNumber, previous as NSNumber) where current != previous: return true
        case let (current as Data, previous as Data)     where current != previous: return true
        case (.some, .none), (.none, .some):                                            return true
        default:                                                                        return false
      }
    }

    guard changedSettings.count > 0 else { logDebug("no changes detected"); return }

    logDebug("changed settings: \(changedSettings.map({$0.rawValue}))")

    for setting in changedSettings {
      let settingValue = setting.currentValue
      settingsCache[setting] = settingValue
      logDebug("posting notification for setting '\(setting.rawValue)'")
      postNotification(name: NotificationName(setting), object: self, userInfo: ["settingValue": settingValue ?? NSNull()])
    }
  }

  static var iCloudStorage: Bool {
    get { 
      if let cachedValue = Setting.iCloudStorage.cachedValue as? Bool {
         assert(Setting.iCloudStorage.currentValue as? Bool == cachedValue,
                "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.iCloudStorage.defaultValue as? Bool else {
          fatalError("unable to retrieve default value for 'iCloudStorage'")
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.iCloudStorage.key) }
  }

  static var confirmDeleteDocument: Bool {
    get { 
      if let cachedValue = Setting.confirmDeleteDocument.cachedValue as? Bool {
         assert(Setting.confirmDeleteDocument.currentValue as? Bool == cachedValue,
                "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.confirmDeleteDocument.defaultValue as? Bool else {
          fatalError("unable to retrieve default value for 'ConfirmDeleteDocument'")
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.confirmDeleteDocument.key) }
  }

  static var confirmDeleteTrack: Bool {
    get { 
      if let cachedValue = Setting.confirmDeleteTrack.cachedValue as? Bool {
         assert(Setting.confirmDeleteTrack.currentValue as? Bool == cachedValue,
                "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.confirmDeleteTrack.defaultValue as? Bool else {
          fatalError("unable to retrieve default value for 'ConfirmDeleteTrack'")
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.confirmDeleteTrack.key) }
  }

  static var scrollTrackLabels: Bool {
    get { 
      if let cachedValue = Setting.scrollTrackLabels.cachedValue as? Bool {
         assert(Setting.scrollTrackLabels.currentValue as? Bool == cachedValue,
                "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.scrollTrackLabels.defaultValue as? Bool else {
          fatalError("unable to retrieve default value for 'ScrollTrackLabels'")
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.scrollTrackLabels.key) }
  }

  static var currentDocumentLocal: Data? {
    get { 
      if let cachedValue = Setting.currentDocumentLocal.cachedValue as? Data {
         assert(Setting.currentDocumentLocal.currentValue as? Data == cachedValue,
               "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.currentDocumentLocal.defaultValue as? Data else { return nil }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.currentDocumentLocal.key) }
  }

  static var currentDocumentiCloud: Data? {
    get {
      if let cachedValue = Setting.currentDocumentiCloud.cachedValue as? Data {
        assert(Setting.currentDocumentiCloud.currentValue as? Data == cachedValue,
              "cached value is not up to date")
        return cachedValue
      } else {
        guard let defaultValue = Setting.currentDocumentiCloud.defaultValue as? Data else {
          return nil
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.currentDocumentiCloud.key) }
  }

  static var makeNewTrackCurrent: Bool {
    get { 
      if let cachedValue = Setting.makeNewTrackCurrent.cachedValue as? Bool {
         assert(Setting.makeNewTrackCurrent.currentValue as? Bool == cachedValue,
                "cached value is not up to date")
         return cachedValue
      } else {
        guard let defaultValue = Setting.makeNewTrackCurrent.defaultValue as? Bool else {
          fatalError("unable to retrieve default value for 'MakeNewTrackCurrent'")
        }
        return defaultValue
      }
    }
    set { logDebug(""); defaults.set(newValue, forKey: Setting.makeNewTrackCurrent.key) }
  }

  fileprivate static let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist()

    receptionist.observe(name: UserDefaults.didChangeNotification.rawValue,
                    from: defaults,
                   queue: OperationQueue.main)
    {
      _ in

      logDebug("observed notification that user defaults have changed")
      SettingsManager.updateCache()
    }

    return receptionist
    }()

  /** initialize */
  static func initialize() {
    guard !initialized else { return }

    defaults.register(defaults: Setting.boolSettings.reduce([String:Any]()) {
      (dict: [String:Any], setting: Setting) in
      var dict = dict
      dict[setting.key] = setting.defaultValue// as? AnyObject
      return dict

      })

    Setting.allCases.forEach { SettingsManager.settingsCache[$0] = $0.currentValue }

    _ = receptionist

    initialized = true
  }
  
}

// MARK: - Notification
extension SettingsManager: NotificationDispatching {

  enum NotificationName: String, LosslessStringConvertible {

    case iCloudStorageChanged
    case confirmDeleteDocumentChanged, confirmDeleteTrackChanged
    case scrollTrackLabelsChanged
    case currentDocumentLocalChanged, currentDocumentiCloudChanged
    case makeNewTrackCurrentChanged
    case didInitializeSettings

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }

    var setting: Setting? {
      switch self {
        case .iCloudStorageChanged:         return .iCloudStorage
        case .confirmDeleteDocumentChanged: return .confirmDeleteDocument
        case .confirmDeleteTrackChanged:    return .confirmDeleteTrack
        case .scrollTrackLabelsChanged:     return .scrollTrackLabels
        case .currentDocumentLocalChanged:  return .currentDocumentLocal
        case .currentDocumentiCloudChanged: return .currentDocumentiCloud
        case .makeNewTrackCurrentChanged:   return .makeNewTrackCurrent
        case .didInitializeSettings:        return nil
      }
    }

    fileprivate init(_ setting: Setting?) {
      guard let setting = setting  else { self = .didInitializeSettings; return }
      switch setting {
        case .iCloudStorage:         self = .iCloudStorageChanged
        case .confirmDeleteDocument: self = .confirmDeleteDocumentChanged
        case .confirmDeleteTrack:    self = .confirmDeleteTrackChanged
        case .scrollTrackLabels:     self = .scrollTrackLabelsChanged
        case .currentDocumentLocal:  self = .currentDocumentLocalChanged
        case .currentDocumentiCloud: self = .currentDocumentiCloudChanged
        case .makeNewTrackCurrent:   self = .makeNewTrackCurrentChanged
      }
    }

  }

}

extension Notification {
  var iCloudStorageSetting: Bool? {
    return (userInfo?["settingValue"] as? NSNumber)?.boolValue
  }
  var confirmDeleteDocumentSetting: Bool? {
    return (userInfo?["settingValue"] as? NSNumber)?.boolValue
  }
  var confirmDeleteTrackSetting: Bool? {
    return (userInfo?["settingValue"] as? NSNumber)?.boolValue
  }
  var scrollTrackLabelsSetting: Bool? {
    return (userInfo?["settingValue"] as? NSNumber)?.boolValue
  }
  var makeNewTrackCurrentSetting: Bool? {
    return (userInfo?["settingValue"] as? NSNumber)?.boolValue
  }
  var currentDocumentSetting: Data? {
    return  userInfo?["settingValue"] as? Data
  }
}

// MARK: - Setting
extension SettingsManager {

  enum Setting: String, KeyType, EnumerableType {
    case iCloudStorage
    case confirmDeleteDocument, confirmDeleteTrack
    case scrollTrackLabels
    case currentDocumentLocal, currentDocumentiCloud
    case makeNewTrackCurrent

    var currentValue: Any? {
      guard let value = defaults.object(forKey: rawValue) else { return nil }

           if let number = value as? NSNumber { return number }
      else if let data   = value as? Data     { return data   }
      else                                    { return nil    }
    }

    var cachedValue: Any? { return SettingsManager.settingsCache[self] }

    var defaultValue: Any? {
      switch self {
        case .currentDocumentLocal, .currentDocumentiCloud: return nil
        case .iCloudStorage, .confirmDeleteDocument, .confirmDeleteTrack,
             .scrollTrackLabels, .makeNewTrackCurrent: return true
      }
    }

    static var boolSettings: [Setting] {
      return [.iCloudStorage, .confirmDeleteDocument, .confirmDeleteTrack,
              .scrollTrackLabels, .makeNewTrackCurrent]
    }
    static var allCases: [Setting] {
      return boolSettings + [.currentDocumentLocal, .currentDocumentiCloud]
    }
  }

}
