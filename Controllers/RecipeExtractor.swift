import Foundation
import Alamofire
import SwiftSoup

// MARK: - Error Handling

enum RecipeExtractionError: Error {
    case noRecipeFound
    case parsingError(String)
    case networkError(Error)
    case invalidURL
    case jsonParsingError(String)
    case imageExtractionFailed
    case ingredientsExtractionFailed
    case instructionsExtractionFailed
    
    var localizedDescription: String {
        switch self {
        case .noRecipeFound:
            return "No recipe was found on this page"
        case .parsingError(let details):
            return "Error parsing recipe: \(details)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .invalidURL:
            return "The provided URL is invalid"
        case .jsonParsingError(let details):
            return "JSON parsing error: \(details)"
        case .imageExtractionFailed:
            return "Failed to extract recipe image"
        case .ingredientsExtractionFailed:
            return "Failed to extract recipe ingredients"
        case .instructionsExtractionFailed:
            return "Failed to extract recipe instructions"
        }
    }
}

// MARK: - Recipe Extractor Service

class RecipeExtractor {
    
    enum DebugLevel {
        case info
        case warning
        case error
    }
    
    // MARK: - Public API
    
    func extractRecipe(from url: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        let headers: HTTPHeaders = [
            "User-Agent": "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/15.0 Safari/605.1.15",
            "Accept": "text/html,application/xhtml+xml,application/xml",
            "Accept-Language": "en-US,en;q=0.9",
            "Cache-Control": "no-cache"
        ]
        
        print("Attempting to extract recipe from: \(url.absoluteString)")
        
        AF.request(url, headers: headers).responseString { response in
            switch response.result {
            case .success(let html):
                do {
                    let recipe = try self.parseRecipe(from: html, sourceURL: url)
                    
                    guard !recipe.ingredients.isEmpty else {
                        completion(.failure(RecipeExtractionError.ingredientsExtractionFailed))
                        return
                    }
                    
                    guard !recipe.instructions.isEmpty else {
                        completion(.failure(RecipeExtractionError.instructionsExtractionFailed))
                        return
                    }
                    
                    print("Successfully extracted recipe: \(recipe.name)")
                    completion(.success(recipe))
                } catch {
                    print("Extraction error: \(error.localizedDescription)")
                    completion(.failure(error))
                }
            case .failure(let error):
                print("Network error: \(error.localizedDescription)")
                completion(.failure(RecipeExtractionError.networkError(error)))
            }
        }
    }
    
    func extractRecipeFromHTML(_ html: String, sourceURL: URL, completion: @escaping (Result<Recipe, Error>) -> Void) {
        do {
            let recipe = try self.parseRecipe(from: html, sourceURL: sourceURL)
            completion(.success(recipe))
        } catch {
            completion(.failure(error))
        }
    }
    
    // MARK: - Recipe Parsing Logic
    
    private func parseRecipe(from html: String, sourceURL: URL) throws -> Recipe {
        let document = try SwiftSoup.parse(html)
        
        // Try multiple extraction methods in order of reliability
        if let jsonLdRecipe = try extractJsonLdRecipe(from: html) {
            return jsonLdRecipe
        }
        
        if let microdataRecipe = try extractMicrodataRecipe(from: document) {
            return microdataRecipe
        }
        
        // Fallback to HTML extraction
        return try parseHtmlRecipe(from: document, sourceURL: sourceURL)
    }
    
    // MARK: - Utility Methods
    
    private func cleanText(_ text: String) -> String {
        return text.trimmingCharacters(in: .whitespacesAndNewlines)
                   .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
                   .replacingOccurrences(of: "\\n+", with: " ", options: .regularExpression)
    }
    
    private func log(_ message: String, level: DebugLevel = .info) {
        #if DEBUG
        switch level {
        case .info:
            print("📘 [RecipeExtractor] INFO: \(message)")
        case .warning:
            print("⚠️ [RecipeExtractor] WARNING: \(message)")
        case .error:
            print("🔴 [RecipeExtractor] ERROR: \(message)")
        }
        #endif
    }
    
    static func isLikelyRecipePage(_ url: URL) -> Bool {
        let urlString = url.absoluteString.lowercased()
        let path = url.path.lowercased()
        
        let recipeKeywords = ["recipe", "recipes", "cooking", "food", "dish", "meal", "baking"]
        
        for keyword in recipeKeywords {
            if urlString.contains(keyword) {
                return true
            }
        }
        
        let recipeWebsites = [
            "allrecipes.com", "foodnetwork.com", "epicurious.com", "simplyrecipes.com",
            "bonappetit.com", "thekitchn.com", "seriouseats.com", "tasty.co",
            "food.com", "delish.com", "cooking.nytimes.com", "bbcgoodfood.com",
            "taste.com.au", "recipetineats.com", "budgetbytes.com", "skinnytaste.com"
        ]
        
        if let host = url.host?.lowercased() {
            for website in recipeWebsites {
                if host.contains(website) {
                    return true
                }
            }
        }
        
        return false
    }
}

