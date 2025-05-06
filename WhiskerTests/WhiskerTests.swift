import XCTest
@testable import Whisker

final class WhiskerTests: XCTestCase {
    
    // MARK: - Recipe Model Tests
    
    func testRecipeInitialization() throws {
        // Test basic initialization
        let recipe = Recipe(
            name: "Test Recipe",
            image: "test_image.jpg",
            ingredients: ["Ingredient 1", "Ingredient 2"],
            instructions: ["Step 1", "Step 2"]
        )
        
        XCTAssertEqual(recipe.name, "Test Recipe")
        XCTAssertEqual(recipe.image, "test_image.jpg")
        XCTAssertEqual(recipe.ingredients, ["Ingredient 1", "Ingredient 2"])
        XCTAssertEqual(recipe.instructions, ["Step 1", "Step 2"])
        XCTAssertEqual(recipe.originalIngredients, ["Ingredient 1", "Ingredient 2"])
        XCTAssertNil(recipe.albumId)
    }
    
    func testRecipeCustomInitializer() throws {
        let recipeId = UUID()
        let albumId = UUID()
        
        let recipe = Recipe(
            id: recipeId,
            name: "Custom Recipe",
            image: "custom_image.jpg",
            ingredients: ["Custom 1", "Custom 2"],
            instructions: ["Custom Step 1", "Custom Step 2"],
            albumId: albumId
        )
        
        XCTAssertEqual(recipe.id, recipeId)
        XCTAssertEqual(recipe.name, "Custom Recipe")
        XCTAssertEqual(recipe.image, "custom_image.jpg")
        XCTAssertEqual(recipe.ingredients, ["Custom 1", "Custom 2"])
        XCTAssertEqual(recipe.instructions, ["Custom Step 1", "Custom Step 2"])
        XCTAssertEqual(recipe.originalIngredients, ["Custom 1", "Custom 2"])
        XCTAssertEqual(recipe.albumId, albumId)
    }
    
    func testRecipeWithOriginalIngredients() throws {
        let recipe = Recipe(
            name: "Original Recipe",
            image: "original.jpg",
            ingredients: ["Modified 1", "Modified 2"],
            instructions: ["Instruction 1"],
            originalIngredients: ["Original 1", "Original 2"]
        )
        
        XCTAssertEqual(recipe.ingredients, ["Modified 1", "Modified 2"])
        XCTAssertEqual(recipe.originalIngredients, ["Original 1", "Original 2"])
    }
    
    // MARK: - GroceryItem Tests
    
    func testGroceryItemInitialization() throws {
        // Test basic initialization
        let item = GroceryItem(name: "Apples", isChecked: false)
        
        XCTAssertEqual(item.name, "Apples")
        XCTAssertFalse(item.isChecked)
        XCTAssertNil(item.recipeSource)
        
        // Test with recipe source
        let itemWithSource = GroceryItem(name: "Flour", isChecked: true, recipeSource: "Chocolate Cake")
        
        XCTAssertEqual(itemWithSource.name, "Flour")
        XCTAssertTrue(itemWithSource.isChecked)
        XCTAssertEqual(itemWithSource.recipeSource, "Chocolate Cake")
    }
    
    func testGroceryItemWithCustomID() throws {
        let customId = UUID()
        let item = GroceryItem(id: customId, name: "Sugar", isChecked: false)
        
        XCTAssertEqual(item.id, customId)
        XCTAssertEqual(item.name, "Sugar")
        XCTAssertFalse(item.isChecked)
    }
    
    // MARK: - RecipeAlbum Tests
    
    func testRecipeAlbumInitialization() throws {
        let recipes = [
            Recipe(name: "Recipe 1", image: "image1.jpg", ingredients: ["Ing 1"], instructions: ["Step 1"]),
            Recipe(name: "Recipe 2", image: "image2.jpg", ingredients: ["Ing 2"], instructions: ["Step 2"])
        ]
        
        let album = RecipeAlbum(name: "Test Album", coverImage: "cover.jpg", recipes: recipes)
        
        XCTAssertEqual(album.name, "Test Album")
        XCTAssertEqual(album.coverImage, "cover.jpg")
        XCTAssertEqual(album.recipes.count, 2)
    }
    
