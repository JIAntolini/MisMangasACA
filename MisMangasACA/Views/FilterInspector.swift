import SwiftUI

// MARK: – Panel de filtros avanzado
@available(iOS 17.0, macOS 14.0, *)
struct FilterInspector: View {
    @ObservedObject var vm: HomeViewModel
    @Environment(\.dismiss) private var dismiss     // Para cerrar el inspector/sheet

    // Wrapper que da identidad estable a cada opción de catálogo
    private struct OptionRow: Identifiable, Hashable {
        let id = UUID()
        let label: String
    }

    // Colecciones con identidad estable (se rellenan en onAppear)
    @State private var demoRows: [OptionRow] = []
    @State private var themeRows: [OptionRow] = []

    var body: some View {
        NavigationStack {
            Form {
                // Campo de texto para título
                Section("Título") {
                    TextField(
                        "",
                        text: $vm.filterSearchText,
                        prompt: Text(vm.filterContains ? "Contiene…" : "Empieza por…")
                    )
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                }

                // Segmentado Contiene / Empieza por
                Section("Coincidencia") {
                    Picker("", selection: $vm.filterContains) {
                        Text("Contiene").tag(true)
                        Text("Empieza por").tag(false)
                    }
                    .pickerStyle(.segmented)
                }

                // Género (selección única)
                if !vm.genres.isEmpty {
                    Section("Género") {
                        Picker("Seleccionar género", selection: $vm.selectedGenre) {
                            Text("Todos").tag(String?.none)
                            ForEach(vm.genres, id: \.self) { genre in
                                Text(genre).tag(String?.some(genre))
                            }
                        }
                        .labelsHidden()          // Evita la fila vacía en el picker
                        .pickerStyle(.inline)
                    }
                }

                // Demografías (multi‑selección)
                if !vm.demographics.isEmpty {
                    Section("Demografía") {
                        ForEach(demoRows) { row in
                            Toggle(row.label, isOn: Binding(
                                get: { vm.selectedDemographies.contains(row.label) },
                                set: { isOn in
                                    if isOn {
                                        vm.selectedDemographies.insert(row.label)
                                    } else {
                                        vm.selectedDemographies.remove(row.label)
                                    }
                                }))
                        }
                    }
                }

                // Temáticas (multi‑selección)
                if !vm.themes.isEmpty {
                    Section("Temática") {
                        ForEach(themeRows) { row in
                            Toggle(row.label, isOn: Binding(
                                get: { vm.selectedThemes.contains(row.label) },
                                set: { isOn in
                                    if isOn {
                                        vm.selectedThemes.insert(row.label)
                                    } else {
                                        vm.selectedThemes.remove(row.label)
                                    }
                                }))
                        }
                    }
                }
            }
            .onAppear {
                if demoRows.isEmpty {
                    demoRows  = vm.demographics.map { OptionRow(label: $0) }
                    themeRows = vm.themes.map        { OptionRow(label: $0) }
                }
            }
            .navigationTitle("Filtros")
            .toolbar {
                // Botón Limpiar
                ToolbarItem(placement: .cancellationAction) {
                    Button("Limpiar") {
                        dismiss()   // Cierra primero
                        Task {
                            vm.resetFilters()
                            await vm.loadPage(1, forceReload: true)
                        }
                    }
                    .foregroundColor(.accentColor)
                }
                // Botón Aplicar
                ToolbarItem(placement: .confirmationAction) {
                    Button("Aplicar") {
                        dismiss()   // Cierra primero
                        Task {
                            await vm.applyFilters()
                        }
                    }
                    .foregroundColor(.accentColor)
                }
            }
            .tint(.accentColor)   // Fuerza botones azules en cualquier estado del sheet
        }
    }
}

