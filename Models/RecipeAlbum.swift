//
//  RecipeAlbum.swift
//  Whisker
//
//  Created by Julia Yu on 4/29/25.
//

import Foundation

struct RecipeAlbum: Identifiable {
    var id: UUID
    var name: String
    var coverImage: String
    var recipes: [Recipe]
    
    // Default initializer with generated ID
    init(name: String, coverImage: String, recipes: [Recipe]) {
        self.id = UUID()
        self.name = name
        self.coverImage = coverImage
        self.recipes = recipes
    }
    
    // Custom initializer with specified ID
    init(id: UUID, name: String, coverImage: String, recipes: [Recipe]) {
        self.id = id
        self.name = name
        self.coverImage = coverImage
        self.recipes = recipes
    }
}