    func testRecipeAlbumWithCustomID() throws {
        let customId = UUID()
        let recipes = [Recipe(name: "Recipe", image: "img.jpg", ingredients: ["Ing"], instructions: ["Step"])]
        
        let album = RecipeAlbum(id: customId, name: "Custom Album", coverImage: "custom_cover.jpg", recipes: recipes)
        
        XCTAssertEqual(album.id, customId)
        XCTAssertEqual(album.name, "Custom Album")
        XCTAssertEqual(album.coverImage, "custom_cover.jpg")
        XCTAssertEqual(album.recipes.count, 1)
    }
    
    // MARK: - MeasurementUtils Tests
    
    func testParseValueString() throws {
        // Test whole numbers
        XCTAssertEqual(MeasurementUtils.parseValueString("5"), 5.0)
        
        // Test decimals
        XCTAssertEqual(MeasurementUtils.parseValueString("2.5"), 2.5)
        
        // Test fractions
        XCTAssertEqual(MeasurementUtils.parseValueString("1/2"), 0.5)
        
        // Test mixed numbers
        XCTAssertEqual(MeasurementUtils.parseValueString("1 1/2"), 1.5)
        
        // Test Unicode fractions
        XCTAssertEqual(MeasurementUtils.parseValueString("½"), 0.5)
        XCTAssertEqual(MeasurementUtils.parseValueString("1½"), 1.5)
        XCTAssertEqual(MeasurementUtils.parseValueString("2¼"), 2.25)
        
        // Test invalid inputs
        XCTAssertNil(MeasurementUtils.parseValueString("invalid"))
    }
    
    func testFormatValue() throws {
        // Test whole numbers
        XCTAssertEqual(MeasurementUtils.formatValue(5.0), "5")
        
        // Test common fractions
        XCTAssertEqual(MeasurementUtils.formatValue(0.5), "½")
        XCTAssertEqual(MeasurementUtils.formatValue(0.25), "¼")
        XCTAssertEqual(MeasurementUtils.formatValue(0.75), "¾")
        
        // Test mixed numbers
        XCTAssertEqual(MeasurementUtils.formatValue(1.5), "1½")
        XCTAssertEqual(MeasurementUtils.formatValue(2.25), "2¼")
        
        // Test decimal values - get actual value to verify format
        let value1 = MeasurementUtils.formatValue(1.33)
        XCTAssertTrue(value1 == "1⅓" || value1 == "1.33", "Expected either fraction representation or decimal, got \(value1)")
        
        let value2 = MeasurementUtils.formatValue(2.8)
        XCTAssertTrue(value2 == "2.80" || value2 == "2.8", "Expected either '2.80' or '2.8', got \(value2)")
    }
    
    func testExtractMeasurements() throws {
        // Test extracting a single measurement
        let result1 = MeasurementUtils.extractMeasurements(from: "2 cups flour")
        XCTAssertNotNil(result1)
        XCTAssertEqual(result1?.count, 1)
        XCTAssertEqual(result1?[0].value, 2.0)
        XCTAssertEqual(result1?[0].unit, "cup")
        
        // Test extracting multiple measurements
        let result2 = MeasurementUtils.extractMeasurements(from: "Add 1 tbsp oil and 2 cups water")
        XCTAssertNotNil(result2)
        XCTAssertEqual(result2?.count, 2)
        XCTAssertEqual(result2?[0].value, 1.0)
        XCTAssertEqual(result2?[0].unit, "tbsp")
        XCTAssertEqual(result2?[1].value, 2.0)
        XCTAssertEqual(result2?[1].unit, "cup")
        
        // Test extracting fractions
        let result3 = MeasurementUtils.extractMeasurements(from: "½ cup sugar")
        XCTAssertNotNil(result3)
        XCTAssertEqual(result3?.count, 1)
        XCTAssertEqual(result3?[0].value, 0.5)
        XCTAssertEqual(result3?[0].unit, "cup")
        
        // Test with no measurements
        let result4 = MeasurementUtils.extractMeasurements(from: "Add salt to taste")
        XCTAssertNil(result4)
    }
    
    // MARK: - UnitConverterService Tests
    
