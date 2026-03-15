import SwiftUI
import SwiftData

struct LibraryView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Book.dateAdded, order: .reverse) private var books: [Book]
    @State private var showingDocumentPicker = false
    @State private var errorMessage: String?
    @State private var showingError = false

    var body: some View {
        NavigationStack {
            Group {
                if books.isEmpty {
                    emptyState
                } else {
                    bookList
                }
            }
            .navigationTitle("SpeedReader")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingDocumentPicker = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingDocumentPicker) {
                DocumentPicker { url in
                    importPDF(from: url)
                }
            }
            .alert("Import Error", isPresented: $showingError) {
                Button("OK") { }
            } message: {
                Text(errorMessage ?? "An unknown error occurred.")
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("NO BOOKS", systemImage: "book.closed")
                .font(.custom("SourceCodePro-SemiBold", size: 18))
        } description: {
            Text("TAP + TO IMPORT A PDF BOOK.")
                .font(.custom("SourceCodePro-Regular", size: 13))
        } actions: {
            Button("IMPORT PDF") {
                showingDocumentPicker = true
            }
            .font(.custom("SourceCodePro-SemiBold", size: 15))
            .buttonStyle(.borderedProminent)
        }
    }

    private var bookList: some View {
        List {
            ForEach(books) { book in
                NavigationLink(destination: ReaderView(book: book)) {
                    BookRow(book: book)
                }
            }
            .onDelete(perform: deleteBooks)
        }
        .listStyle(.plain)
    }

    private func deleteBooks(at offsets: IndexSet) {
        for index in offsets {
            modelContext.delete(books[index])
        }
    }

    private func importPDF(from url: URL) {
        do {
            guard url.startAccessingSecurityScopedResource() else {
                throw PDFTextExtractor.ExtractionError.failedToLoadPDF
            }
            defer { url.stopAccessingSecurityScopedResource() }

            let words = try PDFTextExtractor.extractWords(from: url)
            let title = PDFTextExtractor.extractTitle(from: url)
            let author = PDFTextExtractor.extractAuthor(from: url)

            let book = Book(title: title, author: author, words: words)
            modelContext.insert(book)
        } catch {
            errorMessage = error.localizedDescription
            showingError = true
        }
    }
}

struct BookRow: View {
    let book: Book

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(book.title.uppercased())
                .font(.custom("SourceCodePro-SemiBold", size: 16))
            Text(book.author.uppercased())
                .font(.custom("SourceCodePro-Regular", size: 13))
                .foregroundStyle(.secondary)
            HStack {
                ProgressView(value: book.progressPercentage, total: 100)
                    .tint(.blue)
                Text("\(Int(book.progressPercentage))%")
                    .font(.custom("SourceCodePro-Regular", size: 11.5))
                    .foregroundStyle(.secondary)
                if let lastRead = book.dateLastRead {
                    Spacer()
                    Text(lastRead, style: .relative)
                        .font(.custom("SourceCodePro-Regular", size: 10))
                        .foregroundStyle(.tertiary)
                        .textCase(.uppercase)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    LibraryView()
        .modelContainer(for: Book.self, inMemory: true)
        .preferredColorScheme(.dark)
}
