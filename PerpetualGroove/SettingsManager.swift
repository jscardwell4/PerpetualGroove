//
//  SettingsManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/9/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import Foundation
import MoonKit

/// Enumeration of the various settings stored by the application.
enum Setting: String {

  /// A boolean value specifying whether documents should use iCloud.
  case iCloudStorage

  /// A boolean value specifying whether requests to delete a document should be confirmed via alert.
  case confirmDeleteDocument

  /// A boolean value specifying whether requests to delete a track should be confirmed via alert.
  case confirmDeleteTrack

  /// A boolean value specifiying whether the label for a track's name should continuously scroll its
  /// text when too long to fit within the width of the label.
  case scrollTrackLabels

  /// A boolean value specifying whether creating a new track should also set this new track as the current
  /// track for the sequence.
  case makeNewTrackCurrent

  /// Bookmark data for the most recently opened document from local storage.
  case currentDocumentLocal

  /// Bookmark data for the most recently opened document from iCloud storage.
  case currentDocumentiCloud

  /// The value contained by the standard user defaults for the setting.
  ///
  /// For a boolean setting:
  /// * The getter returns `true` when the setting value is `true` and `false` otherwise.
  /// * The setter stores `true` when the new value is `true` and `false` otherwise.
  ///
  /// For an optional data setting:
  /// * The getter returns the setting value `as? Data`.
  /// * The setter stores the new value when `newValue is Data` and nullifies the setting value otherwise.
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
          UserDefaults.standard.set(newValue as? Data, forKey: rawValue)

        default:
          UserDefaults.standard.set(newValue as? Bool ?? false, forKey: rawValue)

      }

    }

  }

  /// The name used for posting notifications when the setting has changed.
  var notificationName: SettingsManager.NotificationName {
    return SettingsManager.NotificationName(rawValue: "\(rawValue)Changed")!
  }

}

/// Singleton class for managing the application's user-facing settings.
final class SettingsManager: NotificationDispatching {

  /// Cache of setting values for use when determining whether a setting's value has changed.
  private static var settingsCache: [Setting:Any] = [:]

  /// Flag indicating whether `initialize()` has been invoked. A notification is posted when this
  /// property's value is set to `true`.
  private(set) static var isInitialized = false {
    didSet {
      guard isInitialized else { return }
      Log.debug("Settings initialized with cached values:\n\(settingsCache.prettyDescription)")
      postNotification(name: .didInitializeSettings, object: self)
    }
  }

  /// Updates cached setting values that are out of sync and posts change notifications.
  static private func updateCache() {

    // Generate a collection of settings with a value that differs from the cached value.
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

    // Check that at least one setting value has changed.
    guard changedSettings.count > 0 else {
      Log.debug("no changes detected")
      return
    }

    Log.debug("changed settings: \(changedSettings.map({$0.rawValue}))")

    // Update the cached value and post a notification for each setting that has changed.
    for setting in changedSettings {

      settingsCache[setting] = setting.value

      Log.debug("posting notification for setting '\(setting.rawValue)'")

      postNotification(name: setting.notificationName, object: self)

    }

  }

  /// Handles registration and reception of notifications from the standard user defaults.
  private static let receptionist = NotificationReceptionist()

  /// Registers defaults for the boolean settings with the standard user defaults, caches the current
  /// value for all settings, and registers to receive the `didChangeNotification` from the standard
  /// user defaults.
  /// - Requires: `isInitialized == false`.
  static func initialize() {

    // Check that this is the first invocation.
    guard !isInitialized else { return }

    // Register default values.
    UserDefaults.standard.register(defaults: [
      Setting.iCloudStorage.rawValue:         true,
      Setting.confirmDeleteDocument.rawValue: true,
      Setting.confirmDeleteTrack.rawValue:    true,
      Setting.scrollTrackLabels.rawValue:     true,
      Setting.makeNewTrackCurrent.rawValue:   true
    ])

    // Cache current values.
    for setting in ([.iCloudStorage, .confirmDeleteTrack, .confirmDeleteDocument, .scrollTrackLabels,
                     .makeNewTrackCurrent, .currentDocumentLocal, .currentDocumentiCloud] as [Setting])
    {
      settingsCache[setting] = setting.value
    }

    // Observe changes to the standard user defaults.
    receptionist.observe(name: UserDefaults.didChangeNotification.rawValue,
                         from: UserDefaults.standard,
                         queue: OperationQueue.main)
    {
      _ in

      Log.debug("observed notification that user defaults have changed")
      SettingsManager.updateCache()
    }

    // Update the flag.
    isInitialized = true
    
  }
  
  /// An enumeration of the names of notifications posted by `SettingsManager`.
  enum NotificationName: String, LosslessStringConvertible {

    /// Posted when the value of `Setting.iCloudStorage` has changed.
    case iCloudStorageChanged

    /// Posted when the value of `Setting.confirmDeleteDocument` has changed.
    case confirmDeleteDocumentChanged

    /// Posted when the value of `Setting.confirmDeleteTrack` has changed.
    case confirmDeleteTrackChanged

    /// Posted when the value of `Setting.scrollTrackLabels` has changed.
    case scrollTrackLabelsChanged

    /// Posted when the value of `Setting.currentDocumentLocal` has changed.
    case currentDocumentLocalChanged

    /// Posted when the value of `Setting.currentDocumentiCloud` has changed.
    case currentDocumentiCloudChanged

    /// Posted when the value of `Setting.makeNewTrackCurrent` has changed.
    case makeNewTrackCurrentChanged

    /// Posted when the value of `SettingsManager.isInitialized` has been set to `true`.
    case didInitializeSettings

    var description: String { return rawValue }
    init?(_ description: String) { self.init(rawValue: description) }

  }

}