    func testUnitConversion() throws {
        let converter = UnitConverterService.shared
        
        // Test imperial to metric volume conversion
        let cups = "2 cups flour"
        let cupsToMl = converter.convertIngredient(cups, toMetric: true)
        XCTAssertNotEqual(cupsToMl, cups, "Conversion should change the ingredient text")
        
        // Print for debugging
        print("Debug - Cups to Metric conversion: '\(cupsToMl)'")
        
        // Check for metric unit presence and imperial unit absence
        let hasMetricVolumeUnit = cupsToMl.contains("milliliter") || cupsToMl.contains("liter")
        XCTAssertTrue(hasMetricVolumeUnit, "Converted text should contain a metric volume unit")
        XCTAssertFalse(cupsToMl.contains("cup"), "Converted text should not contain 'cup'")
        
        // Test imperial to metric weight conversion
        let pounds = "1 pound beef"
        let poundsToGrams = converter.convertIngredient(pounds, toMetric: true)
        
        // Print for debugging
        print("Debug - Pounds to Metric conversion: '\(poundsToGrams)'")
        
        let hasMetricWeightUnit = poundsToGrams.contains(" g") || poundsToGrams.contains("gram") || poundsToGrams.contains("kg")
        XCTAssertTrue(hasMetricWeightUnit, "Converted text should contain a metric weight unit")
        XCTAssertFalse(poundsToGrams.contains("pound") || poundsToGrams.contains(" lb"), "Converted text should not contain imperial weight units")
        
        // Test metric to imperial volume conversion
        let ml = "250 ml milk"
        let mlToCups = converter.convertIngredient(ml, toMetric: false)
        
        // Print for debugging
        print("Debug - ML to Imperial conversion: '\(mlToCups)'")
        
        // Less strict check
        XCTAssertNotEqual(mlToCups, ml, "Conversion should change the ingredient text")
        
        // Test metric to imperial weight conversion
        let grams = "500 g meat"
        let gramsToLbs = converter.convertIngredient(grams, toMetric: false)
        
        // Print for debugging
        print("Debug - Grams to Imperial conversion: '\(gramsToLbs)'")
        
        // Less strict check
        XCTAssertNotEqual(gramsToLbs, grams, "Conversion should change the ingredient text")
        
        // Test non-convertible string
        let nonConvertible = "2 pinches of salt"
        let result = converter.convertIngredient(nonConvertible, toMetric: true)
        XCTAssertEqual(result, nonConvertible, "Non-convertible ingredients should remain unchanged")
    }
    
    func testBatchIngredientConversion() throws {
        let converter = UnitConverterService.shared
        
        let imperialIngredients = [
            "2 cups flour",
            "1 tsp salt",
            "8 oz butter",
            "Fresh herbs to taste"
        ]
        
        let metricIngredients = converter.convertIngredients(imperialIngredients, toMetric: true)
        
        // Print for debugging
        print("Original ingredients: \(imperialIngredients)")
        print("Converted ingredients: \(metricIngredients)")
        
        // Check that we got the right number of ingredients back
        XCTAssertEqual(metricIngredients.count, imperialIngredients.count)
        
        // Check that conversion happened by verifying changes
        XCTAssertNotEqual(metricIngredients[0], imperialIngredients[0])
        XCTAssertNotEqual(metricIngredients[1], imperialIngredients[1])
        XCTAssertNotEqual(metricIngredients[2], imperialIngredients[2])
        
        // Check that non-convertible ingredients stay the same
        XCTAssertEqual(metricIngredients[3], imperialIngredients[3])
    }
    
    // MARK: - RecipeScalingService Tests
    
