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
                                Task { await vm.loadMangasByGenre(genre) }
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
                }
                .padding()
            }
            .background(.ultraThinMaterial) // fallback para iOS < 18; usa backgroundEffect en Xcode 16+
            .navigationTitle("Top Mangas")
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
                Task {
                    await vm.loadPage(1)
                }
            }
        }
        // Carga inicial: primero los géneros para el filtro y luego la primera página de mangas
        .task {
            await vm.loadGenres()
            await vm.loadNextPageIfNeeded(currentItem: nil)
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
                    Color.gray.frame(width: 60, height: 90)
                case .success(let img):
                    img
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 90)
                        .clipped()
                case .failure:
                    Color.red.frame(width: 60, height: 90)
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
