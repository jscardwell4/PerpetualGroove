//
//  SettingsManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/9/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit


enum Setting: String {
  case iCloudStorage
  case confirmDeleteDocument, confirmDeleteTrack
  case scrollTrackLabels
  case makeNewTrackCurrent
  case currentDocumentLocal, currentDocumentiCloud

  var value: Any? {
    get {
      switch self {
        case .currentDocumentLocal, .currentDocumentiCloud:
          return UserDefaults.standard.data(forKey: rawValue)
        default:
          return UserDefaults.standard.bool(forKey: rawValue)
      }
    }
    nonmutating set {
      switch self {
        case .currentDocumentLocal, .currentDocumentiCloud:
          UserDefaults.standard.set(newValue, forKey: rawValue)
        default:
          UserDefaults.standard.set(newValue as? Bool ?? false, forKey: rawValue)
      }
    }
  }

  var notificationName: SettingsManager.NotificationName {
    return SettingsManager.NotificationName(rawValue: "\(rawValue)Changed")!
  }

}

final class SettingsManager {

  private static var settingsCache: [Setting:Any] = [:]

  private(set) static var initialized = false {
    didSet {
      guard initialized else { return }
      Log.debug("Settings initialized with cached values:\n\(settingsCache.prettyDescription)")
      postNotification(name: .didInitializeSettings, object: self)
    }
  }

  /// Updates cached setting values that are out of sync and posts change notification.
  static fileprivate func updateCache() {

    let changedSettings: [Setting] = ([
      .iCloudStorage, .confirmDeleteDocument, .confirmDeleteTrack, .scrollTrackLabels,
      .makeNewTrackCurrent, .currentDocumentLocal, .currentDocumentiCloud
    ] as [Setting]).filter({
      switch $0 {
        case .currentDocumentiCloud, .currentDocumentLocal:
          return (settingsCache[$0] as? Data) != ($0.value as? Data)
        default:
          return (settingsCache[$0] as? Bool) != ($0.value as? Bool)
      }
    })

    guard changedSettings.count > 0 else {
      Log.debug("no changes detected")
      return
    }

    Log.debug("changed settings: \(changedSettings.map({$0.rawValue}))")

    for setting in changedSettings {

      settingsCache[setting] = setting.value

      Log.debug("posting notification for setting '\(setting.rawValue)'")

      postNotification(name: setting.notificationName, object: self)

    }

  }

  private static let receptionist = NotificationReceptionist()

  static func initialize() {

    guard !initialized else { return }

    UserDefaults.standard.register(defaults: [
      Setting.iCloudStorage.rawValue:         true,
      Setting.confirmDeleteDocument.rawValue: true,
      Setting.confirmDeleteTrack.rawValue:    true,
      Setting.scrollTrackLabels.rawValue:     true,
      Setting.makeNewTrackCurrent.rawValue:   true
    ])

    for setting in ([.iCloudStorage, .confirmDeleteTrack, .confirmDeleteDocument, .scrollTrackLabels,
                     .makeNewTrackCurrent, .currentDocumentLocal, .currentDocumentiCloud] as [Setting])
    {
      settingsCache[setting] = setting.value
    }

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
