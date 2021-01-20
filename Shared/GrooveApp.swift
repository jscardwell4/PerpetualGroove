//
//  GrooveApp.swift
//  Shared
//
//  Created by Jason Cardwell on 1/19/21.
//  Copyright © 2021 Moondeer Studios. All rights reserved.
//
import SwiftUI
import Documents

@main
struct GrooveApp: App
{
  var body: some Scene
  {
    DocumentGroup(newDocument: GrooveDocument())
    {
      ContentView(document: $0.$document)
    }
  }
}
