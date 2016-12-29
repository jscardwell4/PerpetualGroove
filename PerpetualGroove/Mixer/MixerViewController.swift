//
//  MixerViewController.swift
//  PerpetualGroove
//
//  Created by Jason Cardwell on 8/15/15.
//  Copyright © 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import MoonKit

// TODO: Review file
import typealias AudioUnit.AudioUnitElement

final class MixerViewController: UICollectionViewController, SecondaryControllerContentProvider {

  @IBOutlet private var magnifyingGesture: UILongPressGestureRecognizer!

  private let receptionist: NotificationReceptionist = {
    let receptionist = NotificationReceptionist(callbackQueue: OperationQueue.main)
    receptionist.logContext = LogManager.UIContext
    return receptionist
  }()

  private var widthConstraint: NSLayoutConstraint?
  private var heightConstraint: NSLayoutConstraint?

  override var collectionViewLayout: MixerLayout { return super.collectionViewLayout as! MixerLayout }

  fileprivate weak var sequence: Sequence? {
    didSet {
      guard oldValue !== sequence else { return }
      if let oldSequence = oldValue { stopObservingSequence(oldSequence) }
      if let sequence = sequence { observeSequence(sequence) }
      collectionView?.reloadData()
      if let idx = sequence?.currentTrackIndex { selectTrack(at: idx) }
    }
  }

  private func observeSequence(_ sequence: Sequence) {
    receptionist.observe(name: .didChangeTrack, from: sequence) {
      [weak self] _ in
        guard let idx = self?.sequence?.currentTrack?.index else { return }
        self?.selectTrack(at: idx)
    }
    receptionist.observe(name: .didAddTrack, from: sequence,
                         callback: weakMethod(self, MixerViewController.updateTracks))
    receptionist.observe(name: .didRemoveTrack, from: sequence,
                callback: weakMethod(self, MixerViewController.updateTracks))
  }

  private func stopObservingSequence(_ sequence: Sequence) {
    receptionist.stopObserving(name: .didChangeTrack, from: sequence)
    receptionist.stopObserving(name: .didAddTrack,    from: sequence)
    receptionist.stopObserving(name: .didRemoveTrack, from: sequence)
  }

  fileprivate var pendingTrackIndex: Int?
  fileprivate var addedTrackIndex: IndexPath?

  @IBAction func addTrack() {
    do {
      pendingTrackIndex = Section.instruments.itemCount
      let instrument = try Instrument(track: nil, preset: Sequencer.auditionInstrument.preset)
      try sequence?.insertTrack(instrument: instrument)
    } catch {
      Log.error(error, message: "Failed to add new track")
      pendingTrackIndex = nil
    }
  }

  private func indexPath(for sender: AnyObject) -> IndexPath? {
    switch sender {
      case let view as UIView:
        return collectionView?.indexPathForItem(at: collectionView!.convert(view.center, from: view.superview))
      case let gesture as UILongPressGestureRecognizer:
        return collectionView?.indexPathForItem(at: gesture.location(in: gesture.view))
      default:
        return nil
    }
  }

  /// Invoked when a `TrackCell` has had its `trackColor` button tapped
  @IBAction func selectItem(_ sender: ImageButtonView) {
    sequence?.currentTrackIndex = indexPath(for: sender)?.item
  }

  private var magnifiedCellLocation: CGPoint?
  private var markedForRemoval = false {
    didSet {
      guard markedForRemoval != oldValue,
        let item = collectionViewLayout.magnifiedItem,
            let cell = collectionView?.cellForItem(at: item as IndexPath) as? TrackCell else { return }
      UIView.animate(withDuration: 0.25, animations: {
        [weak cell = cell, marked = markedForRemoval] in cell?.removalDisplay.isHidden = !marked
      }) 
    }
  }

