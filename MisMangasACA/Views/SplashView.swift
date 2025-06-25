//
//  SplashView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 25/06/2025.
//


import SwiftUI

/// Pantalla inicial con el logo animado de MisMangasACA.
/// Transiciona automáticamente a HomeView tras una breve animación.
struct SplashView: View {
    @State private var showHome = false

    var body: some View {
        ZStack {
            // Fondo sólido oscuro
            Color.black.ignoresSafeArea()

            if showHome {
                MainTabView() // restaurar navegación principal
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 16) {
                    // ✨ Logo sobre tarjeta de vidrio
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 260, height: 220)
                        .overlay {
                            MisMangasACALogoView()
                                .font(.mangaTitle) // Aplica la fuente personalizada Manga Temple
                        }
                        .shadow(radius: 10)

                    // 📝 Eslogan
                    Text("Tu biblioteca de mangas en un solo lugar")
                        .font(.mangaBody) // Aplica la fuente personalizada Manga Temple
                        .foregroundStyle(.white)
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    showHome = true
                }
            }
        }
    }
}
