//
//  TransformTestViewController.swift
//  TransformTest
//
//  Created by Jason Cardwell on 7/14/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//

import UIKit
import MoonKit

class TransformTestViewController: UIViewController {

  @IBOutlet weak var contentView: UIView!
  @IBOutlet weak var labelOne: UILabel!
  @IBOutlet weak var labelTwo: UILabel!
  @IBOutlet weak var labelThree: UILabel!
  @IBOutlet weak var labelFour: UILabel!
  @IBOutlet weak var labelFive: UILabel!

  func applyTranformToView(label: UILabel) {

    let visibleRect = contentView.bounds
    let visibleMidX = visibleRect.midX

    let rect = label.frame
    let midX = rect.midX
    let w_2 = rect.width / 2

    let d = midX - (visibleMidX - w_2)
    let r = visibleRect.width / 2

    let L = CGFloat(M_PI_2) * r
    let l = d / r * L

    let alpha = l / r
    let sigma = CGFloat(M_PI_2) - alpha
    let theta = CGFloat(M_PI_2) - sigma

    let w_2_Prime = w_2 * cos(theta)
    let deltaW = w_2 - w_2_Prime

    let tx = (visibleMidX > midX ? deltaW : -deltaW) * 2 * abs(d / visibleMidX)

//    let a = sin(alpha) * r
//    let b = sin(sigma) * r

    let transform = CATransform3D(
      m11: cos(theta), m12: 0, m13: -sin(theta), m14: 0,
      m21: 0, m22: 1, m23: 0, m24: 0,
      m31: sin(theta), m32: 0, m33: cos(theta), m34: 0,
      m41: tx, m42: 0, m43: 0, m44: 1)
//    var transform = CATransform3DIdentity
//    transform = CATransform3DTranslate(transform, d / 4, 0, b / 4)
//    transform = CATransform3DRotate(transform, theta, 0, 1, 0)
//    transform = CATransform3DTranslate(transform, a / 4, 0, b / 4)

    label.layer.transform = transform
    
  }


  override func viewDidLoad() {
    super.viewDidLoad()
    // Do any additional setup after loading the view, typically from a nib.

    let transform = CATransform3D(m11: 1, m12: 0, m13: 0, m14: 0, m21: 0, m22: 1, m23: 0, m24: 0, m31: 0, m32: 0, m33: 0, m34: CGFloat(-1.0/500.0), m41: 0, m42: 0, m43: 0, m44: 1)
    contentView.layer.sublayerTransform = transform

    for label in [labelOne, labelTwo, labelThree, labelFour, labelFive] {
      applyTranformToView(label)
    }
  }

  override func didReceiveMemoryWarning() {
    super.didReceiveMemoryWarning()
    // Dispose of any resources that can be recreated.
  }


}

