import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var renameTarget: ScreenshotItem?
    @State private var selectionMode = false
    @State private var selectedIDs = Set<URL>()

    private let columns = [
        GridItem(.flexible(), spacing: 14),
        GridItem(.flexible(), spacing: 14)
    ]

    var body: some View {
        VStack(spacing: 0) {
            header

            Divider()

            content
        }
        .background(.background)
        .sheet(item: $renameTarget) { item in
            RenameScreenshotView(
                filename: item.filename,
                onCancel: { renameTarget = nil },
                onSave: { newName in
                    store.rename(item, to: newName)
                    renameTarget = nil
                }
            )
        }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SnapShelf")
                        .font(.title3.weight(.semibold))

                    Text(store.watchedFolderURL.lastPathComponent)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()

                if selectionMode {
                    Button("Done") {
                        selectionMode = false
                        selectedIDs.removeAll()
                    }
                    .buttonStyle(.borderless)
                } else {
                    Button("Select") {
                        selectionMode = true
                    }
                    .buttonStyle(.borderless)
                }

                SettingsLink {
                    Image(systemName: "gearshape")
                }
                .buttonStyle(.borderless)

                Button {
                    Task { await store.refresh() }
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
            }

            TextField("Search screenshots", text: $store.searchText)
                .textFieldStyle(.roundedBorder)

            if selectionMode, selectedItems.isEmpty == false {
                selectionBar
            }
        }
        .padding(16)
    }

    @ViewBuilder
    private var content: some View {
        if store.isLoading && store.screenshots.isEmpty {
            ProgressView("Loading screenshots…")
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else if store.groupedScreenshots.isEmpty {
            VStack(spacing: 12) {
                ContentUnavailableView(
                    "No screenshots found",
                    systemImage: "photo.on.rectangle.angled",
                    description: Text("Drop screenshots into \(store.watchedFolderURL.lastPathComponent) or change the watched folder in Settings.")
                )

                if let error = store.lastErrorMessage {
                    Text(error)
                        .font(.caption)
                        .foregroundStyle(.red)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .padding()
        } else {
            ScrollView {
                VStack(alignment: .leading, spacing: 22) {
                    if let error = store.lastErrorMessage {
                        Text(error)
                            .font(.caption)
                            .foregroundStyle(.red)
                    }

                    ForEach(store.groupedScreenshots, id: \.section.id) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeaderView(title: group.section.title, count: group.items.count)

                            LazyVGrid(columns: columns, spacing: 14) {
                                ForEach(group.items) { item in
                                    ScreenshotCardView(
                                        item: item,
                                        isSelected: selectedIDs.contains(item.id),
                                        selectionMode: selectionMode,
                                        onSelect: { toggleSelection(for: item) },
                                        onCopyImage: { store.copyImage(item) },
                                        onCopyPath: { store.copyPaths([item]) },
                                        onDelete: { store.delete(item) },
                                        onMove: { store.move(item) },
                                        onRename: {
                                            renameTarget = item
                                        },
                                        onReveal: { store.revealInFinder(item) }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding(16)
            }
        }
    }

    private var selectedItems: [ScreenshotItem] {
        store.screenshots.filter { selectedIDs.contains($0.id) }
    }

    private var selectionBar: some View {
        HStack(spacing: 10) {
            Text("\(selectedItems.count) selected")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer()

            Button("Copy Files") {
                store.copyFiles(selectedItems)
            }

            Button("Copy Paths") {
                store.copyPaths(selectedItems)
            }

            Button("Reveal") {
                store.revealInFinder(selectedItems)
            }

            Button("Delete", role: .destructive) {
                let items = selectedItems
                selectedIDs.removeAll()
                selectionMode = false
                store.delete(items)
            }

            Button("Clear") {
                selectedIDs.removeAll()
            }
        }
        .font(.caption)
    }

    private func toggleSelection(for item: ScreenshotItem) {
        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }
}

private struct RenameScreenshotView: View {
    let filename: String
    let onCancel: () -> Void
    let onSave: (String) -> Void

    @State private var newName = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Rename Screenshot")
                .font(.title3.weight(.semibold))

            TextField("Filename", text: $newName)
                .textFieldStyle(.roundedBorder)
                .focused($isFocused)

            HStack {
                Spacer()

                Button("Cancel", action: onCancel)
                Button("Save") {
                    onSave(newName)
                }
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            newName = filename
            isFocused = true
        }
    }
}

struct ShelfView_Previews: PreviewProvider {
    static var previews: some View {
        ShelfView()
            .environmentObject(PreviewSampleData.store)
            .frame(width: 440, height: 620)
    }
}
