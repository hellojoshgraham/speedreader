import SwiftUI

struct TransportControls: View {
    var engine: ReadingEngine

    var body: some View {
        HStack(spacing: 40) {
            Button {
                engine.back30()
            } label: {
                Image(systemName: "gobackward.30")
                    .font(.title2)
                    .foregroundStyle(.white)
            }

            Button {
                engine.toggle()
            } label: {
                Image(systemName: engine.isPlaying ? "pause.fill" : "play.fill")
                    .font(.system(size: 36))
                    .foregroundStyle(.white)
                    .frame(width: 64, height: 64)
            }

            // Spacer to balance the layout
            Color.clear
                .frame(width: 28, height: 28)
        }
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        TransportControls(engine: ReadingEngine())
    }
}
