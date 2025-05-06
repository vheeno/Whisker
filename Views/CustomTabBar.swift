import SwiftUI

struct CustomMainTabView: View {
    @StateObject private var authManager = AuthenticationManager.shared
    @State private var selectedTab: Int = 0
    
    // Adjust this value to control how high the tab bar sits from the bottom
    private let tabBarBottomPadding: CGFloat = 25
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabContentView(selectedTab: $selectedTab)
                .padding(.bottom, 80) // Reduced padding to account for shorter tab bar
            
            CustomTabBar(selectedTab: $selectedTab)
                .padding(.bottom, tabBarBottomPadding) // This creates space between tab bar and screen bottom
        }
        .ignoresSafeArea(edges: .bottom)
        .background(WhiskerStyles.backgroundColor)
    }
}

struct TabContentView: View {
    @Binding var selectedTab: Int
    
    var body: some View {
        ZStack {
            // First tab content - Recipes
            if selectedTab == 0 {
                RecipeListView()
            }
            
            // Second tab content - Add Recipe
            if selectedTab == 1 {
                AddRecipeView()
            }
            
            // Third tab content - Grocery List (NEW)
            if selectedTab == 2 {
                GroceryListView()
            }
            
            // Fourth tab content - Profile
            if selectedTab == 3 {
                ProfileView()
            }
        }
    }
}


struct CustomTabBar: View {
    @Binding var selectedTab: Int
    
    let tabs = [
        TabItem(icon: "fork.knife", title: "Recipes"),
        TabItem(icon: "plus.circle.fill", title: "Add"),
        TabItem(icon: "cart.fill", title: "Groceries"),
        TabItem(icon: "person.fill", title: "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                TabButton(
                    tabItem: tabs[index],
                    isSelected: selectedTab == index,
                    action: {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedTab = index
                        }
                    }
                )
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 16)
        .background(
            Capsule()
                .fill(Color.white)
                .shadow(
                    color: Color.black.opacity(0.08),
                    radius: 8,
                    x: 0,
                    y: 3
                )
        )
        .padding(.horizontal, 24)
    }
}

struct TabButton: View {
    let tabItem: TabItem
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 2) {
                Image(systemName: tabItem.icon)
                    .font(.system(size: 20))
                    .foregroundColor(isSelected ? WhiskerStyles.primaryColor : Color.gray.opacity(0.7))
                
                Text(tabItem.title)
                    .font(WhiskerStyles.Fonts.bodyRegular)
                    .font(.system(size: 10))
                    .foregroundColor(isSelected ? WhiskerStyles.primaryColor : Color.gray.opacity(0.7))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 5)
            .background(
                Capsule()
                    .fill(isSelected ? WhiskerStyles.primaryColor.opacity(0.1) : Color.clear)
                    .padding(.horizontal, 5)
            )
        }
    }
}

struct TabItem {
    let icon: String
    let title: String
}
