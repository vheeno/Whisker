//
//  WhiskerApp.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//

import SwiftUI
import FirebaseAuth
import FirebaseCore
import GoogleSignIn
import FacebookLogin

// MARK: - App entry point
@main
struct WhiskerApp: App {
    // Register app delegate for Firebase, Google Sign-In, and Facebook SDK setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .onOpenURL { url in
                    // Handle incoming URLs for authentication callbacks
                    GIDSignIn.sharedInstance.handle(url)
                    ApplicationDelegate.shared.application(
                        UIApplication.shared,
                        open: url,
                        sourceApplication: nil,
                        annotation: [UIApplication.OpenURLOptionsKey.annotation]
                    )
                }
        }
    }
}
