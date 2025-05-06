import SwiftUI

struct RecipeListView: View {
    @ObservedObject private var dataManager = RecipeDataManager.shared
    @State private var searchText = ""
    @State private var isSearching = false
    @FocusState private var searchBarFocused: Bool
    @State private var isEditMode: Bool = false
    
    // Force refresh mechanism - create a new UUID whenever view needs to completely refresh
    @State private var forceRefresh = UUID()
    
    // Combine all recipes from all albums into a single array
    private var allRecipes: [Recipe] {
        var recipes: [Recipe] = []
        
        for album in dataManager.albums {
            for recipe in album.recipes {
                // Create a copy of the recipe with the album ID
                var recipeWithAlbum = recipe
                recipeWithAlbum.albumId = album.id
                recipes.append(recipeWithAlbum)
            }
        }
        
        return recipes.sorted { $0.name < $1.name }
    }
    
    // Filtered recipes based on search
    private var filteredRecipes: [Recipe] {
        if searchText.isEmpty {
            return allRecipes
        } else {
            let searchTextLowercased = searchText.lowercased()
            return allRecipes.filter { recipe in
                return recipe.name.lowercased().contains(searchTextLowercased) ||
                       recipe.ingredients.contains { $0.lowercased().contains(searchTextLowercased) }
            }
        }
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                WhiskerStyles.backgroundColor.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    VStack(alignment: .leading, spacing: 7) {
                        if !isSearching {
                            Text("My Recipes")
                                .font(WhiskerStyles.Fonts.title)
                                .foregroundColor(WhiskerStyles.textColor)
                                .frame(maxWidth: .infinity, alignment: .center)
                                .padding(.top, 25)
                        } else if isSearching && !searchText.isEmpty {
                            Spacer().frame(height: 25)
                            Text("\(filteredRecipes.count) result(s) found")
                                .font(WhiskerStyles.Fonts.bodyLight)
                                .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else if isSearching && searchText.isEmpty {
                            Spacer().frame(height: 25)
                            Text("Type search terms to find specific recipes")
                                .font(WhiskerStyles.Fonts.bodyLight)
                                .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                                .frame(maxWidth: .infinity, alignment: .center)
                        } else {
                            // Empty spacer when not searching
                            Spacer().frame(height: 42)
                        }
                    }
                    .frame(height: 60)
                    .padding(.bottom, 10)
                    
                    // List of recipes
                    if filteredRecipes.isEmpty {
                        emptyStateView
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredRecipes) { recipe in
                                    if isEditMode {
                                        RecipeListItemView(recipe: recipe, isEditMode: true)
                                            .id("\(recipe.id)-\(forceRefresh.uuidString)")
                                            .overlay(
                                                ZStack {
                                                    Rectangle()
                                                        .fill(Color.black.opacity(0.15))
                                                        .cornerRadius(12)
                                                    
                                                    VStack {
                                                        HStack {
                                                            Spacer()
                                                            
                                                            Image(systemName: "trash")
                                                                .foregroundColor(.red.opacity(0.7))
                                                                .font(.system(size: 16))
                                                                .padding(12)
                                                        }
                                                        Spacer()
                                                    }
                                                }
                                            )
                                            .onTapGesture {
                                                if let albumId = recipe.albumId {
                                                    deleteRecipe(albumId: albumId, recipeId: recipe.id)
                                                }
                                            }
                                    } else {
                                        NavigationLink(destination:
                                            RecipeDetailView(recipe: recipe, albumId: recipe.albumId ?? UUID())
                                                .onDisappear {
                                                    forceRefresh = UUID()
                                                }
                                        ) {
                                            RecipeListItemView(recipe: recipe, isEditMode: false)
                                                .id("\(recipe.id)-\(forceRefresh.uuidString)")
                                        }
                                        .buttonStyle(PlainButtonStyle())
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 20)
                        }
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if isEditMode {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.1)) {
                                isEditMode = false
                            }
                        }) {
                            Text("Done")
                                .foregroundColor(.blue)
                        }
                    } else if !isSearching {
                        Button(action: {
                            withAnimation(.easeOut(duration: 0.1)) {
                                isEditMode = true
                                if isSearching {
                                    isSearching = false
                                    searchText = ""
                                }
                            }
                        }) {
                            Image(systemName: "trash")
                                .foregroundColor(WhiskerStyles.textColor)
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarLeading) {
                    if !isEditMode {
                        searchBarView
                    }
                }
            }
            .onAppear {
                loadDataIfNeeded()
                // Force refresh when view appears
                forceRefresh = UUID()
            }
            // Listen for notification when recipes are added/modified
            .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("RecipeAdded"))) { _ in
                // Force refresh when a recipe is added
                forceRefresh = UUID()
            }
        }
    }
    
    private var searchBarView: some View {
        HStack(spacing: 4) {
            if isSearching {
                Button(action: {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isSearching = false
                        searchText = ""
                        searchBarFocused = false
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                }) {
                    Image(systemName: "arrow.left")
                        .foregroundColor(WhiskerStyles.textColor)
                        .frame(width: 30, height: 40)
                }
                
                ZStack(alignment: .trailing) {
                    TextField("Search recipes", text: $searchText)
                        .foregroundColor(WhiskerStyles.textColor)
                        .font(WhiskerStyles.Fonts.bodyRegular)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 8)
                        .background(Color.gray.opacity(0.2))
                        .cornerRadius(20)
                        .focused($searchBarFocused)
                        .frame(width: UIScreen.main.bounds.width - 70)
                    
                    // Clear button overlay positioned inside the text field
                    if !searchText.isEmpty {
                        Button(action: {
                            searchText = ""
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(WhiskerStyles.textColor.opacity(0.6))
                        }
                        .padding(.trailing, 10)
                    }
                }
            } else {
                // Search icon button
                Button(action: {
                    withAnimation(.easeOut(duration: 0.1)) {
                        isSearching = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        searchBarFocused = true
                    }
                }) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(WhiskerStyles.textColor)
                        .frame(width: 40, height: 40)
                }
            }
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            if searchText.isEmpty {
                Image(systemName: "fork.knife")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.6))
                
                Text("No recipes yet")
                    .font(WhiskerStyles.Fonts.bodyMedium)
                    .foregroundColor(WhiskerStyles.textColor)
                
                Text("Add your first recipe to get started")
                    .font(WhiskerStyles.Fonts.bodyLight)
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            } else {
                Image(systemName: "magnifyingglass")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 70, height: 70)
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.6))
                
                Text("No results found")
                    .font(WhiskerStyles.Fonts.bodyMedium)
                    .foregroundColor(WhiskerStyles.textColor)
                
                Text("Try a different search term")
                    .font(WhiskerStyles.Fonts.bodyLight)
                    .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 100)
    }
    
    private func deleteRecipe(albumId: UUID, recipeId: UUID) {
        let recipeIds = Set([recipeId])
        dataManager.deleteRecipes(fromAlbumId: albumId, recipeIds: recipeIds)
        
        forceRefresh = UUID()
    }
    
    private func loadDataIfNeeded() {
        if dataManager.albums.isEmpty {
            dataManager.loadAlbums()
        }
    }
}

