import SwiftUI

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

