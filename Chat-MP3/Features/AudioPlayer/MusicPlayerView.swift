import Observation
import SwiftUI

enum PlayerDesign {
    enum Spacing {
        static let xs: CGFloat = 8
        static let sm: CGFloat = 16
        static let md: CGFloat = 24
        static let lg: CGFloat = 36
        static let xl: CGFloat = 72
    }
    
    enum Sizes {
        static let albumArtCompact: CGFloat = 72
        static let controlButtonSmall: CGFloat = 36
        static let controlButtonLarge: CGFloat = 60
        static let progressHeight: CGFloat = 2
        static let minTouchTarget: CGFloat = 44
        static let scrobblerCircleSize: CGFloat = 10
    }
    
    enum Typography {
        static let trackTitle: Font = .custom("Google Sans", size: 18).weight(.medium)
        static let artistName: Font = .custom("Google Sans", size: 15)
        static let timestamp: Font = .custom("Google Sans", size: 11)
    }
    
    enum CornerRadius {
        static let small: CGFloat = 4
        static let medium: CGFloat = 12
        static let large: CGFloat = 20
    }
}

struct MusicPlayerView: View {
    @Environment(AudioPlayerManager.self) private var audioPlayerManager
    
    var body: some View {
        @Bindable var bindableAudioPlayerManager = audioPlayerManager
        
        VStack(spacing: PlayerDesign.Spacing.sm) {
            switch audioPlayerManager.playerState {
            case .idle:
                emptyStateView
            case .loading(let track), .loaded(let track):
                trackInformationView(for: track)
                
                let isLoaded = audioPlayerManager.isLoaded
                
                TimelineScrubberView(
                    currentValue: isLoaded
                    ? $bindableAudioPlayerManager.currentTrackProgress
                    : .constant(0.0),
                    bufferValue: audioPlayerManager.currentTrackDownloadProgress,
                    duration: track.duration
                )
                
                trackControlButtons(for: track, isLoading: !isLoaded)
                    .padding(.bottom, PlayerDesign.Spacing.sm)

            case .error(let error):
                errorView(error: error)
            }
        }
        .task {
            audioPlayerManager.startPlaying()
        }
        .padding(PlayerDesign.Spacing.sm)
        .background {
            RoundedRectangle(cornerRadius: PlayerDesign.CornerRadius.medium)
                .fill(.playerBackground)
                .shadow(color: .black.opacity(0.1), radius: 8, y: 4)
        }
        .contentShape(Rectangle())
        
    }
    
    private func trackInformationView(for track: Track) -> some View {
        HStack(spacing: PlayerDesign.Spacing.sm) {
            AlbumArtView(
                url: track.albumArtURL,
                size: PlayerDesign.Sizes.albumArtCompact
            )
            
            VStack(alignment: .leading, spacing: PlayerDesign.Spacing.xs) {
                TrackTitleView(text: track.title)
                
                Text(track.artist)
                    .font(PlayerDesign.Typography.artistName)
                    .foregroundStyle(.playerSubtext)
                    .lineLimit(1)
            }
            Spacer()
        }
    }
    
