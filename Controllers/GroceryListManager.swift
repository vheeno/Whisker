//
//  GroceryListManager.swift
//  Whisker
//

import Foundation
import SwiftUI
import Combine
import FirebaseAuth
import FirebaseFirestore

// MARK: - Grocery List Manager

class GroceryListManager: ObservableObject {
    static let shared = GroceryListManager()
    
    @Published var groceryItems: [GroceryItem] = []
    @Published var isLoading: Bool = false
    @Published var error: String? = nil
    
    private let db = Firestore.firestore()
    
    private init() {
        setupAuthListener()
    }
    
    // MARK: - Authentication
    
    private func setupAuthListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (auth, user) in
            if let user = user {
                self?.loadGroceryList()
            } else {
                self?.groceryItems = []
            }
        }
    }
    
    // MARK: - Data Loading
    
    func loadGroceryList() {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        isLoading = true
        error = nil
        
        db.collection("users").document(userId).collection("groceryList")
            .getDocuments { [weak self] (snapshot, error) in
                DispatchQueue.main.async {
                    self?.isLoading = false
                    
                    if let error = error {
                        self?.error = error.localizedDescription
                        return
                    }
                    
                    guard let documents = snapshot?.documents else {
                        self?.groceryItems = []
                        return
                    }
                    
                    let items = documents.compactMap { document -> GroceryItem? in
                        let data = document.data()
                        
                        guard let name = data["name"] as? String,
                              let isChecked = data["isChecked"] as? Bool else {
                            return nil
                        }
                        
                        let recipeSource = data["recipeSource"] as? String
                        
                        guard let itemId = UUID(uuidString: document.documentID) else {
                            return nil
                        }
                        
                        return GroceryItem(
                            id: itemId,
                            name: name,
                            isChecked: isChecked,
                            recipeSource: recipeSource
                        )
                    }
                    
                    self?.groceryItems = items.sorted { item1, item2 in
                        if item1.isChecked != item2.isChecked {
                            return !item1.isChecked
                        }
                        return item1.name.lowercased() < item2.name.lowercased()
                    }
                }
            }
    }
    
    // MARK: - Data Manipulation
    
    func addItems(_ items: [GroceryItem], fromRecipe recipeName: String? = nil) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        if items.isEmpty {
            return
        }
        
        isLoading = true
        error = nil
        
        let batch = db.batch()
        
        var newItems: [GroceryItem] = []
        
        for var item in items {
            if item.recipeSource == nil {
                item.recipeSource = recipeName
            }
            
            if let existingIndex = groceryItems.firstIndex(where: { $0.name.lowercased() == item.name.lowercased() }) {
                continue
            }
            
            let docRef = db.collection("users").document(userId).collection("groceryList").document(item.id.uuidString)
            
            batch.setData([
                "name": item.name,
                "isChecked": item.isChecked,
                "recipeSource": item.recipeSource as Any,
                "createdAt": FieldValue.serverTimestamp()
            ], forDocument: docRef)
            
            newItems.append(item)
        }
        
        batch.commit { [weak self] error in
            DispatchQueue.main.async {
                self?.isLoading = false
                
                if let error = error {
                    self?.error = error.localizedDescription
                    return
                }
                
                var updatedItems = self?.groceryItems ?? []
                
                for item in newItems {
                    if !updatedItems.contains(where: { $0.name.lowercased() == item.name.lowercased() }) {
                        updatedItems.append(item)
                    }
                }
                
                self?.groceryItems = updatedItems.sorted { item1, item2 in
                    if item1.isChecked != item2.isChecked {
                        return !item1.isChecked
                    }
                    return item1.name.lowercased() < item2.name.lowercased()
                }
            }
        }
    }
    
    func toggleItemChecked(_ id: UUID) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        guard let index = groceryItems.firstIndex(where: { $0.id == id }) else {
            return
        }
        
        groceryItems[index].isChecked.toggle()
        let isChecked = groceryItems[index].isChecked
        
        groceryItems = groceryItems.sorted { item1, item2 in
            if item1.isChecked != item2.isChecked {
                return !item1.isChecked
            }
            return item1.name.lowercased() < item2.name.lowercased()
        }
        
        db.collection("users").document(userId).collection("groceryList").document(id.uuidString)
            .updateData([
                "isChecked": isChecked,
                "updatedAt": FieldValue.serverTimestamp()
            ]) { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                    
                    DispatchQueue.main.async {
                        if let index = self?.groceryItems.firstIndex(where: { $0.id == id }) {
                            self?.groceryItems[index].isChecked = !isChecked
                            
                            self?.groceryItems = (self?.groceryItems.sorted { item1, item2 in
                                if item1.isChecked != item2.isChecked {
                                    return !item1.isChecked
                                }
                                return item1.name.lowercased() < item2.name.lowercased()
                            }) ?? []
                        }
                    }
                }
            }
    }
    
    func removeItem(_ id: UUID) {
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        groceryItems.removeAll { $0.id == id }
        
        db.collection("users").document(userId).collection("groceryList").document(id.uuidString)
            .delete { [weak self] error in
                if let error = error {
                    self?.error = error.localizedDescription
                    self?.loadGroceryList()
                }
            }
    }
    
    func clearCheckedItems() {
        let checkedIds = groceryItems.filter { $0.isChecked }.map { $0.id }
        guard !checkedIds.isEmpty else { return }
        
        guard let userId = Auth.auth().currentUser?.uid else {
            self.error = "User not authenticated"
            return
        }
        
        groceryItems.removeAll { $0.isChecked }
        
        let batch = db.batch()
        
        for id in checkedIds {
            let docRef = db.collection("users").document(userId).collection("groceryList").document(id.uuidString)
            batch.deleteDocument(docRef)
        }
        
        batch.commit { [weak self] error in
            if let error = error {
                self?.error = error.localizedDescription
                self?.loadGroceryList()
            }
        }
    }
    
    // MARK: - Data Organization
    
    func itemsByRecipe() -> [String: [GroceryItem]] {
        var result: [String: [GroceryItem]] = [:]
        
        for item in groceryItems {
            let key = item.recipeSource ?? "Other Items"
            var items = result[key] ?? []
            items.append(item)
            result[key] = items
        }
        
        return result
    }
    
    func searchItems(query: String) -> [GroceryItem] {
        guard !query.isEmpty else {
            return groceryItems
        }
        
        let lowercasedQuery = query.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        
        return groceryItems.filter { item in
            item.name.lowercased().contains(lowercasedQuery) ||
            (item.recipeSource?.lowercased().contains(lowercasedQuery) ?? false)
        }
    }
}
