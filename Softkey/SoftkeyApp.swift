//
//  SoftkeyApp.swift
//  Softkey
//
//  Created by Barry Hall on 2024-10-06.
//

import SwiftUI

@main
struct SoftkeyApp: App {
    init() {
        initKeyLayout()
    }
    
    var body: some Scene {
        WindowGroup {
            KeyFrame()
        }
    }
}
