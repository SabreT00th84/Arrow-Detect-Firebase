//
//  Arrow_DetectApp.swift
//  Arrow Detect
//
//  Created by Eesa Adam on 13/10/2024.
//

import FirebaseCore
import SwiftUI

@main
struct Arrow_DetectApp: App {
    
    @StateObject var authTest =  AuthenticationTest()

    var body: some Scene {
        WindowGroup {
            if authTest.isSignedInAndVerified {
                MainTabView()
            } else {
                LoginView()
            }
        }
    }
    
    init () {
        FirebaseApp.configure()
    }
}
