//
//  MangaCoverView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 01/07/2025.
//

//
//  MangaCoverView.swift
//  MisMangasACA
//
//  Vista compacta para usar dentro de un LazyVGrid (modo cuadrícula).
//

import SwiftUI

/// # MangaCoverView
///
/// Celda compacta para mostrar la **portada** y el título de un manga dentro
/// de una cuadrícula (`LazyVGrid`) o cualquier contenedor flexible.
///
/// ## Overview
/// - Descarga la imagen desde `manga.mainPicture` y la muestra con
///   `.scaledToFill()` y `cornerRadius(8)`.
/// - Mantiene un ancho fijo de **140 pt** y alto de **200 pt** para la portada.
/// - El título se muestra en `font(.caption)` con `lineLimit(2)`.
///
/// ## Usage
/// ```swift
/// LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))]) {
///     ForEach(mangas) { manga in
///         NavigationLink {
///             DetailView(manga: manga)
///         } label: {
///             MangaCoverView(manga: manga)
///         }
///     }
/// }
/// ```
///
/// ## Design
/// | Elemento | Estilo |
/// |----------|--------|
/// | Portada  | 140×200 pt, `cornerRadius(8)`, `shadow(radius: 1)` |
/// | Título   | `.caption`, centrado, máximo 2 líneas |
///
/// ## See Also
/// - ``MangaRowView``
/// - ``MangaDTO``
/// - ``HomeView``
///
struct MangaCoverView: View {
    let manga: MangaDTO

    private var coverURL: URL? {
        manga.mainPicture
            .flatMap { $0.replacingOccurrences(of: "\"", with: "") }
            .flatMap(URL.init)
    }

    var body: some View {
        VStack(spacing: 8) {
            // Portada
            AsyncImage(url: coverURL) { phase in
                switch phase {
                case .empty:
                    Color.gray.opacity(0.3)
                case .success(let image):
                    image.resizable().scaledToFill()
                case .failure:
                    Color.red
                @unknown default:
                    Color.gray
                }
            }
            .frame(width: 140, height: 200)
            .clipped()
            .cornerRadius(8)
            .shadow(radius: 1)

            // Título
            Text(manga.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 140)
        }
    }
}

// MARK: - Preview
#Preview {
    MangaCoverView(manga: .previewSample)
        .padding()
}
