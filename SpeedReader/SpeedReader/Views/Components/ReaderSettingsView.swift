import SwiftUI

struct ReaderSettingsView: View {
    var engine: ReadingEngine
    @Environment(\.dismiss) private var dismiss
    @State private var transitionEnabled: Bool = false
    @State private var staggerDelay: Double = 0.01
    @State private var sentencePauseEnabled: Bool = true
    @State private var scaleEnabled: Bool = false
    @State private var scaleAmount: Double = 1.1

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Toggle("SENTENCE PAUSE", isOn: $sentencePauseEnabled)
                        .font(.custom("SourceCodePro-Regular", size: 15))
                        .onChange(of: sentencePauseEnabled) {
                            engine.updateSentencePause(sentencePauseEnabled)
                        }
                } footer: {
                    Text("PAUSE FOR DOUBLE THE TIME AFTER SENTENCES ENDING IN . ! OR ?")
                        .font(.custom("SourceCodePro-Regular", size: 10))
                }

                Section {
                    Toggle("LETTER ANIMATION", isOn: $transitionEnabled)
                        .font(.custom("SourceCodePro-Regular", size: 15))
                        .onChange(of: transitionEnabled) {
                            engine.updateTransition(transitionEnabled ? staggerDelay : 0)
                        }

                    if transitionEnabled {
                        VStack(spacing: 4) {
                            HStack {
                                Text("SUBTLE")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                                Slider(value: $staggerDelay, in: 0.005...0.04, step: 0.005)
                                    .tint(.blue)
                                    .onChange(of: staggerDelay) {
                                        engine.updateTransition(staggerDelay)
                                    }
                                Text("DRAMATIC")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Spacer()
                                Text("\(Int(staggerDelay * 1000))MS/LETTER")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                } footer: {
                    Text("EACH LETTER SLIDES IN WITH A STAGGER OFFSET. HIGHER VALUES CREATE A CASCADING REVEAL EFFECT.")
                        .font(.custom("SourceCodePro-Regular", size: 10))
                }

                Section {
                    Toggle("SCALE", isOn: $scaleEnabled)
                        .font(.custom("SourceCodePro-Regular", size: 15))
                        .onChange(of: scaleEnabled) {
                            engine.updateScaleAmount(scaleEnabled ? scaleAmount : 0)
                        }

                    if scaleEnabled {
                        VStack(spacing: 4) {
                            HStack {
                                Text("1X")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                                Slider(value: $scaleAmount, in: 1.0...1.5, step: 0.05)
                                    .tint(.blue)
                                    .onChange(of: scaleAmount) {
                                        engine.updateScaleAmount(scaleAmount)
                                    }
                                Text("1.5X")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                            }
                            HStack {
                                Spacer()
                                Text("\(String(format: "%.2f", scaleAmount))X")
                                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                                    .foregroundStyle(.secondary)
                                    .monospacedDigit()
                            }
                        }
                    }
                } footer: {
                    Text("SCALE THE WORD UP FROM CENTRE FOR EASIER FOCUS.")
                        .font(.custom("SourceCodePro-Regular", size: 10))
                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("DONE") { dismiss() }
                        .font(.custom("SourceCodePro-SemiBold", size: 15))
                }
            }
        }
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
        .onAppear {
            transitionEnabled = engine.transitionDuration > 0
            staggerDelay = engine.transitionDuration > 0 ? engine.transitionDuration : 0.01
            sentencePauseEnabled = engine.sentencePauseEnabled
            scaleEnabled = engine.scaleAmount > 0
            scaleAmount = engine.scaleAmount > 0 ? engine.scaleAmount : 1.1
        }
    }
}

#Preview {
    ReaderSettingsView(engine: ReadingEngine())
        .preferredColorScheme(.dark)
}
