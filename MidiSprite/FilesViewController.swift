//
//  FilesViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 10/24/14.
//  Copyright (c) 2014 Moondeer Studios. All rights reserved.
//

import Foundation
import UIKit
import MoonKit
import Eveleth

final class FilesViewController: UITableViewController {

  var didSelectFile: ((NSURL) -> Void)?
  var didDeleteFile: ((NSURL) -> Void)?

  private let constraintID = Identifier("FilesViewController", "Internal")
  private lazy var directoryMonitor: DirectoryMonitor = {
    do {
      return try DirectoryMonitor(directoryURL: documentsURL) { [unowned self] _ in self.refreshFiles() }
    } catch { logError(error); fatalError("failed to create monitor for documents directory: \(error)") }
  }()

  private var files: [NSURL] = [] {
    didSet {
      maxLabelSize = files.reduce(.zero) {
        [attributes = [NSFontAttributeName:UIFont.controlFont]] size, url in

        let urlSize = url.lastPathComponent!.sizeWithAttributes(attributes)
        return CGSize(width: max(size.width, urlSize.width), height: max(size.height, urlSize.height))
      }
      view.removeConstraints(view.constraintsWithIdentifier(constraintID))
      view.invalidateIntrinsicContentSize()
      tableView?.reloadData()
    }
  }

  private var maxLabelSize: CGSize = .zero { didSet { maxLabelSize.height += 10; tableView?.rowHeight = maxLabelSize.height } }

  /** refreshFiles */
  private func refreshFiles() {
    do { files = try documentsDirectoryContents().filter {$0.pathExtension == "mid" } } catch { logError(error) }
  }

  private var tableWidth: CGFloat { return maxLabelSize.width }
  private var tableHeight: CGFloat { return maxLabelSize.height * CGFloat(files.count) }

  /** loadView */
//  override func loadView() {
//    view = IntrinsicSizeDelegatingView(autolayout: true) {
//      [unowned self] _ in CGSize(width: self.tableWidth, height: self.tableHeight)
//    }
//    view.setContentHuggingPriority(1000, forAxis: .Horizontal)
//    view.setContentHuggingPriority(1000, forAxis: .Vertical)
//    view.setContentCompressionResistancePriority(1000, forAxis: .Horizontal)
//    view.setContentCompressionResistancePriority(1000, forAxis: .Vertical)
//    view.backgroundColor = .popoverBackgroundColor
//    view.opaque = true
//
//    let tableView = UITableView(frame: .zero, style: .Plain)
//    tableView.translatesAutoresizingMaskIntoConstraints = false
//    tableView.opaque = true
//    tableView.backgroundColor = .popoverBackgroundColor
//    tableView.rowHeight = 32
//    tableView.separatorStyle = .None
//    tableView.registerClass(Cell.self, forCellReuseIdentifier: "\(Cell.self)")
//    tableView.delegate = self
//    tableView.dataSource = self
//    view.addSubview(tableView)
//    self.tableView = tableView
//  }

//  override func updateViewConstraints() {
//    super.updateViewConstraints()
//    guard view.constraintsWithIdentifier(constraintID).count == 0, let tableView = tableView else { return }
//    view.constrain(
//      [ 𝗩|--10--tableView--10--|𝗩, 𝗛|--10--tableView--10--|𝗛,
//        [tableView.height => tableHeight, tableView.width => tableWidth] ] --> constraintID
//    )
//  }

  /**
  viewWillAppear:

  - parameter animated: Bool
  */
  override func viewWillAppear(animated: Bool) {
    super.viewWillAppear(animated)
    refreshFiles()
    tableView?.reloadData()
    directoryMonitor.startMonitoring()
  }

  /**
  viewWillDisappear:

  - parameter animated: Bool
  */
  override func viewWillDisappear(animated: Bool) {
    super.viewWillDisappear(animated)
    directoryMonitor.stopMonitoring()
  }

  /**
  numberOfSectionsInTableView:

  - parameter tableView: UITableView

  - returns: Int
  */
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int { return 1 }

  /**
  tableView:numberOfRowsInSection:

  - parameter tableView: UITableView
  - parameter section: Int

  - returns: Int
  */
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int { return files.count }

  /**
  tableView:cellForRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath

  - returns: UITableViewCell
  */
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath)
    let fileName = files[indexPath.row].lastPathComponent!
    cell.textLabel?.text = fileName[..<fileName.endIndex.advancedBy(-4)]
    return cell
  }

  /**
  tableView:didSelectRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter indexPath: NSIndexPath
  */
  override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
    didSelectFile?(files[indexPath.row])
  }

  /**
  tableView:canEditRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter canEditRowAtIndexPath: NSIndexPath

  - returns: Bool
  */
  override func tableView(tableView: UITableView, canEditRowAtIndexPath: NSIndexPath) -> Bool { return true }


  /**
  tableView:commitEditingStyle:forRowAtIndexPath:

  - parameter tableView: UITableView
  - parameter commitEditingStyle: UITableViewCellEditingStyle
  - parameter forRowAtIndexPath: NSIndexPath
  */
  override func tableView(tableView: UITableView,
       commitEditingStyle editingStyle: UITableViewCellEditingStyle,
        forRowAtIndexPath indexPath: NSIndexPath)
  {
    guard editingStyle == .Delete else { return }
    let url = files.removeAtIndex(indexPath.row)
    do {
      try NSFileManager.defaultManager().removeItemAtURL(url)
      didDeleteFile?(url)
    } catch {
      logError(error)
    }
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool { return true }

}

//@IBDesignable final class FilesCell: UITableViewCell {
//
//  @IBInspectable var wtf: Bool = false
//
//  override var textLabel: UILabel? {
//    guard let label = super.textLabel else { return nil }
//    label.translatesAutoresizingMaskIntoConstraints = false
//    label.backgroundColor = .popoverBackgroundColor
//    label.opaque = true
//    label.font = .controlFont
//    label.textColor = .controlColor
//    label.highlightedTextColor = .controlSelectedColor
//    return label
//  }
//
//  override var highlighted: Bool { didSet { textLabel?.highlighted = highlighted } }
//
//  /**
//  setHighlighted:animated:
//
//  - parameter highlighted: Bool
//  - parameter animated: Bool
//  */
//  override func setHighlighted(highlighted: Bool, animated: Bool) {
//    super.setHighlighted(highlighted, animated: animated)
//    textLabel?.highlighted = highlighted
//  }
//
//  /** setup */
//  private func setup() {
//    backgroundColor = .popoverBackgroundColor
//    contentView.backgroundColor = .redColor()
//    opaque = true
//    separatorInset = .zeroInsets
//    selectionStyle = .None
//  }
//  /**
//  initWithStyle:reuseIdentifier:
//
//  - parameter style: UITableViewCellStyle
//  - parameter reuseIdentifier: String?
//  */
//  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
//    super.init(style: style, reuseIdentifier: reuseIdentifier)
//    setup()
//  }
//
//  override func updateConstraints() {
//    super.updateConstraints()
//    let id = Identifier(self, "Internal")
//    guard constraintsWithIdentifier(id).count == 0, let textLabel = textLabel  else { return }
//    constrain([𝗩|textLabel|𝗩, 𝗛|textLabel|𝗛] --> id)
//  }
//
//  /**
//  init:
//
//  - parameter aDecoder: NSCoder
//  */
//  required init?(coder aDecoder: NSCoder) { super.init(coder: aDecoder); setup() }
//}
//
