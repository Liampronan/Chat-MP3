import SwiftUI

struct MarqueeText: View {
    let text: String
    let font: Font
    
    @State private var textWidth: CGFloat = 0
    @State private var containerWidth: CGFloat = 0
    @State private var offset: CGFloat = 0
    
    private let animationDuration: Double = 6.0
    private let delay: Double = 2.0
    
    var body: some View {
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            
            ZStack(alignment: .leading) {
                Text(text)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .background(
                        GeometryReader { textGeo in
                            Color.clear
                                .onAppear {
                                    textWidth = textGeo.size.width
                                    containerWidth = availableWidth
                                }
                                .onChange(of: availableWidth) {
                                    containerWidth = availableWidth
                                }
                                .onChange(of: textGeo.size.width) {
                                    textWidth = textGeo.size.width
                                }
                        }
                    )
                    .offset(x: offset)
            }
            .frame(width: availableWidth, alignment: .leading)
            .clipped()
            .mask(
                HStack(spacing: 0) {
                    LinearGradient(gradient: Gradient(colors: [.clear, .black]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 20)
                    
                    Rectangle().fill(Color.black)
                    
                    LinearGradient(gradient: Gradient(colors: [.black, .clear]), startPoint: .leading, endPoint: .trailing)
                        .frame(width: 20)
                }
            )
            .onAppear {
                startAnimation()
            }
            .onChange(of: text) {
                offset = 0 // Reset
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    startAnimation()
                }
            }
        }
        .frame(height: 30)
    }
    
    private func startAnimation() {
        let scrollDistance = textWidth - containerWidth
        
        guard scrollDistance > 0 else {
            withAnimation { offset = 0 }
            return
        }
        
        offset = 0
        
        withAnimation(
            Animation
                .linear(duration: animationDuration)
                .delay(delay)
                .repeatForever(autoreverses: true)
        ) {
            offset = -scrollDistance
        }
    }
}

struct TrackTitleView: View {
    let text: String
    let isEnabled = false
    
    var body: some View {
        Group {
            if isEnabled {
                MarqueeText(
                    text: text,
                    font: PlayerDesign.Typography.trackTitle
                    
                )
            } else {
                Text(text)
                    .lineLimit(1)
                    .font(PlayerDesign.Typography.trackTitle)
            }
        }
        .foregroundStyle(.white)
    }
}
