//
//  MeasurementUtils.swift
//  Whisker
//

import Foundation

/// Shared utility functions for working with recipe measurements
struct MeasurementUtils {
    
    // MARK: - Unicode Fraction Definitions
    
    /// Unicode fraction characters and their decimal values
    static let unicodeFractions: [String: Double] = [
        "½": 0.5,
        "⅓": 1.0/3.0,
        "⅔": 2.0/3.0,
        "¼": 0.25,
        "¾": 0.75,
        "⅕": 0.2,
        "⅖": 0.4,
        "⅗": 0.6,
        "⅘": 0.8,
        "⅙": 1.0/6.0,
        "⅚": 5.0/6.0,
        "⅐": 1.0/7.0,
        "⅛": 0.125,
        "⅜": 0.375,
        "⅝": 0.625,
        "⅞": 0.875,
        "⅑": 1.0/9.0,
        "⅒": 0.1
    ]
    
    // MARK: - Regular Expression Patterns
    
    static let imperialVolumePattern = #"(\d*\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒]|\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s*(cup|cups|c\.|tablespoon|tablespoons|tbsp|tbsps|tbs|tbs\.|teaspoon|teaspoons|tsp|tsps|tsp\.|fluid ounce|fluid ounces|fl oz|fl\.oz\.|quart|quarts|qt|qt\.|pint|pints|pt|pt\.|gallon|gallons|gal|gal\.)"#
    
    static let imperialWeightPattern = #"(\d*\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒]|\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s*(pound|pounds|lb|lbs|lb\.|ounce|ounces|oz|oz\.)"#
    
    static let metricVolumePattern = #"(\d*\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒]|\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s*(milliliter|milliliters|ml|mL|liter|liters|l|L)"#
    
    static let metricWeightPattern = #"(\d*\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒]|\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s*(gram|grams|g|g\.|kilogram|kilograms|kg|kg\.)"#
    
    static let numericQuantityPattern = #"^(\d*\s*[½⅓⅔¼¾⅕⅖⅗⅘⅙⅚⅐⅛⅜⅝⅞⅑⅒]|\d+(?:\s+\d+\/\d+|\.\d+|\/\d+)?)\s+(?!cup|cups|c\.|tablespoon|tablespoons|tbsp|tbsps|tbs|tbs\.|teaspoon|teaspoons|tsp|tsps|tsp\.|fluid ounce|fluid ounces|fl oz|fl\.oz\.|quart|quarts|qt|qt\.|pint|pints|pt|pt\.|gallon|gallons|gal|gal\.|pound|pounds|lb|lbs|lb\.|ounce|ounces|oz|oz\.|gram|grams|g|g\.|kilogram|kilograms|kg|kg\.|milliliter|milliliters|ml|mL|liter|liters|l|L)"#
    
    static var allPatterns: [String] {
        return [imperialVolumePattern, imperialWeightPattern, metricVolumePattern, metricWeightPattern, numericQuantityPattern]
    }
    
    // MARK: - Unit Definitions
    
    /// Represents a measurement unit with conversion information
    struct Unit {
        let name: String              // Base name of the unit (e.g., "cup")
        let abbreviations: [String]   // Common abbreviations (e.g., ["c.", "cups"])
        let type: UnitType            // Volume or weight
        let system: UnitSystem        // Imperial or metric
        let conversionFactor: Double  // Base value for conversion
        let metricEquivalent: String  // Name of equivalent metric unit
        let imperialEquivalent: String // Name of equivalent imperial unit
        
        /// Use to find the abbreviated form of the unit suitable for display
        var displayAbbreviation: String {
            return abbreviations.first ?? name
        }
    }
    
    enum UnitType {
        case volume
        case weight
    }
    
    enum UnitSystem {
        case imperial
        case metric
    }
    
