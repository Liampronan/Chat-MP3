import AVFoundation
import Foundation
import MediaPlayer

enum RepeatMode {
    case off
    case playlist
    case track
    
    mutating func toggleNext() {
        self = switch self {
        case .off: .playlist
        case .playlist: .track
        case .track: .off
        }
    }
    
    var canRepeat: Bool {
        self == .playlist || self == .track
    }
}

enum LoadableDataState<T> {
    case idle
    case loading(T)
    case loaded(T)
    case error(Error)
}

typealias PlayerState = LoadableDataState<Track>

protocol AudioPlayerControlling {
    var playerState: PlayerState { get }
    var isPlaying: Bool { get }
    func play(track: Track?)
    func pause()
    func togglePlayPause()
    func skipNext()
    func skipPrev()
}

@Observable
@MainActor
class AudioPlayerManager {
    private(set) var playerState: PlayerState = .idle
    var isPlaying = false
    var currentTrackTime: TimeInterval = 0
    var currentTrackProgress: Double {
        get {
            guard let currentTrack else { return 0.0 }
            return Double(currentTrackTime) / Double(currentTrack.duration)
        }
        set {
            guard let currentTrack else { return }
            let newTime = newValue * currentTrack.duration
            seek(to: newTime)
        }
    }
    var currentTrackDownloadProgress = 0.0
    
    var currentTrackIndex: Int = 0
    var currentRepeatMode = RepeatMode.off
    
    var isLoaded: Bool {
        if case .loaded = playerState {
            return true
        }
        return false
    }
    var playlist: Playlist
    var currentTrack: Track? {
        switch playerState {
        case .loading(let track), .loaded(let track):
            return track
        case .idle, .error:
            return nil
        }
    }
    
    private var isScrubbing = false
    private var player: AVPlayer?
    private var timeObserver: Any?
    
    init(playlist: Playlist = Playlist.mock) {
        self.playlist = playlist
        self.currentTrackIndex = 0
        setupAudioSession()
        setupRemoteCommands()
    }
    
    func startPlaying() {
        guard let firstTrack = playlist.tracks.first else { return }
        
        play(track: firstTrack)
        togglePlayPause()
    }
    enum TestError: Error {
        case network
    }
    func play(track: Track? = nil, startPlayback: Bool = true) {
        if let track = track {
            playerState = .loading(track)
            cleanUpTimeObserver()
            let playerItem = AVPlayerItem(url: track.audioURL)
            player = AVPlayer(playerItem: playerItem)
            setupTimeObserver()
            resetDownloadProgress()
            Task {
                do {
                    let _ = try await playerItem.asset.load(.duration)
                    playerState = .loaded(track)
                    simulateDownloadProgress()
                } catch {
                    playerState = .error(error)
                }
            }
        }
        
        if startPlayback {
            player?.play()
            isPlaying = true
        } else {
            player?.pause()
            isPlaying = false
        }
        
        updateNowPlayingInfo()
    }
    
    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }
    
    func togglePlayPause() {
        if isPlaying {
            pause()
        } else if player?.currentItem != nil {
            play()
        } else {
            if let track = currentTrack ?? playlist.tracks.safeIndexLookup(i: currentTrackIndex) {
                play(track: track)
            }
        }
    }
    
    func seek(to time: TimeInterval) {
        let cmTime = CMTime(seconds: time, preferredTimescale: 600)
        let tolerance = isScrubbing ? CMTime(seconds: 0.3, preferredTimescale: 600) : .zero
        
        player?.seek(to: cmTime, toleranceBefore: tolerance, toleranceAfter: tolerance)
        currentTrackTime = time
        updateNowPlayingInfo()
    }
    
    var canSkipNext: Bool {
        currentTrackIndex < playlist.tracks.count - 1 || currentRepeatMode.canRepeat
    }
    
    var canSkipPrevious: Bool {
        currentTrackIndex > 0
    }
    
    func skipNext() {
        guard canSkipNext else { return }
        
        let shouldContinuePlaying = isPlaying
        
        if currentTrackIndex < playlist.tracks.count - 1 {
            currentTrackIndex += 1
        } else if currentRepeatMode == .playlist {
            currentTrackIndex = 0
        }
        
        if let track = playlist.tracks.safeIndexLookup(i: currentTrackIndex) {
            play(track: track, startPlayback: shouldContinuePlaying)
        }
    }

    func skipPrev() {
        if currentTrackTime > 3.0 {
            seek(to: 0)
        } else if canSkipPrevious {
            let shouldContinuePlaying = isPlaying
            
            resetDownloadProgress()
            currentTrackIndex -= 1
            
            if let track = playlist.tracks.safeIndexLookup(i: currentTrackIndex) {
                play(track: track, startPlayback: shouldContinuePlaying)
            }
        }
    }
    
    func toggleLike() {
        guard currentTrackIndex < playlist.tracks.count else { return }
        playlist.tracks[currentTrackIndex].isLiked.toggle()
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        playerState = .loaded(playlist.tracks[currentTrackIndex])
    }
    
    func toggleRepeat() {
        currentRepeatMode.toggleNext()
    }
    private func cleanUpTimeObserver() {
        if let timeObserver, let player {
            player.removeTimeObserver(timeObserver)
            self.timeObserver = nil
        }
    }
    
    private func setupTimeObserver() {
        let interval = CMTime(seconds: 0.1, preferredTimescale: 600)
        
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            Task { @MainActor [weak self] in
                guard let self, !isScrubbing else { return }
                self.currentTrackTime = time.seconds
            }
        }
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, mode: .default)
            try session.setActive(true)
        } catch {
            print("Failed to setup audio session: \(error)")
        }
    }
    
    
    private func resetDownloadProgress() {
        currentSimulateDownloadTask?.cancel()
        currentTrackDownloadProgress = 0.0
        currentTrackTime = 0.0
    }
    private var currentSimulateDownloadTask: Task<Void, Never>?
    private func simulateDownloadProgress() {
        resetDownloadProgress()
        
        currentSimulateDownloadTask = Task {
            var progress = 0.0
            
            while progress < 1.0 {
                let randomDelay = Double.random(in: 0.1...0.4)
                try? await Task.sleep(nanoseconds: UInt64(randomDelay * 1_000_000_000))
                guard !Task.isCancelled else { break }
                let randomChunk = Double.random(in: 0.02...0.08)
                progress += randomChunk
                currentTrackDownloadProgress = min(progress, 1.0)
            }
        }
    }
}

