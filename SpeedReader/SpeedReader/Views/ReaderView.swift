import SwiftUI

struct ReaderView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Bindable var book: Book
    @State private var engine = ReadingEngine()
    @State private var controlsVisible = true
    @State private var showingSettings = false
    @State private var showPageDot = false
    @State private var isDragging = false
    @State private var dragStartWPM: Int = 300
    @State private var infoTextWidth: CGFloat = 200

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            // Green page dot — top left
            VStack {
                HStack {
                    Circle()
                        .fill(.green)
                        .frame(width: 8, height: 8)
                        .padding(.leading, 16)
                        .padding(.top, 8)
                        .opacity(showPageDot ? 1 : 0)
                    Spacer()
                }
                Spacer()
            }

            // Main content
            VStack(spacing: 0) {
                if !controlsVisible {
                    Text(book.title.uppercased())
                        .font(.custom("SourceCodePro-Regular", size: 11.5))
                        .foregroundStyle(.white.opacity(0.3))
                        .lineLimit(1)
                        .padding(.top, 12)
                        .padding(.horizontal, 16)
                }

                Spacer()

                wordDisplay

                Spacer()

                miniProgress
                    .padding(.bottom, controlsVisible ? 0 : 20)

                if controlsVisible {
                    bottomBar
                }
            }
        }
        .navigationTitle(book.title.uppercased())
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.black, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar(controlsVisible ? .visible : .hidden, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showingSettings = true
                } label: {
                    Image(systemName: "gearshape")
                        .foregroundStyle(.white)
                }
            }
        }
        .sheet(isPresented: $showingSettings) {
            ReaderSettingsView(engine: engine)
        }
        .statusBarHidden(!controlsVisible)
        .onAppear {
            engine.load(book: book)
        }
        .onDisappear {
            engine.pause()
        }
        .onChange(of: scenePhase) { _, newPhase in
            if newPhase != .active {
                engine.pause()
            }
        }
        .onChange(of: engine.isNewPage) { _, isNew in
            if isNew {
                withAnimation(.easeIn(duration: 0.1)) {
                    showPageDot = true
                }
                withAnimation(.easeOut(duration: 1.0).delay(0.1)) {
                    showPageDot = false
                }
            }
        }
    }

    private var wordDisplay: some View {
        ZStack {
            // Giant ultrathin WPM while dragging
            Text("\(engine.wordsPerMinute)")
                .font(.system(size: 200, weight: .ultraLight, design: .rounded))
                .foregroundStyle(.white.opacity(isDragging ? 0.08 : 0))
                .monospacedDigit()
                .animation(.easeInOut(duration: 0.2), value: isDragging)
                .allowsHitTesting(false)

            Group {
                if engine.transitionDuration > 0 {
                    HStack(spacing: 0) {
                        ForEach(Array(engine.currentWord.enumerated()), id: \.offset) { index, char in
                            StaggeredCharacter(
                                character: char,
                                delay: Double(index) * engine.transitionDuration,
                                font: wordFont,
                                color: wordColor
                            )
                        }
                    }
                    .id(engine.wordIndex)
                } else {
                    Text(engine.currentWord)
                        .font(wordFont)
                        .foregroundStyle(wordColor)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 120)
            .modifier(ScaleGrow(
                enabled: engine.scaleAmount > 0,
                startScale: engine.scaleAmount > 0 ? (2.0 - engine.scaleAmount) : 1.0,
                wordIndex: engine.wordIndex,
                duration: 60.0 / Double(engine.wordsPerMinute) * Double(engine.currentWordTickCount)
            ))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .contentShape(Rectangle())
            .onTapGesture(count: 2) {
                withAnimation(.easeInOut(duration: 0.2)) {
                    controlsVisible.toggle()
                }
            }
            .onTapGesture(count: 1) {
                engine.toggle()
            }
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if !isDragging && abs(value.translation.height) > 5 {
                            isDragging = true
                            dragStartWPM = engine.wordsPerMinute
                        }
                        if isDragging {
                            let delta = Int(-value.translation.height / 4) * 5
                            let newWPM = min(800, max(100, dragStartWPM + delta))
                            engine.updateSpeed(newWPM)
                        }
                    }
                    .onEnded { _ in
                        isDragging = false
                    }
            )
    }

    private let infoFont: Font = .custom("SourceCodePro-Regular", size: 11.5)

    private var miniProgress: some View {
        VStack(spacing: 6) {
            HStack(spacing: 6) {
                Text("\(engine.wordsPerMinute) WPM")
                    .foregroundStyle(isDragging ? .white : .secondary)
                    .animation(.easeInOut(duration: 0.2), value: isDragging)
                Text("·")
                    .foregroundStyle(.tertiary)
                Text("\(Int(engine.progressPercentage))%")
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(engine.timeRemainingFormatted.uppercased())
                Text("·")
                    .foregroundStyle(.tertiary)
                Text(engine.finishTimeFormatted.uppercased())
            }
            .font(infoFont)
            .monospacedDigit()
            .textCase(.uppercase)
            .foregroundStyle(.secondary)
            .background(
                GeometryReader { geo in
                    Color.clear.preference(key: InfoTextWidthKey.self, value: geo.size.width)
                }
            )
            .onPreferenceChange(InfoTextWidthKey.self) { width in
                infoTextWidth = width
            }

            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.1))
                    .frame(height: 2)
                RoundedRectangle(cornerRadius: 1)
                    .fill(.white.opacity(0.3))
                    .frame(width: infoTextWidth * engine.progressPercentage / 100, height: 2)
            }
            .frame(width: infoTextWidth, height: 2)
        }
    }

    private var wordFont: Font {
        engine.isChapterHeading
            ? .system(size: 32, weight: .heavy, design: .default)
            : .system(size: 48, weight: .bold, design: .monospaced)
    }

    private var wordColor: Color {
        engine.isChapterHeading ? .yellow : .white
    }

    private var bottomBar: some View {
        VStack(spacing: 16) {
            TransportControls(engine: engine)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .transition(.move(edge: .bottom).combined(with: .opacity))
    }
}

private struct StaggeredCharacter: View {
    let character: Character
    let delay: Double
    let font: Font
    let color: Color
    @State private var visible = false

    var body: some View {
        Text(String(character))
            .font(font)
            .foregroundStyle(color)
            .opacity(visible ? 1 : 0)
            .offset(y: visible ? 0 : 12)
            .onAppear {
                withAnimation(.easeOut(duration: 0.12).delay(delay)) {
                    visible = true
                }
            }
    }
}

private struct ScaleGrow: ViewModifier {
    let enabled: Bool
    let startScale: CGFloat
    let wordIndex: Int
    let duration: Double

    @State private var scale: CGFloat = 1.0

    func body(content: Content) -> some View {
        content
            .scaleEffect(enabled ? scale : 1.0)
            .onChange(of: wordIndex) {
                guard enabled else { return }
                scale = startScale
                withAnimation(.linear(duration: duration)) {
                    scale = 1.0
                }
            }
            .onAppear {
                if enabled {
                    scale = startScale
                    withAnimation(.linear(duration: duration)) {
                        scale = 1.0
                    }
                }
            }
    }
}

private struct InfoTextWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 200
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

#Preview {
    NavigationStack {
        ReaderView(book: Book(
            title: "Sample Book",
            author: "Author",
            words: "The quick brown fox jumps over the lazy dog and then runs away into the forest".components(separatedBy: " ")
        ))
    }
    .preferredColorScheme(.dark)
}
