import SwiftUI

/// Fila sencilla para cada manga.
struct MangaRowView: View {
    let manga: MangaDTO

    var body: some View {
        let cleanedURL = manga.mainPicture
            .flatMap { raw -> URL? in
                let trimmed = raw.replacingOccurrences(of: "\"", with: "")
                return URL(string: trimmed)
            }

        ViewThatFits {
            // Horizontal layout
            HStack(alignment: .top, spacing: 12) {
                coverImage(from: cleanedURL)
                mangaDetails
                Spacer()
            }

            // Vertical layout
            VStack(alignment: .leading, spacing: 8) {
                coverImage(from: cleanedURL)
                mangaDetails
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .cornerRadius(12)
        .shadow(radius: 2)
    }

    @ViewBuilder
    private var mangaDetails: some View {
        VStack(alignment: .leading, spacing: 4) {
            ViewThatFits {
                // Pantallas grandes: 1 línea truncada
                Text(manga.title)
                    .font(.title3.bold())
                    .lineLimit(1)
                    .truncationMode(.tail)
                    .frame(maxWidth: .infinity, alignment: .leading)

                // Pantallas chicas: hasta 2 líneas
                Text(manga.title)
                    .font(.title3.bold())
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }

            if let score = manga.score {
                Text("⭐️ \(String(format: "%.1f", score))")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }

            if let status = manga.status {
                Text(status.replacingOccurrences(of: "_", with: " ").capitalized)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if let startDate = manga.startDate {
                let year = Calendar.current.component(.year, from: startDate)
                Text("📅 \(year)")
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }

            if !manga.genres.isEmpty {
                HStack(spacing: 4) {
                    ForEach(manga.genres.prefix(2), id: \.id) { genre in
                        Text(genre.genre)
                            .font(.caption2)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.accentColor.opacity(0.1))
                            .cornerRadius(4)
                    }
                }
            }
        }
    }

    private func coverImage(from url: URL?) -> some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .empty:
                Color.gray
            case .success(let img):
                img.resizable().scaledToFill()
            case .failure:
                Color.red
            @unknown default:
                EmptyView()
            }
        }
        .frame(width: 80, height: 120)
        .clipped()
        .cornerRadius(8)
        .shadow(radius: 2)
        .accessibilityLabel(Text("Portada de \(manga.title)"))
    }
}