    /// Definitions of all supported units with conversion factors
    static let unitDefinitions: [Unit] = [
        // Imperial volume units
        Unit(name: "cup", abbreviations: ["cup", "cups", "c."],
             type: .volume, system: .imperial,
             conversionFactor: 236.588, metricEquivalent: "ml", imperialEquivalent: "cup"),
        
        Unit(name: "tablespoon", abbreviations: ["tablespoon", "tablespoons", "tbsp", "tbsps", "tbs", "tbs."],
             type: .volume, system: .imperial,
             conversionFactor: 14.7868, metricEquivalent: "ml", imperialEquivalent: "tablespoon"),
        
        Unit(name: "teaspoon", abbreviations: ["teaspoon", "teaspoons", "tsp", "tsps", "tsp."],
             type: .volume, system: .imperial,
             conversionFactor: 4.92892, metricEquivalent: "ml", imperialEquivalent: "teaspoon"),
        
        Unit(name: "fluid ounce", abbreviations: ["fluid ounce", "fluid ounces", "fl oz", "fl.oz."],
             type: .volume, system: .imperial,
             conversionFactor: 29.5735, metricEquivalent: "ml", imperialEquivalent: "fluid ounce"),
        
        Unit(name: "quart", abbreviations: ["quart", "quarts", "qt", "qt."],
             type: .volume, system: .imperial,
             conversionFactor: 946.353, metricEquivalent: "ml", imperialEquivalent: "quart"),
        
        Unit(name: "pint", abbreviations: ["pint", "pints", "pt", "pt."],
             type: .volume, system: .imperial,
             conversionFactor: 473.176, metricEquivalent: "ml", imperialEquivalent: "pint"),
        
        Unit(name: "gallon", abbreviations: ["gallon", "gallons", "gal", "gal."],
             type: .volume, system: .imperial,
             conversionFactor: 3785.41, metricEquivalent: "ml", imperialEquivalent: "gallon"),
        
        // Imperial weight units
        Unit(name: "pound", abbreviations: ["pound", "pounds", "lb", "lbs", "lb."],
             type: .weight, system: .imperial,
             conversionFactor: 453.592, metricEquivalent: "g", imperialEquivalent: "pound"),
        
        Unit(name: "ounce", abbreviations: ["ounce", "ounces", "oz", "oz."],
             type: .weight, system: .imperial,
             conversionFactor: 28.3495, metricEquivalent: "g", imperialEquivalent: "ounce"),
        
        // Metric volume units
        Unit(name: "milliliter", abbreviations: ["milliliter", "milliliters", "ml", "mL"],
             type: .volume, system: .metric,
             conversionFactor: 1.0, metricEquivalent: "ml", imperialEquivalent: "teaspoon"),
        
        Unit(name: "liter", abbreviations: ["liter", "liters", "l", "L"],
             type: .volume, system: .metric,
             conversionFactor: 1000.0, metricEquivalent: "ml", imperialEquivalent: "quart"),
        
        // Metric weight units
        Unit(name: "gram", abbreviations: ["gram", "grams", "g", "g."],
             type: .weight, system: .metric,
             conversionFactor: 1.0, metricEquivalent: "g", imperialEquivalent: "ounce"),
        
        Unit(name: "kilogram", abbreviations: ["kilogram", "kilograms", "kg", "kg."],
             type: .weight, system: .metric,
             conversionFactor: 1000.0, metricEquivalent: "g", imperialEquivalent: "pound")
    ]
    
    // MARK: - Helper methods for unit lookup
    
    /// Find a unit definition by any of its names or abbreviations
    static func findUnit(for unitString: String) -> Unit? {
        let normalizedUnitString = unitString.lowercased()
        
        return unitDefinitions.first { unit in
            unit.name == normalizedUnitString ||
            unit.abbreviations.contains(normalizedUnitString)
        }
    }
    
    /// Find the appropriate target unit for conversion
    static func findTargetUnit(for sourceUnit: Unit, toMetric: Bool) -> Unit? {
        let targetName = toMetric ? sourceUnit.metricEquivalent : sourceUnit.imperialEquivalent
        
        return unitDefinitions.first { unit in
            unit.name == targetName || unit.abbreviations.contains(targetName)
        }
    }
    
    // MARK: - Value Parsing
    
    /// Parse a value string that might contain fractions or mixed numbers
    static func parseValueString(_ valueString: String) -> Double? {
        // Handle Unicode fractions alone (e.g., "½")
        if valueString.count == 1, let unicodeFraction = unicodeFractions[valueString] {
            return unicodeFraction
        }
        
        // Handle Unicode fractions with leading integer (e.g., "1½")
        for (fractionChar, fractionValue) in unicodeFractions {
            if valueString.contains(fractionChar) {
                let components = valueString.components(separatedBy: fractionChar)
                if components.count == 2 {
                    let wholeString = components[0].trimmingCharacters(in: .whitespaces)
                    if wholeString.isEmpty {
                        // Just the fraction (e.g., "½")
                        return fractionValue
                    } else if let wholeNumber = Double(wholeString) {
                        // Mixed number with Unicode fraction (e.g., "1½")
                        return wholeNumber + fractionValue
                    }
                }
            }
        }
        
        // Check if it's a simple decimal number
        if let value = Double(valueString) {
            return value
        }
        
        // Check if it's a simple fraction like "1/2"
        if valueString.contains("/") {
            let components = valueString.components(separatedBy: "/")
            if components.count == 2,
               let numerator = Double(components[0].trimmingCharacters(in: .whitespaces)),
               let denominator = Double(components[1].trimmingCharacters(in: .whitespaces)),
               denominator != 0 {
                return numerator / denominator
            }
        }
        
        // Check if it's a mixed number like "1 1/2"
        let parts = valueString.components(separatedBy: .whitespaces)
        if parts.count == 2,
           let wholeNumber = Double(parts[0]),
           parts[1].contains("/") {
            let fractionParts = parts[1].components(separatedBy: "/")
            if fractionParts.count == 2,
               let numerator = Double(fractionParts[0]),
               let denominator = Double(fractionParts[1]),
               denominator != 0 {
                return wholeNumber + (numerator / denominator)
            }
        }
        
        return nil
    }
    
