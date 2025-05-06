//
//  EditableRecipeDetailView.swift
//  Whisker
//

import SwiftUI

struct RecipeDetailView: View {
    @ObservedObject private var dataManager = RecipeDataManager.shared
    @ObservedObject private var unitPreferences = RecipeUnitPreferences.shared
    @ObservedObject private var scalingManager = RecipeScalingManager.shared
    @Environment(\.presentationMode) var presentationMode
    
    // Recipe data
    let recipeId: UUID
    let albumId: UUID
    @State private var recipeName: String
    @State private var ingredients: [String]
    @State private var instructions: [String]
    @State private var originalImage: String
    @State private var originalIngredients: [String]
    
    // UI state
    @State private var isEditing: Bool
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showDiscardAlert: Bool = false
    
    // New property to track if this is a newly imported recipe
    let isNewlyImported: Bool
    
    // Initialize with recipe and album ID
    init(recipe: Recipe, albumId: UUID, isInitiallyEditing: Bool = false, isNewlyImported: Bool = false) {
        self.recipeId = recipe.id
        // Use the albumId from the recipe if available, otherwise use the provided one
        self.albumId = recipe.albumId ?? albumId
        self.isNewlyImported = isNewlyImported
        
        // Initialize state variables with the recipe data
        self._recipeName = State(initialValue: recipe.name)
        self._ingredients = State(initialValue: recipe.ingredients)
        self._originalIngredients = State(initialValue: recipe.originalIngredients)
        self._instructions = State(initialValue: recipe.instructions)
        self._originalImage = State(initialValue: recipe.image)
        self._isEditing = State(initialValue: isInitiallyEditing)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                // Recipe image
                RecipeImageView(imageSource: originalImage)
                    .frame(height: 250)
                
                VStack(alignment: .leading, spacing: 20) {
                    // Recipe name - editable when in edit mode
                    if isEditing {
                        TextField("Recipe Name", text: $recipeName)
                            .font(WhiskerStyles.Fonts.title)
                            .foregroundColor(WhiskerStyles.textColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal)
                            .background(
                                RoundedRectangle(cornerRadius: 5)
                                    .stroke(WhiskerStyles.primaryColor, lineWidth: 1)
                            )
                    } else {
                        Text(recipeName)
                            .font(WhiskerStyles.Fonts.title)
                            .foregroundColor(WhiskerStyles.textColor)
                    }
                    
                    // Control panel for units and scaling (only visible in non-edit mode)
                    if !isEditing {
                        VStack(spacing: 15) {
                            // Units toggle
                            HStack {
                                Text("Units:")
                                    .foregroundColor(WhiskerStyles.textColor)
                                    .font(WhiskerStyles.Fonts.bodyRegular)
                                
                                Picker("", selection: $unitPreferences.useMetricUnits) {
                                    Text("Imperial").tag(false)
                                    Text("Metric").tag(true)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                                .onChange(of: unitPreferences.useMetricUnits) { useMetric in
                                    convertIngredients(toMetric: useMetric)
                                }
                                
                                Spacer()
                            }
                            
                            RecipeScalingView(ingredients: $ingredients)
                        }
                        .padding(.bottom, 5)
                    }
                    
                    // Ingredients Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Ingredients")
                            .font(WhiskerStyles.Fonts.bodyMedium)
                            .foregroundColor(WhiskerStyles.textColor)
                            .fontWeight(.bold)
                        
                        if isEditing {
                            // Editable ingredients list
                            ForEach(0..<ingredients.count, id: \.self) { index in
                                HStack {
                                    Text("•")
                                        .foregroundColor(WhiskerStyles.primaryColor)
                                    
                                    TextField("Ingredient", text: $ingredients[index])
                                        .whiskerTextField()
                                    
                                    Button(action: {
                                        ingredients.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            // Add ingredient button
                            Button(action: {
                                ingredients.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Ingredient")
                                }
                            }
                            .foregroundColor(WhiskerStyles.primaryColor)
                            .padding(.top, 5)
                        } else {
                            // Read-only ingredients list
                            ForEach(ingredients, id: \.self) { ingredient in
                                HStack(alignment: .top) {
                                    Text("•")
                                        .foregroundColor(WhiskerStyles.primaryColor)
                                    
                                    Text(ingredient)
                                        .font(WhiskerStyles.Fonts.bodyRegular)
                                        .foregroundColor(WhiskerStyles.textColor)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                    
                    // Instructions Section
                    VStack(alignment: .leading, spacing: 10) {
                        Text("Instructions")
                            .font(WhiskerStyles.Fonts.bodyMedium)
                            .foregroundColor(WhiskerStyles.textColor)
                            .fontWeight(.bold)
                        
                        if isEditing {
                            // Editable instructions list
                            ForEach(0..<instructions.count, id: \.self) { index in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .foregroundColor(WhiskerStyles.primaryColor)
                                        .frame(width: 25, alignment: .leading)
                                        .padding(.top, 15)
                                    
                                    TextField("Step", text: $instructions[index])
                                        .whiskerTextField()
                                    
                                    Button(action: {
                                        instructions.remove(at: index)
                                    }) {
                                        Image(systemName: "minus.circle.fill")
                                            .foregroundColor(.red)
                                            .padding(.top, 15)
                                    }
                                }
                            }
                            
                            // Add instruction button
                            Button(action: {
                                instructions.append("")
                            }) {
                                HStack {
                                    Image(systemName: "plus.circle")
                                    Text("Add Step")
                                }
                            }
                            .foregroundColor(WhiskerStyles.primaryColor)
                            .padding(.top, 5)
                        } else {
                            // Read-only instructions list
                            ForEach(Array(instructions.enumerated()), id: \.element) { index, instruction in
                                HStack(alignment: .top) {
                                    Text("\(index + 1).")
                                        .foregroundColor(WhiskerStyles.primaryColor)
                                        .frame(width: 25, alignment: .leading)
                                    
                                    Text(instruction)
                                        .font(WhiskerStyles.Fonts.bodyRegular)
                                        .foregroundColor(WhiskerStyles.textColor)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .padding(.top, 10)
                    
                    // Action buttons when in edit mode
                    if isEditing {
                        HStack {
                            Button(action: {
                                showDiscardAlert = true
                            }) {
                                Text("Cancel")
                                    .font(WhiskerStyles.Fonts.buttonText)
                                    .foregroundColor(WhiskerStyles.textColor)
                                    .padding()
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white)
                                    .cornerRadius(10)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 10)
                                            .stroke(WhiskerStyles.textColor.opacity(0.3), lineWidth: 1)
                                    )
                            }
                            
                            Button(action: saveRecipe) {
                                Text("Save Changes")
                            }
                            .primaryButton()
                        }
                        .padding(.top, 20)
                        .padding(.bottom, 50)
                    }
                }
                .padding()
            }
        }
        .background(WhiskerStyles.backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarItems(
            trailing:
                Group {
                    if isEditing {
                        Button(action: {
                            showDiscardAlert = true
                        }) {
                            Text("Cancel")
                                .foregroundColor(WhiskerStyles.primaryColor)
                        }
                    } else {
                        Menu {
                            Button(action: {
                                isEditing = true
                            }) {
                                Label("Edit Recipe", systemImage: "pencil")
                            }
                            
                            Button(action: {
                                addToGroceryList()
                            }) {
                                Label("Add to Groceries", systemImage: "cart.fill.badge.plus")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .foregroundColor(WhiskerStyles.primaryColor)
                                .imageScale(.large)
                        }
                    }
                }
        )
        .alert(isPresented: $showAlert) {
            Alert(
                title: Text(alertTitle),
                message: Text(alertMessage),
                dismissButton: .default(Text("OK"))
            )
        }
        .alert(isPresented: $showDiscardAlert) {
            Alert(
                title: Text("Discard Changes"),
                message: Text("Are you sure you want to discard your changes?"),
                primaryButton: .destructive(Text("Discard")) {
                    // Check if this is a newly imported recipe
                    if isNewlyImported && isEditing {
                        // If newly imported and still in first edit, go back to AddRecipeView
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        // Otherwise, just reset to original values
                        resetToOriginal()
                    }
                },
                secondaryButton: .cancel()
            )
        }
        .onAppear {
            // Initialize the scaling manager with the original ingredients
            scalingManager.setOriginalIngredients(originalIngredients)
            
            // Convert ingredients to the current unit preference when view appears
            convertIngredients(toMetric: unitPreferences.useMetricUnits)
        }
    }
    
    // Function to add recipe ingredients to grocery list
    private func addToGroceryList() {
        // Create grocery items from ingredients
        let groceryItems = ingredients.map { ingredient in
            return GroceryItem(name: ingredient, isChecked: false, recipeSource: recipeName)
        }
        
        // Add to grocery list manager
        GroceryListManager.shared.addItems(groceryItems)
        
        // Show confirmation alert
        showAlert(title: "Added to Groceries", message: "\(ingredients.count) ingredients from \(recipeName) have been added to your grocery list.")
    }
    
    // Convert ingredients based on the unit selection
    private func convertIngredients(toMetric: Bool) {
        let converter = UnitConverterService.shared
        
        // Always convert from original ingredients to avoid cumulative conversion errors
        let convertedIngredients = originalIngredients.map { ingredient in
            converter.convertIngredient(ingredient, toMetric: toMetric)
        }
        
        // If there is a scaling factor applied, scale the converted ingredients
        if scalingManager.scalingFactor != 1.0 {
            ingredients = scalingManager.scaleIngredients(convertedIngredients, by: scalingManager.scalingFactor)
        } else {
            ingredients = convertedIngredients
            // Update the scaling manager's original ingredients after unit conversion
            scalingManager.setOriginalIngredients(convertedIngredients)
        }
    }
    
    // Update the recipe in the data manager
    private func saveRecipe() {
        // Validate inputs
        guard !recipeName.isEmpty else {
            showAlert(title: "Error", message: "Recipe name cannot be empty")
            return
        }
        
        // Create updated recipe
        let updatedRecipe = Recipe(
            id: recipeId,
            name: recipeName,
            image: originalImage,
            ingredients: ingredients.filter { !$0.isEmpty },
            instructions: instructions.filter { !$0.isEmpty },
            originalIngredients: originalIngredients,
            albumId: albumId
        )
        
        // Save the recipe using our unified method
        dataManager.saveRecipe(to: albumId, recipe: updatedRecipe)
        
        // Update the original ingredients to match edited values
        originalIngredients = ingredients.filter { !$0.isEmpty }
        
        // Only toggle edit mode - don't dismiss the view
        withAnimation {
            isEditing = false
        }
        
        // Show success confirmation
        showAlert(title: "Success", message: "Recipe saved successfully")
    }
    
    // Reset to original recipe data
    private func resetToOriginal() {
        // Find the current recipe in the album
        if let album = dataManager.albums.first(where: { $0.id == albumId }),
           let recipe = album.recipes.first(where: { $0.id == recipeId }) {
            recipeName = recipe.name
            ingredients = recipe.ingredients
            originalIngredients = recipe.originalIngredients
            instructions = recipe.instructions
            
            // Reset scaling
            scalingManager.resetScaling()
        }
        
        // Exit edit mode
        isEditing = false
    }
    
    // Helper to show alerts
    private func showAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

