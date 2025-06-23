//
//  AuthorsView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import SwiftUI

struct AuthorsView: View {
    @StateObject private var viewModel = AuthorsViewModel()

    var body: some View {
        NavigationStack {
            List(viewModel.authors, id: \.id) { author in
                VStack(alignment: .leading) {
                    Text("\(author.firstName) \(author.lastName ?? "")")
                        .font(.headline)
                    if let nationality = author.nationality {
                        Text("Nacionalidad: \(nationality)").font(.subheadline)
                    }
                    if let year = author.birthYear {
                        Text("Año de nacimiento: \(year)").font(.subheadline)
                    }
                }
            }
            .navigationTitle("Autores")
            .task {
                await viewModel.loadAuthors()
            }
            .overlay {
                if viewModel.isLoading {
                    ProgressView("Cargando autores…")
                }
            }
        }
    }
}