// MARK: - JSON-LD Extraction
extension RecipeExtractor {
    private func extractJsonLdRecipe(from html: String) throws -> Recipe? {
        let document = try SwiftSoup.parse(html)
        let scripts = try document.select("script[type='application/ld+json']")
        
        for script in scripts {
            guard let jsonString = try? script.html() else { continue }
            
            do {
                let cleanedData = cleanJsonString(jsonString).data(using: .utf8) ?? Data()
                
                // Try parsing as array
                if let jsonArray = try? JSONSerialization.jsonObject(with: cleanedData) as? [Any] {
                    for item in jsonArray {
                        if let recipeObject = item as? [String: Any],
                           let recipe = extractRecipeFromJson(recipeObject) {
                            return recipe
                        }
                    }
                }
                
                // Try parsing as single object
                if let json = try? JSONSerialization.jsonObject(with: cleanedData) as? [String: Any] {
                    // Look for @graph array which might contain nested recipes
                    if let graph = json["@graph"] as? [[String: Any]] {
                        for item in graph {
                            if let recipe = extractRecipeFromJson(item) {
                                return recipe
                            }
                        }
                    }
                    
                    // Try direct extraction
                    if let recipe = extractRecipeFromJson(json) {
                        return recipe
                    }
                    
                    // Look deeper for nested objects
                    if let recipe = searchForNestedRecipe(in: json) {
                        return recipe
                    }
                }
            } catch {
                // Continue to the next script if this one fails
                continue
            }
        }
        
        return nil
    }
    
    // Handles JSON strings that might have invalid formatting
    private func cleanJsonString(_ jsonString: String) -> String {
        var cleaned = jsonString
            .replacingOccurrences(of: "\\/", with: "/")
            .replacingOccurrences(of: "\t", with: " ")
        
        cleaned = cleaned.replacingOccurrences(of: ",\\s*\\}", with: "}", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: ",\\s*\\]", with: "]", options: .regularExpression)
        cleaned = cleaned.replacingOccurrences(of: "\\s", with: " ")
        
        // Handle unescaped quotes in JSON
        cleaned = cleaned.replacingOccurrences(of: "([^\\\\])\"([^\"]*?)\"([^\"]*?)\"", with: "$1\"$2\\\"$3\"", options: .regularExpression)
        
        return cleaned
    }
    
    private func searchForNestedRecipe(in json: [String: Any]) -> Recipe? {
        // Check if this is a recipe
        if let recipe = extractRecipeFromJson(json) {
            return recipe
        }
        
        // Check all object values for nested recipes
        for (_, value) in json {
            if let nestedObject = value as? [String: Any] {
                if let recipe = extractRecipeFromJson(nestedObject) {
                    return recipe
                }
                
                // Try one level deeper
                if let recipe = searchForNestedRecipe(in: nestedObject) {
                    return recipe
                }
            } else if let nestedArray = value as? [[String: Any]] {
                // Check arrays of objects
                for item in nestedArray {
                    if let recipe = extractRecipeFromJson(item) {
                        return recipe
                    }
                }
            }
        }
        
        return nil
    }
    
    private func isJsonObjectRecipe(_ json: [String: Any]) -> Bool {
        // Check @type property
        if let type = json["@type"] as? String {
            return type == "Recipe" || type.hasSuffix("/Recipe")
        } else if let types = json["@type"] as? [String] {
            return types.contains("Recipe") || types.contains { $0.hasSuffix("/Recipe") }
        }
        
        // Check for common recipe properties as a fallback
        let recipeProperties = ["name", "recipeIngredient", "recipeInstructions"]
        let containsProperties = recipeProperties.reduce(0) { count, prop in
            return json[prop] != nil ? count + 1 : count
        }
        
        return containsProperties >= 2 // If it has at least 2 recipe properties
    }
    
    private func extractRecipeFromJson(_ json: [String: Any]) -> Recipe? {
        // Skip if not a recipe
        guard isJsonObjectRecipe(json) else { return nil }
        
        // Parse name with fallback
        let name = json["name"] as? String ?? json["headline"] as? String ?? "Untitled Recipe"
        
        // Parse ingredients
        let ingredients = extractIngredientsFromJson(json)
        
        // Parse instructions
        let instructionData = json["recipeInstructions"]
        let instructions = extractInstructionsFromJson(instructionData)
        
        // No recipe without ingredients and instructions
        if ingredients.isEmpty && instructions.isEmpty {
            return nil
        }
        
        // Parse image URL
        let imageURL = extractImageFromJson(json)
        
        return Recipe(
            name: name,
            image: imageURL,
            ingredients: ingredients,
            instructions: instructions
        )
    }
    