    // MARK: - Value Formatting
    
    /// Format a value to display with appropriate precision, handling fractions
    static func formatValue(_ value: Double) -> String {
        // Handle whole numbers
        if value == Double(Int(value)) {
            return "\(Int(value))"
        }
        
        // Try to convert to a friendly fraction for common values if the number is less than 10
        if value < 10 {
            // Handle common fractions (1/4, 1/3, 1/2, 2/3, 3/4)
            let tolerance = 0.01
            
            // Try to convert to Unicode fractions for better readability
            if abs(value - 0.5) < tolerance {
                return "½"
            } else if abs(value - 0.25) < tolerance {
                return "¼"
            } else if abs(value - 0.75) < tolerance {
                return "¾"
            } else if abs(value - 1.0/3.0) < tolerance {
                return "⅓"
            } else if abs(value - 2.0/3.0) < tolerance {
                return "⅔"
            } else if abs(value - 0.125) < tolerance {
                return "⅛"
            } else if abs(value - 0.375) < tolerance {
                return "⅜"
            } else if abs(value - 0.625) < tolerance {
                return "⅝"
            } else if abs(value - 0.875) < tolerance {
                return "⅞"
            }
            
            // Handle mixed numbers with Unicode fractions
            let wholePart = Int(value)
            let fractionPart = value - Double(wholePart)
            
            if wholePart > 0 {
                if abs(fractionPart - 0.5) < tolerance {
                    return "\(wholePart)½"
                } else if abs(fractionPart - 0.25) < tolerance {
                    return "\(wholePart)¼"
                } else if abs(fractionPart - 0.75) < tolerance {
                    return "\(wholePart)¾"
                } else if abs(fractionPart - 1.0/3.0) < tolerance {
                    return "\(wholePart)⅓"
                } else if abs(fractionPart - 2.0/3.0) < tolerance {
                    return "\(wholePart)⅔"
                } else if abs(fractionPart - 0.125) < tolerance {
                    return "\(wholePart)⅛"
                } else if abs(fractionPart - 0.375) < tolerance {
                    return "\(wholePart)⅜"
                } else if abs(fractionPart - 0.625) < tolerance {
                    return "\(wholePart)⅝"
                } else if abs(fractionPart - 0.875) < tolerance {
                    return "\(wholePart)⅞"
                }
            }
        }
        
        // For values that don't fit common fractions, use decimal format
        // Round to 2 decimal places
        let rounded = (value * 100).rounded() / 100
        
        // Format to avoid trailing zeros
        if rounded == Double(Int(rounded)) {
            return "\(Int(rounded))"
        } else {
            return String(format: "%.2f", rounded).replacingOccurrences(of: ".00", with: "")
        }
    }
    
    // MARK: - Measurement Extraction
    
    /// Extract measurement components from a text string
    static func extractMeasurements(from text: String) -> [(value: Double, unit: String, range: Range<String.Index>)]? {
        var results: [(value: Double, unit: String, range: Range<String.Index>)] = []
        
        for pattern in allPatterns {
            do {
                let regex = try NSRegularExpression(pattern: pattern, options: [.caseInsensitive])
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                for match in matches {
                    if let valueRange = Range(match.range(at: 1), in: text),
                       match.numberOfRanges > 2,
                       let unitRange = Range(match.range(at: 2), in: text),
                       let fullRange = Range(match.range, in: text) {
                        
                        let valueString = String(text[valueRange])
                        let unit = String(text[unitRange])
                        
                        if let value = parseValueString(valueString) {
                            results.append((value: value, unit: unit, range: fullRange))
                        }
                    } else if let valueRange = Range(match.range(at: 1), in: text),
                              let fullRange = Range(match.range, in: text) {
                        // Handle case for numeric only pattern
                        let valueString = String(text[valueRange])
                        
                        if let value = parseValueString(valueString) {
                            results.append((value: value, unit: "", range: fullRange))
                        }
                    }
                }
            } catch {
                print("Error with regex pattern: \(error.localizedDescription)")
            }
        }
        
        return results.isEmpty ? nil : results
    }
}
