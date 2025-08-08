import SwiftUI

struct AudioVisualizerView: View {
    @Binding var isSpeaking: Bool
    @State private var barHeights: [CGFloat] = [10, 10, 10]
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3, id: \.self) { i in
                Rectangle()
                    .frame(width: 8, height: barHeights[i])
                    .animation(.easeInOut(duration: 0.2), value: barHeights)
            }
        }
        .foregroundColor(.blue)
        .onChange(of: isSpeaking) {
            if isSpeaking { startAnimating() } else { stopAnimating() }
        }
        .onDisappear { stopAnimating() }
    }

    private func startAnimating() {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.2, repeats: true) { _ in
            barHeights = [CGFloat.random(in: 10...50), CGFloat.random(in: 10...50), CGFloat.random(in: 10...50)]
        }
    }

    private func stopAnimating() {
        timer?.invalidate()
        timer = nil
        barHeights = [10, 10, 10]
    }
}


