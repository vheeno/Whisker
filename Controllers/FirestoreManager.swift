//
//  FirestoreManager.swift
//  Whisker
//

import Foundation
import FirebaseFirestore
import FirebaseAuth

/// Error types for Firestore operations
enum FirestoreError: Error {
    case notAuthenticated
    case documentCreationFailed
    case documentDeletionFailed
    case documentUpdateFailed
    case documentNotFound
    case invalidData
    case networkError
    case unknown
    
    var localizedDescription: String {
        switch self {
        case .notAuthenticated:
            return "User not authenticated"
        case .documentCreationFailed:
            return "Failed to create document"
        case .documentDeletionFailed:
            return "Failed to delete document"
        case .documentUpdateFailed:
            return "Failed to update document"
        case .documentNotFound:
            return "Document not found"
        case .invalidData:
            return "Invalid data format"
        case .networkError:
            return "Network error"
        case .unknown:
            return "Unknown error occurred"
        }
    }
}

/// Manager class to interact with Firestore database
class FirestoreManager {
    static let shared = FirestoreManager()
    
    private let db = Firestore.firestore()
    
    private init() {}
    
    // MARK: - Albums
    
    /// Get all albums for the current user
    func getAlbums(completion: @escaping (Result<[RecipeAlbum], FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        db.collection("users").document(userId).collection("albums")
            .getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting albums: \(error.localizedDescription)")
                    completion(.failure(.networkError))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                var albums: [RecipeAlbum] = []
                
                let group = DispatchGroup()
                
                for document in documents {
                    let data = document.data()
                    
                    guard let albumId = UUID(uuidString: document.documentID),
                          let name = data["name"] as? String,
                          let coverImage = data["coverImage"] as? String else {
                        continue
                    }
                    
                    let album = RecipeAlbum(id: albumId, name: name, coverImage: coverImage, recipes: [])
                    
                    group.enter()
                    
                    self.getRecipes(forAlbumId: albumId) { result in
                        switch result {
                        case .success(let recipes):
                            var albumWithRecipes = album
                            var recipesWithAlbumId = recipes
                            for i in 0..<recipesWithAlbumId.count {
                                recipesWithAlbumId[i].albumId = albumId
                            }
                            albumWithRecipes.recipes = recipesWithAlbumId
                            albums.append(albumWithRecipes)
                            
                        case .failure(let error):
                            print("Error fetching recipes for album \(albumId): \(error.localizedDescription)")
                            albums.append(album)
                        }
                        
                        group.leave()
                    }
                }
                
                group.notify(queue: .main) {
                    completion(.success(albums))
                }
            }
    }
    
    /// Create a new album
    func createAlbum(name: String, coverImage: String, completion: @escaping (Result<RecipeAlbum, FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        let albumId = UUID()
        
        let albumData: [String: Any] = [
            "name": name,
            "coverImage": coverImage,
            "createdAt": FieldValue.serverTimestamp()
        ]
        
        db.collection("users").document(userId).collection("albums").document(albumId.uuidString)
            .setData(albumData) { error in
                if let error = error {
                    print("Error creating album: \(error.localizedDescription)")
                    completion(.failure(.documentCreationFailed))
                    return
                }
                
                let album = RecipeAlbum(id: albumId, name: name, coverImage: coverImage, recipes: [])
                completion(.success(album))
            }
    }
    
    /// Delete an album
    func deleteAlbum(albumId: UUID, completion: @escaping (Result<Void, FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        db.collection("users").document(userId).collection("albums").document(albumId.uuidString)
            .collection("recipes").getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting recipes for deletion: \(error.localizedDescription)")
                    completion(.failure(.networkError))
                    return
                }
                
                let batch = self.db.batch()
                
                snapshot?.documents.forEach { doc in
                    let recipeRef = self.db.collection("users").document(userId)
                        .collection("albums").document(albumId.uuidString)
                        .collection("recipes").document(doc.documentID)
                    batch.deleteDocument(recipeRef)
                }
                
                batch.commit { error in
                    if let error = error {
                        print("Error deleting recipes: \(error.localizedDescription)")
                        completion(.failure(.documentDeletionFailed))
                        return
                    }
                    
                    self.db.collection("users").document(userId)
                        .collection("albums").document(albumId.uuidString)
                        .delete { error in
                            if let error = error {
                                print("Error deleting album: \(error.localizedDescription)")
                                completion(.failure(.documentDeletionFailed))
                                return
                            }
                            
                            completion(.success(()))
                        }
                }
            }
    }
    
