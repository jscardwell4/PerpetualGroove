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

  fileprivate static let _iCloudStorage         = Setting<Bool>(name: "iCloudStorage",         defaultValue: true)
  fileprivate static let _confirmDeleteDocument = Setting<Bool>(name: "confirmDeleteDocument", defaultValue: true)
  fileprivate static let _confirmDeleteTrack    = Setting<Bool>(name: "confirmDeleteTrack",    defaultValue: true)
  fileprivate static let _scrollTrackLabels     = Setting<Bool>(name: "scrollTrackLabels",     defaultValue: true)
  fileprivate static let _makeNewTrackCurrent   = Setting<Bool>(name: "makeNewTrackCurrent",   defaultValue: true)

  fileprivate static let _currentDocumentLocal  = Setting<Data>(name: "currentDocumentLocal",  defaultValue: nil)
  fileprivate static let _currentDocumentiCloud = Setting<Data>(name: "currentDocumentiCloud", defaultValue: nil)



  fileprivate static var settingsCache: [String:Any] = [:]

  fileprivate(set) static var initialized = false {
    didSet {
      guard initialized else { return }
      postNotification(name: .didInitializeSettings, object: self, userInfo: nil)
    }
  }

  static fileprivate func updateCache() {
    let changedSettings: [SettingProtocol] = ([
    _iCloudStorage,
    _confirmDeleteDocument,
    _confirmDeleteTrack,
    _scrollTrackLabels,
    _makeNewTrackCurrent,
    _currentDocumentLocal,
    _currentDocumentiCloud] as [SettingProtocol]).filter {$0.needsUpdateCachedValue }

    guard changedSettings.count > 0 else {
      Log.debug("no changes detected")
      return
    }

    Log.debug("changed settings: \(changedSettings.map({$0.name}))")

    var settingValue: Any?

    for setting in changedSettings {
      switch setting.name {
        case "iCloudStorage":
          _iCloudStorage.cachedValue = _iCloudStorage.storedValue
          settingValue = _iCloudStorage.cachedValue
        case "confirmDeleteDocument":
          _confirmDeleteDocument.cachedValue = _confirmDeleteDocument.storedValue
          settingValue = _confirmDeleteDocument.cachedValue
        case "confirmDeleteTrack":
          _confirmDeleteTrack.cachedValue = _confirmDeleteTrack.storedValue
          settingValue = _confirmDeleteTrack.cachedValue
        case "scrollTrackLabels":
          _scrollTrackLabels.cachedValue = _scrollTrackLabels.storedValue
          settingValue = _scrollTrackLabels.cachedValue
        case "makeNewTrackCurrent":
          _makeNewTrackCurrent.cachedValue = _makeNewTrackCurrent.storedValue
          settingValue = _makeNewTrackCurrent.cachedValue
        case "currentDocumentLocal":
          _currentDocumentLocal.cachedValue = _currentDocumentLocal.storedValue
          settingValue = _currentDocumentLocal.cachedValue
        case "currentDocumentiCloud":
          _currentDocumentiCloud.cachedValue = _currentDocumentiCloud.storedValue
          settingValue = _currentDocumentiCloud.cachedValue
        default: unreachable()
      }

      Log.debug("posting notification for setting '\(setting.name)'")
      postNotification(name: NotificationName(rawValue: setting.name + "Changed")!,
                       object: self,
                       userInfo: ["settingValue": settingValue ?? NSNull()])
    }

  }

  private static func value(for setting: Setting<Bool>) -> Bool {
    guard let value = setting.cachedValue else {
      if let value = setting.storedValue {
        setting.cachedValue = value
        return value
      } else if let value = setting.defaultValue {
        setting.cachedValue = value
        return value
      } else {
        setting.cachedValue = false
        return false
      }
    }
    return value
  }

  private static func value(for setting: Setting<Data>) -> Data? {
    guard let value = setting.cachedValue else {
      if let value = setting.storedValue {
        setting.cachedValue = value
        return value
      } else if let value = setting.defaultValue {
        setting.cachedValue = value
        return value
      } else {
        return nil
      }
    }
    return value
  }

  static var iCloudStorage: Bool {
    get { return value(for: _iCloudStorage) }
    set { _iCloudStorage.storedValue = newValue }
  }

  static var confirmDeleteDocument: Bool {
    get { return value(for: _confirmDeleteDocument) }
    set { _confirmDeleteDocument.storedValue = newValue }
  }

  static var confirmDeleteTrack: Bool {
    get { return value(for: _confirmDeleteTrack) }
    set { _confirmDeleteTrack.storedValue = newValue }
  }

  static var scrollTrackLabels: Bool {
    get { return value(for: _scrollTrackLabels) }
    set { _scrollTrackLabels.storedValue = newValue }
  }

  static var makeNewTrackCurrent: Bool {
    get { return value(for: _makeNewTrackCurrent) }
    set { _makeNewTrackCurrent.storedValue = newValue }
  }

  static var currentDocumentLocal: Data? {
    get { return value(for: _currentDocumentLocal) }
    set { _currentDocumentLocal.storedValue = newValue }
  }

  static var currentDocumentiCloud: Data? {
    get { return value(for: _currentDocumentiCloud) }
    set { _currentDocumentiCloud.storedValue = newValue }
  }

  private static let receptionist = NotificationReceptionist()

  static func initialize() {

    guard !initialized else { return }

    UserDefaults.standard.register(defaults:
      [
      _iCloudStorage.name:         _iCloudStorage.defaultValue ?? false,
      _confirmDeleteDocument.name: _confirmDeleteDocument.defaultValue ?? false,
      _confirmDeleteTrack.name:    _confirmDeleteTrack.defaultValue ?? false,
      _scrollTrackLabels.name:     _scrollTrackLabels.defaultValue ?? false,
      _makeNewTrackCurrent.name:   _makeNewTrackCurrent.defaultValue ?? false
      ]
    )

    _iCloudStorage.cachedValue         = _iCloudStorage.storedValue
    _confirmDeleteDocument.cachedValue = _confirmDeleteDocument.storedValue
    _confirmDeleteTrack.cachedValue    = _confirmDeleteTrack.storedValue
    _scrollTrackLabels.cachedValue     = _scrollTrackLabels.storedValue
    _makeNewTrackCurrent.cachedValue   = _makeNewTrackCurrent.storedValue
    _currentDocumentLocal.cachedValue  = _currentDocumentLocal.storedValue
    _currentDocumentiCloud.cachedValue = _currentDocumentiCloud.storedValue

    receptionist.observe(name: UserDefaults.didChangeNotification.rawValue,
                         from: UserDefaults.standard,
                         queue: OperationQueue.main)
    {
      _ in

      Log.debug("observed notification that user defaults have changed")
      SettingsManager.updateCache()
    }

    initialized = true
  }
  
}

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

  }

}

