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
    @State private var scale: CGFloat = 0.8
    @State private var opacity: Double = 0.0
    @State private var logoScale: CGFloat = 0.8
    @State private var logoOpacity: Double = 0.0
    @State private var pulse = false

    var body: some View {
        ZStack {
            // 🎨 Fondo degradado suave y oscuro
            LinearGradient(colors: [
                Color(red: 0.9, green: 0.2, blue: 0.2),
                Color(red: 0.2, green: 0, blue: 0)
            ], startPoint: .top, endPoint: .bottom)
            .ignoresSafeArea()

            if showHome {
                MainTabView()
                    .transition(.move(edge: .trailing).combined(with: .opacity))
            } else {
                VStack(spacing: 24) {
                    Spacer()

                    // 💠 Card de vidrio con ícono y título
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .frame(width: 260, height: 220)
                        .overlay {
                            VStack(spacing: 12) {
                                Image(systemName: "book.fill")
                                    .resizable()
                                    .scaledToFit()
                                    .frame(width: 60, height: 60)
                                    .foregroundStyle(.primary)
                                    .scaleEffect(pulse ? 1.05 : 1.0)
                                    .animation(.easeInOut(duration: 1).repeatForever(autoreverses: true), value: pulse)

                                Text("Mis Mangas")
                                    .font(.mangaTitleBold)
                                    .foregroundStyle(.primary)
                            }
                            .opacity(opacity)
                            .scaleEffect(scale)
                            .animation(.easeOut(duration: 1), value: scale)
                            .animation(.easeIn(duration: 1.2), value: opacity)
                        }
                        .shadow(radius: 10)

                    // 📝 Eslogan animado
                    Text("Tu biblioteca de mangas en un solo lugar")
                        .font(.mangaBody)
                        .foregroundStyle(.white.opacity(0.9))
                        .opacity(opacity)
                        .animation(.easeIn(duration: 1.6).delay(0.2), value: opacity)

                    Spacer()

                    // 🤝 Créditos institucionales
                    HStack(spacing: 8) {
                        Image("appleCodingLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24)
                            .clipShape(RoundedRectangle(cornerRadius: 6))
                            .opacity(0.85)

                        Text("Desarrollada con el apoyo de Apple Coding Academy")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.7))
                    }
                    .opacity(logoOpacity)
                    .scaleEffect(logoScale)
                    .animation(.easeOut(duration: 1), value: logoScale)
                    .animation(.easeIn(duration: 1.2), value: logoOpacity)
                    .padding(.bottom, 32)
                }
                .padding(.horizontal)
            }
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                scale = 1.0
                opacity = 1.0
                logoScale = 1.0
                logoOpacity = 1.0
                pulse = true
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                withAnimation(.easeInOut(duration: 1.2)) {
                    showHome = true
                }
            }
        }
    }
}
