/// # AuthorsView
///
/// Lista de **autores** con búsqueda integrada y paginación infinita.
/// Permite navegar al detalle de mangas de cada autor.
///
/// ## Overview
/// - Barra superior con `TextField` y lupa para búsqueda local/remota.
/// - Agrupa autores por inicial (`A–Z`, “#” para no alfabéticos).
/// - Paginación incremental: carga más al llegar al final.
/// - Indicador *shimmer* mientras descarga la primera página.
/// - Pull‑to‑refresh para recargar todo.
///
/// ## Usage
/// ```swift
/// @StateObject var vm = AuthorsViewModel()
///
/// AuthorsView()                 // inyecta el ViewModel desde el parent
///     .environmentObject(vm)
///     .task { await vm.loadAuthors() }
/// ```
///
/// ## Topics
/// ### Subvistas
/// - ``AuthorMangasView``
///
/// ### Helpers
/// - ``groupedAuthors``
/// - ``sectionTitles``
///
/// ### Modifiers
/// - ``shimmering()``
///
/// ## See Also
/// - ``AuthorsViewModel``
/// - ``AuthorDTO``
/// - ``HomeView``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
struct AuthorsView: View {
    @EnvironmentObject var viewModel: AuthorsViewModel

    var body: some View {
        NavigationStack {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("Buscar autor", text: $viewModel.searchText)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                if !viewModel.searchText.isEmpty {
                    Button(action: {
                        viewModel.searchText = ""
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding([.horizontal, .top])
            // Observa los cambios en el campo de búsqueda para disparar la búsqueda remota o local (iOS 17+)
            .onChange(of: viewModel.searchText) { _, newValue in
                Task {
                    if newValue.count > 2 {
                        // Búsqueda remota si hay más de 2 caracteres
                        await viewModel.searchAuthorsRemotely(newValue)
                    } else if newValue.isEmpty {
                        // Si se borra el texto, recarga la lista general
                        await viewModel.loadAuthors(forceReload: true)
                    }
                    // Si hay 1 o 2 caracteres, no se realiza ninguna acción (evita consultas innecesarias)
                }
            }
            List {
                ForEach(groupedAuthors, id: \.key) { section in
                    Section(header: Text(section.key)) {
                        ForEach(section.value) { author in
                            NavigationLink(destination: AuthorMangasView(author: author)) {
                                HStack(spacing: 12) {
                                // Avatar circular con ícono dinámico según el rol
                                ZStack {
                                    Circle()
                                        .fill(.blue.opacity(0.15))
                                        .frame(width: 44, height: 44)

                                    Image(systemName: {
                                        if let role = author.role?.lowercased() {
                                            if role.contains("story") && role.contains("art") {
                                                return "person.2.fill"
                                            } else if role.contains("art") {
                                                return "pencil.circle.fill"
                                            } else if role.contains("story") {
                                                return "text.book.closed.fill"
                                            }
                                        }
                                        return "person.fill"
                                    }())
                                    .foregroundColor(.blue)
                                }

                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("\(author.firstName) \(author.lastName ?? "")")
                                            .font(.headline)
                                        if let nationality = author.nationality {
                                            Text("Nacionalidad: \(nationality)").font(.subheadline).foregroundColor(.secondary)
                                        }
                                        if let year = author.birthYear {
                                            Text("Año de nacimiento: \(year)").font(.subheadline).foregroundColor(.secondary)
                                        }
                                    }
                                }
                                .padding(.vertical, 4)
                                .transition(.opacity.combined(with: .move(edge: .bottom)))
                            }
                            .onAppear {
                                viewModel.loadNextPageIfNeeded(currentItem: author)
                            }
                        }
                    }
                }
            }
            .navigationTitle("Autores")
            .overlay {
                if viewModel.isLoading && viewModel.displayedAuthors.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "person.3")
                            .font(.system(size: 44))
                            .foregroundColor(.gray.opacity(0.3))
                        VStack(spacing: 8) {
                            ForEach(0..<8, id: \.self) { _ in
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.gray.opacity(0.17))
                                    .frame(height: 44)
                                    .redacted(reason: .placeholder)
                                    .shimmering()
                            }
                        }
                        Text("Cargando autores…")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 60)
                }
            }
            .onAppear {
                // Si la cantidad mostrada es igual a la página actual * pageSize, intenta cargar más (hasta llenar la pantalla)
                if viewModel.displayedAuthors.count == viewModel.currentPage * 10 &&
                    viewModel.displayedAuthors.count < viewModel.authors.count {
                    viewModel.loadNextPage()
                }
            }
            .refreshable {
                await viewModel.loadAuthors(forceReload: true)
            }
        }
    }
}

// MARK: - Shimmer Effect

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -0.7

    func body(content: Content) -> some View {
        content
            .overlay(
                GeometryReader { geo in
                    LinearGradient(
                        gradient: Gradient(colors: [
                            .clear,
                            Color.white.opacity(0.7),
                            .clear
                        ]),
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                    .frame(width: geo.size.width, height: geo.size.height)
                    .offset(x: geo.size.width * phase)
                    .blendMode(.plusLighter)
                    .onAppear {
                        withAnimation(
                            Animation.linear(duration: 1.3)
                                .repeatForever(autoreverses: false)
                        ) {
                            phase = 0.7
                        }
                    }
                }
            )
            .mask(content)
    }
}

extension View {
    func shimmering() -> some View {
        self.modifier(Shimmer())
    }
}

// MARK: - Agrupación de autores por inicial

private extension AuthorsView {
    // Agrupa autores por la inicial del nombre y devuelve un array ordenado por clave (inicial)
    private var groupedAuthors: [(key: String, value: [AuthorDTO])] {
        let authors = viewModel.displayedAuthors
        let groups = Dictionary(grouping: authors) { author in
            let firstChar = String(author.firstName.prefix(1)).uppercased()
            let isAlpha = firstChar.range(of: "^[A-Z]$", options: .regularExpression) != nil
            return isAlpha ? firstChar : "#"
        }

        let sorted = groups.sorted { lhs, rhs in
            switch (lhs.key, rhs.key) {
            case ("#", _): return false   // "#" siempre al final
            case (_, "#"): return true
            default: return lhs.key < rhs.key
            }
        }

        return sorted
    }

    private var sectionTitles: [String] {
        groupedAuthors.map(\.key)
    }
}