// MARK: handling Now Playing View commands and display
extension AudioPlayerManager {
    private func setupRemoteCommands() {
        let commandCenter = MPRemoteCommandCenter.shared()
        
        commandCenter.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        
        commandCenter.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        
        commandCenter.nextTrackCommand.addTarget { [weak self] _ in
            self?.skipNext()
            return .success
        }
        
        commandCenter.previousTrackCommand.addTarget { [weak self] _ in
            self?.skipPrev()
            return .success
        }
        
        commandCenter.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let event = event as? MPChangePlaybackPositionCommandEvent else {
                return .commandFailed
            }
            self?.seek(to: event.positionTime)
            return .success
        }
    }
    
    private func updateNowPlayingInfo() {
        guard let track = currentTrack else { return }
        
        var nowPlayingInfo = [String: Any]()
        nowPlayingInfo[MPMediaItemPropertyTitle] = track.title
        nowPlayingInfo[MPMediaItemPropertyArtist] = track.artist
        nowPlayingInfo[MPMediaItemPropertyPlaybackDuration] = track.duration
        nowPlayingInfo[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTrackTime
        nowPlayingInfo[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0
        
        guard let albumArtURL = track.albumArtURL else {
            MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            return
        }
        
        setNowPlayingWithAlbumArt(track: track, albumArtURL: albumArtURL, nowPlayingInfo: nowPlayingInfo)
    }
    
    private func setNowPlayingWithAlbumArt(track: Track, albumArtURL: URL, nowPlayingInfo: [String: Any]) {
        var nowPlayingInfo = nowPlayingInfo
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: albumArtURL)
                guard let image = UIImage(data: data) else { return }
                
                nowPlayingInfo[MPMediaItemPropertyArtwork] = MPMediaItemArtwork(
                    boundsSize: image.size,
                    requestHandler: { _ in image }
                )
                
                guard let existingTitle = nowPlayingInfo[MPMediaItemPropertyTitle] as? String,
                      existingTitle == track.title else { return }
                
                MPNowPlayingInfoCenter.default().nowPlayingInfo = nowPlayingInfo
            } catch {
                print("Failed to load album art: \(error)")
            }
        }
    }
}
