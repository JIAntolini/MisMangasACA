//
//  Font+Custom.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 25/06/2025.
//

// Font+Custom.swift
// Fuente personalizada para MisMangasACA
// Carga la fuente Manga Temple de forma reutilizable

import SwiftUI

extension Font {
    /// Fuente personalizada para títulos llamativos
    static let mangaTitle = Font.custom("Manga Temple", size: 20)

    /// Fuente personalizada para texto secundario
    static let mangaBody = Font.custom("Manga Temple", size: 14)

    /// Fuente personalizada en negrita
    static let mangaTitleBold = Font.custom("Manga Temple Bold", size: 20)

    /// Fuente personalizada en cursiva
    static let mangaItalic = Font.custom("Manga Temple Italic", size: 14)
}
