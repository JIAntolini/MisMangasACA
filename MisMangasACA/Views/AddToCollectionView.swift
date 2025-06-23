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

            // Botón para guardar el manga en la colección, evitando duplicados
//            Button("Guardar en mi colección") {
//                // Buscamos si ya existe el manga en la colección usando su ID único
//                let descriptor = FetchDescriptor(
//                    predicate: #Predicate<MangaEntity> { $0.id == manga.id }
//                )
//                if let existing = try? modelContext.fetch(descriptor).first {
//                    // Si ya existe, solo actualizamos los datos relevantes
//                    existing.completeCollection = isComplete
//                    existing.volumesOwned = ownedVolumes
//                    existing.readingVolume = readingVolume
//                } else {
//                    // Si no existe, creamos una nueva entrada en la colección
//                    let entity = MangaEntity(from: manga, context: modelContext)
//                    entity.completeCollection = isComplete
//                    entity.volumesOwned = ownedVolumes
//                    entity.readingVolume = readingVolume
//                    modelContext.insert(entity)
//                }
//                // Guardamos los cambios y cerramos el modal
//                try? modelContext.save()
//                dismiss()
//            }
            .buttonStyle(.borderedProminent)
        }
        .navigationTitle("Agregar a colección")
    }
}

