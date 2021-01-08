//
//  Shorthand.swift
//  Sequencer
//
//  Created by Jason Cardwell on 1/7/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import Foundation

public var controller: Controller { .shared }
public var player: Player { controller.player }
public var time: Time { controller.time }
public var sequence: Sequence? { controller.sequence }
public var transport: Transport { controller.transport } 
