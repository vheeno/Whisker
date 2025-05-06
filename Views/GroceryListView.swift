//
//  GroceryListView.swift
//  Whisker

import SwiftUI

struct GroceryListView: View {
    @ObservedObject private var groceryManager = GroceryListManager.shared
    @State private var showingAddItemAlert = false
    @State private var newItemName = ""
    @State private var showClearConfirmation = false
    
    var body: some View {
        NavigationView {
            ZStack {
                WhiskerStyles.backgroundColor.ignoresSafeArea()
                VStack(spacing: 0) {
                    Text("Grocery List")
                        .font(WhiskerStyles.Fonts.title)
                        .foregroundColor(WhiskerStyles.textColor)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 20)
                        .padding(.bottom, 10)
                    
                    if groceryManager.groceryItems.isEmpty {
                        emptyStateView
                    } else {
                        groceryListByRecipe
                    }
                }
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(action: {
                            showingAddItemAlert = true
                        }) {
                            Image(systemName: "plus")
                                .foregroundColor(WhiskerStyles.primaryColor)
                        }
                    }
                    
                    ToolbarItem(placement: .navigationBarTrailing) {
                        if !groceryManager.groceryItems.filter({ $0.isChecked }).isEmpty {
                            Button(action: {
                                showClearConfirmation = true
                            }) {
                                Image(systemName: "trash")
                                    .foregroundColor(WhiskerStyles.primaryColor)
                            }
                        }
                    }
                }
                .alert("Add New Item", isPresented: $showingAddItemAlert) {
                    TextField("Item name", text: $newItemName)
                    Button("Cancel", role: .cancel) {}
                    Button("Add") {
                        if !newItemName.isEmpty {
                            let newItem = GroceryItem(name: newItemName)
                            groceryManager.addItems([newItem])
                            newItemName = ""
                        }
                    }
                }
                .alert("Clear Checked Items", isPresented: $showClearConfirmation) {
                    Button("Cancel", role: .cancel) {}
                    Button("Clear", role: .destructive) {
                        groceryManager.clearCheckedItems()
                    }
                } message: {
                    Text("Remove all checked items from your grocery list?")
                }
                .navigationBarTitleDisplayMode(.inline)
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "cart")
                .resizable()
                .scaledToFit()
                .frame(width: 70, height: 70)
                .foregroundColor(WhiskerStyles.textColor.opacity(0.6))
            
            Text("Your grocery list is empty")
                .font(WhiskerStyles.Fonts.bodyMedium)
                .foregroundColor(WhiskerStyles.textColor)
            
            Text("Add ingredients from your recipes or tap + to add items manually")
                .font(WhiskerStyles.Fonts.bodyLight)
                .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var groceryListByRecipe: some View {
        List {
            ForEach(Array(groceryManager.itemsByRecipe().keys.sorted()), id: \.self) { recipeName in
                Section(header: Text(recipeName)) {
                    ForEach(groceryManager.itemsByRecipe()[recipeName]!) { item in
                        GroceryItemRow(item: item)
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            let item = groceryManager.itemsByRecipe()[recipeName]![index]
                            groceryManager.removeItem(item.id)
                        }
                    }
                }
            }
        }
        .listStyle(InsetGroupedListStyle())
        .scrollContentBackground(.hidden)
        .background(WhiskerStyles.backgroundColor)
    }
}
