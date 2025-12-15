
import SwiftUI

@main
struct Chat_MP3App: App {
    private var audioPlayerManager = AudioPlayerManager()
    
    var body: some Scene {
        WindowGroup {
            ChatView()
                .environment(audioPlayerManager)
        }
    }
}
