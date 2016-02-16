//
//  DirectoryMonitor.swift
//  MoonKit
//
//  Created by Jason Cardwell on 8/31/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//  source: This a port of code created by Martin Hwasser found here https://github.com/hwaxxer/MHWDirectoryWatcher
//

import Foundation

public final class DirectoryMonitor {

  public typealias Callback = (added: [String], removed: [String]) -> Void
  public let callback: Callback
  public var callbackQueue = NSOperationQueue.mainQueue()
  public let directoryURL: NSURL
  public let directoryWrapper: NSFileWrapper

  public enum Error: String, ErrorType { case NotADirectory = "The URL provided must point to a directory" }

  private let queue = serialBackgroundQueue("com.moondeerstudios.directorymonitor")
  private var source: dispatch_source_t?
  private static let maxRetries = 5

  /**
  init:start:callback:

  - parameter url: NSURL
  - parameter start: Bool = false
  - parameter c: Callback? = nil
  */
  public init(directoryURL url: NSURL, start: Bool = false, callback c: Callback) throws {
    directoryURL = url
    callback = c

    do {
      directoryWrapper = try NSFileWrapper(URL: url, options: [.Immediate, .WithoutMapping])
      fileWrappers = directoryWrapper.fileWrappers
    } catch {
      directoryWrapper = NSFileWrapper()
      throw error
    }
    guard directoryWrapper.directory else { throw Error.NotADirectory }

    if start { startMonitoring() }
  }

  deinit { stopMonitoring() }

  /** startMonitoring */
  public func startMonitoring() {
    guard source == nil else { logWarning("already monitoring…"); return }
    let fd = open(directoryURL.fileSystemRepresentation, O_EVTONLY)
    guard fd >= 0 else { logError("failed to open '\(directoryURL)' for monitoring"); return }
    source = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE, UInt(fd), DISPATCH_VNODE_WRITE, globalBackgroundQueue)
    dispatch_source_set_event_handler(source!, directoryDidChange)
    dispatch_source_set_cancel_handler(source!, { close(fd) })
    dispatch_resume(source!)
  }

  /** stopWatching */
  public func stopMonitoring() {
    guard let source = source where dispatch_source_testcancel(source) == 0 else { return }
    dispatch_source_cancel(source)
    self.source = nil
  }

  private typealias FileHash = String
  private var isDirectoryChanging = false
  private var retryCount = 0

  private var fileWrappers: [String:NSFileWrapper]?

  /** invokeCallback */
  private func invokeCallback() {
    let added:   [String]
    let removed: [String]

    switch (fileWrappers?.values, directoryWrapper.fileWrappers?.values) {
    case let (oldWrappers?, newWrappers?):
      added = (Set(newWrappers) ∖ Set(oldWrappers)).flatMap({$0.preferredFilename})
      removed = (Set(oldWrappers) ∖ Set(newWrappers)).flatMap({$0.preferredFilename})
    case let (nil, newWrappers?):
      added = newWrappers.flatMap({$0.preferredFilename}); removed = []
    case let (oldWrappers?, nil):
      removed = oldWrappers.flatMap({$0.preferredFilename}); added = []
    case (nil, nil):
      added = []; removed = []
    }

    fileWrappers = directoryWrapper.fileWrappers
    callback(added: added, removed: removed)
  }

  /**
  generateDirectoryMetadata

  - returns: [FileHash]
  */
  private func directoryMetadata() throws -> [FileHash] {
    try directoryWrapper.readFromURL(directoryURL, options: [.Immediate, .WithoutMapping])
    return directoryWrapper.fileWrappers?.map({ "\($0)\($1.fileAttributes[NSFileSize]!)" }) ?? []
//
//    let keys = [NSURLPathKey, NSURLFileSizeKey]
//    let fm = NSFileManager.defaultManager()
//    let urls = try fm.contentsOfDirectoryAtURL(directoryURL, includingPropertiesForKeys: keys, options: [])
//    return try urls.map {
//      (url: NSURL) -> FileHash in
//
//      let values = try url.resourceValuesForKeys(keys).values.map {"\($0)"}
//      return values.joinWithSeparator("")
//    }
  }

  private var checkAfterDelay: ([FileHash]) -> Void {
    return { [unowned self] data in self.queue.after(0.2) { self.pollDirectory(metadata: data) } }
  }

  /**
  pollDirectory:

  - parameter metadata: [FileHash]
  */
  private func pollDirectory(metadata oldData: [FileHash]) {
    do {
      let newData = try directoryMetadata()
      isDirectoryChanging = !newData.elementsEqual(oldData)
      if isDirectoryChanging { retryCount = DirectoryMonitor.maxRetries }
      if isDirectoryChanging || 0 < retryCount { retryCount -= 1; checkAfterDelay(newData) }
      else { callbackQueue.addOperationWithBlock { [unowned self] in self.invokeCallback() } }
    } catch {
      logError(error)
    }
  }

  /** directoryDidChange */
  private func directoryDidChange() {
    guard !isDirectoryChanging else { return }
    do {
      let metadata = try directoryMetadata()
      isDirectoryChanging = true
      retryCount = DirectoryMonitor.maxRetries
      checkAfterDelay(metadata)
    } catch { logError(error) }
  }

}
