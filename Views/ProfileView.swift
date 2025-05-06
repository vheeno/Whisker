//
//  ProfileView.swift
//  Whisker

import SwiftUI
import FirebaseAuth

struct ProfileView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @ObservedObject private var dataManager = RecipeDataManager.shared
    @State private var showingLogoutAlert = false
    
    private var userEmail: String {
        Auth.auth().currentUser?.email ?? "User"
    }
    
    private var userInitial: String {
        (Auth.auth().currentUser?.email?.first?.uppercased() ?? "U").description
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 25) {
                ZStack {
                    Circle()
                        .fill(WhiskerStyles.primaryColor)
                        .frame(width: 100, height: 100)
                        .shadow(color: Color.black.opacity(0.15), radius: 8, x: 0, y: 4)
                    
                    Text(userInitial)
                        .font(.system(size: 42, weight: .medium))
                        .foregroundColor(.white)
                }
                .padding(.top, 40)
                
                Text(userEmail)
                    .font(WhiskerStyles.Fonts.bodyMedium)
                    .foregroundColor(WhiskerStyles.textColor)
                
                VStack(spacing: 15) {
                    Text("Your Whisker Stats")
                        .font(WhiskerStyles.Fonts.bodyMedium)
                        .foregroundColor(WhiskerStyles.textColor)
                        .padding(.bottom, 5)
                    
                    Text("\(getTotalRecipeCount())")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(WhiskerStyles.primaryColor)
                    
                    Text("Recipes")
                        .font(WhiskerStyles.Fonts.bodyLight)
                        .foregroundColor(WhiskerStyles.textColor)
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
                )
                .padding(.horizontal)
                .padding(.top, 10)
                
                Spacer()
                
                // Sign out button
                Button(action: {
                    showingLogoutAlert = true
                }) {
                    HStack {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Sign Out")
                            .font(WhiskerStyles.Fonts.buttonText)
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(Color.red)
                    .cornerRadius(15)
                    .shadow(color: Color.red.opacity(0.3), radius: 5, x: 0, y: 3)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .padding(.bottom, 50)
                .alert(isPresented: $showingLogoutAlert) {
                    Alert(
                        title: Text("Sign Out"),
                        message: Text("Are you sure you want to sign out?"),
                        primaryButton: .destructive(Text("Sign Out")) {
                            _ = authManager.signOut()
                        },
                        secondaryButton: .cancel()
                    )
                }
                
                Spacer()
            }
        }
        .background(WhiskerStyles.backgroundColor.ignoresSafeArea())
        .navigationBarTitle("My Profile", displayMode: .inline)
        .onAppear {
            // Load data if needed when the profile view appears
            if dataManager.albums.isEmpty {
                dataManager.loadAlbums()
            }
        }
    }
    
    private func getTotalRecipeCount() -> Int {
        var count = 0
        for album in dataManager.albums {
            count += album.recipes.count
        }
        return count
    }
    
    private func getAlbumCount() -> Int {
        return dataManager.albums.count
    }
}
