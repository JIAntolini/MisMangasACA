//
//  DetailView.swift
//  MisMangasACA
//
//  Versión mejorada: secciones claras, accesibilidad, enlaces externos y mejor visualización.
//

import SwiftUI

/// # DetailView
///
/// Pantalla de detalle de un **manga**.
/// Muestra la portada con efecto *stretchy header*, metadatos, sinopsis expandible,
/// autores, géneros y enlace externo.
///
/// ## Overview
/// - Utiliza `ScrollView` con cabecera elástica similar a Apple TV.
/// - Sinopsis colapsable con botón *Leer más / Leer menos*.
/// - Botón “Añadir a mi colección” abre ``AddToCollectionView`` como sheet.
/// - Accesibilidad: `accessibilityLabel` en portada; jerarquía de encabezados.
///
/// ## Sections
/// | Sección | Descripción |
/// |---------|-------------|
/// | Portada | Imagen remota con parallax |
/// | Metadatos | Título, puntaje, estado, fechas |
/// | Sinopsis / Contexto | Texto expandible |
/// | Autores | Lista con rol |
/// | Géneros / Temas / Demografía | Tags concatenados |
/// | Enlace externo | Link a MyAnimeList |
///
/// ## Usage
/// ```swift
/// NavigationLink(destination: DetailView(manga: manga)) {
///     MangaRowView(manga: manga)
/// }
/// ```
///
/// ## See Also
/// - ``MangaDTO``
/// - ``AddToCollectionView``
/// - ``HomeView``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
struct DetailView: View {
    let manga: MangaDTO
    @State private var showAddSheet = false
    @State private var showFullSynopsis = false // Estado para expandir/cortar sinopsis

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {

                // Portada del manga con efecto "stretchy header" estilo Apple TV
                if let url = manga.mainPicture
                    .flatMap({ $0.replacingOccurrences(of: "\"", with: "").trimmingCharacters(in: .whitespacesAndNewlines) })
                    .flatMap(URL.init)
                {
                    GeometryReader { geo in
                        let minY = geo.frame(in: .global).minY
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .empty:
                                Color.gray
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: geo.size.width, height: minY > 0 ? 300 + minY : 300)
                                    .clipped()
                                    .accessibilityLabel(Text("Portada de \(manga.title)"))
                                    .overlay(alignment: .top) {
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color(.systemBackground),
                                                Color(.systemBackground).opacity(0.7),
                                                Color.clear
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 120)
                                        .ignoresSafeArea()
                                    }
                                    .overlay(alignment: .bottom) {
                                        LinearGradient(
                                            gradient: Gradient(colors: [
                                                Color.clear,
                                                Color(.systemBackground).opacity(0.7),
                                                Color(.systemBackground)
                                            ]),
                                            startPoint: .top,
                                            endPoint: .bottom
                                        )
                                        .frame(height: 120)
                                    }
                            case .failure:
                                Color.red
                            @unknown default:
                                EmptyView()
                            }
                        }
                        .frame(height: 300)
                    }
                    .frame(height: 300)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(manga.title)
                        .font(.largeTitle.bold())
                        .foregroundStyle(.primary)
                        .accessibilityAddTraits(.isHeader)
                    
                    if let jp = manga.titleJapanese {
                        Text(jp)
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    
                    if let en = manga.titleEnglish {
                        Text(en)
                            .font(.title3)
                            .italic()
                            .foregroundColor(.secondary)
                    }

                    HStack(spacing: 16) {
                        if let score = manga.score {
                            Label(String(format: "%.1f", score), systemImage: "star.fill")
                                .foregroundColor(.yellow)
                                .font(.headline)
                        }

                        if let status = manga.status {
                            Text(status.replacingOccurrences(of: "_", with: " "))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        if let start = manga.startDate {
                            Text(start, style: .date)
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }

                        if let end = manga.endDate {
                            Text("– \(end, style: .date)")
                                .font(.subheadline)
                                .foregroundColor(.primary)
                        }
                    }
                }
                .padding(.horizontal)

                Divider()

                // Sinopsis y contexto
                if let s = manga.synopsis {
                    Section(header: Text("Sinopsis").font(.headline)) {
                        Group {
                            if showFullSynopsis {
                                Text(s)
                            } else {
                                Text(s)
                                    .lineLimit(5)
                            }
                        }
                        .font(.body)
                        .animation(.easeInOut, value: showFullSynopsis)

                        Button(showFullSynopsis ? "Leer menos" : "Leer más") {
                            showFullSynopsis.toggle()
                        }
                        .font(.caption)
                        .foregroundColor(.accentColor)
                        .padding(.top, 4)
                    }
                }
                if let bg = manga.background {
                    Section(header: Text("Contexto").font(.headline)) {
                        Text(bg)
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                }

                Divider()

                // Autores
                if !manga.authors.isEmpty {
                    Section(header: Text("Autores").font(.headline)) {
                        ForEach(manga.authors, id: \.id) { a in
                            HStack {
                                Text("\(a.firstName) \(a.lastName ?? "")")
                                    .fontWeight(.medium)
                                if let role = a.role {
                                    Text("(\(role))")
                                        .font(.footnote)
                                        .foregroundColor(.secondary)
                                }
                            }
                        }
                    }
                }

                Divider()

                // Géneros, Temas y Demografías
                VStack(alignment: .leading, spacing: 8) {
                    if !manga.genres.isEmpty {
                        HStack(alignment: .top) {
                            Text("Géneros:").font(.headline)
                            Text(manga.genres.map(\.genre).joined(separator: ", "))
                        }
                    }
                    if !manga.themes.isEmpty {
                        HStack(alignment: .top) {
                            Text("Temas:").font(.headline)
                            Text(manga.themes.map(\.theme).joined(separator: ", "))
                        }
                    }
                    if !manga.demographics.isEmpty {
                        HStack(alignment: .top) {
                            Text("Demografías:").font(.headline)
                            Text(manga.demographics.map(\.demographic).joined(separator: ", "))
                        }
                    }
                }

                Divider()

                // Enlace externo si hay URL válida
                if let rawURL = manga.url?.replacingOccurrences(of: #"\""#, with: ""),
                   let extURL = URL(string: rawURL) {
                    Link("Ver en MyAnimeList", destination: extURL)
                        .font(.footnote)
                        .foregroundColor(.accentColor)
                        .padding(.vertical, 4)
                }

                // Botón para agregar a la colección (muestra un modal)
                Button("Añadir a mi colección") {
                    showAddSheet.toggle()
                }
                .buttonStyle(.borderedProminent)
                .padding(.top, 8)
            }
            .padding()
        }
        .navigationTitle(manga.title)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddSheet) {
            AddToCollectionView(manga: manga)
        }
    }
}
