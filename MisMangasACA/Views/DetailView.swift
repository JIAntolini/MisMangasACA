//
//  DetailView.swift
//  MisMangasACA
//
//  Versión mejorada: secciones claras, accesibilidad, enlaces externos y mejor visualización.
//

import SwiftUI

struct DetailView: View {
    let manga: MangaDTO
    @State private var showAddSheet = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {

                // Portada del manga con fondo y esquinas redondeadas
                if
                    let raw = manga.mainPicture?.replacingOccurrences(of: #"\""#, with: ""),
                    let url = URL(string: raw)
                {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img
                                .resizable()
                                .scaledToFill()
                                .frame(maxWidth: .infinity)
                                .clipped()
                                .cornerRadius(16)
                                .accessibilityLabel(Text("Portada de \(manga.title)"))
                        default:
                            Color.gray
                                .frame(height: 300)
                                .cornerRadius(16)
                        }
                    }
                    .frame(height: 300)
                    .background(.ultraThinMaterial)
                    .padding(.bottom, 8)
                }

                // Títulos principales
                VStack(alignment: .leading, spacing: 2) {
                    Text(manga.title)
                        .font(.largeTitle.bold())
                        .accessibilityAddTraits(.isHeader)
                    if let jp = manga.titleJapanese {
                        Text(jp)
                            .font(.mangaBody)
                            .italic()
                            .foregroundColor(.secondary)
                    }
                    if let en = manga.titleEnglish {
                        Text(en)
                            .font(.mangaBody)
                            .foregroundColor(.secondary)
                    }
                }

                // Metadatos clave: score, estado y fechas
                HStack(spacing: 16) {
                    if let score = manga.score {
                        Label("\(String(format: "%.1f", score))", systemImage: "star.fill")
                            .foregroundColor(.yellow)
                            .font(.headline)
                    }
                    if let status = manga.status {
                        Text(status.capitalized)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    if let start = manga.startDate {
                        Text(start, style: .date)
                    }
                    if let end = manga.endDate {
                        Text("– \(end, style: .date)")
                    }
                }
                .accessibilityElement(children: .combine)
                .font(.subheadline)

                Divider()

                // Sinopsis y contexto
                if let s = manga.synopsis {
                    Section(header: Text("Sinopsis").font(.headline)) {
                        Text(s)
                            .font(.body)
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