    private var emptyStateView: some View {
        Text("No track loaded")
            .foregroundStyle(.playerSubtext)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlayerDesign.Spacing.lg)
    }
    
    private var loadingView: some View {
        ProgressView()
            .tint(.playerPrimaryText)
            .frame(maxWidth: .infinity)
            .padding(.vertical, PlayerDesign.Spacing.lg)
    }
    
    private func errorView(error: Error) -> some View {
        VStack(spacing: PlayerDesign.Spacing.xs) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 24))
                .foregroundStyle(.red)
            Text("Failed to load track")
                .foregroundStyle(.white.opacity(0.7))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, PlayerDesign.Spacing.lg)
    }
    
    private func trackControlButtons(for track: Track, isLoading: Bool) -> some View {
        HStack(spacing: PlayerDesign.Spacing.sm) {
            ControlButton(
                systemImage: imageName(for: audioPlayerManager.currentRepeatMode),
                size: PlayerDesign.Sizes.controlButtonSmall,
                colorPair: colorPair(for: audioPlayerManager.currentRepeatMode),
                isEnabled: !isLoading
            ) {
                audioPlayerManager.toggleRepeat()
            }
            .accessibilityLabel(repeatAccessibilityLabel)
            
            ControlButton(
                imageName: "skip_previous",
                size: PlayerDesign.Sizes.controlButtonSmall,
                isEnabled: !isLoading && audioPlayerManager.canSkipPrevious,
                symbolEffect: .replaceDownUp,
                action: audioPlayerManager.skipPrev
            )
            .accessibilityLabel("Previous track")
            
            if isLoading {
                ProgressView()
                    .tint(.white)
                    .frame(width: PlayerDesign.Sizes.controlButtonLarge, height: PlayerDesign.Sizes.controlButtonLarge)
            } else {
                ControlButton(
                    systemImage: audioPlayerManager.isPlaying ? "pause.circle.fill" : "play.circle.fill",
                    size: PlayerDesign.Sizes.controlButtonLarge,
                    colorPair: (.white, .playerSelected),
                    symbolEffect: .replaceByLayer,
                    action: {
                        withAnimation {
                            audioPlayerManager.togglePlayPause()
                        }
                    }
                )
                .accessibilityLabel(audioPlayerManager.isPlaying ? "Pause" : "Play")
                .accessibilityHint("Double tap to \(audioPlayerManager.isPlaying ? "pause" : "play") \(track.title)")
            }
            
            ControlButton(
                imageName: "skip_next",
                size: PlayerDesign.Sizes.controlButtonSmall,
                isEnabled: !isLoading && audioPlayerManager.canSkipNext,
                action: audioPlayerManager.skipNext
            )
            .accessibilityLabel("Next track")
            
            ControlButton(
                systemImage: track.isLiked ? "heart.fill" : "heart",
                size: PlayerDesign.Sizes.controlButtonSmall,
                colorPair: (track.isLiked ? .red : .white, nil),
                isEnabled: !isLoading,
                symbolEffect: .replaceDownUp
            ) {
                withAnimation {
                    audioPlayerManager.toggleLike()
                }
            }
            .id(track.title)
            .accessibilityLabel(track.isLiked ? "Unlike" : "Like")
        }
    }
    private func colorPair(for repeatMode: RepeatMode) -> (Color, Color) {
        switch repeatMode {
        case .off: (.white, .clear)
        case .playlist: (.playerSelected, .clear)
        case .track: (.white, .playerSelected)
                
        }
    }
    
    private var repeatAccessibilityLabel: String {
        switch audioPlayerManager.currentRepeatMode {
        case .off: return "Repeat Off"
        case .playlist: return "Repeat All"
        case .track: return "Repeat One"
        }
    }
    
    private func imageName(for repeatMode: RepeatMode) -> String {
        switch repeatMode {
        case .off, .playlist: "repeat"
        case .track: "repeat.1"
        }
    }
}

struct ControlButton: View {
    enum SymbolEffect {
        case replaceDownUp
        case replaceByLayer
    }
    let systemImage: String?
    let imageName: String?
    let size: CGFloat
    let colorPair: (Color, Color?)
    let isEnabled: Bool
    let symbolEffect: SymbolEffect?
    let action: () -> Void
    
    init(
        systemImage: String? = nil,
        imageName: String? = nil,
        size: CGFloat,
        colorPair: (Color, Color?) = (.white, nil),
        isEnabled: Bool = true,
        symbolEffect: SymbolEffect? = nil,
        action: @escaping () -> Void
    ) {
        self.systemImage = systemImage
        self.imageName = imageName
        self.size = size
        self.isEnabled = isEnabled
        self.colorPair = colorPair
        self.symbolEffect = symbolEffect
        self.action = action
    }
    
    var body: some View {
        Button(action: action) {
            Group {
                if let systemImage {
                    Image(systemName: systemImage)
                        .font(.system(size: iconSize))
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(colorPair.0, colorPair.1 ?? .clear)
                        .if(symbolEffect != nil && symbolEffect == .replaceDownUp) { view in
                            view.contentTransition(.symbolEffect(.replace.downUp, options: .speed(1.5)))
                        }
                        .if(symbolEffect != nil && symbolEffect == .replaceByLayer) { view in
                            view.contentTransition(.symbolEffect(.replace.byLayer, options: .speed(1.5)))
                        }
                } else if let imageName {
                    Image(imageName)
                        .resizable()
                        .frame(width: size, height: size)
                        .foregroundStyle(.white, .playerSelected)
                }
            }
            .frame(width: size, height: size)
            .contentShape(Circle().inset(by: -8))
        }
        .buttonStyle(.plain)
        .disabled(!isEnabled)
        .opacity(isEnabled ? 1 : 0.5)
    }
    
    private var iconSize: CGFloat {
        size == PlayerDesign.Sizes.controlButtonLarge ? size : size / 2
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        MusicPlayerView()
            .environment(AudioPlayerManager())
    }
}
