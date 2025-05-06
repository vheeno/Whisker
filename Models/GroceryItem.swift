//
//  GroceryItem.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//

import Foundation

struct GroceryItem: Identifiable, Codable, Hashable {
    var id = UUID()
    var name: String
    var isChecked: Bool
    var recipeSource: String?
    
    /// Initialize with name and checked status
    init(name: String, isChecked: Bool = false, recipeSource: String? = nil) {
        self.name = name
        self.isChecked = isChecked
        self.recipeSource = recipeSource
    }
    
    /// Initialize with specific ID
    init(id: UUID, name: String, isChecked: Bool = false, recipeSource: String? = nil) {
        self.id = id
        self.name = name
        self.isChecked = isChecked
        self.recipeSource = recipeSource
    }
}
