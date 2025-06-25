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
        // Carga inicial: primero los géneros para el filtro y luego la primera página de mangas
        .task {
            await vm.loadGenres()
            await vm.loadPage(1, forceReload: true)
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
        HStack(alignment: .top, spacing: 12) {
            let cleanedURL = manga.mainPicture
                .flatMap { raw -> URL? in
                    let trimmed = raw.replacingOccurrences(of: "\"", with: "")
                    return URL(string: trimmed)
                }

            AsyncImage(url: cleanedURL) { phase in
                switch phase {
                case .empty:
                    Color.gray
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: 80)
                        .cornerRadius(8)
                        .accessibilityLabel(Text("Portada de \(manga.title)"))
                case .failure:
                    Color.red
                        .frame(width: 60, height: 90)
                        .cornerRadius(8)
                @unknown default:
                    EmptyView()
                }
            }
            VStack(alignment: .leading, spacing: 4) {
                Text(manga.title)
                    .font(.headline)
//                    .foregroundColor(.primary) // fuerza a negro en modo claro
                if let score = manga.score {
                    Text("⭐️ \(String(format: "%.1f", score))")
                        .font(.subheadline)
                        .foregroundColor(.primary) // fuerza a negro en modo claro
                }
            }
            Spacer()
        }
        .background(.ultraThinMaterial) // fallback para iOS < 18; usa backgroundEffect en Xcode 16+
        .cornerRadius(8)
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
