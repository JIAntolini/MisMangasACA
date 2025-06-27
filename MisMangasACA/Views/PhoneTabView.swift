//
//  PhoneTabView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//


import SwiftUI

struct PhoneTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Label("Mangas", systemImage: "books.vertical") }

            AuthorsView()
                .tabItem { Label("Autores", systemImage: "person.3") }

            CollectionView()
                .tabItem { Label("Colección", systemImage: "books.vertical.fill") }
        }
    }
}