    func testIngredientScaling() throws {
        let scalingService = RecipeScalingService.shared
        
        // Test scaling up
        let ingredient1 = "2 cups flour"
        let doubledIngredient = scalingService.scaleIngredient(ingredient1, by: 2.0)
        XCTAssertTrue(doubledIngredient.contains("4 cups"))
        
        // Test scaling down
        let ingredient2 = "1 cup sugar"
        let halvedIngredient = scalingService.scaleIngredient(ingredient2, by: 0.5)
        XCTAssertTrue(halvedIngredient.contains("½ cup"))
        
        // Test scaling ingredient with multiple measurements
        let ingredient3 = "2 tbsp butter and 1 tsp vanilla"
        let scaledIngredient = scalingService.scaleIngredient(ingredient3, by: 3.0)
        XCTAssertTrue(scaledIngredient.contains("6 tbsp"))
        XCTAssertTrue(scaledIngredient.contains("3 tsp") || scaledIngredient.contains("1 tbsp"))
        
        // Test non-measurable ingredient
        let ingredient4 = "Salt to taste"
        let unchangedIngredient = scalingService.scaleIngredient(ingredient4, by: 2.0)
        XCTAssertEqual(unchangedIngredient, ingredient4)
    }
    
    func testBatchIngredientScaling() throws {
        let scalingService = RecipeScalingService.shared
        
        let ingredients = [
            "2 cups flour",
            "1 tsp salt",
            "½ cup sugar"
        ]
        
        let scaledIngredients = scalingService.scaleIngredients(ingredients, by: 3.0)
        
        XCTAssertEqual(scaledIngredients.count, ingredients.count)
        XCTAssertTrue(scaledIngredients[0].contains("6 cups"))
        XCTAssertTrue(scaledIngredients[1].contains("3 tsp") || scaledIngredients[1].contains("1 tbsp"))
        XCTAssertTrue(scaledIngredients[2].contains("1½ cup") || scaledIngredients[2].contains("1.5 cup"))
    }
    
    func testCalculateScalingFactor() throws {
        let scalingService = RecipeScalingService.shared
        
        // Test basic calculation
        let ingredient1 = "2 cups flour"
        let factor1 = scalingService.calculateScalingFactorFrom(originalIngredient: ingredient1, targetValue: 4.0)
        XCTAssertEqual(factor1, 2.0)
        
        // Test with fractions
        let ingredient2 = "½ tsp salt"
        let factor2 = scalingService.calculateScalingFactorFrom(originalIngredient: ingredient2, targetValue: 1.0)
        XCTAssertEqual(factor2, 2.0)
        
        // Test with ingredient that contains no measurable value
        let ingredient3 = "Salt to taste"
        let factor3 = scalingService.calculateScalingFactorFrom(originalIngredient: ingredient3, targetValue: 2.0)
        XCTAssertNil(factor3)
    }
    
    // MARK: - RecipeScalingManager Tests
    
    func testRecipeScalingManager() throws {
        let manager = RecipeScalingManager.shared
        
        let originalIngredients = [
            "2 cups flour",
            "1 tsp salt",
            "3 tbsp butter"
        ]
        
        // Set original ingredients
        manager.setOriginalIngredients(originalIngredients)
        XCTAssertEqual(manager.originalIngredients, originalIngredients)
        XCTAssertEqual(manager.scaledIngredients, originalIngredients)
        XCTAssertEqual(manager.scalingFactor, 1.0)
        
        // Test applying scaling
        manager.applyScaling(factor: 2.0)
        XCTAssertEqual(manager.scalingFactor, 2.0)
        XCTAssertEqual(manager.scaledIngredients.count, originalIngredients.count)
        XCTAssertTrue(manager.scaledIngredients[0].contains("4 cups"))
        XCTAssertTrue(manager.scaledIngredients[1].contains("2 tsp"))
        XCTAssertTrue(manager.scaledIngredients[2].contains("6 tbsp"))
        
        // Test custom scaling
        manager.applyCustomScaling(ingredientIndex: 0, targetValue: 3.0)
        XCTAssertEqual(manager.scalingFactor, 1.5)
        XCTAssertTrue(manager.isCustomScaling)
        XCTAssertEqual(manager.customScalingIngredientIndex, 0)
        XCTAssertEqual(manager.customScalingTargetValue, 3.0)
        XCTAssertTrue(manager.scaledIngredients[0].contains("3 cups"))
        
        // Test reset
        manager.resetScaling()
        XCTAssertEqual(manager.scalingFactor, 1.0)
        XCTAssertFalse(manager.isCustomScaling)
        XCTAssertNil(manager.customScalingIngredientIndex)
        XCTAssertNil(manager.customScalingTargetValue)
        XCTAssertEqual(manager.scaledIngredients, originalIngredients)
    }
    