  @IBAction private func magnifyItem(_ sender: UILongPressGestureRecognizer) {

    switch sender.state {
      case .began:
        guard let indexPath = indexPath(for: sender), Section.instruments.contains(indexPath) else { return }
        collectionViewLayout.magnifiedItem = indexPath
        magnifiedCellLocation = sender.location(in: collectionView)

      case .changed:
        guard let previousLocation = magnifiedCellLocation,
              let indexPath = collectionViewLayout.magnifiedItem else { break }
        let currentLocation = sender.location(in: collectionView)

        switch currentLocation.y {
          case let y where y > view.bounds.height && !markedForRemoval: markedForRemoval = true; return
          case let y where y < view.bounds.height && markedForRemoval:  markedForRemoval = false; return
          default:                                                      break
        }

        let threshold = half(MixerLayout.itemSize.width)
        let newPath: IndexPath

        switch (currentLocation - previousLocation).unpack {
          case let (x, _) where x > threshold && !markedForRemoval:
            newPath = Section.instruments[indexPath.item + 1]
          case let (x, _) where x < -threshold && !markedForRemoval:
            newPath = Section.instruments[indexPath.item - 1]
          default:
            return
        }

        guard Section.instruments.contains(newPath) else { return }
        collectionView?.moveItem(at: indexPath as IndexPath, to: newPath)
        sequence?.exchangeInstrumentTrackAtIndex(indexPath.item, withTrackAtIndex: newPath.item)
        magnifiedCellLocation = currentLocation

      case .ended:
        guard let indexPath = collectionViewLayout.magnifiedItem else { return }
        if markedForRemoval, let cell = collectionView?.cellForItem(at: indexPath as IndexPath) as? TrackCell {
          delete(track: cell.track)
        }
        collectionViewLayout.magnifiedItem = nil

      default: break
    }
  }

  private func selectTrack(at index: Int, animated: Bool = false) {
    let section = Section.instruments
    guard section.cellCount(collectionView!) > index else { return }
    collectionView?.selectItem(at: section[index], 
                                 animated: animated, 
                           scrollPosition: UICollectionViewScrollPosition())
  }

  func delete(track: InstrumentTrack?) {
    guard let index = track?.index else { return }
    if SettingsManager.confirmDeleteTrack {
      Log.warning("delete confirmation not yet implemented for tracks")
    }
    sequence?.removeTrack(at: index)
  }

  weak var soundFontTarget: TrackCell? {
    didSet {

      switch (oldValue, soundFontTarget) {

        case let (oldValue?, newValue?):
          oldValue.soundSetImage.isSelected = false
          guard let controller =  _secondaryContent as? InstrumentViewController else {
            fatalError("Unable to obtain `_secondaryContent` as `InstrumentViewController`.")
          }
          Log.debug("Updating instrument of secondary content for new target…")
          controller.instrument = newValue.track?.instrument

        case (nil, .some):
          guard let container = parent as? MixerContainer else {
            fatalError("Failed to obtain `parent` as `MixerContainer`.")
          }
          Log.debug("Presenting content for mixer view controller…")
          container.presentContent(for: self)

        case let (oldValue?, nil):
          oldValue.soundSetImage.isSelected = false

        case (nil, nil):
          break

      }

    }
  }

  private weak var _secondaryContent: SecondaryControllerContent? {
    didSet {
      (_secondaryContent as? InstrumentViewController)?.instrument = soundFontTarget?.track?.instrument
    }
  }

  var secondaryContent: SecondaryControllerContent {
    guard _secondaryContent == nil else { return _secondaryContent! }
    let storyboard = UIStoryboard(name: "Instrument", bundle: nil)
    return storyboard.instantiateInitialViewController() as! InstrumentViewController
  }

  var isShowingContent: Bool { return _secondaryContent != nil }

  func didShow(content: SecondaryControllerContent) { _secondaryContent = content }

  func didHide(content: SecondaryControllerContent,
               dismissalAction: SecondaryControllerContainer.DismissalAction)
  {
    guard case .cancel = dismissalAction else { return }
    (content as? InstrumentViewController)?.rollBackInstrument()
  }

  private var initialized = false

  override func viewDidLoad() {
    super.viewDidLoad()
    let maskHeight = MixerLayout.itemSize.height * 1.1
    let maskView = UIView(frame: CGRect(size: CGSize(width: view.bounds.width, height: maskHeight)))
    maskView.backgroundColor = UIColor.white
    view.mask = maskView
  }

  override func awakeFromNib() {
    super.awakeFromNib()
    guard !initialized else { return }
    receptionist.observe(name: Sequencer.NotificationName.didChangeSequence.rawValue, from: Sequencer.self) {
      [weak self] _ in self?.sequence = Sequence.current
    }
    initialized = true
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    sequence = Sequence.current
  }

  func updateTracks(_ notification: Notification) {

    guard collectionView != nil else { return }
    guard sequence != nil else {
      fatalError("internal inconsistency…if sequence is nil what sent this notification?")
    }

    Log.debug("\n".join(
      "\ntotal instrument tracks in sequence: \(sequence!.instrumentTracks.count)",
      "total track cells: \(collectionView!.numberOfItems(inSection: Section.instruments.rawValue))"
      ))

    let section = Section.instruments

    switch (notification.addedIndex, notification.removedIndex) {

      case let (added?, removed?):
        Log.debug("added index: \(added); removed index: \(removed)")
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        collectionView?.performBatchUpdates({
          [weak collectionView = collectionView] in
            collectionView?.deleteItems(at: [section[removed]])
            collectionView?.insertItems(at: [section[added]])
          }, completion: nil)

      case let (added?, nil):
        if pendingTrackIndex == added { addedTrackIndex = section[added] }
        Log.debug("added index: \(added)")
        collectionView?.insertItems(at: [section[added]])

      case let (nil, removed?):
        Log.debug("removed index: \(removed)")
        collectionView?.deleteItems(at: [section[removed]])

      case (nil, nil): break
    }

    let (w, h) = viewSize.unpack
    widthConstraint?.constant = w
    heightConstraint?.constant = h
    collectionView?.contentSize = CGSize(width: w, height: h)
  }

