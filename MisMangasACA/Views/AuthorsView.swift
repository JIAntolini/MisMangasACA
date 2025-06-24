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
            List(viewModel.displayedAuthors, id: \.id) { author in
                NavigationLink(destination: AuthorMangasView(author: author)) {
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
                .onAppear {
                    viewModel.loadNextPageIfNeeded(currentItem: author)
                }
            }
            .navigationTitle("Autores")
            .task {
                if viewModel.displayedAuthors.isEmpty {
                    await viewModel.loadAuthors()
                }
            }
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
