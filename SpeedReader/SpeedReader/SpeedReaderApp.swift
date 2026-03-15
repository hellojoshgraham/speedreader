import SwiftUI
import SwiftData

@main
 struct SpeedReaderApp: App {
    var body: some Scene {
        WindowGroup {
            LibraryView()
                .preferredColorScheme(.dark)
        }
        .modelContainer(for: Book.self)
    }
}
