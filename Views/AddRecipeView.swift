//
//  AddRecipeView.swift
//  Whisker
//
//  Created by Julia Yu on 4/29/25.
//

import SwiftUI

struct AddRecipeView: View {
    @State private var recipeUrl: String = ""
    @State private var isExtracting: Bool = false
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @Environment(\.presentationMode) var presentationMode
    @ObservedObject private var dataManager = RecipeDataManager.shared
    
    // Navigation state
    @State private var navigateToEditRecipe: Bool = false
    @State private var savedRecipe: Recipe?
    @State private var savedAlbumId: UUID?
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Improved title presentation
                    VStack(spacing: 10) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 35))
                            .foregroundColor(WhiskerStyles.primaryColor)
                            .padding(.top, 30)
                            .shadow(color: Color.black.opacity(0.1), radius: 2, x: 0, y: 2)
                        
                        Text("Add New Recipe")
                            .font(WhiskerStyles.Fonts.title)
                            .foregroundColor(WhiskerStyles.textColor)
                            .frame(maxWidth: .infinity, alignment: .center)
                        
                        Text("Import a recipe from your favorite cooking site")
                            .font(WhiskerStyles.Fonts.bodyLight)
                            .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                            .multilineTextAlignment(.center)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .padding(.bottom, 20)
                    
                    // URL Input section with improved visuals
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Paste a URL to import a recipe")
                            .font(WhiskerStyles.Fonts.bodyMedium)
                            .foregroundColor(WhiskerStyles.textColor)
                            .padding(.horizontal)
                        
                        HStack {
                            Image(systemName: "link")
                                .foregroundColor(WhiskerStyles.primaryColor)
                                .padding(.horizontal, 5)
                            
                            TextField("https://example.com/recipe", text: $recipeUrl)
                                .whiskerTextField()
                                .keyboardType(.URL)
                                .autocorrectionDisabled()
                                .autocapitalization(.none)
                                .disabled(isExtracting)
                                .padding(.vertical, 14)
                        }
                        .padding(.horizontal)
                        
                        Button(action: extractRecipe) {
                            if isExtracting {
                                HStack {
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle())
                                        .tint(.white)
                                    Text("Extracting recipe...")
                                        .font(WhiskerStyles.Fonts.buttonText)
                                }
                            } else {
                                HStack {
                                    Image(systemName: "arrow.down.doc.fill")
                                    Text("Extract Recipe")
                                        .font(WhiskerStyles.Fonts.buttonText)
                                }
                            }
                        }
                        .primaryButton()
                        .padding(.horizontal)
                        .disabled(recipeUrl.isEmpty || isExtracting)
                        .shadow(color: Color.black.opacity(0.1), radius: 5, x: 0, y: 3)
                    }
                    .padding(.vertical, 20)
                    .background(
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white)
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 4)
                    )
                    .padding(.horizontal)
                    
                    // Tips section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Tips for best results:")
                            .font(WhiskerStyles.Fonts.bodyMedium)
                            .foregroundColor(WhiskerStyles.textColor)
                            .padding(.bottom, 5)
                        
                        tipRow(icon: "checkmark.circle.fill", text: "Use URLs from popular recipe websites")
                        tipRow(icon: "checkmark.circle.fill", text: "Make sure the URL leads directly to a recipe page")
                        tipRow(icon: "checkmark.circle.fill", text: "You can edit the recipe after importing")
                    }
                    .padding(.horizontal, 25)
                    .padding(.vertical, 20)
                }
                .padding(.bottom, 30)
                
                // NavigationLink for programmatic navigation
                NavigationLink(
                    destination:
                        Group {
                            if let recipe = savedRecipe, let albumId = savedAlbumId {
                                RecipeDetailView(
                                    recipe: recipe,
                                    albumId: albumId,
                                    isInitiallyEditing: true,
                                    isNewlyImported: true  // Mark this as a newly imported recipe
                                )
                            } else {
                                EmptyView()
                            }
                        },
                    isActive: $navigateToEditRecipe
                ) {
                    EmptyView()
                }
            }
            .background(WhiskerStyles.backgroundColor.ignoresSafeArea())
            .navigationBarHidden(true)
            .alert(isPresented: $showAlert) {
                Alert(
                    title: Text(alertTitle),
                    message: Text(alertMessage),
                    dismissButton: .default(Text("OK"))
                )
            }
        }
    }
    
    // Helper function to create consistent tip rows
    private func tipRow(icon: String, text: String) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(WhiskerStyles.primaryColor)
            
            Text(text)
                .font(WhiskerStyles.Fonts.bodyLight)
                .foregroundColor(WhiskerStyles.textColor)
        }
    }
    
    // Extract recipe from URL
    private func extractRecipe() {
        // Validate URL format
        guard let url = URL(string: recipeUrl), recipeUrl.starts(with: "http") else {
            showAlert(title: "Invalid URL", message: "Please enter a valid URL starting with http:// or https://")
            return
        }
        
        // Show extraction is in progress
        isExtracting = true
        
        // Use RecipeExtractor to get recipe from URL
        let extractor = RecipeExtractor()
        extractor.extractRecipe(from: url) { result in
            DispatchQueue.main.async {
                self.isExtracting = false
                
                switch result {
                case .success(let recipe):
                    // Save the recipe and prepare for navigation
                    saveRecipeAndNavigate(recipe)
                    
                case .failure(let error):
                    self.showAlert(
                        title: "Extraction Failed",
                        message: "Could not extract recipe from this URL. \(error.localizedDescription)"
                    )
                }
            }
        }
    }
    
    // Prepare recipe for editing and navigation
    private func saveRecipeAndNavigate(_ recipe: Recipe) {
        // Always find or create the "Uncategorized" album
        var albumId: UUID
        
        if let uncategorizedAlbum = dataManager.albums.first(where: { $0.name == "Uncategorized" }) {
            albumId = uncategorizedAlbum.id
        } else {
            // Create "Uncategorized" album if it doesn't exist
            let newAlbum = dataManager.createAlbum(name: "Uncategorized")
            albumId = newAlbum.id
        }
        
        // Set the saved recipe and album ID for navigation
        savedRecipe = recipe
        savedAlbumId = albumId
        
        // Reset the URL field
        recipeUrl = ""
        
        // Navigate to the recipe detail view
        navigateToEditRecipe = true
    }
    
    // Helper method to show alerts
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}
