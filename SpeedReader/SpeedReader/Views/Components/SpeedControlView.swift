import SwiftUI

struct SpeedControlView: View {
    var engine: ReadingEngine
    @State private var sliderValue: Double = 300

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Speed")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(sliderValue)) WPM")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }

            Slider(value: $sliderValue, in: 100...800, step: 25) { editing in
                if !editing {
                    engine.updateSpeed(Int(sliderValue))
                }
            }
            .tint(.blue)
            .onChange(of: sliderValue) {
                engine.updateSpeed(Int(sliderValue))
            }
        }
        .onAppear {
            sliderValue = Double(engine.wordsPerMinute)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        SpeedControlView(engine: ReadingEngine())
            .padding()
    }
}
