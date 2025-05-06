//
//  ContentView.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//

import SwiftUI

// MARK: - Modified ContentView for main app navigation
struct ContentView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                CustomMainTabView()
            } else {
                LoginView()
            }
        }
    }
}