    private func extractIngredientsFromJson(_ json: [String: Any]) -> [String] {
        // Try multiple keys that might contain ingredients
        let possibleKeys = ["recipeIngredient", "ingredients", "recipeIngredients", "supply"]
        var ingredients: [String] = []
        
        for key in possibleKeys {
            if let ingredientList = json[key] as? [String] {
                ingredients = ingredientList
                break
            } else if let ingredientObject = json[key] as? [String: Any],
                      let text = ingredientObject["text"] as? String {
                // Handle case where ingredients are in a text property
                ingredients = text.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                break
            } else if let ingredientText = json[key] as? String {
                // Handle case where ingredients are in a single string
                ingredients = ingredientText.components(separatedBy: .newlines)
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty }
                break
            }
        }
        
        // Clean up ingredients
        return ingredients.map {
            $0.trimmingCharacters(in: .whitespacesAndNewlines)
              .replacingOccurrences(of: "\\s+", with: " ", options: .regularExpression)
        }.filter { !$0.isEmpty }
    }
    
    private func extractInstructionsFromJson(_ instructionData: Any?) -> [String] {
        // Handle HowToSection objects
        if let sections = instructionData as? [[String: Any]] {
            let howToSectionInstructions = parseHowToSectionInstructions(sections)
            if !howToSectionInstructions.isEmpty {
                return howToSectionInstructions
            }
        }
        
        // Handle string array
        if let instructionsArray = instructionData as? [String] {
            return instructionsArray.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                  .filter { !$0.isEmpty }
        }
        
        // Handle array of instruction objects
        if let instructionObjects = instructionData as? [[String: Any]] {
            return instructionObjects.compactMap { extractTextFromStep($0) }
        }
        
        // Handle single string with multiple steps
        if let instructionString = instructionData as? String {
            return parseInstructionString(instructionString)
        }
        
        return []
    }
    
    private func extractImageFromJson(_ json: [String: Any]) -> String {
        // Default placeholder
        let defaultImage = "photo"
        
        if let image = json["image"] as? String {
            return image
        } else if let imageObject = json["image"] as? [String: Any],
                  let url = imageObject["url"] as? String {
            return url
        } else if let imageArray = json["image"] as? [[String: Any]],
                  !imageArray.isEmpty,
                  let url = imageArray[0]["url"] as? String {
            return url
        } else if let imageArray = json["image"] as? [String],
                  !imageArray.isEmpty {
            return imageArray[0]
        }
        
        return defaultImage
    }
    
    private func parseHowToSectionInstructions(_ sections: [[String: Any]]) -> [String] {
        var allInstructions: [String] = []
        
        for section in sections {
            // Handle HowToSection type
            if let type = section["@type"] as? String,
               (type == "HowToSection" || type.hasSuffix("/HowToSection")) {
                if let sectionName = section["name"] as? String {
                    allInstructions.append("SECTION: \(sectionName)")
                }
                
                if let steps = section["itemListElement"] as? [[String: Any]] {
                    let stepTexts = steps.compactMap { extractTextFromStep($0) }
                    allInstructions.append(contentsOf: stepTexts)
                }
            }
            // Handle HowToStep type
            else if let type = section["@type"] as? String,
                    (type == "HowToStep" || type.hasSuffix("/HowToStep")) {
                if let stepText = extractTextFromStep(section) {
                    allInstructions.append(stepText)
                }
            }
        }
        
        return allInstructions
    }
    
    private func extractTextFromStep(_ step: [String: Any]) -> String? {
        // List of possible keys that might contain the step text
        let possibleTextKeys = ["text", "name", "@value", "instructions", "description", "itemListElement"]
        
        for key in possibleTextKeys {
            if let text = step[key] as? String {
                let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmedText.isEmpty {
                    return trimmedText
                }
            } else if let textObject = step[key] as? [String: Any],
                      let text = textObject["text"] as? String {
                // Handle nested text object format
                return text.trimmingCharacters(in: .whitespacesAndNewlines)
            } else if let textArray = step[key] as? [String] {
                // Handle array of text strings
                return textArray.joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        return nil
    }
}

// MARK: - Microdata Extraction
extension RecipeExtractor {
    private func extractMicrodataRecipe(from document: Document) throws -> Recipe? {
        // Look for elements with itemtype="http://schema.org/Recipe"
        let recipeElements = try document.select("[itemtype*='schema.org/Recipe'], [itemtype*='schema.org/recipe']")
        
        guard !recipeElements.isEmpty else { return nil }
        
        // Extract recipe name
        let nameElement = try recipeElements.select("[itemprop='name']").first()
        let name = try nameElement?.text() ?? "Untitled Recipe"
        
        // Extract ingredients
        let ingredientElements = try recipeElements.select("[itemprop='recipeIngredient'], [itemprop='ingredients']")
        let ingredients = try ingredientElements.map { try $0.text() }
        
        // Extract instructions
        let instructionElements = try recipeElements.select("[itemprop='recipeInstructions']")
        var instructions: [String] = []
        
        // Handle different instruction formats
        if !instructionElements.isEmpty {
            for element in instructionElements {
                // Check if it contains step elements
                let steps = try element.select("[itemprop='itemListElement'], [itemprop='text']")
                
                if !steps.isEmpty {
                    instructions.append(contentsOf: try steps.map { try $0.text() })
                } else {
                    // The element itself might contain the instruction text
                    instructions.append(try element.text())
                }
            }
        }
        
        // Extract image
        let imageElement = try recipeElements.select("[itemprop='image']").first()
        let imageUrl: String
        
        if let element = imageElement {
            if try element.tagName() == "img" {
                imageUrl = try element.attr("src")
            } else {
                imageUrl = try element.attr("content")
            }
        } else {
            imageUrl = "photo"
        }
        
        // If we couldn't extract enough data, return nil
        if ingredients.isEmpty && instructions.isEmpty {
            return nil
        }
        
        return Recipe(
            name: name,
            image: imageUrl,
            ingredients: ingredients,
            instructions: instructions
        )
    }
}

// MARK: - HTML Parsing
extension RecipeExtractor {
    private func parseHtmlRecipe(from document: Document, sourceURL: URL) throws -> Recipe {
        // Extract recipe components with improved selectors
        let name = try extractRecipeTitle(from: document, fallbackURL: sourceURL)
        let ingredients = try extractIngredients(from: document)
        let instructions = try extractInstructions(from: document)
        let image = try extractImage(from: document) ?? "photo"
        
        // Validate recipe has minimal requirements
        if ingredients.isEmpty && instructions.isEmpty {
            throw RecipeExtractionError.noRecipeFound
        }
        
        return Recipe(
            name: name,
            image: image,
            ingredients: ingredients,
            instructions: instructions
        )
    }
    
    private func extractRecipeTitle(from document: Document, fallbackURL: URL) throws -> String {
        // Extended list of title selectors
        let titleSelectors = [
            "h1.recipe__title",
            "h1.recipe-title",
            "h1.entry-title",
            "h1[class*='title']",
            "h1[class*='recipe']",
            "h1[itemprop='name']",
            ".recipe-title", // Non-h1 elements
            ".recipe__title",
            ".entry-title",
            "[class*='recipe'][class*='title']",
            ".post-title",
            ".article-title",
            ".heading-title",
            "h1" // Generic fallback
        ]
        
        // Try each selector
        for selector in titleSelectors {
            if let titleElement = try? document.select(selector).first(),
               let titleText = try? titleElement.text(),
               !titleText.isEmpty {
                return titleText.trimmingCharacters(in: .whitespacesAndNewlines)
            }
        }
        
        // Try to find the first large heading in the content area
        let contentSelectors = [".content", ".article", ".post", ".recipe", "article", "main"]
        for selector in contentSelectors {
            if let contentElement = try? document.select(selector).first() {
                if let headingElement = try? contentElement.select("h1, h2").first(),
                   let headingText = try? headingElement.text(),
                   !headingText.isEmpty {
                    return headingText.trimmingCharacters(in: .whitespacesAndNewlines)
                }
            }
        }
        
        // Fallback to page title
        if let titleElement = try? document.select("title").first(),
           let titleText = try? titleElement.text(),
           !titleText.isEmpty {
            return cleanPageTitle(titleText)
        }
        
        // Last resort: extract from URL
        return extractTitleFromURL(fallbackURL)
    }
    
    private func cleanPageTitle(_ titleText: String) -> String {
        // Remove site name patterns
        var title = titleText
            .replacingOccurrences(of: " - .+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: " \\| .+$", with: "", options: .regularExpression)
            .replacingOccurrences(of: " • .+$", with: "", options: .regularExpression)
        
        // Remove recipe/food keywords from title
        let removeWords = ["recipe", "recipes", "how to make", "how to cook"]
        for word in removeWords {
            title = title.replacingOccurrences(of: "(?i)\(word)", with: "", options: .regularExpression)
        }
        
        return title.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    private func extractTitleFromURL(_ url: URL) -> String {
        let host = url.host ?? ""
        let path = url.path
            .replacingOccurrences(of: "^/", with: "", options: .regularExpression)
            .replacingOccurrences(of: "-", with: " ")
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "/", with: " ")
        
        return "Recipe from \(host): \(path)"
    }
    
    private func extractIngredients(from document: Document) throws -> [String] {
        // Extended list of ingredient selectors
        let ingredientSelectors = [
            ".recipe__list--ingredients li",
            "ul.ingredients li",
            ".ingredient-list li",
            ".recipe-ingredients li",
            "[itemprop='recipeIngredient']",
            "[itemprop='ingredients']",
            ".recipe__ingredients li",
            "[class*='ingredient'] li",
            ".ingredients p",
            "[class*='ingredients']",
            // Additional selectors for problematic sites
            ".wprm-recipe-ingredient-group li",
            ".wprm-recipe-ingredients li",
            ".tasty-recipes-ingredients li",
            ".tasty-recipe-ingredients li",
            ".easyrecipe .ingredient",
            ".recipe-ingred_txt",
            ".entry-content ul li", // Generic fallback for blog posts
            "ul li" // Very generic fallback
        ]
        
        // Try structured selectors first
        for selector in ingredientSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                let items = try extractAndValidateItems(elements, isIngredient: true)
                if !items.isEmpty {
                    return items
                }
            }
        }
        
        // Try to find ingredient section by common headings
        let ingredientHeadings = ["Ingredients", "What You'll Need", "What You Need"]
        for heading in ingredientHeadings {
            if let ingredients = try extractSectionByHeading(document, heading: heading, isIngredient: true) {
                return ingredients
            }
        }
        
        // Last attempt - try generic lists
        return try searchGenericListsForIngredients(document)
    }
    
    private func extractSectionByHeading(_ document: Document, heading: String, isIngredient: Bool) throws -> [String]? {
        // Find headings that match the target heading text
        let headingElements = try document.select("h1, h2, h3, h4, h5, h6, .heading, [class*='heading'], [class*='title']")
        
        for headingElement in headingElements {
            let headingText = try headingElement.text().lowercased()
            if headingText.contains(heading.lowercased()) {
                // Found the heading, now get the content after it
                let elementAfter = try headingElement.nextElementSibling()
                
                if elementAfter != nil {
                    // Check if it's a list
                    let listItems = try elementAfter?.select("li")
                    if listItems != nil && !listItems!.isEmpty {
                        let items = try listItems!.map { try $0.text() }
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        if isIngredient {
                            return validateIngredientsLikelihood(items) ? items : nil
                        } else {
                            return validateInstructionsLikelihood(items) ? items : nil
                        }
                    }
                    
                    // Check if it's a paragraph list
                    let paragraphs = try elementAfter?.select("p")
                    if paragraphs != nil && !paragraphs!.isEmpty {
                        let items = try paragraphs!.map { try $0.text() }
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        if isIngredient {
                            return validateIngredientsLikelihood(items) ? items : nil
                        } else {
                            return validateInstructionsLikelihood(items) ? items : nil
                        }
                    }
                    
                    // Try to get text content and split it
                    if let textContent = try? elementAfter?.text() {
                        let items = textContent.components(separatedBy: .newlines)
                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                            .filter { !$0.isEmpty }
                        
                        if isIngredient {
                            return validateIngredientsLikelihood(items) ? items : nil
                        } else {
                            return validateInstructionsLikelihood(items) ? items : nil
                        }
                    }
                }
            }
        }
        
        return nil
    }
    
    private func searchGenericListsForIngredients(_ document: Document) throws -> [String] {
        // Try to find any unordered list that might be ingredients
        let allLists = try document.select("ul")
        
        for list in allLists {
            let elements = try list.select("li")
            let items = try extractAndValidateItems(elements, isIngredient: true)
            if !items.isEmpty {
                return items
            }
        }
        
        // Last resort: try to find comma-separated lists in paragraphs
        let paragraphs = try document.select("p")
        for paragraph in paragraphs {
            let text = try paragraph.text()
            if text.contains(",") && text.count < 500 { // Avoid long paragraphs
                let items = text.components(separatedBy: ",")
                    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                    .filter { !$0.isEmpty && $0.count < 100 } // Ingredient items shouldn't be too long
                
                if validateIngredientsLikelihood(items) {
                    return items
                }
            }
        }
        
        return []
    }
    
    private func extractAndValidateItems(_ elements: Elements, isIngredient: Bool) throws -> [String] {
        let items = try elements.map { try $0.text() }
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty && (isIngredient ? $0.count < 200 : $0.count > 10) }
        
        if isIngredient {
            return validateIngredientsLikelihood(items) ? items : []
        } else {
            return validateInstructionsLikelihood(items) ? items : []
        }
    }
    
    private func validateIngredientsLikelihood(_ items: [String]) -> Bool {
        // Skip validation for empty lists
        if items.isEmpty {
            return false
        }
        
        // Common ingredient terminology
        let commonUnits = ["cup", "cups", "tbsp", "tablespoon", "teaspoon", "tsp", "oz", "ounce",
                           "pound", "lb", "g", "gram", "kg", "ml", "l", "liter", "pinch", "dash",
                           "slice", "slices", "piece", "pieces", "clove", "cloves", "sprig", "sprigs"]
        
        let commonIngredients = ["flour", "sugar", "salt", "olive oil", "butter", "egg", "eggs",
                                "water", "milk", "vanilla", "pepper", "garlic", "onion", "chicken",
                                "beef", "pork", "rice", "pasta", "tomato", "potato", "carrot"]
        
        var likelyIngredientsCount = 0
        
        for item in items {
            let lowercased = item.lowercased()
            
            // Check if item has features of ingredients
            let hasNumbers = lowercased.rangeOfCharacter(from: .decimalDigits) != nil
            let hasQuantityWords = ["half", "quarter", "one", "two", "three", "four", "five", "handful"].contains { lowercased.contains($0) }
            let hasUnits = commonUnits.contains { unit in lowercased.contains(" \(unit)") || lowercased.contains(" \(unit)s") }
            let hasCommonIngredient = commonIngredients.contains { lowercased.contains($0) }
            
            if hasNumbers || hasQuantityWords || hasUnits || hasCommonIngredient {
                likelyIngredientsCount += 1
            }
        }
        
        // Consider it likely ingredients if at least 30% of items have ingredient features
        return items.count >= 2 && Double(likelyIngredientsCount) / Double(items.count) >= 0.3
    }
    
    private func extractInstructions(from document: Document) throws -> [String] {
        // Extended list of instruction selectors
        let instructionSelectors = [
            ".recipe__list--instructions li",
            ".recipe__instructions p",
            ".recipe-steps li",
            ".recipe-method li",
            ".recipe-instructions li",
            "[itemprop='recipeInstructions']",
            ".recipe__instruction-step",
            ".recipe-steps__item",
            ".recipe__instructions li",
            "[class*='instruction'] li",
            "[class*='direction'] li",
            "[class*='step'] li",
            "[class*='method'] li",
            ".instructions p",
            ".directions p",
            // Additional selectors for problematic sites
            ".wprm-recipe-instruction",
            ".wprm-recipe-instructions-text",
            ".tasty-recipes-instructions li",
            ".tasty-recipe-instructions li",
            ".easyrecipe .instruction",
            ".steps li",
            ".preparation li",
            "ol li" // Generic fallback for ordered lists
        ]
        
        // Try structured selectors first
        for selector in instructionSelectors {
            let elements = try document.select(selector)
            if !elements.isEmpty() {
                let instructions = try elements.map {
                    let text = try $0.text()
                    return text.replacingOccurrences(of: "^\\d+\\.\\s*", with: "", options: .regularExpression)
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                }.filter { !$0.isEmpty }
                
                if validateInstructionsLikelihood(instructions) {
                    return instructions
                }
            }
        }
        
        // Try instruction containers
        if let instructions = try extractFromInstructionContainers(document) {
            return instructions
        }
        
        // Try to find instructions section by common headings
        let instructionHeadings = ["Instructions", "Directions", "Method", "Steps", "Preparation", "How to Make It"]
        for heading in instructionHeadings {
            if let instructions = try extractSectionByHeading(document, heading: heading, isIngredient: false) {
                return instructions
            }
        }
        
        // Try to extract instructions from paragraphs in the content area
        let contentSelectors = [".content", ".article", ".post", ".recipe", "article", "main"]
        for selector in contentSelectors {
            if let contentElement = try? document.select(selector).first() {
                let paragraphs = try contentElement.select("p")
                if paragraphs.size() > 2 { // Need at least a few paragraphs
                    let paragraphTexts = try paragraphs.map { try $0.text() }
                        .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                        .filter { !$0.isEmpty && $0.count > 20 } // Instructions should be reasonably long
                    
                    if validateInstructionsLikelihood(paragraphTexts) {
                        return paragraphTexts
                    }
                }
            }
        }
        
        // Last resort: look for ordered lists
        return try searchForOrderedListInstructions(document)
    }
    
    private func extractFromInstructionContainers(_ document: Document) throws -> [String]? {
        let containerSelectors = [
            ".recipe__instructions",
            ".recipe-instructions",
            ".recipe-steps",
            ".recipe-method",
            "[itemprop='recipeInstructions']",
            "[class*='instruction']",
            "[class*='direction']",
            "[class*='step']",
            "[class*='method']",
            // Additional container selectors
            ".wprm-recipe-instructions",
            ".tasty-recipes-instructions",
            ".easyrecipe .instructions",
            ".directions",
            ".steps",
            ".preparation"
        ]
        
        for selector in containerSelectors {
            if let container = try? document.select(selector).first() {
                // Try structured elements first
                let elements = try container.select("p, li")
                if !elements.isEmpty {
                    let instructions = try extractAndValidateItems(elements, isIngredient: false)
                    if !instructions.isEmpty {
                        return instructions
                    }
                }
                
                // If no structured elements, try text parsing
                let text = try container.text()
                let steps = parseInstructionString(text)
                
                if validateInstructionsLikelihood(steps) {
                    return steps
                }
            }
        }
        
        return nil
    }
    
    private func searchForOrderedListInstructions(_ document: Document) throws -> [String] {
        let allOrderedLists = try document.select("ol")
        for list in allOrderedLists {
            let elements = try list.select("li")
            let instructions = try extractAndValidateItems(elements, isIngredient: false)
            if !instructions.isEmpty {
                return instructions
            }
        }
        
        // Last resort: try to find numbered paragraphs
        let paragraphs = try document.select("p")
        var numberedInstructions: [String] = []
        
        for paragraph in paragraphs {
            let text = try paragraph.text().trimmingCharacters(in: .whitespacesAndNewlines)
            // Check for paragraphs that start with a number
            if text.range(of: "^\\d+\\.\\s", options: .regularExpression) != nil {
                numberedInstructions.append(text)
            }
        }
        
        if validateInstructionsLikelihood(numberedInstructions) {
            return numberedInstructions
        }
        
        return []
    }
    
    private func validateInstructionsLikelihood(_ items: [String]) -> Bool {
        // Filter out very short items that are unlikely to be instructions
        let validItems = items.filter { $0.count > 10 }
        
        // Make sure we have enough items
        if validItems.count < 2 {
            return false
        }
        
        // Check if the average length is reasonable for instructions
        let averageLength = validItems.reduce(0) { $0 + $1.count } / validItems.count
        
        // Look for cooking verbs
        let cookingVerbs = ["add", "stir", "mix", "cook", "bake", "fry", "simmer", "boil", "heat",
                          "combine", "whisk", "chop", "slice", "dice", "grill", "roast", "place"]
        
        let containsCookingWords = validItems.reduce(0) { count, item in
            let lowercased = item.lowercased()
            return cookingVerbs.contains { lowercased.contains($0) } ? count + 1 : count
        }
        
        // Require cooking verbs in at least 50% of instructions
        let hasEnoughCookingWords = Double(containsCookingWords) / Double(validItems.count) >= 0.5
        
        return averageLength > 20 && hasEnoughCookingWords
    }
    
    private func extractImage(from document: Document) throws -> String? {
        let imageSelectors = [
            "[itemprop='image']",
            ".recipe-image img",
            ".recipe__image img",
            ".recipe-featured-image img",
            ".wp-post-image",
            "img[class*='hero']",
            "img[class*='feature']",
            "img[class*='main']",
            "img[class*='primary']",
            // Additional selectors
            ".featured-image img",
            "img.recipe-image",
            "img.attachment-full",
            "[property='og:image']", // Open Graph image
            "header img",
            ".post-thumbnail img",
            "article img" // Try to get any image in the article
        ]
        
        // Try direct image selectors
        for selector in imageSelectors {
            if let imgElement = try? document.select(selector).first() {
                // Handle different element types
                if try imgElement.tagName() == "img" {
                    if let src = try? imgElement.attr("src"), !src.isEmpty {
                        return src
                    } else if let dataSrc = try? imgElement.attr("data-src"), !dataSrc.isEmpty {
                        // Some sites use data-src for lazy loading
                        return dataSrc
                    }
                } else if let content = try? imgElement.attr("content"), !content.isEmpty {
                    // For meta tags with content attribute
                    return content
                }
            }
        }
        
        // Try meta tags
        let metaImageSelectors = [
            "meta[property='og:image']",
            "meta[name='twitter:image']",
            "meta[itemprop='image']"
        ]
        
        for selector in metaImageSelectors {
            if let metaElement = try? document.select(selector).first(),
               let content = try? metaElement.attr("content"),
               !content.isEmpty {
                return content
            }
        }
        
        // Fall back to the first large image in the content
        if let contentElement = try? document.select(".content, .article, .post, article, main").first() {
            let images = try contentElement.select("img")
            for image in images {
                // Look for large-width images which might be recipe images
                if let width = try? image.attr("width"), let widthVal = Int(width), widthVal > 300,
                   let src = try? image.attr("src"), !src.isEmpty {
                    return src
                }
                
                // Try data-src for lazy-loaded images
                if let dataSrc = try? image.attr("data-src"), !dataSrc.isEmpty {
                    return dataSrc
                }
                
                // Check regular src
                if let src = try? image.attr("src"), !src.isEmpty {
                    return src
                }
            }
        }
        
        // Last resort: check for any image on the page
        if let firstImage = try? document.select("img").first(),
           let src = try? firstImage.attr("src"),
           !src.isEmpty {
            return src
        }
        
        return "photo" // Default placeholder
    }
    
    private func parseInstructionString(_ instructionString: String) -> [String] {
        // Try splitting by numbered step patterns
        if let steps = splitByNumberedSteps(instructionString), !steps.isEmpty {
            return steps
        }
        
        // If numbered splitting failed, try paragraph splitting
        let paragraphSteps = instructionString.components(separatedBy: .newlines)
                                            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                            .filter { !$0.isEmpty && $0.count > 5 }
        
        if !paragraphSteps.isEmpty {
            return paragraphSteps
        }
        
        // Try to split by double newlines (common in blog posts)
        let doubleNewlineSteps = instructionString.components(separatedBy: "\n\n")
                                                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                                                .filter { !$0.isEmpty && $0.count > 10 }
        
        if !doubleNewlineSteps.isEmpty {
            return doubleNewlineSteps
        }
        
        // Last resort: split by sentences for long text blocks
        if instructionString.count > 100 {
            let sentenceSeparators = [".", "!", "?"]
            var sentences: [String] = []
            
            var currentSentence = ""
            for char in instructionString {
                currentSentence.append(char)
                
                if sentenceSeparators.contains(String(char)) {
                    sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
                    currentSentence = ""
                }
            }
            
            // Add any remaining text
            if !currentSentence.isEmpty {
                sentences.append(currentSentence.trimmingCharacters(in: .whitespacesAndNewlines))
            }
            
            return sentences.filter { !$0.isEmpty && $0.count > 10 }
        }
        
        return []
    }
    
    private func splitByNumberedSteps(_ text: String) -> [String]? {
        let patterns = [
            "\\d+\\.\\s+",         // "1. Step text"
            "Step\\s+\\d+:\\s+",   // "Step 1: Step text"
            "Step\\s+\\d+\\.\\s+", // "Step 1. Step text"
            "\\n\\s*\\d+\\.\\s+",  // Newline followed by numbered step
            "#\\d+\\s+"            // "#1 Step text"
        ]
        
        for pattern in patterns {
            // First check if the pattern exists at all in the text
            if let regex = try? NSRegularExpression(pattern: pattern, options: []),
               regex.firstMatch(in: text, options: [], range: NSRange(text.startIndex..., in: text)) != nil {
                
                // Now try to extract steps
                let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
                
                if matches.count > 0 {
                    return extractStepsFromMatches(text, matches)
                }
            }
        }
        
        return nil
    }
    
    private func extractStepsFromMatches(_ text: String, _ matches: [NSTextCheckingResult]) -> [String] {
        var steps: [String] = []
        
        // Special case: if the first match isn't at the beginning, capture text before it
        if let firstMatch = matches.first, firstMatch.range.location > 0 {
            let initialRange = NSRange(location: 0, length: firstMatch.range.location)
            if let range = Range(initialRange, in: text) {
                let initialText = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                if !initialText.isEmpty && initialText.count > 10 {
                    steps.append(initialText)
                }
            }
        }
        
        // Process each match as a step start indicator
        for (i, match) in matches.enumerated() {
            let matchEnd = match.range.location + match.range.length
            let endIndex = i < matches.count - 1 ? matches[i+1].range.location : text.count
            
            if matchEnd < endIndex {
                let stepRange = NSRange(location: matchEnd, length: endIndex - matchEnd)
                if let range = Range(stepRange, in: text) {
                    let step = String(text[range]).trimmingCharacters(in: .whitespacesAndNewlines)
                    if !step.isEmpty && step.count > 5 {
                        steps.append(step)
                    }
                }
            }
        }
        
        return steps
    }
}