struct RecipeListItemView: View {
    let recipe: Recipe
    let isEditMode: Bool
    
    // Create a unique cache key for this image
    private var imageCacheKey: String {
        return "\(recipe.id.uuidString)-\(recipe.image)"
    }
    
    var body: some View {
        HStack(spacing: 16) {
            if let url = URL(string: recipe.image), recipe.image.hasPrefix("http") {
                AsyncImage(
                    url: url,
                    transaction: Transaction(animation: .easeInOut)
                ) { phase in
                    switch phase {
                    case .empty:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                ProgressView()
                                    .progressViewStyle(CircularProgressViewStyle())
                            )
                    case .success(let image):
                        image
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width: 80, height: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                    case .failure:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                            .overlay(
                                Image(systemName: "photo")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 30, height: 30)
                                    .foregroundColor(.white)
                            )
                    @unknown default:
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.gray.opacity(0.3))
                            .frame(width: 80, height: 80)
                    }
                }
                .frame(width: 80, height: 80)
                .id(imageCacheKey)
            } else {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 80, height: 80)
                    .overlay(
                        Image(systemName: recipe.image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 30, height: 30)
                            .foregroundColor(.white)
                    )
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(recipe.name)
                    .font(WhiskerStyles.Fonts.bodyMedium)
                    .foregroundColor(WhiskerStyles.textColor)
                    .lineLimit(1)
                
                HStack(spacing: 20) {
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet")
                            .font(.system(size: 12))
                            .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                        Text("\(recipe.ingredients.count) ingredients")
                            .font(WhiskerStyles.Fonts.bodyLight)
                            .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                            .lineLimit(1)
                    }
                    
                    HStack(spacing: 4) {
                        Image(systemName: "text.badge.checkmark")
                            .font(.system(size: 12))
                            .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                        
                        Text("\(recipe.instructions.count) instructions")
                            .font(WhiskerStyles.Fonts.bodyLight)
                            .foregroundColor(WhiskerStyles.textColor.opacity(0.7))
                            .lineLimit(1)
                    }
                }
            }
            
            Spacer()
            
            // Navigation arrow - always show
            Image(systemName: "chevron.right")
                .foregroundColor(WhiskerStyles.textColor.opacity(0.5))
                .padding(.trailing, 4)
        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
    }
}