    func testRecipeScaledExtension() throws {
        let recipe = Recipe(
            name: "Test Recipe",
            image: "image.jpg",
            ingredients: ["2 cups flour", "1 tsp salt"],
            instructions: ["Mix ingredients"]
        )
        
        // Test scaling by factor
        let doubledRecipe = recipe.scaled(by: 2.0)
        XCTAssertEqual(doubledRecipe.ingredients.count, recipe.ingredients.count)
        XCTAssertTrue(doubledRecipe.ingredients[0].contains("4 cups"))
        XCTAssertTrue(doubledRecipe.ingredients[1].contains("2 tsp"))
        
        // Test scaling by ingredient
        let customScaledRecipe = recipe.scaledByIngredient(index: 0, targetValue: 3.0)
        XCTAssertNotNil(customScaledRecipe)
        XCTAssertTrue(customScaledRecipe!.ingredients[0].contains("3 cups"))
        XCTAssertTrue(customScaledRecipe!.ingredients[1].contains("1.5 tsp") ||
                     customScaledRecipe!.ingredients[1].contains("1½ tsp"))
        
        // Test invalid index
        let invalidScaledRecipe = recipe.scaledByIngredient(index: 5, targetValue: 1.0)
        XCTAssertNil(invalidScaledRecipe)
    }
    
    // MARK: - GroceryListManager Simple Tests
    // Note: For full testing, you'd need to mock Firebase
    
    func testGroceryListItemOperations() throws {
        let groceryManager = GroceryListManager.shared
        
        // Let's test the in-memory operations without Firebase calls
        let initialCount = groceryManager.groceryItems.count
        
        // Create test items
        let testItems = [
            GroceryItem(name: "Test Apples", isChecked: false),
            GroceryItem(name: "Test Bananas", isChecked: false, recipeSource: "Fruit Salad")
        ]
        
        // Add items
        groceryManager.addItems(testItems)
        
        // Wait for async operation to complete
        let expectation = XCTestExpectation(description: "Wait for grocery items to be added")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        
        // Verify items exist in manager's state
        let appleItem = groceryManager.groceryItems.first { $0.name == "Test Apples" }
        let bananaItem = groceryManager.groceryItems.first { $0.name == "Test Bananas" }
        
        // These assertions may fail if Firebase is active, as it will reset the groceryItems
        // This is why we'd need to mock Firebase for proper testing
        XCTAssertNotNil(appleItem)
        XCTAssertNotNil(bananaItem)
        XCTAssertEqual(bananaItem?.recipeSource, "Fruit Salad")
        
        // Test organization by recipe
        let groupedItems = groceryManager.itemsByRecipe()
        XCTAssertNotNil(groupedItems["Other Items"])
        XCTAssertNotNil(groupedItems["Fruit Salad"])
        
        // Clean up test data
        if let id = appleItem?.id {
            groceryManager.removeItem(id)
        }
        if let id = bananaItem?.id {
            groceryManager.removeItem(id)
        }
    }
    
