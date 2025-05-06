//
//  Recipe.swift
//  Whisker
//
//  Created by Julia Yu on 4/12/25.
//
import SwiftUI

struct Recipe: Identifiable {
    var id: UUID
    var name: String
    var image: String
    var ingredients: [String]
    var instructions: [String]
    
    // Original ingredients (needed for toggling between unit systems)
    var originalIngredients: [String]
    
    var albumId: UUID?
    
    // Default initializer that generates a new ID
    init(name: String, image: String, ingredients: [String], instructions: [String], albumId: UUID? = nil) {
        self.id = UUID()
        self.name = name
        self.image = image
        self.ingredients = ingredients
        self.originalIngredients = ingredients
        self.instructions = instructions
        self.albumId = albumId
    }
    
    // Custom initializer that allows specifying an ID (for updates)
    init(id: UUID, name: String, image: String, ingredients: [String], instructions: [String], albumId: UUID? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.ingredients = ingredients
        self.originalIngredients = ingredients
        self.instructions = instructions
        self.albumId = albumId
    }
    
    init(id: UUID = UUID(), name: String, image: String, ingredients: [String], instructions: [String], originalIngredients: [String] = [], albumId: UUID? = nil) {
        self.id = id
        self.name = name
        self.image = image
        self.ingredients = ingredients
        self.instructions = instructions
        self.originalIngredients = originalIngredients.isEmpty ? ingredients : originalIngredients
        self.albumId = albumId
    }
    
    mutating func convertIngredientsTo(useMetric: Bool) {
        let converter = UnitConverterService.shared
        
        // Use original ingredients as the source to avoid cumulative conversion errors
        ingredients = originalIngredients.map { ingredient in
            converter.convertIngredient(ingredient, toMetric: useMetric)
        }
    }
}

// MARK: - Recipe Unit Preferences
class RecipeUnitPreferences: ObservableObject {
    static let shared = RecipeUnitPreferences()
    
    @Published var useMetricUnits: Bool {
        didSet {
            UserDefaults.standard.set(useMetricUnits, forKey: "useMetricUnits")
        }
    }
    
    private init() {
        // Read the preference from UserDefaults or default to false (imperial)
        self.useMetricUnits = UserDefaults.standard.bool(forKey: "useMetricUnits")
    }
}
