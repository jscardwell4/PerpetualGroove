//
//  Slider.swift
//  MoonKit
//
//  Created by Jason Cardwell on 9/2/15.
//  Copyright © 2015 Jason Cardwell. All rights reserved.
//
import Foundation
import UIKit
import MoonKit
var points: [CGPoint] = []
points.append(CGPoint(x: 184.5, y: 509.5))
points.append(CGPoint(x: 182.5, y: 509.5))
points.append(CGPoint(x: 181.5, y: 509.5))
points.append(CGPoint(x: 179.5, y: 510.5))
points.append(CGPoint(x: 176.5, y: 512.5))
points.append(CGPoint(x: 173.5, y: 514.5))
points.append(CGPoint(x: 171.0, y: 515.5))
points.append(CGPoint(x: 168.5, y: 518.5))
points.append(CGPoint(x: 167.5, y: 519.5))
points.append(CGPoint(x: 166.5, y: 520.5))
points.append(CGPoint(x: 165.5, y: 521.5))
points.append(CGPoint(x: 163.5, y: 524.0))
points.append(CGPoint(x: 160.5, y: 527.0))
points.append(CGPoint(x: 159.5, y: 530.5))
points.append(CGPoint(x: 159.5, y: 531.5))
points.append(CGPoint(x: 159.5, y: 532.0))
points.append(CGPoint(x: 159.5, y: 535.0))
points.append(CGPoint(x: 159.5, y: 538.0))
points.append(CGPoint(x: 163.0, y: 546.5))
points.append(CGPoint(x: 166.0, y: 551.5))
points.append(CGPoint(x: 168.0, y: 554.5))
points.append(CGPoint(x: 170.0, y: 556.5))
points.append(CGPoint(x: 173.5, y: 560.5))
points.append(CGPoint(x: 175.5, y: 565.0))
points.append(CGPoint(x: 180.0, y: 568.5))
points.append(CGPoint(x: 181.0, y: 569.5))
points.append(CGPoint(x: 182.0, y: 571.0))
points.append(CGPoint(x: 183.0, y: 572.0))
points.append(CGPoint(x: 185.0, y: 573.0))
points.append(CGPoint(x: 188.0, y: 574.0))
points.append(CGPoint(x: 189.5, y: 575.0))
points.append(CGPoint(x: 191.5, y: 575.0))
points.append(CGPoint(x: 193.0, y: 575.0))
points.append(CGPoint(x: 194.0, y: 575.0))
points.append(CGPoint(x: 196.0, y: 575.0))
points.append(CGPoint(x: 196.5, y: 575.0))
points.append(CGPoint(x: 197.5, y: 575.0))
points.append(CGPoint(x: 198.5, y: 574.0))
points.append(CGPoint(x: 199.5, y: 572.0))
points.append(CGPoint(x: 201.5, y: 571.0))
points.append(CGPoint(x: 203.5, y: 569.5))
points.append(CGPoint(x: 205.5, y: 566.5))
points.append(CGPoint(x: 208.0, y: 563.0))
points.append(CGPoint(x: 209.0, y: 561.0))
points.append(CGPoint(x: 210.0, y: 560.0))
points.append(CGPoint(x: 213.5, y: 558.0))
points.append(CGPoint(x: 215.5, y: 555.0))
points.append(CGPoint(x: 218.0, y: 551.5))
points.append(CGPoint(x: 219.0, y: 550.5))
points.append(CGPoint(x: 221.0, y: 546.5))
points.append(CGPoint(x: 221.0, y: 545.5))
points.append(CGPoint(x: 221.0, y: 543.5))
points.append(CGPoint(x: 221.0, y: 541.0))
points.append(CGPoint(x: 221.0, y: 537.0))
points.append(CGPoint(x: 221.0, y: 526.5))
points.append(CGPoint(x: 221.0, y: 519.0))
points.append(CGPoint(x: 221.0, y: 515.0))
points.append(CGPoint(x: 219.0, y: 512.5))
points.append(CGPoint(x: 218.0, y: 511.0))
points.append(CGPoint(x: 213.5, y: 509.0))
points.append(CGPoint(x: 210.5, y: 508.0))
points.append(CGPoint(x: 204.5, y: 507.0))
points.append(CGPoint(x: 198.5, y: 507.0))
points.append(CGPoint(x: 190.0, y: 507.0))
points.append(CGPoint(x: 186.0, y: 507.0))
points.append(CGPoint(x: 182.5, y: 508.5))
points.append(CGPoint(x: 181.5, y: 509.5))
points.append(CGPoint(x: 177.5, y: 512.5))
points.append(CGPoint(x: 175.5, y: 514.5))
points.append(CGPoint(x: 172.0, y: 519.0))
points.append(CGPoint(x: 170.0, y: 522.5))
points.append(CGPoint(x: 167.0, y: 527.5))
points.append(CGPoint(x: 166.0, y: 530.5))
points.append(CGPoint(x: 166.0, y: 534.0))
points.append(CGPoint(x: 165.0, y: 540.0))
points.append(CGPoint(x: 164.0, y: 542.0))
points.append(CGPoint(x: 164.0, y: 548.0))
points.append(CGPoint(x: 164.0, y: 553.5))
points.append(CGPoint(x: 164.0, y: 556.5))
points.append(CGPoint(x: 164.0, y: 561.5))
points.append(CGPoint(x: 166.5, y: 565.0))
points.append(CGPoint(x: 168.5, y: 567.0))
points.append(CGPoint(x: 169.5, y: 568.0))
points.append(CGPoint(x: 172.5, y: 570.0))
points.append(CGPoint(x: 178.0, y: 574.5))
points.append(CGPoint(x: 180.0, y: 574.5))
points.append(CGPoint(x: 193.0, y: 579.0))
points.append(CGPoint(x: 196.0, y: 580.0))
points.append(CGPoint(x: 198.0, y: 580.0))
points.append(CGPoint(x: 204.5, y: 580.0))
points.append(CGPoint(x: 209.5, y: 580.0))
points.append(CGPoint(x: 213.0, y: 580.0))
points.append(CGPoint(x: 216.0, y: 580.0))
points.append(CGPoint(x: 225.5, y: 574.5))
points.append(CGPoint(x: 228.5, y: 572.5))
points.append(CGPoint(x: 232.0, y: 570.5))
points.append(CGPoint(x: 234.5, y: 566.5))
points.append(CGPoint(x: 235.5, y: 562.0))
points.append(CGPoint(x: 238.5, y: 552.5))
points.append(CGPoint(x: 240.0, y: 547.5))
points.append(CGPoint(x: 240.0, y: 543.5))
points.append(CGPoint(x: 240.0, y: 533.5))
points.append(CGPoint(x: 237.5, y: 528.5))
points.append(CGPoint(x: 235.5, y: 524.0))
points.append(CGPoint(x: 233.5, y: 521.0))
points.append(CGPoint(x: 229.5, y: 517.0))
points.append(CGPoint(x: 228.5, y: 515.0))
points.append(CGPoint(x: 224.5, y: 513.0))
points.append(CGPoint(x: 220.5, y: 511.0))
points.append(CGPoint(x: 218.0, y: 510.0))
points.append(CGPoint(x: 212.5, y: 508.0))
points.append(CGPoint(x: 203.0, y: 507.0))
points.append(CGPoint(x: 198.5, y: 507.0))
points.append(CGPoint(x: 194.5, y: 507.0))
points.append(CGPoint(x: 190.5, y: 507.0))
points.append(CGPoint(x: 182.0, y: 507.5))
points.append(CGPoint(x: 170.5, y: 513.0))
points.append(CGPoint(x: 165.0, y: 516.0))
points.append(CGPoint(x: 164.0, y: 517.0))
points.append(CGPoint(x: 161.5, y: 524.0))
points.append(CGPoint(x: 161.5, y: 526.0))
points.append(CGPoint(x: 160.5, y: 528.0))
points.append(CGPoint(x: 159.5, y: 531.0))
points.append(CGPoint(x: 159.5, y: 534.0))
points.append(CGPoint(x: 159.5, y: 535.0))
points.append(CGPoint(x: 159.5, y: 538.5))
points.append(CGPoint(x: 159.5, y: 550.0))
points.append(CGPoint(x: 160.5, y: 553.0))
points.append(CGPoint(x: 161.5, y: 556.0))
points.append(CGPoint(x: 162.5, y: 558.0))
points.append(CGPoint(x: 167.5, y: 563.5))
points.append(CGPoint(x: 170.0, y: 565.5))
points.append(CGPoint(x: 173.0, y: 566.5))
points.append(CGPoint(x: 175.0, y: 567.5))
points.append(CGPoint(x: 181.5, y: 569.5))
points.append(CGPoint(x: 184.0, y: 571.0))
points.append(CGPoint(x: 188.0, y: 572.0))
points.append(CGPoint(x: 191.5, y: 573.0))
points.append(CGPoint(x: 199.5, y: 575.5))
points.append(CGPoint(x: 202.0, y: 575.5))
points.append(CGPoint(x: 203.0, y: 575.5))
points.append(CGPoint(x: 205.5, y: 575.5))
points.append(CGPoint(x: 207.5, y: 575.5))
points.append(CGPoint(x: 209.0, y: 575.5))
points.append(CGPoint(x: 209.0, y: 573.0))
points.append(CGPoint(x: 208.0, y: 573.0))
points.append(CGPoint(x: 207.0, y: 573.0))
points.append(CGPoint(x: 206.0, y: 574.0))
points.append(CGPoint(x: 206.0, y: 575.5))
points.append(CGPoint(x: 205.0, y: 576.5))
points.append(CGPoint(x: 203.0, y: 577.5))
points.append(CGPoint(x: 202.0, y: 578.5))
points.append(CGPoint(x: 201.0, y: 579.5))
points.append(CGPoint(x: 200.0, y: 579.5))
points.append(CGPoint(x: 199.0, y: 579.5))
points.append(CGPoint(x: 196.5, y: 580.5))
points.append(CGPoint(x: 192.5, y: 580.5))
points.append(CGPoint(x: 189.5, y: 580.5))
points.append(CGPoint(x: 182.5, y: 580.5))
points.append(CGPoint(x: 179.5, y: 580.5))
points.append(CGPoint(x: 177.5, y: 580.5))
points.append(CGPoint(x: 175.5, y: 580.5))
points.append(CGPoint(x: 171.0, y: 578.5))
points.append(CGPoint(x: 170.0, y: 577.5))
points.append(CGPoint(x: 163.0, y: 572.0))
points.append(CGPoint(x: 162.0, y: 568.5))
points.append(CGPoint(x: 161.0, y: 567.5))
points.append(CGPoint(x: 159.5, y: 565.0))
points.append(CGPoint(x: 158.5, y: 559.5))
points.append(CGPoint(x: 158.5, y: 557.5))
points.append(CGPoint(x: 158.5, y: 555.5))
points.append(CGPoint(x: 158.5, y: 553.5))
points.append(CGPoint(x: 158.5, y: 550.0))
points.append(CGPoint(x: 158.5, y: 547.5))
points.append(CGPoint(x: 158.5, y: 546.5))
points.append(CGPoint(x: 158.5, y: 545.5))
points.append(CGPoint(x: 158.5, y: 544.5))
points.append(CGPoint(x: 158.5, y: 542.5))
points.append(CGPoint(x: 159.0, y: 538.5))
points.append(CGPoint(x: 161.0, y: 535.5))
points.append(CGPoint(x: 162.0, y: 533.5))
points.append(CGPoint(x: 170.5, y: 525.0))
points.append(CGPoint(x: 173.5, y: 523.0))
points.append(CGPoint(x: 175.5, y: 522.0))
points.append(CGPoint(x: 178.5, y: 521.0))
points.append(CGPoint(x: 182.5, y: 519.0))
points.append(CGPoint(x: 185.0, y: 518.0))
points.append(CGPoint(x: 187.0, y: 516.5))
points.append(CGPoint(x: 189.0, y: 516.0))
points.append(CGPoint(x: 194.0, y: 515.0))
points.append(CGPoint(x: 200.5, y: 515.0))
points.append(CGPoint(x: 205.5, y: 515.0))
points.append(CGPoint(x: 207.0, y: 516.0))
points.append(CGPoint(x: 209.0, y: 519.5))
points.append(CGPoint(x: 211.0, y: 523.5))
points.append(CGPoint(x: 213.0, y: 528.0))
points.append(CGPoint(x: 213.0, y: 530.0))
points.append(CGPoint(x: 213.0, y: 534.0))
points.append(CGPoint(x: 213.0, y: 538.5))
points.append(CGPoint(x: 213.0, y: 540.5))
points.append(CGPoint(x: 213.0, y: 542.5))
points.append(CGPoint(x: 213.0, y: 545.5))
points.append(CGPoint(x: 213.0, y: 547.5))
points.append(CGPoint(x: 212.0, y: 552.5))
points.append(CGPoint(x: 211.0, y: 557.0))
points.append(CGPoint(x: 208.5, y: 562.5))
points.append(CGPoint(x: 205.5, y: 567.0))
points.append(CGPoint(x: 204.5, y: 569.0))
points.append(CGPoint(x: 203.5, y: 571.0))
points.append(CGPoint(x: 200.0, y: 575.5))
points.append(CGPoint(x: 197.5, y: 577.0))
points.append(CGPoint(x: 195.5, y: 577.0))
points.append(CGPoint(x: 191.0, y: 578.0))
points.append(CGPoint(x: 189.0, y: 578.0))
points.append(CGPoint(x: 188.0, y: 578.0))
points.append(CGPoint(x: 186.0, y: 578.0))
points.append(CGPoint(x: 182.5, y: 578.0))
points.append(CGPoint(x: 180.5, y: 578.0))
points.append(CGPoint(x: 177.0, y: 578.0))
points.append(CGPoint(x: 176.0, y: 578.0))
points.append(CGPoint(x: 174.0, y: 577.0))
points.append(CGPoint(x: 173.0, y: 575.0))
points.append(CGPoint(x: 172.0, y: 574.0))
points.append(CGPoint(x: 170.0, y: 569.5))
points.append(CGPoint(x: 169.0, y: 567.5))
points.append(CGPoint(x: 168.0, y: 563.5))
points.append(CGPoint(x: 168.0, y: 561.5))
points.append(CGPoint(x: 166.0, y: 555.5))
points.append(CGPoint(x: 165.0, y: 554.5))
points.append(CGPoint(x: 165.0, y: 552.5))
points.append(CGPoint(x: 165.0, y: 551.0))
points.append(CGPoint(x: 163.0, y: 549.0))
points.append(CGPoint(x: 161.5, y: 545.0))
points.append(CGPoint(x: 161.5, y: 543.0))
points.append(CGPoint(x: 160.5, y: 539.5))
points.append(CGPoint(x: 160.5, y: 537.5))
points.append(CGPoint(x: 160.5, y: 535.5))
points.append(CGPoint(x: 160.5, y: 533.5))
points.append(CGPoint(x: 160.5, y: 527.5))
points.append(CGPoint(x: 160.5, y: 525.5))
points.append(CGPoint(x: 163.0, y: 521.5))
points.append(CGPoint(x: 164.5, y: 520.0))
points.append(CGPoint(x: 166.5, y: 519.0))
points.append(CGPoint(x: 168.5, y: 518.0))
points.append(CGPoint(x: 172.5, y: 515.0))
points.append(CGPoint(x: 174.5, y: 513.0))
points.append(CGPoint(x: 178.0, y: 511.0))
points.append(CGPoint(x: 180.0, y: 510.0))
points.append(CGPoint(x: 185.0, y: 509.0))
points.append(CGPoint(x: 190.5, y: 509.0))
points.append(CGPoint(x: 196.5, y: 509.0))
points.append(CGPoint(x: 199.5, y: 509.0))
points.append(CGPoint(x: 205.5, y: 510.0))
points.append(CGPoint(x: 208.0, y: 511.0))
points.append(CGPoint(x: 212.0, y: 515.5))
points.append(CGPoint(x: 213.5, y: 519.0))
points.append(CGPoint(x: 215.0, y: 522.0))
points.append(CGPoint(x: 216.0, y: 527.0))
points.append(CGPoint(x: 217.0, y: 533.5))
points.append(CGPoint(x: 217.0, y: 536.5))
points.append(CGPoint(x: 217.0, y: 539.5))
points.append(CGPoint(x: 217.0, y: 548.5))
points.append(CGPoint(x: 217.0, y: 551.5))
points.append(CGPoint(x: 217.0, y: 554.5))
points.append(CGPoint(x: 216.0, y: 565.0))
points.append(CGPoint(x: 215.0, y: 568.0))
points.append(CGPoint(x: 213.0, y: 575.5))
points.append(CGPoint(x: 211.0, y: 581.5))
points.append(CGPoint(x: 208.0, y: 588.0))
points.append(CGPoint(x: 207.0, y: 590.0))
points.append(CGPoint(x: 204.5, y: 592.5))
points.append(CGPoint(x: 202.5, y: 593.5))
points.append(CGPoint(x: 200.0, y: 593.5))
points.append(CGPoint(x: 193.0, y: 593.5))
points.append(CGPoint(x: 188.5, y: 593.5))
points.append(CGPoint(x: 178.5, y: 592.5))
points.append(CGPoint(x: 172.5, y: 589.5))
points.append(CGPoint(x: 169.0, y: 587.5))
points.append(CGPoint(x: 167.0, y: 586.5))
points.append(CGPoint(x: 165.0, y: 584.5))
points.append(CGPoint(x: 162.5, y: 580.0))
points.append(CGPoint(x: 160.5, y: 578.0))
points.append(CGPoint(x: 156.5, y: 565.5))
points.append(CGPoint(x: 155.0, y: 560.5))
points.append(CGPoint(x: 154.0, y: 558.0))
points.append(CGPoint(x: 154.0, y: 554.0))
points.append(CGPoint(x: 154.0, y: 551.0))
points.append(CGPoint(x: 153.0, y: 549.0))
points.append(CGPoint(x: 153.0, y: 546.5))
points.append(CGPoint(x: 153.0, y: 542.5))
points.append(CGPoint(x: 153.0, y: 539.5))
points.append(CGPoint(x: 153.0, y: 533.0))
points.append(CGPoint(x: 153.0, y: 529.0))
points.append(CGPoint(x: 153.0, y: 528.0))
points.append(CGPoint(x: 153.0, y: 526.0))
points.append(CGPoint(x: 153.5, y: 525.0))
points.append(CGPoint(x: 156.5, y: 522.0))
points.append(CGPoint(x: 160.0, y: 522.0))
points.append(CGPoint(x: 166.0, y: 518.0))
points.append(CGPoint(x: 169.0, y: 515.5))
points.append(CGPoint(x: 172.5, y: 514.5))
points.append(CGPoint(x: 177.0, y: 513.5))
points.append(CGPoint(x: 181.0, y: 512.0))
points.append(CGPoint(x: 188.5, y: 511.0))
points.append(CGPoint(x: 193.5, y: 511.0))
points.append(CGPoint(x: 196.5, y: 511.0))
points.append(CGPoint(x: 201.0, y: 511.0))
points.append(CGPoint(x: 206.0, y: 511.0))
points.append(CGPoint(x: 207.0, y: 512.0))
points.append(CGPoint(x: 211.5, y: 514.5))
points.append(CGPoint(x: 216.0, y: 518.5))
points.append(CGPoint(x: 218.0, y: 522.5))
points.append(CGPoint(x: 219.0, y: 526.0))
points.append(CGPoint(x: 219.0, y: 533.0))
points.append(CGPoint(x: 219.0, y: 535.0))
points.append(CGPoint(x: 219.0, y: 537.5))
points.append(CGPoint(x: 219.0, y: 540.5))
points.append(CGPoint(x: 219.0, y: 541.5))
points.append(CGPoint(x: 217.0, y: 547.5))
points.append(CGPoint(x: 216.0, y: 550.0))
points.append(CGPoint(x: 213.0, y: 560.5))
points.append(CGPoint(x: 212.0, y: 562.5))
points.append(CGPoint(x: 211.0, y: 564.5))
points.append(CGPoint(x: 209.0, y: 567.5))
points.append(CGPoint(x: 207.5, y: 569.5))
points.append(CGPoint(x: 206.5, y: 570.5))
points.append(CGPoint(x: 201.0, y: 575.0))
points.append(CGPoint(x: 198.0, y: 575.0))
points.append(CGPoint(x: 193.0, y: 575.0))
points.append(CGPoint(x: 189.5, y: 575.0))
points.append(CGPoint(x: 183.0, y: 574.0))
points.append(CGPoint(x: 180.0, y: 572.0))
points.append(CGPoint(x: 177.0, y: 569.5))
points.append(CGPoint(x: 172.5, y: 565.5))
points.append(CGPoint(x: 170.5, y: 563.5))
points.append(CGPoint(x: 168.0, y: 559.0))
points.append(CGPoint(x: 166.0, y: 557.0))
points.append(CGPoint(x: 165.0, y: 556.0))
points.append(CGPoint(x: 162.0, y: 546.5))
points.append(CGPoint(x: 161.0, y: 543.0))
points.append(CGPoint(x: 161.0, y: 541.0))
points.append(CGPoint(x: 159.0, y: 535.0))
points.append(CGPoint(x: 158.0, y: 531.5))
points.append(CGPoint(x: 158.0, y: 523.5))
points.append(CGPoint(x: 158.0, y: 515.5))
points.append(CGPoint(x: 158.0, y: 512.5))
points.append(CGPoint(x: 158.0, y: 510.5))
points.append(CGPoint(x: 158.0, y: 507.5))
points.append(CGPoint(x: 158.0, y: 503.0))
points.append(CGPoint(x: 160.0, y: 500.5))
points.append(CGPoint(x: 161.0, y: 500.5))
points.append(CGPoint(x: 164.0, y: 500.5))
points.append(CGPoint(x: 166.0, y: 500.5))
points.append(CGPoint(x: 169.0, y: 500.5))
points.append(CGPoint(x: 172.5, y: 499.5))
points.append(CGPoint(x: 180.0, y: 499.5))
points.append(CGPoint(x: 188.5, y: 499.5))
points.append(CGPoint(x: 194.5, y: 499.5))
points.append(CGPoint(x: 197.5, y: 500.5))
points.append(CGPoint(x: 204.0, y: 502.5))
points.append(CGPoint(x: 208.0, y: 505.5))
points.append(CGPoint(x: 212.5, y: 508.5))
points.append(CGPoint(x: 217.5, y: 514.0))
points.append(CGPoint(x: 220.5, y: 516.5))
points.append(CGPoint(x: 221.5, y: 518.0))
points.append(CGPoint(x: 223.5, y: 520.0))
points.append(CGPoint(x: 225.5, y: 524.0))
points.append(CGPoint(x: 226.5, y: 525.0))
points.append(CGPoint(x: 227.5, y: 529.5))
points.append(CGPoint(x: 227.5, y: 534.0))
points.append(CGPoint(x: 227.5, y: 536.0))
points.append(CGPoint(x: 227.5, y: 538.0))
points.append(CGPoint(x: 226.5, y: 540.0))
points.append(CGPoint(x: 223.0, y: 546.0))
points.append(CGPoint(x: 220.0, y: 552.5))
points.append(CGPoint(x: 219.0, y: 556.5))
points.append(CGPoint(x: 215.0, y: 564.0))
points.append(CGPoint(x: 212.5, y: 568.0))
points.append(CGPoint(x: 210.5, y: 572.0))
points.append(CGPoint(x: 209.0, y: 575.0))
points.append(CGPoint(x: 206.0, y: 580.0))
points.append(CGPoint(x: 204.0, y: 582.0))
points.append(CGPoint(x: 201.0, y: 585.5))
points.append(CGPoint(x: 199.0, y: 587.0))
points.append(CGPoint(x: 199.0, y: 588.0))

