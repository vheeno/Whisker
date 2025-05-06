//
//  UnitConverterService.swift
//  Whisker
//
//  Refactored for improved organization and reduced redundancy
//

import Foundation

/// Service for converting between imperial and metric units in recipes
class UnitConverterService {
    static let shared = UnitConverterService()
    
    // Private initializer for singleton pattern
    private init() {}
    
    /// Convert a text ingredient from imperial to metric or vice versa - with improved pluralization
        /// - Parameters:
        ///   - text: The ingredient text to convert
        ///   - toMetric: True if converting to metric, false for imperial
        /// - Returns: The converted text
        func convertIngredient(_ text: String, toMetric: Bool) -> String {
            var result = text
            
            // Get all measurements from the text
            guard let measurements = MeasurementUtils.extractMeasurements(from: text) else {
                return text // No measurements found, return original text
            }
            
            // Process measurements in reverse to avoid range issues when replacing
            for (value, unitString, range) in measurements.reversed() {
                // Skip measurements without a unit
                guard !unitString.isEmpty else { continue }
                
                // Find the unit definition
                if let sourceUnit = MeasurementUtils.findUnit(for: unitString),
                   let targetUnit = MeasurementUtils.findTargetUnit(for: sourceUnit, toMetric: toMetric) {
                    
                    // Only convert if the source and target units have different systems
                    if (sourceUnit.system == .imperial && toMetric) || (sourceUnit.system == .metric && !toMetric) {
                        // Calculate the converted value
                        let convertedValue = convertValue(value, from: sourceUnit, to: targetUnit)
                        
                        // Find the most appropriate unit for the converted value
                        let (bestValue, bestUnit) = findBestUnit(convertedValue, type: sourceUnit.type, targetSystem: toMetric ? .metric : .imperial)
                        
                        // Format the value and create the new measurement string
                        let formattedValue = MeasurementUtils.formatValue(bestValue)
                        
                        // Apply pluralization rules
                        let unitDisplay = getUnitDisplay(value: bestValue, unit: bestUnit)
                        
                        let newMeasurement = "\(formattedValue) \(unitDisplay)"
                        
                        // Replace the old measurement with the new one
                        result = result.replacingCharacters(in: range, with: newMeasurement)
                    }
                }
            }
            
            return result
        }
    
    /// Convert a value from one unit to another
    /// - Parameters:
    ///   - value: The value to convert
    ///   - sourceUnit: The source unit
    ///   - targetUnit: The target unit
    /// - Returns: The converted value
    private func convertValue(_ value: Double, from sourceUnit: MeasurementUtils.Unit, to targetUnit: MeasurementUtils.Unit) -> Double {
        // First convert to base unit (ml or g)
        let baseValue = value * sourceUnit.conversionFactor
        
        // Then convert from base unit to target unit
        return baseValue / targetUnit.conversionFactor
    }
    
    /// Find the most appropriate unit for a measurement value
    /// - Parameters:
    ///   - value: The value to represent
    ///   - type: The type of unit (volume or weight)
    ///   - targetSystem: The unit system to use (imperial or metric)
    /// - Returns: A tuple containing the adjusted value and the recommended unit
    private func findBestUnit(_ value: Double, type: MeasurementUtils.UnitType, targetSystem: MeasurementUtils.UnitSystem) -> (Double, MeasurementUtils.Unit) {
        // Get all units of the specified type and system
        let eligibleUnits = MeasurementUtils.unitDefinitions.filter {
            $0.type == type && $0.system == targetSystem
        }
        
        // Convert the value to the base unit (ml or g)
        let baseUnit = eligibleUnits.first { $0.conversionFactor == 1.0 } ?? eligibleUnits.first!
        let baseValue = value
        
        // Define reasonable ranges for each unit type
        var bestUnit = baseUnit
        var bestValue = baseValue
        
        if type == .volume {
            if targetSystem == .imperial {
                // Imperial volume unit selection
                if baseValue >= 3785 {  // >= 1 gallon
                    bestUnit = eligibleUnits.first { $0.name == "gallon" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else if baseValue >= 946 {  // >= 1 quart
                    bestUnit = eligibleUnits.first { $0.name == "quart" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else if baseValue >= 473 {  // >= 1 pint
                    bestUnit = eligibleUnits.first { $0.name == "pint" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else if baseValue >= 59 {  // >= 1/4 cup (use cups for most measurements)
                    bestUnit = eligibleUnits.first { $0.name == "cup" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else if baseValue >= 14.8 {  // >= 1 tablespoon
                    bestUnit = eligibleUnits.first { $0.name == "tablespoon" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else {  // Use teaspoons for small amounts
                    bestUnit = eligibleUnits.first { $0.name == "teaspoon" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                }
            } else {
                // Metric volume unit selection
                if baseValue >= 1000 {  // >= 1 liter
                    bestUnit = eligibleUnits.first { $0.name == "liter" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else {  // Use milliliters for smaller amounts
                    bestUnit = eligibleUnits.first { $0.name == "milliliter" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                }
            }
        } else if type == .weight {
            if targetSystem == .imperial {
                // Imperial weight unit selection
                if baseValue >= 453.6 {  // >= 1 pound
                    bestUnit = eligibleUnits.first { $0.name == "pound" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else {  // Use ounces for smaller weights
                    bestUnit = eligibleUnits.first { $0.name == "ounce" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                }
            } else {
                // Metric weight unit selection
                if baseValue >= 1000 {  // >= 1 kilogram
                    bestUnit = eligibleUnits.first { $0.name == "kilogram" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                } else {  // Use grams for smaller weights
                    bestUnit = eligibleUnits.first { $0.name == "gram" }!
                    bestValue = baseValue / bestUnit.conversionFactor
                }
            }
        }
        
        return (bestValue, bestUnit)
    }
    
    /// Convert a batch of ingredients
    /// - Parameters:
    ///   - ingredients: Array of ingredient strings
    ///   - toMetric: Whether to convert to metric (true) or imperial (false)
    /// - Returns: Array of converted ingredient strings
    func convertIngredients(_ ingredients: [String], toMetric: Bool) -> [String] {
        return ingredients.map { convertIngredient($0, toMetric: toMetric) }
    }
    
    /// Returns the appropriate display form of the unit (singular or plural)
        /// - Parameters:
        ///   - value: The numeric value associated with the unit
        ///   - unit: The unit definition
        /// - Returns: The display form of the unit with proper pluralization
        private func getUnitDisplay(value: Double, unit: MeasurementUtils.Unit) -> String {
            // Use the abbreviated form for metric units
            if unit.system == .metric {
                return unit.displayAbbreviation
            }
            
            // For imperial units, handle pluralization
            let shouldPluralize = value > 1.0 && value != 0
            
            switch unit.name {
            case "cup":
                return shouldPluralize ? "cups" : "cup"
            case "tablespoon":
                return shouldPluralize ? "tablespoons" : "tablespoon"
            case "teaspoon":
                return shouldPluralize ? "teaspoons" : "teaspoon"
            case "fluid ounce":
                return shouldPluralize ? "fluid ounces" : "fluid ounce"
            case "quart":
                return shouldPluralize ? "quarts" : "quart"
            case "pint":
                return shouldPluralize ? "pints" : "pint"
            case "gallon":
                return shouldPluralize ? "gallons" : "gallon"
            case "pound":
                return shouldPluralize ? "pounds" : "pound"
            case "ounce":
                return shouldPluralize ? "ounces" : "ounce"
            default:
                // For units not explicitly handled, use displayAbbreviation
                return unit.displayAbbreviation
            }
        }
    }

