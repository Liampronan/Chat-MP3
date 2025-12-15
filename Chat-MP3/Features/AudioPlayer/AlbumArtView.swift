import Observation
import SwiftUI

struct AlbumArtView: View {
    let url: URL?
    let size: CGFloat
    
    var body: some View {
        AsyncImage(url: url) { phase in
            switch phase {
            case .success(let image):
                image
                    .resizable()
                    .aspectRatio(contentMode: .fill)
            case .failure, .empty:
                placeholderView
            @unknown default:
                placeholderView
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: PlayerDesign.CornerRadius.small))
        .accessibilityHidden(true)
        .id(url)
    }
    
    private var placeholderView: some View {
        Rectangle()
            .fill(.playerBarUnfilled.opacity(0.2))
            .overlay {
                Image(systemName: "music.note")
                    .font(.system(size: size * 0.4))
                    .foregroundStyle(.white)
            }
    }
}
