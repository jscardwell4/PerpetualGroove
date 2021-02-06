//
//  File.swift
//
//
//  Created by Jason Cardwell on 2/5/21.
//
import Foundation
import SpriteKit
import SwiftUI

// MARK: - ExampleView

@available(iOS 14.0, *)
@available(macCatalyst 14.0, *)
@available(OSX 10.15, *)
struct ExampleView: View
{
  var body: some View
  {
    GeometryReader
    {
      let 𝘴 = min($0.size.width, $0.size.height)
      VStack
      {
        SpriteView(scene: buildScene(CGSize(width: 𝘴, height: 𝘴)),
                   transition: nil,
                   isPaused: false,
                   preferredFramesPerSecond: 60,
                   options: [.shouldCullNonVisibleNodes],
                   shouldRender: { _ in true })
          .frame(width: 𝘴, height: 𝘴)
      }
    }
  }

  private func buildScene(_ size: CGSize) -> BouncingSquares
  {
    let scene = BouncingSquares()
    scene.size = size
    scene.scaleMode = .fill
    scene.backgroundColor = UIColor.backgroundColor2

    scene.populate()
    return scene
  }

}

// MARK: - BouncingSquares

class BouncingSquares: SKScene
{
  let colors: [UIColor] = [
    .systemRed,
    .systemOrange,
    .systemYellow,
    .systemGreen,
    .systemBlue,
    .systemPurple,
    .systemPink
  ]
  var moving = true

  func populate()
  {
    for _ in 0 ..< 20
    {
      let square = SKSpriteNode(
        color: colors[children.count % 7],
        size: CGSize(width: 20, height: 20)
      )

      square.position = CGPoint(x: .random(in: 0 ... 300), y: .random(in: 0 ... 300))
      square.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 20, height: 20))
      addChild(square)
    }

    configureSquares()
  }

  func configureSquares()
  {
    for square in children
    {
      square.physicsBody?.velocity = moving ? CGVector(
        dx: .random(in: -200 ... 200),
        dy: .random(in: -200 ... 200)
      ) : .zero
      square.physicsBody?.restitution = moving ? 1.0 : 0.0
      square.physicsBody?.linearDamping = moving ? 0.0 : 1.0
      square.physicsBody?.angularDamping = moving ? 0.0 : 1.0
      square.physicsBody?.friction = moving ? 0.0 : 1.0
    }

    physicsWorld.gravity = moving ? .zero : CGVector(dx: 0, dy: -9.8)
  }

  override func didMove(to view: SKView)
  {
    physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
    physicsWorld.gravity = .zero
  }

  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?)
  {
    moving.toggle()
    configureSquares()
  }
}
