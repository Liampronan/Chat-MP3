import SwiftUI
// note: the code in this file is a quick AI-generated protoype of a chatview.
// it's primarly used to show the AudioPlayer in a LLM-like chat context.
enum MessageSender {
    case user
    case assistant
}

struct ChatMessage: Identifiable {
    let id = UUID()
    let sender: MessageSender
    var text: String
    let showPlayer: Bool
    var isStreaming: Bool = false
}

@Observable
class ChatViewModel {
    var messages: [ChatMessage] = []
    var isTyping = false
    
    func sendMessage(_ text: String) {
        let userMessage = ChatMessage(sender: .user, text: text, showPlayer: false)
        messages.append(userMessage)
        
        Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            isTyping = true
            
            try? await Task.sleep(for: .milliseconds(1200))
            isTyping = false
            
            let responseText = "Let me find some great Friday vibes for you! Here's a perfect playlist to get your weekend started:"
            let streamingMessage = ChatMessage(sender: .assistant, text: "", showPlayer: false, isStreaming: true)
            messages.append(streamingMessage)
            
            for char in responseText {
                try? await Task.sleep(for: .milliseconds(20))
                if let index = messages.firstIndex(where: { $0.id == streamingMessage.id }) {
                    messages[index].text.append(char)
                }
            }
            
            if let index = messages.firstIndex(where: { $0.id == streamingMessage.id }) {
                messages[index].isStreaming = false
            }
            
            try? await Task.sleep(for: .milliseconds(400))
            
            let playerMessage = ChatMessage(sender: .assistant, text: "", showPlayer: true)
            messages.append(playerMessage)
        }
    }
}

struct ChatView: View {
    @State private var viewModel = ChatViewModel()
    @State private var audioPlayerManager = AudioPlayerManager()
    @State private var messageText = ""
    @FocusState private var isInputFocused: Bool
    private var shouldDisableMsgInputForDemo = true
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            ChatBubbleView(message: message)
                                .environment(audioPlayerManager)
                                .id(message.id)
                        }
                        
                        if viewModel.isTyping {
                            TypingIndicatorView()
                                .transition(.scale.combined(with: .opacity))
                                .id("typing")
                        }
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 12)
                }
                .onChange(of: viewModel.messages.count) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        if let lastMessage = viewModel.messages.last {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
                .onChange(of: viewModel.isTyping) { _, _ in
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("typing", anchor: .bottom)
                    }
                }
            }
            
            inputBar
        }
        .background(Color.black)
        .preferredColorScheme(.dark)
        .onAppear {
            viewModel.sendMessage("hey I need some Friday songs")
        }
    }
    
    private var inputBar: some View {
        HStack(spacing: 8) {
            TextField("Ask away", text: $messageText, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(Color(white: 0.15))
                .clipShape(RoundedRectangle(cornerRadius: 18))
                .focused($isInputFocused)
                // for demo purposes
                .disabled(shouldDisableMsgInputForDemo)
            
            Button(action: sendMessage) {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 28))
                    .foregroundStyle(messageText.isEmpty ? Color(white: 0.3) : Color.blue)
            }
            .disabled(messageText.isEmpty)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.black)
    }
    
    private func sendMessage() {
        guard !messageText.isEmpty else { return }
        let text = messageText
        messageText = ""
        viewModel.sendMessage(text)
    }
}

struct ChatBubbleView: View {
    let message: ChatMessage
    @Environment(AudioPlayerManager.self) private var audioPlayerManager
    @State private var hasAppeared = false
    
    var body: some View {
        VStack(alignment: message.sender == .user ? .trailing : .leading, spacing: 6) {
            if !message.text.isEmpty {
                HStack(alignment: .bottom, spacing: 0) {
                    if message.sender == .user { Spacer(minLength: 50) }
                    
                    Text(message.text)
                        .font(.system(size: 17))
                        .foregroundStyle(message.sender == .user ? .white : .white)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(
                            message.sender == .user
                                ? Color.blue
                                : Color(white: 0.15)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 18))
                        .frame(maxWidth: message.isStreaming ? .infinity : nil, alignment: message.sender == .user ? .trailing : .leading)
                        .fixedSize(horizontal: false, vertical: true)
                    
                    if message.sender == .assistant { Spacer(minLength: 50) }
                }
            }
            
            if message.showPlayer {
                MusicPlayerView()
                    .environment(audioPlayerManager)
                    .opacity(hasAppeared ? 1 : 0)
                    .offset(y: hasAppeared ? 0 : 10)
                    
                    .onAppear {
                        withAnimation(.easeOut(duration: 0.4).delay(0.3)) {
                            hasAppeared = true
                        }
                    }
            }
        }
    }
}

struct TypingIndicatorView: View {
    @State private var animationPhase = 0
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            HStack(spacing: 6) {
                ForEach(0..<3) { index in
                    Circle()
                        .fill(Color.gray.opacity(0.7))
                        .frame(width: 8, height: 8)
                        .scaleEffect(animationPhase == index ? 1.2 : 1.0)
                        .animation(
                            .easeInOut(duration: 0.6)
                            .repeatForever(autoreverses: true)
                            .delay(Double(index) * 0.2),
                            value: animationPhase
                        )
                }
            }
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
            .background(Color(white: 0.15))
            .clipShape(RoundedRectangle(cornerRadius: 18))
            .onAppear {
                animationPhase = 0
                withAnimation {
                    animationPhase = 1
                }
            }
            
            Spacer(minLength: 50)
        }
    }
}

#Preview {
    ChatView()
}
