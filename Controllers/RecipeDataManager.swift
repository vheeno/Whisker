//
//  RecipeDataManager.swift
//  Whisker
//

import SwiftUI
import Combine
import Firebase
import FirebaseAuth
import FirebaseFirestore

/// Manager class to handle recipe data throughout the app
class RecipeDataManager: ObservableObject {
    static let shared = RecipeDataManager()
    
    @Published var albums: [RecipeAlbum] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let firestoreManager = FirestoreManager.shared
    
    private init() {
        setupAuthListener()
    }
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.loadAlbums()
            } else {
                self?.albums = []
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadAlbums() {
        guard Auth.auth().currentUser != nil else {
            self.error = "User not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        firestoreManager.getAlbums { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let albums):
                    self?.albums = albums
                    if albums.isEmpty {
                        self?.createAlbum(name: "Uncategorized")
                    } else if !albums.contains(where: { $0.name == "Uncategorized" }) {
                        self?.createAlbum(name: "Uncategorized")
                    }
                    
                    for i in 0..<(self?.albums.count ?? 0) {
                        let albumId = self?.albums[i].id
                        for j in 0..<(self?.albums[i].recipes.count ?? 0) {
                            self?.albums[i].recipes[j].albumId = albumId
                        }
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    // MARK: - Album Management
    
    func deleteAlbum(withId id: UUID) {
        isLoading = true
        error = nil
        
        firestoreManager.deleteAlbum(albumId: id) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    self?.albums.removeAll { $0.id == id }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func updateAlbumName(albumId: UUID, newName: String) {
        guard !newName.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.updateAlbumName(albumId: albumId, newName: newName) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    if let index = self?.albums.firstIndex(where: { $0.id == albumId }) {
                        self?.albums[index].name = newName
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func createAlbum(name: String, coverImage: String = "photo.on.rectangle") -> RecipeAlbum {
        isLoading = true
        error = nil
        
        let temporaryAlbum = RecipeAlbum(name: name, coverImage: coverImage, recipes: [])
        albums.append(temporaryAlbum)
        
        firestoreManager.createAlbum(name: name, coverImage: coverImage) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let album):
                    if let index = self?.albums.firstIndex(where: { $0.name == name && $0.id == temporaryAlbum.id }) {
                        self?.albums[index] = album
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                    self?.albums.removeAll { $0.id == temporaryAlbum.id }
                }
            }
        }
        
        return temporaryAlbum
    }
    
    // MARK: - Recipe Management
    
    func deleteRecipes(fromAlbumId albumId: UUID, recipeIds: Set<UUID>) {
        guard !recipeIds.isEmpty else { return }
        
        isLoading = true
        error = nil
        
        firestoreManager.deleteRecipes(fromAlbumId: albumId, recipeIds: recipeIds) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success:
                    if let albumIndex = self?.albums.firstIndex(where: { $0.id == albumId }) {
                        self?.albums[albumIndex].recipes.removeAll { recipeIds.contains($0.id) }
                    }
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
    }
    
    func saveRecipe(to albumId: UUID, recipe: Recipe) {
        isLoading = true
        error = nil
        
        var recipeToSave = recipe
        
        recipeToSave.albumId = albumId
        
        if let album = albums.first(where: { $0.id == albumId }),
           let existingRecipe = album.recipes.first(where: { $0.id == recipe.id }) {
            if recipe.ingredients == existingRecipe.ingredients {
                recipeToSave.originalIngredients = existingRecipe.originalIngredients
            } else {
                recipeToSave.originalIngredients = recipe.ingredients
            }
        } else {
            recipeToSave.originalIngredients = recipe.ingredients
        }
        
        firestoreManager.saveRecipe(to: albumId, recipe: recipeToSave) { [weak self] result in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                switch result {
                case .success(let savedRecipe):
                    self?.updateLocalRecipeData(albumId: albumId, recipe: savedRecipe)
                case .failure(let error):
                    self?.error = error.localizedDescription
                }
            }
        }
        NotificationCenter.default.post(name: NSNotification.Name("RecipeAdded"), object: nil)
    }
    
    private func updateLocalRecipeData(albumId: UUID, recipe: Recipe) {
        var updatedAlbums = self.albums
        
        if let albumIndex = updatedAlbums.firstIndex(where: { $0.id == albumId }) {
            if let recipeIndex = updatedAlbums[albumIndex].recipes.firstIndex(where: { $0.id == recipe.id }) {
                var updatedRecipe = recipe
                updatedRecipe.albumId = albumId
                updatedAlbums[albumIndex].recipes[recipeIndex] = updatedRecipe
            } else {
                var newRecipe = recipe
                newRecipe.albumId = albumId
                updatedAlbums[albumIndex].recipes.append(newRecipe)
            }
        }
        
        self.albums = updatedAlbums
    }
    
    // MARK: - Recipe Access Methods
    
    func getAllRecipes() -> [Recipe] {
        var allRecipes: [Recipe] = []
        
        for album in albums {
            for var recipe in album.recipes {
                recipe.albumId = album.id
                allRecipes.append(recipe)
            }
        }
        
        return allRecipes.sorted { $0.name < $1.name }
    }
}
