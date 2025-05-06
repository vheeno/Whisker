//
//  GroceryItemRow.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//
import SwiftUI

struct GroceryItemRow: View {
    let item: GroceryItem
    @ObservedObject private var groceryManager = GroceryListManager.shared
    
    var body: some View {
        HStack {
            // Checkbox button
            Button(action: {
                groceryManager.toggleItemChecked(item.id)
            }) {
                Image(systemName: item.isChecked ? "checkmark.circle.fill" : "circle")
                    .foregroundColor(item.isChecked ? WhiskerStyles.primaryColor : .gray)
                    .font(.system(size: 20))
            }
            .buttonStyle(PlainButtonStyle())
            
            // Item name with optional strikethrough for checked items
            Text(item.name)
                .font(WhiskerStyles.Fonts.bodyRegular)
                .foregroundColor(WhiskerStyles.textColor)
                .strikethrough(item.isChecked)
                .lineLimit(2)
                .multilineTextAlignment(.leading)
            
            Spacer()
            
            if let source = item.recipeSource, !item.isChecked {
                Text(source)
                    .font(WhiskerStyles.Fonts.bodyLight(size: 12))
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.6))
                    .lineLimit(1)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(WhiskerStyles.primaryColor.opacity(0.1))
                    )
            }
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle()) // Makes the whole row tappable
        .contextMenu {
            Button(action: {
                groceryManager.toggleItemChecked(item.id)
            }) {
                Label(item.isChecked ? "Mark as Unchecked" : "Mark as Checked",
                      systemImage: item.isChecked ? "circle" : "checkmark.circle")
            }
            
            Button(role: .destructive, action: {
                groceryManager.removeItem(item.id)
            }) {
                Label("Remove Item", systemImage: "trash")
            }
        }
        .swipeActions(edge: .trailing) {
            Button(role: .destructive) {
                groceryManager.removeItem(item.id)
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
        .swipeActions(edge: .leading) {
            Button {
                groceryManager.toggleItemChecked(item.id)
            } label: {
                Label(item.isChecked ? "Uncheck" : "Check",
                      systemImage: item.isChecked ? "circle" : "checkmark.circle.fill")
            }
            .tint(WhiskerStyles.primaryColor)
        }
    }
}
