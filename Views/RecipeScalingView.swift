//
//  RecipeScalingUI.swift
//  Whisker
//
//  Created for recipe scaling UI components
//

import SwiftUI

/// View for recipe scaling controls
struct RecipeScalingView: View {
    @ObservedObject private var scalingManager = RecipeScalingManager.shared
    @Binding var ingredients: [String]
    
    @State private var showingCustomScalingSheet = false
    @State private var selectedIngredientIndex: Int = 0
    @State private var customQuantity: String = ""
    
    var body: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Scale Recipe:")
                    .foregroundColor(WhiskerStyles.textColor)
                    .font(WhiskerStyles.Fonts.bodyRegular)
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                scaleButton(factor: 1.0, label: "1x")
                scaleButton(factor: 2.0, label: "2x")
                scaleButton(factor: 3.0, label: "3x")
                
                // Custom scaling button
                Button(action: {
                    // Reset the selection
                    selectedIngredientIndex = 0
                    customQuantity = ""
                    showingCustomScalingSheet = true
                }) {
                    HStack {
                        Image(systemName: "slider.horizontal.3")
                        Text("Custom")
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .foregroundColor(
                        scalingManager.isCustomScaling ? WhiskerStyles.backgroundColor : WhiskerStyles.primaryColor
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(scalingManager.isCustomScaling ? WhiskerStyles.primaryColor : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(WhiskerStyles.primaryColor, lineWidth: 1.5)
                            )
                    )
                }
                
                Spacer() // Add spacer to push content to the left
            }
            .padding(.bottom, 5)
        }
        .padding(.top, 10)
        .onAppear {
            // Initialize scaling manager with original ingredients
            scalingManager.setOriginalIngredients(ingredients)
        }
        .onChange(of: scalingManager.scaledIngredients) { newIngredients in
            ingredients = newIngredients
        }
        .sheet(isPresented: $showingCustomScalingSheet) {
            customScalingView
        }
    }
    
    // Helper to create scaling buttons with consistent styling
    private func scaleButton(factor: Double, label: String) -> some View {
        Button(action: {
            scalingManager.applyScaling(factor: factor)
            ingredients = scalingManager.scaledIngredients
        }) {
            Text(label)
                .padding(.horizontal, 15)
                .padding(.vertical, 8)
                .foregroundColor(
                    scalingManager.scalingFactor == factor && !scalingManager.isCustomScaling
                    ? WhiskerStyles.backgroundColor : WhiskerStyles.primaryColor
                )
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            scalingManager.scalingFactor == factor && !scalingManager.isCustomScaling
                            ? WhiskerStyles.primaryColor : Color.clear
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(WhiskerStyles.primaryColor, lineWidth: 1.5)
                        )
                )
        }
    }
    
    // Custom scaling sheet view
    private var customScalingView: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Custom Recipe Scaling")
                    .font(WhiskerStyles.Fonts.title)
                    .foregroundColor(WhiskerStyles.textColor)
                    .padding(.top, 20)
                
                Text("Select an ingredient and enter the desired quantity")
                    .font(WhiskerStyles.Fonts.bodyLight)
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                Divider()
                
                // Ingredient picker
                VStack(alignment: .leading) {
                    Text("Select Ingredient:")
                        .font(WhiskerStyles.Fonts.bodyMedium)
                        .foregroundColor(WhiskerStyles.textColor)
                    
                    Picker("Ingredient", selection: $selectedIngredientIndex) {
                        ForEach(0..<scalingManager.originalIngredients.count, id: \.self) { index in
                            Text(scalingManager.originalIngredients[index])
                                .tag(index)
                        }
                    }
                    .pickerStyle(WheelPickerStyle())
                    .frame(height: 120)
                }
                .padding(.horizontal)
                
                // Custom quantity input
                VStack(alignment: .leading) {
                    Text("Enter New Quantity:")
                        .font(WhiskerStyles.Fonts.bodyMedium)
                        .foregroundColor(WhiskerStyles.textColor)
                    
                    TextField("Ex: 2 or 2.5", text: $customQuantity)
                        .keyboardType(.decimalPad)
                        .whiskerTextField()
                        .frame(height: 50)
                }
                .padding(.horizontal)
                
                Button(action: {
                    if let value = Double(customQuantity) {
                        scalingManager.applyCustomScaling(
                            ingredientIndex: selectedIngredientIndex,
                            targetValue: value
                        )
                        ingredients = scalingManager.scaledIngredients
                        showingCustomScalingSheet = false
                    }
                }) {
                    Text("Apply Custom Scaling")
                        .font(WhiskerStyles.Fonts.buttonText)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(
                            RoundedRectangle(cornerRadius: 10)
                                .fill(WhiskerStyles.primaryColor)
                        )
                }
                .padding(.horizontal)
                .padding(.top, 20)
                .disabled(customQuantity.isEmpty)
                .opacity(customQuantity.isEmpty ? 0.6 : 1.0)
                
                Spacer()
            }
            .padding(.bottom, 20)
            .navigationBarItems(
                trailing: Button("Cancel") {
                    showingCustomScalingSheet = false
                }
                .foregroundColor(WhiskerStyles.primaryColor)
            )
        }
    }
}
