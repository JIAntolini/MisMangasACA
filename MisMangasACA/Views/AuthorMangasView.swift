import SwiftUI // Importado para habilitar propiedades de vista

struct AuthorMangasView: View {
    @StateObject var viewModel: AuthorMangasViewModel

    init(author: AuthorDTO) {
        _viewModel = StateObject(wrappedValue: AuthorMangasViewModel(author: author))
    }

    var body: some View {
        List(viewModel.mangas) { manga in // ← MangaDTO debe adoptar Identifiable, o usar id: \.id
            VStack(alignment: .leading, spacing: 2) {
                Text(manga.title)
                    .font(.headline)
                // Busca el rol del autor actual en el manga
                if let matchingAuthor = manga.authors.first(where: { $0.id == viewModel.author.id }),
                   let role = matchingAuthor.role {
                    Text("Rol: \(role)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
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
