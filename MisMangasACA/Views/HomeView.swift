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

// MARK: – Panel de filtros avanzado
@available(iOS 17.0, macOS 14.0, *)
struct FilterInspector: View {
    @ObservedObject var vm: HomeViewModel
    @Environment(\.dismiss) private var dismiss     // Para cerrar el inspector/sheet

    // Wrapper que da identidad estable a cada opción de catálogo
    private struct OptionRow: Identifiable, Hashable {
        let id = UUID()
        let label: String
    }

    // Colecciones con identidad estable (se rellenan en onAppear)
    @State private var demoRows: [OptionRow] = []
    @State private var themeRows: [OptionRow] = []

    var body: some View {
        NavigationStack {
            Form {
                // Campo de texto para título
                Section("Título") {
                    TextField(
                        "",
                        text: $vm.filterSearchText,
                        prompt: Text(vm.filterContains ? "Contiene…" : "Empieza por…")
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }

                // Segmentado Contiene / Empieza por
                Section("Coincidencia") {
                    Picker("", selection: $vm.filterContains) {
                        Text("Contiene").tag(true)
                        Text("Empieza por").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                // Género (selección única)
                if !vm.genres.isEmpty {
                    Section("Género") {
                        Picker("Seleccionar género", selection: $vm.selectedGenre) {
                            Text("Todos").tag(String?.none)
                            ForEach(vm.genres, id: \.self) { genre in
                                Text(genre).tag(String?.some(genre))
                            }
                        }
                        .labelsHidden()          // Evita la fila vacía en el picker
                        .pickerStyle(.inline)
                    }
                }

                // Demografías (multi‑selección)
                if !vm.demographics.isEmpty {
                    Section("Demografía") {
                        ForEach(demoRows) { row in
                            Toggle(row.label, isOn: Binding(
                                get: { vm.selectedDemographies.contains(row.label) },
                                set: { isOn in
                                    if isOn {
                                        vm.selectedDemographies.insert(row.label)
                                    } else {
                                        vm.selectedDemographies.remove(row.label)
                                    }
                                }))
                        }
                    }
                }

                // Temáticas (multi‑selección)
                if !vm.themes.isEmpty {
                    Section("Temática") {
                        ForEach(themeRows) { row in
                            Toggle(row.label, isOn: Binding(
                                get: { vm.selectedThemes.contains(row.label) },
                                set: { isOn in
                                    if isOn {
                                        vm.selectedThemes.insert(row.label)
                                    } else {
                                        vm.selectedThemes.remove(row.label)
                                    }
                                }))
                        }
                    }
                }
            }
            .onAppear {
                if demoRows.isEmpty {
                    demoRows  = vm.demographics.map { OptionRow(label: $0) }
                    themeRows = vm.themes.map        { OptionRow(label: $0) }
                }
            }
            .navigationTitle("Filtros")
            .toolbar {
                // Botón Limpiar
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") {
                        dismiss()   // Cierra primero
                        Task {
                            vm.resetFilters()
                            await vm.loadPage(1, forceReload: true)
                        }
                    }
                    .foregroundColor(.accentColor)
                }
                // Botón Aplicar
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        dismiss()   // Cierra primero
                        Task {
                            await vm.applyFilters()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .tint(.accentColor)   // Fuerza botones azules en cualquier estado del sheet
        }
    }
}

// MARK: – Celda compacta para grid
/*
 struct MangaCoverCell: View {
    let manga: MangaDTO
    
    var body: some View {
        VStack(spacing: 8) {
            AsyncImage(url: manga.mainPicture.flatMap {
                URL(string: $0.replacingOccurrences(of: "\"", with: ""))
            }) { phase in
                switch phase {
                case .empty: Color.gray.opacity(0.3)
                case .success(let img): img.resizable().scaledToFill()
                case .failure: Color.red
                @unknown default: Color.gray
                }
            }
            .frame(width: 140, height: 200)
            .clipped()
            .cornerRadius(8)
            .shadow(radius: 1)
            
            Text(manga.title)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 140)
        }
    }
}
*/
