//
//  RecipeImageView.swift
//  Whisker
//
//  Created by Julia Yu on 5/5/25.
//

import SwiftUI

struct RecipeImageView: View {
    let imageSource: String
    
    var body: some View {
        if let url = URL(string: imageSource), imageSource.hasPrefix("http") {
            // If the image is a valid URL, load it asynchronously
            AsyncImage(url: url) { phase in
                switch phase {
                case .empty:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .overlay(
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle())
                        )
                case .success(let image):
                    image
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth: .infinity)
                        .frame(height: 250)
                        .clipped()
                case .failure:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                        .overlay(
                            Image(systemName: "photo")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 60, height: 60)
                                .foregroundColor(.white)
                        )
                @unknown default:
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(height: 250)
                }
            }
        } else {
            // If not a URL, use system image or placeholder
            Rectangle()
                .fill(Color.gray.opacity(0.3))
                .frame(height: 250)
                .overlay(
                    Image(systemName: imageSource)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 60, height: 60)
                        .foregroundColor(.white)
                )
        }
    }
}
