//
//  AddToCollectionView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 21/06/2025.
//


import SwiftUI
import SwiftData

struct AddToCollectionView: View {
    let manga: MangaDTO
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext

    @State private var isComplete = false
    @State private var ownedVolumes: [Int] = []
    @State private var readingVolume: Int?

    var body: some View {
        Form {
            Toggle("Tengo la colección completa", isOn: $isComplete)
            Stepper("Cantidad de volúmenes: \(ownedVolumes.count)", value: Binding(
                get: { ownedVolumes.count },
                set: { newValue in ownedVolumes = Array(1...max(newValue, 0)) }
            ), in: 0...(manga.volumes ?? 100))

            Picker("Tomo que estoy leyendo", selection: $readingVolume) {
                Text("Ninguno").tag(nil as Int?)
                ForEach(1...(manga.volumes ?? 10), id: \.self) { vol in
                    Text("Tomo \(vol)").tag(vol as Int?)
                }
            }

            // Botón para guardar la información en SwiftData,
            // evitando duplicados mediante un #Predicate.
            Button("Guardar en mi colección") {
                do {
                    // 1️⃣ Verificamos si el manga ya está en la colección local
                    let mangaID = manga.id
                    let descriptor = FetchDescriptor(
                        predicate: #Predicate<UserCollectionEntry> { $0.mangaID == mangaID }
                    )
                    if let existing = try modelContext.fetch(descriptor).first {
                        // Ya existe: solo actualizamos los campos editables
                        existing.completeCollection = isComplete
                        existing.volumesOwned     = ownedVolumes
                        existing.readingVolume    = readingVolume
                        existing.updatedAt        = .now
                    } else {
                        // No existe: creamos una nueva entrada
                        let entry = UserCollectionEntry(
                            mangaID: manga.id,
                            title: manga.title,
                            coverURL: manga.mainPicture,
                            volumesOwned: ownedVolumes,
                            readingVolume: readingVolume,
                            completeCollection: isComplete
                        )
                        modelContext.insert(entry)
                    }
                    try modelContext.save()   // Persistimos los cambios
                    dismiss()                 // Cerramos el modal
                } catch {
                    // En producción podríamos mostrar un alert; por ahora, log al debugger.
                    print("❌ Error guardando en SwiftData:", error)
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Agregar a colección")
    }
}
