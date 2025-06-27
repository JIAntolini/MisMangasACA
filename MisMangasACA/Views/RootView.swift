//
//  RootView.swift
//  MisMangasACA
//
//  Created by Juan Ignacio Antolini on 27/06/2025.
//


import SwiftUI

struct RootView: View {
    @Environment(\.horizontalSizeClass) private var hSize

    var body: some View {
        if hSize == .regular {
            // iPad / Mac
            SplitLayoutView()
        } else {
            // iPhone
            PhoneTabView()
        }
    }
}