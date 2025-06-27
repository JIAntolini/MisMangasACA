//
//  OwnedMangaDetailView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 22/06/2025.
//  Vista de detalle y edición para un manga de la colección local.
//

import SwiftUI
import SwiftData      // Necesario para `@Bindable`
import Charts

struct OwnedMangaDetailView: View {

    /// Entrada persistente de la colección que estamos editando.
    @Bindable var entry: UserCollectionEntry

    /// Máximo de volúmenes a mostrar en chips / slider. Solo crece.
    @State private var dynamicMax: Int

    /// Portada descargada si no teníamos URL guardada
    @State private var fetchedCoverURL: String?

    /// Tamaño de clase horizontal para adaptar layout (iPad vs iPhone)
    @Environment(\.horizontalSizeClass) private var hSize


    init(entry: UserCollectionEntry) {
        self._entry = Bindable(wrappedValue: entry)
        _dynamicMax = State(initialValue: max(entry.volumesOwned.max() ?? (entry.readingVolume ?? 1), 1))
    }

    // MARK: - Vista
    var body: some View {
        ScrollView {
            HStack {
                VStack(spacing: 16) {
                    // Portada
                    cover
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    // Card principal
                    VStack(spacing: 16) {
                        Divider()

                        // Toggle colección
                        Toggle("Colección completa", isOn: $entry.completeCollection)
                            .toggleStyle(.switch)

                        // Progreso
                        VStack(spacing: 12) {
                            Text("Progreso de lectura")
                                .font(.headline)
                                .frame(maxWidth: .infinity, alignment: .leading)

                            Slider(
                                value: Binding(
                                    get: { Double(entry.readingVolume ?? 0) },
                                    set: { entry.readingVolume = Int($0.rounded()) }
                                ),
                                in: 0...Double(purchasedMax),
                                step: 1
                            )
                            .frame(maxWidth: 240)
                            .padding(.top, 4)

                            // Donut de progreso usando Swift Charts
                            Chart {
                                SectorMark(
                                    angle: .value("Leído", Double(entry.readingVolume ?? 0)),
                                    innerRadius: .ratio(0.60),
                                    angularInset: 2
                                )
                                .foregroundStyle(Color.accentColor)

                                SectorMark(
                                    angle: .value("Restante",
                                                  Double(max(purchasedMax - (entry.readingVolume ?? 0), 0))),
                                    innerRadius: .ratio(0.60),
                                    angularInset: 2
                                )
                                .foregroundStyle(Color.gray.opacity(0.25))
                            }
                            .chartLegend(.hidden)
                            .frame(width: 160, height: 160)
                            .overlay(
                                Text("\(entry.readingVolume ?? 0) / \(purchasedMax)")
                                    .font(.headline)
                            )
                            .accessibilityElement()
                            .accessibilityLabel("Progreso de lectura")
                            .accessibilityValue("\(entry.readingVolume ?? 0) de \(purchasedMax) tomos")
                        }

                        // Chips de tomos
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Tomos comprados")
                                .font(.headline)

                            let columns = [GridItem(.adaptive(minimum: 40), spacing: 8)]
                            LazyVGrid(columns: columns, alignment: .leading, spacing: 8) {
                                ForEach(1...dynamicMax, id: \.self) { tomo in
                                    Text("\(tomo)")
                                        .font(.caption)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(
                                            entry.volumesOwned.contains(tomo)
                                            ? Color.accentColor.opacity(0.25)
                                            : Color.gray.opacity(0.25)
                                        )
                                        .foregroundColor(.primary)
                                        .clipShape(Capsule())
                                        .onTapGesture {
                                            toggleVolume(tomo)
                                        }
                                }
                            }
                        }
                    }
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(radius: 4, y: 2)
                }
                .frame(maxWidth: hSize == .regular ? 600 : .infinity)
            }
            .frame(maxWidth: .infinity)
            .padding(.horizontal, hSize == .regular ? 32 : 16)
        }
        .navigationTitle(entry.title)
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await loadCoverIfNeeded()
        }
    }

    // Portada grande o placeholder
    @ViewBuilder
    private var cover: some View {
        let urlString = entry.coverURL ?? fetchedCoverURL
        if let urlString {
            let clean = urlString.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
            if let url = URL(string: clean) {
                AsyncImage(url: url) { image in
                    image
                        .resizable()
                        .scaledToFill()
                } placeholder: {
                    Color.gray.opacity(0.2)
                }
                .clipped()
                .aspectRatio(16/9, contentMode: .fit)
            } else {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.secondary.opacity(0.15))
                    Image(systemName: "book.closed")
                        .font(.system(size: 60))
                        .foregroundColor(.secondary)
                }
                .aspectRatio(16/9, contentMode: .fit)
            }
        } else {
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(.secondary.opacity(0.15))
                Image(systemName: "book.closed")
                    .font(.system(size: 60))
                    .foregroundColor(.secondary)
            }
            .aspectRatio(16/9, contentMode: .fit)
        }
    }

    /// Mayor tomo realmente comprado
    private var purchasedMax: Int {
        entry.volumesOwned.max() ?? 1
    }

    // MARK: - Carga de portada
    @MainActor
    private func loadCoverIfNeeded() async {
        guard entry.coverURL == nil,
              fetchedCoverURL == nil else { return }

        let base = "https://mymanga-acacademy-5607149ebe3d.herokuapp.com/manga/"
        guard let url = URL(string: base + String(entry.mangaID)) else { return }

        do {
            let (data, _) = try await URLSession.shared.data(from: url)
            if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
               var picture = json["mainPicture"] as? String {
                picture = picture.trimmingCharacters(in: CharacterSet(charactersIn: "\""))
                fetchedCoverURL = picture
            }
        } catch {
            print("❌ Error fetching cover:", error)
        }
    }

    // Alterna un tomo en `volumesOwned`
    private func toggleVolume(_ tomo: Int) {
        if let index = entry.volumesOwned.firstIndex(of: tomo) {
            entry.volumesOwned.remove(at: index)
        } else {
            entry.volumesOwned.append(tomo)
        }
        entry.volumesOwned.sort()        // mantenemos orden

        // Asegura que la lectura no apunte a un tomo que ya no poseemos
        if let current = entry.readingVolume, current > purchasedMax {
            entry.readingVolume = purchasedMax
        }

        // Ajusta `dynamicMax` solo si necesitamos agrandar; nunca lo reducimos
        let candidateMax = max(entry.volumesOwned.max() ?? 0,
                               entry.readingVolume ?? 0,
                               1)
        if candidateMax > dynamicMax {
            dynamicMax = candidateMax
        }
    }
}
