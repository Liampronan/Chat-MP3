import SwiftUI

struct TimelineScrubberView: View {
    @Binding var currentValue: Double
    var bufferValue: Double
    var duration: TimeInterval
    
    let trackHeight: CGFloat = PlayerDesign.Sizes.progressHeight
    let scrobblerCircleSize: CGFloat = PlayerDesign.Sizes.scrobblerCircleSize
    let activeColor: Color = .white
    let bufferColor: Color = .white.opacity(0.2)
    let trackColor: Color = .white.opacity(0.2)
    
    @State private var isDragging = false
    @State private var localDragValue: Double = 0
    
    var body: some View {
        VStack(spacing: 4) {
            scrubberBar
            timeDisplay
        }
    }
    
    private var scrubberBar: some View {
        GeometryReader { geo in
            ScrubberTrackView(
                width: geo.size.width,
                displayValue: displayValue,
                bufferValue: bufferValue,
                trackHeight: trackHeight,
                scrobblerCircleSize: scrobblerCircleSize,
                activeColor: activeColor,
                bufferColor: bufferColor,
                trackColor: trackColor,
                isDragging: isDragging
            )
            .contentShape(Rectangle())
            .gesture(dragGesture(width: geo.size.width))
            .accessibilityLabel("Track Position")
            .accessibilityValue(
                Text("\(Int(currentValue * duration) / 60) minutes \(Int(currentValue * duration) % 60) seconds")
            )
            .accessibilityAdjustableAction { direction in
                switch direction {
                case .increment:
                    let increase = 10.0 / duration
                    currentValue = min(currentValue + increase, 1.0)
                case .decrement:
                    let decrease = 10.0 / duration
                    currentValue = max(currentValue - decrease, 0.0)
                @unknown default: break
                }
            }
            .accessibilityAction(.default) {
                // Do nothing - since we have custom incremenet/decrement we don't want to offer the default "activate" action.
            }
        }
        .frame(height: scrobblerCircleSize)
    }
    
    private var timeDisplay: some View {
        TimeDisplayView(
            currentTime: displayValue * duration,
            totalTime: duration
        )
    }
    
    private var displayValue: Double {
        isDragging ? localDragValue : currentValue
    }
    
    private func dragGesture(width: CGFloat) -> some Gesture {
        DragGesture(minimumDistance: 0)
            .onChanged { gesture in
                if !isDragging {
                    isDragging = true
                    localDragValue = currentValue
                }
                
                let progress = gesture.location.x / width
                let clamped = min(max(progress, 0), 1)
                
                localDragValue = clamped
                currentValue = clamped
            }
            .onEnded { _ in
                isDragging = false
            }
    }
}

struct ScrubberTrackView: View {
    let width: CGFloat
    let displayValue: Double
    let bufferValue: Double
    let trackHeight: CGFloat
    let scrobblerCircleSize: CGFloat
    let activeColor: Color
    let bufferColor: Color
    let trackColor: Color
    let isDragging: Bool
    
    var body: some View {
        ZStack(alignment: .leading) {
            baseTrack
            bufferedTrack
            activeTrack
            scrobblerCircle
        }
    }
    
    private var scrobblerCirclePosition: CGFloat {
        let radius = scrobblerCircleSize / 2
        let usableWidth = width - scrobblerCircleSize
        return radius + (displayValue * usableWidth)
    }
    
    private var bufferWidth: CGFloat {
        width * bufferValue
    }
    
    private var baseTrack: some View {
        Capsule()
            .fill(trackColor)
            .frame(height: trackHeight)
            .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var bufferedTrack: some View {
       Rectangle()
            .fill(bufferColor)
            .frame(width: min(bufferWidth, width), height: trackHeight)
            .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var activeTrack: some View {
        Rectangle()
            .fill(activeColor)
            .frame(width: scrobblerCirclePosition, height: trackHeight)
            .frame(maxHeight: .infinity, alignment: .center)
    }
    
    private var scrobblerCircle: some View {
        Circle()
            .fill(activeColor)
            .frame(width: scrobblerCircleSize, height: scrobblerCircleSize)
            .position(x: scrobblerCirclePosition, y: scrobblerCircleSize / 2)
            .shadow(radius: isDragging ? 4 : 0)
    }
}


struct TimeDisplayView: View {
    let currentTime: TimeInterval
    let totalTime: TimeInterval
    
    var body: some View {
        HStack {
            Text(formatTime(currentTime))
            Spacer()
            Text(formatTime(totalTime))
        }
        .font(PlayerDesign.Typography.timestamp)
        .foregroundStyle(.playerBarFilled)
        .monospacedDigit()
    }
}

fileprivate func formatTime(_ time: TimeInterval) -> String {
    let seconds = Int(time)
    let minutes = seconds / 60
    let remainingSeconds = seconds % 60
    return String(format: "%d:%02d", minutes, remainingSeconds)
}