    /// Update album name
    func updateAlbumName(albumId: UUID, newName: String, completion: @escaping (Result<Void, FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        db.collection("users").document(userId).collection("albums").document(albumId.uuidString)
            .updateData(["name": newName]) { error in
                if let error = error {
                    print("Error updating album name: \(error.localizedDescription)")
                    completion(.failure(.documentUpdateFailed))
                    return
                }
                
                completion(.success(()))
            }
    }
    
    // MARK: - Recipes
    
    /// Get all recipes for an album
    private func getRecipes(forAlbumId albumId: UUID, completion: @escaping (Result<[Recipe], FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        db.collection("users").document(userId).collection("albums").document(albumId.uuidString)
            .collection("recipes").getDocuments { (snapshot, error) in
                if let error = error {
                    print("Error getting recipes: \(error.localizedDescription)")
                    completion(.failure(.networkError))
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    completion(.success([]))
                    return
                }
                
                let recipes = documents.compactMap { document -> Recipe? in
                    let data = document.data()
                    
                    guard let recipeId = UUID(uuidString: document.documentID),
                          let name = data["name"] as? String,
                          let image = data["image"] as? String,
                          let ingredients = data["ingredients"] as? [String],
                          let instructions = data["instructions"] as? [String] else {
                        return nil
                    }
                    
                    let originalIngredients = data["originalIngredients"] as? [String] ?? ingredients
                    
                    return Recipe(
                        id: recipeId,
                        name: name,
                        image: image,
                        ingredients: ingredients,
                        instructions: instructions,
                        originalIngredients: originalIngredients,
                        albumId: albumId
                    )
                }
                
                completion(.success(recipes))
            }
    }
    
    /// Save a recipe to an album (handles both creation and updates)
    func saveRecipe(to albumId: UUID, recipe: Recipe, completion: @escaping (Result<Recipe, FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        var recipeData: [String: Any] = [
            "name": recipe.name,
            "image": recipe.image,
            "ingredients": recipe.ingredients,
            "instructions": recipe.instructions,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        
        if recipe.originalIngredients != recipe.ingredients {
            recipeData["originalIngredients"] = recipe.originalIngredients
        } else {
            recipeData["originalIngredients"] = recipe.ingredients
        }
        
        db.collection("users").document(userId)
            .collection("albums").document(albumId.uuidString)
            .collection("recipes").document(recipe.id.uuidString)
            .setData(recipeData, merge: true) { error in
                if let error = error {
                    print("Error saving recipe: \(error.localizedDescription)")
                    completion(.failure(.documentUpdateFailed))
                    return
                }
                
                var savedRecipe = recipe
                savedRecipe.albumId = albumId
                completion(.success(savedRecipe))
            }
    }
    
    /// Delete recipes from an album
    func deleteRecipes(fromAlbumId albumId: UUID, recipeIds: Set<UUID>, completion: @escaping (Result<Void, FirestoreError>) -> Void) {
        guard let userId = Auth.auth().currentUser?.uid else {
            completion(.failure(.notAuthenticated))
            return
        }
        
        let batch = db.batch()
        
        for recipeId in recipeIds {
            let recipeRef = db.collection("users").document(userId)
                .collection("albums").document(albumId.uuidString)
                .collection("recipes").document(recipeId.uuidString)
            
            batch.deleteDocument(recipeRef)
        }
        
        batch.commit { error in
            if let error = error {
                print("Error deleting recipes: \(error.localizedDescription)")
                completion(.failure(.documentDeletionFailed))
                return
            }
            
            completion(.success(()))
        }
    }
}
