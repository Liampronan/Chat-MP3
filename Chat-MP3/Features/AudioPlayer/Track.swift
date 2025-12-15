import Foundation

struct Track: Identifiable, Codable, Hashable {

    let id: UUID
    let title: String
    let artist: String
    let albumArtURL: URL?
    let audioURL: URL
    let duration: TimeInterval
    var isLiked: Bool = false
    
    nonisolated init(id: UUID = UUID(), title: String, artist: String, albumArtURL: URL?, audioURL: URL, duration: TimeInterval, isLiked: Bool = false) {
        self.id = id
        self.title = title
        self.artist = artist
        self.albumArtURL = albumArtURL
        self.audioURL = audioURL
        self.duration = duration
        self.isLiked = isLiked
    }
    
    nonisolated(unsafe) static var mock1: Self {
        .init(title: "Black Friday (pretty like the sun)",
              artist: "Lost Frequencies, Tom Odell, Poppy Baskcomb",
              albumArtURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/1/1f/Washed_Out_-_Purple_Noon.png"),
              audioURL: URL(string: "https://s3.us-west-2.amazonaws.com/liam.party/BlackFriday.mp3")!,
              duration: 155
        )
    }
    
    nonisolated(unsafe) static var mock2: Self {
        .init(title: "Friday",
              artist: "Riton, Nightcrawlers",
              albumArtURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/8/86/Riton_-_Friday.png"),
              audioURL: URL(string: "https://s3.us-west-2.amazonaws.com/liam.party/Riton+x+Nightcrawlers+-+Friday+ft.+Mufasa+%26+Hypeman+(Dopamine+Re-Edit)+%5BLyric+Video%5D.mp3")!,
              duration: 168
        )
    }
    
    nonisolated(unsafe) static var mock3: Self {
        .init(title: "Friday I'm in Love",
              artist: "The Cure",
              albumArtURL: URL(string: "https://upload.wikimedia.org/wikipedia/en/7/73/Fridayimin_cov.jpg"),
              audioURL: URL(string: "https://s3.us-west-2.amazonaws.com/liam.party/The+Cure+-+Friday+I'm+In+Love.mp3")!,
              duration: 214
        )
    }
    
    nonisolated(unsafe) static var mock4: Self {
        .init(title: "Friday",
              artist: "Rebecca Black",
              albumArtURL: nil,
              audioURL: URL(string: "https://s3.us-west-2.amazonaws.com/liam.party/Rebecca+Black+-+Friday.mp3")!,
              duration: 227
        )
    }
    
}

