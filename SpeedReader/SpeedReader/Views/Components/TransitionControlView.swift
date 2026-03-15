import SwiftUI

struct TransitionControlView: View {
    var engine: ReadingEngine
    @State private var isEnabled: Bool = true
    @State private var sliderValue: Double = 0.05

    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text("Transition")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("", isOn: $isEnabled)
                    .labelsHidden()
                    .scaleEffect(0.7)
                    .onChange(of: isEnabled) {
                        if isEnabled {
                            engine.updateTransition(sliderValue)
                        } else {
                            engine.updateTransition(0)
                        }
                    }
            }

            if isEnabled {
                HStack {
                    Text("Fast")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Slider(value: $sliderValue, in: 0.01...0.15, step: 0.01)
                        .tint(.blue)
                        .onChange(of: sliderValue) {
                            engine.updateTransition(sliderValue)
                        }
                    Text("Slow")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                HStack {
                    Spacer()
                    Text("\(Int(sliderValue * 1000))ms")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .monospacedDigit()
                }
            }
        }
        .onAppear {
            let duration = engine.transitionDuration
            isEnabled = duration > 0
            sliderValue = duration > 0 ? duration : 0.05
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TransitionControlView(engine: ReadingEngine())
            .padding()
    }
}