  override func updateViewConstraints() {
    let id = Identifier(self, "Internal")

    guard    widthConstraint == nil
          && heightConstraint == nil
          && view.constraintsWithIdentifier(id).count == 0
      else
    {
      super.updateViewConstraints()
      return
    }

    view.constrain([𝗩|collectionView!|𝗩, 𝗛|collectionView!|𝗛] --> id)

    let (w, h) = viewSize.unpack
    widthConstraint = (view.width == w ! 750).constraint
    widthConstraint?.identifier = Identifier(self, "View", "Width").string
    widthConstraint?.isActive = true
    heightConstraint = (view.height == h ! 750).constraint
    heightConstraint?.identifier = Identifier(self, "View", "Height").string
    heightConstraint?.isActive = true

    super.updateViewConstraints()
  }

  private var viewSize: CGSize {
    let size = MixerLayout.itemSize
    return CGSize(width: CGFloat(Int(size.width) * (Section.allCases.reduce(0){$0 + $1.itemCount})),
                  height: size.height) - 20
  }

}

  // MARK: UICollectionViewDataSource
extension MixerViewController {

  override func numberOfSections(in collectionView: UICollectionView) -> Int {
    return Section.allCases.count
  }

  override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
    return Section(section).itemCount
  }

  override func collectionView(_ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell
  {
    let cell = Section.dequeueCell(for: indexPath, collectionView: collectionView)
    switch cell {
      case let cell as MasterCell: cell.refresh()
      case let cell as TrackCell:  cell.track = sequence?.instrumentTracks[indexPath.item]
      default:                     break
    }
    
    return cell
  }

}

// MARK: - UICollectionViewDelegate

extension MixerViewController {

  override func  collectionView(_ collectionView: UICollectionView,
    shouldSelectItemAt indexPath: IndexPath) -> Bool
  {
    return Section(indexPath) == .instruments
  }

  override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
    sequence?.currentTrackIndex = (indexPath as NSIndexPath).item
  }

  override func collectionView(_ collectionView: UICollectionView,
               willDisplay cell: UICollectionViewCell,
            forItemAt indexPath: IndexPath)
  {
    guard addedTrackIndex == indexPath, let cell = cell as? TrackCell else { return }
    defer { pendingTrackIndex = nil; addedTrackIndex = nil }
    collectionView.selectItem(at: indexPath, animated: true, scrollPosition: UICollectionViewScrollPosition())
    sequence?.currentTrackIndex = indexPath.item
    cell.instrument()
  }

}

extension MixerViewController {

  fileprivate enum Section: Int, EnumerableType {
    case master, instruments, add

    init(_ value: Int) {
      guard (0 ... 2).contains(value) else { fatalError("invalid value") }
      self.init(rawValue: value)!
    }

    init(_ indexPath: IndexPath) { self = Section(rawValue: (indexPath as NSIndexPath).section) ?? .master }

    subscript(idx: Int) -> IndexPath { return IndexPath(item: idx, section: rawValue) }

    func contains(_ indexPath: IndexPath) -> Bool {
      return indexPath.section == rawValue && (0 ..< itemCount).contains(indexPath.item)
    }

    func cellCount(_ collectionView: UICollectionView) -> Int {
      return collectionView.numberOfItems(inSection: rawValue)
    }

    var itemCount: Int {
      switch self {
        case .master, .add: return 1
        case .instruments: return Sequence.current?.instrumentTracks.count ?? 0
      }
    }

    static let allCases: [Section] = [.master, .instruments, .add]

    var identifier: String {
      switch self {
      case .master:      return MasterCell.Identifier
      case .add:         return AddTrackCell.Identifier
      case .instruments: return TrackCell.Identifier
      }
    }

    static func dequeueCell(for indexPath: IndexPath,
                            collectionView: UICollectionView) -> UICollectionViewCell
    {
      return collectionView.dequeueReusableCell(withReuseIdentifier: Section(indexPath).identifier,
                                                for: indexPath)
    }
  }
  
}
