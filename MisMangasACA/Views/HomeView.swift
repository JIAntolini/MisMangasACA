//
// HomeView.swift
// MisMangasACA
//
// Vista principal que muestra la lista infinita de mangas.
//

import SwiftUI

/// # HomeView
///
/// Vista principal de **MisMangasACA**.  
/// Presenta un listado (o cuadrícula) infinito de mangas, permite búsquedas,
/// filtros avanzados y refresco contextual.
///
/// ## Overview
/// - Consume ``HomeViewModel`` como `@StateObject`.
/// - Alterna **Lista** ⇄ **Grid** con un botón de toolbar.
/// - Integra filtro avanzado mediante ``FilterInspector``
///   y búsqueda por título en la barra superior.
/// - Soporta paginación infinita y pull‑to‑refresh.
///
/// ## Usage
/// ```swift
/// HomeView()                   // Modo iPhone / TabView
/// HomeView(selectedManga: $m)  // Integrado en NavigationSplitView (iPad)
/// ```
///
/// ## Topics
/// ### Subvistas
/// - ``MangaRowView``
/// - ``MangaCoverView``
/// - ``FilterInspector``
///
/// ### Estado local
/// - `query` – Texto de búsqueda.
/// - `useGrid` – Alterna vista lista / grid.
/// - `showFilters` – Presenta el inspector.
/// - `isRefreshing` – Controla animación del botón refresh.
///
/// ## See Also
/// - ``HomeViewModel``
/// - ``MangaDTO``
/// - ``AuthorsView``
/// - ``CollectionView``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
struct HomeView: View {
    /// Manga seleccionado (para NavigationSplitView en iPad)
    @Binding var selectedManga: MangaDTO?
    
    @StateObject private var vm = HomeViewModel()
    @State private var query = "" // Estado para la barra de búsqueda
    /// Controla la presentación del panel de filtros
    @State private var showFilters = false
    /// Para animar el botón de refresco
    @State private var isRefreshing = false
    /// Cambia entre vista de lista y grid
    @State private var useGrid = false

    // Inicializador por defecto para iPhone / TabView.
    init(selectedManga: Binding<MangaDTO?> = .constant(nil)) {
        self._selectedManga = selectedManga
    }
    
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
                Button {
                    showFilters = true
                } label: {
                    Label("", systemImage: "line.3.horizontal.decrease.circle")
                        .labelStyle(.iconOnly)
                        .font(.title2)
                        .foregroundColor(.accentColor)
                        .padding(.trailing, 4)
                }
                .accessibilityLabel("Mostrar filtros")
            }
            .padding(.horizontal)
            .padding(.top, 4)
            
            ScrollView {
                if useGrid {
                    // ───────── GRID (2‑4 columnas adaptativas) ─────────
                    let columns = [GridItem(.adaptive(minimum: 160), spacing: 16)]
                    LazyVGrid(columns: columns, spacing: 16) {
                        ForEach(vm.mangas, id: \.id) { manga in
                            NavigationLink(destination: DetailView(manga: manga)) {
                                MangaCoverView(manga: manga)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                selectedManga = manga
                            })
                            .onAppear {
                                Task { await vm.loadNextPageIfNeeded(currentItem: manga) }
                            }
                        }
                    }
                    .padding(.horizontal)
                    .animation(.easeInOut, value: vm.mangas.count) // Animación de aparición
                } else {
                    // ───────── LISTA (fila horizontal) ─────────
                    LazyVStack(spacing: 16) {
                        ForEach(vm.mangas, id: \.id) { manga in
                            NavigationLink(destination: DetailView(manga: manga)) {
                                MangaRowView(manga: manga)
                            }
                            .simultaneousGesture(TapGesture().onEnded {
                                selectedManga = manga
                            })
                            .onAppear {
                                Task { await vm.loadNextPageIfNeeded(currentItem: manga) }
                            }
                        }
                    }
                    .padding()
                    .animation(.easeInOut, value: vm.mangas.count) // Animación de aparición
                }
                
                if vm.isLoadingPage {
                    ProgressView()
                        .padding()
                }
                
                if !vm.isLoadingPage && vm.mangas.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "tray")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                        Text("Sin resultados")
                            .foregroundColor(.secondary)
                            .font(.callout)
                    }
                    .padding(.vertical, 24)
                } else if !vm.isLoadingPage && vm.isLastPage {
                    Text("No hay más mangas para mostrar.")
                        .foregroundColor(.secondary)
                        .font(.callout)
                        .padding(.vertical, 16)
                }
            }
            .refreshable {
                if vm.selectedGenre != nil {
                    await vm.loadMangasByGenre(vm.selectedGenre!, forceReload: true)
                } else if !query.isEmpty {
                    await vm.searchMangas(with: query)
                } else {
                    await vm.loadPage(1, forceReload: true)
                }
            }
            .background(.ultraThinMaterial) // fallback para iOS < 18; usa backgroundEffect en Xcode 16+
#if swift(>=5.9)
            // Presenta como .inspector en iPad/macOS (iOS 17+). En iPhone se muestra como sheet.
            .inspector(isPresented: $showFilters) {
                FilterInspector(vm: vm)
            }
#else
            .sheet(isPresented: $showFilters) {
                FilterInspector(vm: vm)
            }
#endif
            .navigationTitle(navigationTitle)
            .toolbar {
                // Toggle Grid / List
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        useGrid.toggle()
                    } label: {
                        Image(systemName: useGrid ? "list.bullet" : "square.grid.2x2")
                    }
                    .accessibilityLabel(useGrid ? "Ver como lista" : "Ver como cuadrícula")
                }
                // Ejemplo de toolbar modular
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        guard !isRefreshing else { return }
                        isRefreshing = true
                        Task {
                            if let genre = vm.selectedGenre {
                                await vm.loadMangasByGenre(genre, forceReload: true)
                            } else if !query.isEmpty {
                                await vm.searchMangas(with: query)
                            } else {
                                await vm.applyFilters(page: 1)
                            }
                            await MainActor.run { isRefreshing = false }   // <- NUEVO
                        }
                    } label: {
                        Image(systemName: "arrow.clockwise")
                            .rotationEffect(Angle.degrees(isRefreshing ? 360 : 0))
                            .animation(isRefreshing ? .linear(duration: 0.8).repeatForever(autoreverses: false) : .default, value: isRefreshing)
                    }
                    .disabled(isRefreshing)
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
            await vm.loadCatalogs()
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

