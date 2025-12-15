import Foundation

struct Playlist: Identifiable, Codable {
    let id: UUID
    let title: String
    var tracks: [Track]
    
    nonisolated(unsafe) static var mock: Self {
        .init(
            id: UUID(),
            title: "Friday jams",
            tracks: [Track.mock1, Track.mock2, Track.mock3, Track.mock4]
        )
    }
}
