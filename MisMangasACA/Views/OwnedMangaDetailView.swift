//
//  OwnedMangaDetailView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 22/06/2025.
//


import SwiftUI

struct OwnedMangaDetailView: View {
    let manga: MangaEntity

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if let coverURL = manga.coverURL {
                    AsyncImage(url: coverURL) { image in
                        image.resizable()
                            .scaledToFit()
                            .frame(maxWidth: .infinity)
                            .cornerRadius(16)
                    } placeholder: {
                        Color.gray.frame(height: 300)
                            .cornerRadius(16)
                    }
                }

                Text(manga.title)
                    .font(.largeTitle.bold())
                if let score = manga.score {
                    Text("⭐️ \(String(format: "%.1f", score))")
                        .font(.headline)
                }
                if manga.completeCollection {
                    Text("Colección completa")
                        .font(.subheadline)
                        .foregroundColor(.green)
                }
                if !manga.volumesOwned.isEmpty {
                    Text("Tomos comprados: \(manga.volumesOwned.map(String.init).joined(separator: ", "))")
                        .font(.subheadline)
                }
                if let readingVolume = manga.readingVolume {
                    Text("Leyendo tomo: \(readingVolume)")
                        .font(.subheadline)
                }
            }
            .padding()
        }
        .navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
    }
}