//
//  MisMangasACALogoView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 25/06/2025.
//


import SwiftUI

/// Logo animado de MisMangasACA — se puede usar en el splash, header o como branding.
struct MisMangasACALogoView: View {
    @State private var scale: CGFloat = 0.6
    @State private var opacity: Double = 0.0
    @State private var rotate: Double = -10

    var body: some View {
        VStack(spacing: 12) {
            // 📖 Ícono de libro con estilo manga
            Image(systemName: "book.closed.fill") // podés reemplazar por otro símbolo
                .font(.system(size: 60))
                .foregroundStyle(.ultraThickMaterial)
                .rotationEffect(.degrees(rotate))
                .scaleEffect(scale)
                .shadow(radius: 4)

            // 🧢 Título principal estilizado
            Text("Mis Mangas")
                .font(.mangaTitleBold)
                .foregroundStyle(.primary)
                .scaleEffect(scale)
                .opacity(opacity)
        }
        .padding()
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                scale = 1.0
                opacity = 1.0
                rotate = 0
            }
        }
    }
}