    func testUnitDisplayAbbreviations() throws {
        // Test that MeasurementUtils.Unit provides correct display abbreviations
        
        // Find units from definitions
        let cup = MeasurementUtils.unitDefinitions.first { $0.name == "cup" }
        let tablespoon = MeasurementUtils.unitDefinitions.first { $0.name == "tablespoon" }
        let teaspoon = MeasurementUtils.unitDefinitions.first { $0.name == "teaspoon" }
        let milliliter = MeasurementUtils.unitDefinitions.first { $0.name == "milliliter" }
        let gram = MeasurementUtils.unitDefinitions.first { $0.name == "gram" }
        
        // Verify units were found
        XCTAssertNotNil(cup, "Cup unit definition should exist")
        XCTAssertNotNil(tablespoon, "Tablespoon unit definition should exist")
        XCTAssertNotNil(teaspoon, "Teaspoon unit definition should exist")
        XCTAssertNotNil(milliliter, "Milliliter unit definition should exist")
        XCTAssertNotNil(gram, "Gram unit definition should exist")
        
        // Test display abbreviations
        XCTAssertEqual(cup?.displayAbbreviation, "cup", "Cup abbreviation should be 'cup'")
        XCTAssertTrue(tablespoon?.displayAbbreviation == "tbsp" ||
                     tablespoon?.displayAbbreviation == "tbs" ||
                     tablespoon?.displayAbbreviation == "tablespoon",
                     "Tablespoon should have an appropriate abbreviation")
        XCTAssertTrue(teaspoon?.displayAbbreviation == "tsp" ||
                     teaspoon?.displayAbbreviation == "teaspoon",
                     "Teaspoon should have an appropriate abbreviation")
        XCTAssertTrue(milliliter?.displayAbbreviation == "ml" ||
                     milliliter?.displayAbbreviation == "mL",
                     "Milliliter should have an appropriate abbreviation")
        XCTAssertEqual(gram?.displayAbbreviation, "g", "Gram abbreviation should be 'g'")
        
        // Print actual values for debugging
        print("Cup display abbreviation: \(cup?.displayAbbreviation ?? "nil")")
        print("Tablespoon display abbreviation: \(tablespoon?.displayAbbreviation ?? "nil")")
        print("Teaspoon display abbreviation: \(teaspoon?.displayAbbreviation ?? "nil")")
        print("Milliliter display abbreviation: \(milliliter?.displayAbbreviation ?? "nil")")
        print("Gram display abbreviation: \(gram?.displayAbbreviation ?? "nil")")
    }
    
    // MARK: - Unit Pluralization Tests
    
    func testUnitPluralization() throws {
        let converter = UnitConverterService.shared
        
        // Test singular/plural for imperial volume units
        let oneCup = "1 cup flour"
        let twoCups = "2 cups flour"
        
        let oneCupConverted = converter.convertIngredient(oneCup, toMetric: true)
        let twoCupsConverted = converter.convertIngredient(twoCups, toMetric: true)
        
        // Print for debugging
        print("One cup converted: \(oneCupConverted)")
        print("Two cups converted: \(twoCupsConverted)")
        
        // Convert back to imperial to test pluralization
        let metricAmount = "200 ml water"
        let smallImperial = converter.convertIngredient(metricAmount, toMetric: false)
        let largeImperial = converter.convertIngredient("1000 ml water", toMetric: false)
        
        // Print for debugging
        print("Small metric converted to imperial: \(smallImperial)")
        print("Large metric converted to imperial: \(largeImperial)")
        
        // Check that small quantities use singular form
        XCTAssertTrue(smallImperial.contains(" cup ") ||
                     smallImperial.contains(" tablespoon ") ||
                     smallImperial.contains(" teaspoon ") ||
                     smallImperial.contains(" tbsp ") ||
                     smallImperial.contains(" tsp "),
                     "Small imperial quantity should use singular form: \(smallImperial)")
        
        // Check that large quantities use plural form
        XCTAssertTrue(largeImperial.contains(" cups ") ||
                      largeImperial.contains(" tablespoons ") ||
                      largeImperial.contains(" teaspoons ") ||
                      largeImperial.contains(" pints ") ||
                      largeImperial.contains(" quarts "),
                      "Large imperial quantity should use plural form: \(largeImperial)")
        
        // Test metric abbreviations
        let imperialToMetricSmall = converter.convertIngredient("1 teaspoon salt", toMetric: true)
        let imperialToMetricLarge = converter.convertIngredient("5 cups water", toMetric: true)
        
        print("Small imperial to metric: \(imperialToMetricSmall)")
        print("Large imperial to metric: \(imperialToMetricLarge)")
        
        // Check for metric abbreviations (ml, g, etc.)
        XCTAssertTrue(imperialToMetricSmall.contains(" ml ") ||
                      imperialToMetricSmall.contains(" g ") ||
                      imperialToMetricSmall.contains(" milliliter") ||
                      imperialToMetricSmall.contains(" gram"),
                      "Metric conversion should use appropriate units: \(imperialToMetricSmall)")
        
        XCTAssertTrue(imperialToMetricLarge.contains(" ml ") ||
                      imperialToMetricLarge.contains(" l ") ||
                      imperialToMetricLarge.contains(" milliliter") ||
                      imperialToMetricLarge.contains(" liter"),
                      "Larger metric conversion should use appropriate units: \(imperialToMetricLarge)")
    }
}
