//
//  GameViewController.swift
//  MidiSprite
//
//  Created by Jason Cardwell on 8/5/15.
//  Copyright (c) 2015 Moondeer Studios. All rights reserved.
//

import UIKit
import SpriteKit
import MoonKit
import Eveleth

class GameViewController: UIViewController {

  @IBOutlet weak var tempoSlider: UISlider!
  @IBOutlet weak var tempoLabel: UILabel!

  /** tempoSliderValueDidChange */
  @IBAction func tempoSliderValueDidChange() {
    guard isViewLoaded(), let scene = (view as! SKView).scene else { return }
    scene.speed = CGFloat(tempoSlider.value)
    // TODO: This doesn't work because the balls are already in motion, not driven by actions
  }

  /** viewDidLoad */
  override func viewDidLoad() {
    super.viewDidLoad()

    tempoLabel.font = Eveleth.shadowFontWithSize(16)

    let scene = BallScene(size: view.bounds.size)

    // Configure the view.
    let skView = self.view as! SKView
    skView.showsFPS = true
    skView.showsNodeCount = true

    /* Sprite Kit applies additional optimizations to improve rendering performance */
    skView.ignoresSiblingOrder = true

    /* Set the scale mode to scale to fit the window */
    scene.scaleMode = .AspectFill

    skView.presentScene(scene)
  }

  /**
  shouldAutorotate

  - returns: Bool
  */
  override func shouldAutorotate() -> Bool {
    return false
  }

  /**
  supportedInterfaceOrientations

  - returns: UIInterfaceOrientationMask
  */
  override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
    if UIDevice.currentDevice().userInterfaceIdiom == .Phone {
      return .AllButUpsideDown
    } else {
      return .All
    }
  }

  /** didReceiveMemoryWarning */
  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Release any cached data, images, etc that aren't in use.
    MSLogDebug("")
  }

  /**
  prefersStatusBarHidden

  - returns: Bool
  */
  override func prefersStatusBarHidden() -> Bool {
    return true
  }
}
