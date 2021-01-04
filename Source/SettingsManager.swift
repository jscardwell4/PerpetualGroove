//
//  SettingsManager.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 10/9/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//
import Foundation
import MoonKit


/// Singleton class for managing the application's user-facing settings.
public final class SettingsManager {

  /// The shared singleton instance of `SettingsManager`.
  public static let shared = SettingsManager()

  /// A boolean value specifying whether documents should use iCloud.
  @Setting<Bool>(.iCloudStorage, true) public var iCloudStorage: Bool

  /// A boolean value specifying whether requests to delete a document should
  /// be confirmed via alert.
  @Setting<Bool>(.confirmDeleteDocument, true) public var confirmDeleteDocument: Bool

  /// A boolean value specifying whether requests to delete a track should be
  /// confirmed via alert.
  @Setting<Bool>(.confirmDeleteTrack, true) public var confirmDeleteTrack: Bool

  /// A boolean value specifiying whether the label for a track's name should
  /// continuously scroll its text when too long to fit within the width of the label.
  @Setting<Bool>(.scrollTrackLabels, true) public var scrollTrackLabels: Bool

  /// A boolean value specifying whether creating a new track should also set this
  /// new track as the current track for the sequence.
  @Setting<Bool>(.makeNewTrackCurrent, true) public var makeNewTrackCurrent: Bool

  /// Bookmark data for the most recently opened document from local storage.
  @Setting<Data?>(.currentDocumentLocal, nil) public var currentDocumentLocal: Data?

  /// Bookmark data for the most recently opened document from iCloud storage.
  @Setting<Data?>(.currentDocumentiCloud, nil) public var currentDocumentiCloud: Data?

  private init() {}

}

/// A structure for wrapping values stored in the application's `UserDefaults`.
@propertyWrapper
public struct Setting<Value> {

  /// The key for this setting. Also serves as the key for the setting's value
  /// in the standard `UserDefaults`.
  public let key: Key

  /// Initializing with a name and default value.
  /// - Parameters:
  ///   - key: The name of the setting.
  ///   - defaultValue: The default value to register with `UserDefaults`.
  init(_ key: Key, _ defaultValue: Value) {
    self.key = key
    UserDefaults.standard.register(defaults: [key.rawValue: defaultValue])
  }

  /// Accessor for the setting value stored in the standard `UserDefaults`.
  public var wrappedValue: Value {
    get {
      if  type(of: Value.self) == Bool.self {
        return UserDefaults.standard.bool(forKey: key.rawValue) as! Value
      } else if type(of: Value.self) == Optional<Data>.self {
        return UserDefaults.standard.data(forKey: key.rawValue) as! Value
      } else {
        fatalError("\(#fileID) \(#function) Unexpected data type.")
      }
    }
    set {
      UserDefaults.standard.set(newValue, forKey: key.rawValue)
    }
  }

  /// Enumeration of the names of the various settings stored by the application.
  public enum Key: String {
    
    /// A boolean value specifying whether documents should use iCloud.
    case iCloudStorage

    /// A boolean value specifying whether requests to delete a document should
    /// be confirmed via alert.
    case confirmDeleteDocument

    /// A boolean value specifying whether requests to delete a track should be
    /// confirmed via alert.
    case confirmDeleteTrack

    /// A boolean value specifiying whether the label for a track's name should
    /// continuously scroll its text when too long to fit within the width of the label.
    case scrollTrackLabels

    /// A boolean value specifying whether creating a new track should also set this
    /// new track as the current track for the sequence.
    case makeNewTrackCurrent

    /// Bookmark data for the most recently opened document from local storage.
    case currentDocumentLocal

    /// Bookmark data for the most recently opened document from iCloud storage.
    case currentDocumentiCloud

  }

}

/// Extend `UserDefaults` to make the settings KVO compliant.
extension UserDefaults {
  @objc dynamic var	iCloudStorage: Bool {
    bool(forKey: Setting<Bool>.Key.iCloudStorage.rawValue)
  }

  @objc dynamic var	confirmDeleteDocument: Bool {
    bool(forKey: Setting<Bool>.Key.confirmDeleteDocument.rawValue)
  }

  @objc dynamic var	confirmDeleteTrack: Bool {
    bool(forKey: Setting<Bool>.Key.confirmDeleteTrack.rawValue)
  }

  @objc dynamic var	scrollTrackLabels: Bool {
    bool(forKey: Setting<Bool>.Key.scrollTrackLabels.rawValue)
  }

  @objc dynamic var	makeNewTrackCurrent: Bool {
    bool(forKey: Setting<Bool>.Key.makeNewTrackCurrent.rawValue)
  }

  @objc dynamic var	currentDocumentLocal: Data? {
    data(forKey: Setting<Data?>.Key.currentDocumentLocal.rawValue)
  }

  @objc dynamic var	currentDocumentiCloud: Data? {
    data(forKey: Setting<Data?>.Key.currentDocumentiCloud.rawValue)
  }
}