extension Notification {

  var iCloudStorageSetting:         Bool? { return userInfo?["settingValue"] as? Bool }
  var confirmDeleteDocumentSetting: Bool? { return userInfo?["settingValue"] as? Bool }
  var confirmDeleteTrackSetting:    Bool? { return userInfo?["settingValue"] as? Bool }
  var scrollTrackLabelsSetting:     Bool? { return userInfo?["settingValue"] as? Bool }
  var makeNewTrackCurrentSetting:   Bool? { return userInfo?["settingValue"] as? Bool }
  var currentDocumentSetting:       Data? { return userInfo?["settingValue"] as? Data }

}

fileprivate protocol SettingProtocol {

  var name: String { get }

}

extension SettingProtocol {
  fileprivate var needsUpdateCachedValue: Bool {
    switch (SettingsManager.settingsCache[name], UserDefaults.standard.object(forKey: name)) {
      case let (v1 as Bool, v2 as Bool) where v1 != v2: return true
      case let (v1 as Data, v2 as Data) where v1 != v2: return true
      case (.some, nil), (nil, .some):                  return true
      default:                                          return false
    }
  }
}

fileprivate struct Setting<Value>: SettingProtocol {

  let name: String
  let defaultValue: Value?

  var cachedValue: Value? {
    get { return SettingsManager.settingsCache[name] as? Value }
    nonmutating set { SettingsManager.settingsCache[name] = newValue }
  }

  var storedValue: Value? {
    get { return UserDefaults.standard.object(forKey: name) as? Value }
    nonmutating set { UserDefaults.standard.set(newValue, forKey: name) }
  }

}
