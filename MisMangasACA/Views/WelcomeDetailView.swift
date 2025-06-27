//
//  WelcomeDetailView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//


import SwiftUI

struct WelcomeDetailView: View {
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "books.vertical")
                .font(.system(size: 120))
                .foregroundColor(.accentColor.opacity(0.7))

            Text("Bienvenido a Mis Mangas")
                .font(.title2.bold())

            Text("Selecciona un manga de la lista o explora tus autores y tu colección.")
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
