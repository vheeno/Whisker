//
//  RecipeScalingService.swift
//  Whisker
//

import Foundation
import Combine
import SwiftUI

// MARK: - Recipe Scaling Service

class RecipeScalingService {
    static let shared = RecipeScalingService()
    
    func scaleIngredient(_ ingredient: String, by factor: Double) -> String {
        var result = ingredient
        
        guard let measurements = MeasurementUtils.extractMeasurements(from: ingredient) else {
            return ingredient
        }
        
        for (value, _, range) in measurements.reversed() {
            let scaledValue = value * factor
            let formattedValue = MeasurementUtils.formatValue(scaledValue)
            
            let originalMeasurement = String(ingredient[range])
            let valueString = String(ingredient[range]).components(separatedBy: " ").first ?? ""
            let newMeasurement = originalMeasurement.replacingOccurrences(of: valueString, with: formattedValue)
            
            result = result.replacingCharacters(in: range, with: newMeasurement)
        }
        
        return result
    }
    
    func scaleIngredients(_ ingredients: [String], by factor: Double) -> [String] {
        return ingredients.map { scaleIngredient($0, by: factor) }
    }
    
    func calculateScalingFactorFrom(originalIngredient: String, targetValue: Double) -> Double? {
        guard let measurements = MeasurementUtils.extractMeasurements(from: originalIngredient),
              let firstMeasurement = measurements.first else {
            return nil
        }
        
        let originalValue = firstMeasurement.value
        
        guard originalValue > 0 else { return nil }
        
        return targetValue / originalValue
    }
}

// MARK: - Recipe Scaling Manager

class RecipeScalingManager: ObservableObject {
    static let shared = RecipeScalingManager()
    
    @Published var scalingFactor: Double = 1.0
    @Published var originalIngredients: [String] = []
    @Published var scaledIngredients: [String] = []
    @Published var isCustomScaling: Bool = false
    @Published var customScalingIngredientIndex: Int?
    @Published var customScalingTargetValue: Double?
    
    private let scalingService = RecipeScalingService.shared
    
    private init() {}
    
    func setOriginalIngredients(_ ingredients: [String]) {
        self.originalIngredients = ingredients
        resetScaling()
    }
    
    func resetScaling() {
        scalingFactor = 1.0
        scaledIngredients = originalIngredients
        isCustomScaling = false
        customScalingIngredientIndex = nil
        customScalingTargetValue = nil
    }
    
    func applyScaling(factor: Double) {
        scalingFactor = factor
        isCustomScaling = false
        customScalingIngredientIndex = nil
        customScalingTargetValue = nil
        
        scaledIngredients = scaleIngredients(originalIngredients, by: factor)
    }
    
    func applyCustomScaling(ingredientIndex: Int, targetValue: Double) {
        guard ingredientIndex < originalIngredients.count else { return }
        
        let originalIngredient = originalIngredients[ingredientIndex]
        
        if let calculatedFactor = scalingService.calculateScalingFactorFrom(
            originalIngredient: originalIngredient,
            targetValue: targetValue
        ) {
            isCustomScaling = true
            customScalingIngredientIndex = ingredientIndex
            customScalingTargetValue = targetValue
            scalingFactor = calculatedFactor
            
            scaledIngredients = scaleIngredients(originalIngredients, by: calculatedFactor)
        }
    }
    
    func scaleIngredients(_ ingredients: [String], by factor: Double) -> [String] {
        return scalingService.scaleIngredients(ingredients, by: factor)
    }
    
    func getCurrentScaledRecipe(from recipe: Recipe) -> Recipe {
        var scaledRecipe = recipe
        scaledRecipe.ingredients = scaledIngredients
        return scaledRecipe
    }
}

// MARK: - Recipe Extension

extension Recipe {
    func scaled(by factor: Double) -> Recipe {
        let scalingService = RecipeScalingService.shared
        let scaledIngredients = scalingService.scaleIngredients(self.ingredients, by: factor)
        
        return Recipe(
            id: self.id,
            name: self.name,
            image: self.image,
            ingredients: scaledIngredients,
            instructions: self.instructions,
            originalIngredients: self.originalIngredients
        )
    }
    
    func scaledByIngredient(index: Int, targetValue: Double) -> Recipe? {
        guard index < ingredients.count else { return nil }
        
        let scalingService = RecipeScalingService.shared
        let originalIngredient = ingredients[index]
        
        if let factor = scalingService.calculateScalingFactorFrom(
            originalIngredient: originalIngredient,
            targetValue: targetValue
        ) {
            return scaled(by: factor)
        }
        
        return nil
    }
}