let path = UIBezierPath()
path.moveToPoint(points[0])
for p in points[..<points.endIndex] { path.addLineToPoint(p) }
//path.closePath()

path
var slopes: [CGFloat] = []
enum Direction: String {
  case Clockwise, CounterClockwise
  init(from: CGPoint, to: CGPoint, about: CGPoint, trending: Direction?) {
    let (x1, y1) = from.unpack
    let (x2, y2) = to.unpack
    let slope = (y2 - y1) / (x2 - x1)
    slopes.append(slope)

    switch (y2 - y1) / (x2 - x1) {

    case 0 where x2 < x1:
      
      switch about.unpack {
        case let (_, yc) where y2 <= yc: 
          print("case 0 where x2 < x1 && y2 <= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (_, yc) where y2 >= yc: 
          print("case 0 where x2 < x1 && y2 >= yc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        default:
          let result = trending ?? .Clockwise
          print("case 0 where x2 < x1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
      }

    case 0 where x2 >= x1:
      
      switch about.unpack {
        case let (_, yc) where y2 <= yc: 
          print("case 0 where x2 >= x1 && y2 <= yc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (_, yc) where y2 >= yc: 
          print("case 0 where x2 >= x1 && y2 >= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        default:
          let result = trending ?? .CounterClockwise
          print("case 0 where x2 >= x1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
      }

    case CGFloat.infinity where y2 <= y1:
      
      switch about.unpack {
        case let (xc, _) where x2 <= xc: 
          print("case CGFloat.infinity where y2 <= y1 && x2 <= xc: x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (xc, _) where x2 >= xc: 
          print("case CGFloat.infinity where y2 <= y1 && x2 >= xc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        default:
          let result = trending ?? .CounterClockwise
          print("case CGFloat.infinity where y2 <= y1 && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
      }

    case CGFloat.infinity where y2 >= y1:
      
      switch about.unpack {
        case let (xc, _) where x2 <= xc: 
          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (xc, _) where x2 >= xc: 
          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .Clockwise
        default:
          let result = trending ?? .Clockwise
          print("case CGFloat.infinity where y2 >= y1: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
      }

    case let s where s.isSignMinus:
      
      switch about.unpack {
        case let (xc, yc) where x2 <= xc && y2 >= yc: 
          print("case let s where s.isSignMinus && x2 <= xc && y2 >= yc: x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .CounterClockwise
        case let (xc, yc) where x2 <= xc && y2 <= yc:
          let result = trending ?? .Clockwise
          print("case let s where s.isSignMinus && x2 <= xc && y2 <= yc: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
        case let (xc, yc) where x2 >= xc && y2 >= yc:
          let result = trending ?? .CounterClockwise
          print("case let s where s.isSignMinus && x2 >= xc && y2 >= yc: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        default:
          let result = trending ?? .Clockwise
          print("case let s where s.isSignMinus && default: x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
      }

    default:
      switch about.unpack {
        case let (xc, yc) where x2 <= xc && y2 >= yc:
          print("<default && x2 <= xc && y2 >= yc> x2 = \(x2); y2 = \(y2) CounterClockwise")
          self = .Clockwise
        case let (xc, yc) where x2 <= xc && y2 <= yc:
          print("<default && x2 <= xc && y2 <= yc> x2 = \(x2); y2 = \(y2) Clockwise")
          self = .Clockwise
        case let (xc, yc) where x2 >= xc && y2 >= yc:
          let result = trending ?? .CounterClockwise
          print("<default && x2 >= xc && y2 >= yc> x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .CounterClockwise
        default:
          let result = trending ?? .CounterClockwise
          print("<default && default> x2 = \(x2); y2 = \(y2) \(result.rawValue)")
          self = trending ?? .Clockwise
      }

    }

  }
}

enum Quadrant: String {
  case I, II, III, IV
  init(point: CGPoint, center: CGPoint) {
    switch (point.unpack, center.unpack) {
      case let ((px, py), (cx, cy)) where px >= cx && py <= cy: self = .I
      case let ((px, py), (cx, cy)) where px <= cx && py <= cy: self = .II
      case let ((px, py), (cx, cy)) where px <= cx && py >= cy: self = .III
      default:                                                  self = .IV
    }
  }
}

var quadrants: [Quadrant] = []
func angleForTouchLocation(location: CGPoint, withCenter center: CGPoint, direction: Direction, previousDirection: Direction? = nil, previousAngle: CGFloat? = nil) -> CGFloat {

  let delta = location - center
  let quadrant = Quadrant(point: location, center: center)
  quadrants.append(quadrant)
  let (x, y) = delta.absolute.unpack
  let h = sqrt(pow(x, 2) + pow(y, 2))
  var a = acos(x / h) //+ offset
  switch quadrant {
    case .I: break
    case .II: a = π * 0.5 - a + π * 0.5
    case .III: a += π
    case .IV: a = π * 0.5 - a + π * 1.5
  }

  return direction == .Clockwise ? (π * 2) - a : a
}

let center = CGPoint(x: 187.5, y: 546)
var angles: [CGFloat] = []
var directions: [Direction] = []
var prev = points[0]
var prevDirection: Direction?
for p in points[1 ..< points.endIndex] {
  let direction = Direction(from: prev, to: p, about: center, trending: prevDirection)
  let angle = angleForTouchLocation(p, withCenter: center, direction: direction)
  angles.append(angle)
  directions.append(direction)
  prev = p
  prevDirection = direction
}

print("angles: [\n\t" + "\n\t".join(
  zip(zip(points[1..<points.endIndex], quadrants), zip(zip(angles, slopes), directions)).map {
    tuple1, tuple2 in
    let pointString = String(tuple1.0).pad(" ", count: 15, type: .Suffix)
    let angleString = String(tuple2.0.0.degrees.rounded(2)).pad(" ", count: 6, type: .Suffix)
    let slopeString = String(tuple2.0.1.rounded(2)).pad(" ", count: 6, type: .Suffix)
    return "\(tuple1.1.rawValue):\(pointString)\t\(angleString)\t\(slopeString)\t\(tuple2.1.rawValue)"
  }) + "\n]")
