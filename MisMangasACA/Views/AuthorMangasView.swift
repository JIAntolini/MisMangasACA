import SwiftUI // Importado para habilitar propiedades de vista

/// # AuthorMangasView
///
/// Vista que muestra la lista paginada de **mangas** asociados a un autor
/// seleccionado desde ``AuthorsView``.  Utiliza ``AuthorMangasViewModel``
/// para obtener los datos e implementa *infinite scroll* al llegar al final.
///
/// ## Overview
/// - Descarga la primera página en `.task { await viewModel.loadPage(1) }`.  
/// - Cada celda muestra portada, título y el rol del autor en ese manga.  
/// - Al aparecer la última celda visible, ``loadNextPageIfNeeded(currentItem:)``
///   solicita la página siguiente si existe.
/// - Navega a ``DetailView`` al tocar un manga.
///
/// ## Usage
/// ```swift
/// NavigationLink {
///     AuthorMangasView(author: author)
/// } label: {
///     Text(author.fullName)
/// }
/// ```
///
/// ## Topics
/// ### Subvistas
/// - ``DetailView``
///
/// ### ViewModel
/// - ``AuthorMangasViewModel``
///
/// ## See Also
/// - ``AuthorsView``
/// - ``AuthorDTO``
/// - ``MangaDTO``
///
/// ## Author
/// Creado por Juan Ignacio Antolini — 2025
///
struct AuthorMangasView: View {
    @StateObject var viewModel: AuthorMangasViewModel

    init(author: AuthorDTO) {
        _viewModel = StateObject(wrappedValue: AuthorMangasViewModel(author: author))
    }

    var body: some View {
        List(viewModel.mangas) { manga in
            NavigationLink(destination: DetailView(manga: manga)) {
                HStack(alignment: .top, spacing: 12) {
                    AsyncImage(url: {
                        // mainPicture puede venir con dobles comillas escapadas
                        let raw = manga.mainPicture?.replacingOccurrences(of: "\"", with: "")
                        return URL(string: raw ?? "")
                    }()) { image in
                        image.resizable()
                            .scaledToFill()
                    } placeholder: {
                        Color.gray.opacity(0.1)
                    }
                    .frame(width: 48, height: 68)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .shadow(radius: 1)

                    VStack(alignment: .leading, spacing: 4) {
                        Text(manga.title)
                            .font(.headline)
                            .lineLimit(2)
                        if let matchingAuthor = manga.authors.first(where: { $0.id == viewModel.author.id }),
                           let role = matchingAuthor.role {
                            Text("Rol: \(role)")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .padding(.vertical, 4)
            }
            .onAppear {
                Task {
                    await viewModel.loadNextPageIfNeeded(currentItem: manga)
                }
            }
        }
        .navigationTitle("Mangas de \(viewModel.author.firstName)\(viewModel.author.lastName.map { " \($0)" } ?? "")")
        .task {
            await viewModel.loadPage(1)
        }
    }
}
