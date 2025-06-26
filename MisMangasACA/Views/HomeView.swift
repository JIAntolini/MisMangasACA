//
// HomeView.swift
// MisMangasACA
//
// Vista principal que muestra la lista infinita de mangas.
//

import SwiftUI

struct HomeView: View {
    @StateObject private var vm = HomeViewModel()
    @State private var query = "" // Estado para la barra de búsqueda
    
    var body: some View {
        NavigationStack {
            HStack(spacing: 8) {
                // Barra de búsqueda integrada
                TextField("Buscar manga", text: $query)
                    .textFieldStyle(.roundedBorder)
                    .padding(.vertical, 6)
                    .disableAutocorrection(true)
                    .onSubmit {
                        Task {
                            await vm.searchMangas(with: query)
                        }
                    }
                if !query.isEmpty {
                    Button(action: { query = "" }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                // Botón de filtro por género como icono
                if !vm.genres.isEmpty {
                    Menu {
                        Button("Todos", action: {
                            vm.selectedGenre = nil
                            query = ""
                            Task { await vm.loadPage(1, forceReload: true) }
                        })
                        ForEach(vm.genres, id: \.self) { genre in
                            Button(genre, action: {
                                vm.selectedGenre = genre
                                query = ""
                                Task { await vm.loadMangasByGenre(genre, forceReload: true) }
                            })
                        }
                    } label: {
                        // Solo ícono, sin texto
                        Label("", systemImage: "line.3.horizontal.decrease.circle")
                            .labelStyle(.iconOnly)
                            .font(.title2)
                            .foregroundColor(.accentColor)
                            .padding(.trailing, 4)
                    }
                    .accessibilityLabel("Filtrar por género")
                }
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(vm.mangas, id: \.id) { manga in
                        NavigationLink(destination: DetailView(manga: manga)) {
                            MangaRowView(manga: manga)
                        }
                        .onAppear {
                            Task {
                                await vm.loadNextPageIfNeeded(currentItem: manga)
                            }
                        }
                    }
                    
                    if vm.isLoadingPage {
                        ProgressView()
                            .padding()
                    }

                    if !vm.isLoadingPage && vm.isLastPage && !vm.mangas.isEmpty {
                        Text("No hay más mangas para mostrar.")
                            .foregroundColor(.secondary)
                            .font(.callout)
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.vertical, 16)
                    }
                }
                .padding()
            }
            .background(.ultraThinMaterial) // fallback para iOS < 18; usa backgroundEffect en Xcode 16+
            .navigationTitle(navigationTitle)
            .toolbar {
                // Ejemplo de toolbar modular
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await vm.loadNextPageIfNeeded(currentItem: nil) }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                    }
                }
            }
        }
        // .searchable eliminado
        .onChange(of: query) { old, new in
            // Si se borra la búsqueda, recarga la página 1 para mostrar el top
            if new.isEmpty {
                if vm.selectedGenre != nil {
                    Task { await vm.loadMangasByGenre(vm.selectedGenre!, forceReload: true) }
                } else {
                    Task { await vm.loadPage(1, forceReload: true) }
                }
            }
        }
        // Carga inicial: primero los géneros para el filtro y luego la primera página de mangas (solo si no hay datos)
        .task {
            await vm.loadGenres()
            if vm.mangas.isEmpty {
                await vm.loadPage(1, forceReload: true)
            }
        }
    }
    
    // Dinámicamente ajusta el título según el contexto
    private var navigationTitle: String {
        if let genre = vm.selectedGenre {
            return genre
        } else if !query.isEmpty {
            return "Resultados"
        } else {
            return "Top Mangas"
        }
    }
}

// Fila sencilla para cada manga
struct MangaRowView: View {
    let manga: MangaDTO
    
    var body: some View {
        let cleanedURL = manga.mainPicture
            .flatMap { raw -> URL? in
                let trimmed = raw.replacingOccurrences(of: "\"", with: "")
                return URL(string: trimmed)
            }
        
        ViewThatFits {
            // Horizontal layout
            HStack(alignment: .top, spacing: 12) {
                coverImage(from: cleanedURL)
                mangaDetails
                Spacer()
            }
            
            // Vertical layout
            VStack(alignment: .leading, spacing: 8) {
                coverImage(from: cleanedURL)
                mangaDetails
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    @ViewBuilder
    private var mangaDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits {
                // Pantallas grandes: 1 línea truncada
                Text(manga.title)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Pantallas chicas: hasta 2 líneas
                Text(manga.title)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let score = manga.score {
                Text("⭐️ \(String(format: "%.1f", score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let status = manga.status {
                Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if let startDate = manga.startDate {
                let year = Calendar.current.component(.year, from: startDate)
                Text("📅 \(year)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if !manga.genres.isEmpty {
                HStack(spacing: 4) {
                    ForEach(manga.genres.prefix(2), id: \.id) { genre in
                        Text(genre.genre)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }
    
    private func coverImage(from url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure:
                Color.red
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 80, height: 120)
        .clipped()
        .cornerRadius(8)
        .shadow(radius: 2)
        .accessibilityLabel(Text("Portada de \(manga.title)"))
    }
}

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Mangas", systemImage: "books.vertical")
                }
            AuthorsView()
                .tabItem {
                    Label("Autores", systemImage: "person.3.sequence.fill")
                }
            CollectionView()
                .tabItem {
                    Label("Colección", systemImage: "books.vertical")
                }
        }
    }
}
