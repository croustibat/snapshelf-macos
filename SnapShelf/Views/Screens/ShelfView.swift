import AppKit
import SwiftUI

struct ShelfView: View {
    @EnvironmentObject private var store: ScreenshotStore
    @State private var renameTarget: ScreenshotItem?
    @State private var selectionMode = false
    @State private var selectedIDs = Set<URL>()
    @State private var activeItemID: URL?
    @State private var keyMonitor: Any?

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
        .onAppear(perform: installKeyboardMonitor)
        .onDisappear(perform: removeKeyboardMonitor)
        .onChange(of: visibleItems.map(\.id), initial: true) { _, _ in
            syncActiveItem()
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
                                        isActive: activeItemID == item.id,
                                        selectionMode: selectionMode,
                                        onActivate: { activeItemID = item.id },
                                        onSelect: { toggleSelection(for: item) },
                                        onCopyImage: { store.copyImage(item) },
                                        onCopyPath: { store.copyPaths([item]) },
                                        onDelete: { store.delete(item) },
                                        onQuickLook: { store.quickLook(item) },
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

    private var visibleItems: [ScreenshotItem] {
        store.filteredScreenshots
    }

    private var selectionBar: some View {
        HStack(spacing: 12) {
            Label(selectionSummaryText, systemImage: "checkmark.circle.fill")
                .font(.caption.weight(.semibold))
                .foregroundStyle(.secondary)

            Spacer(minLength: 0)

            HStack(spacing: 6) {
                MultiFileDragButton(items: selectedItems, compact: true)
                    .frame(width: 30, height: 30)

                Button {
                    store.quickLook(selectedItems, current: selectedItems.first)
                } label: {
                    Image(systemName: "space")
                }
                .help("Quick Look")
                .keyboardShortcut(.space, modifiers: [])

                Button {
                    store.copyFiles(selectedItems)
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                .help("Copy Files")
                .keyboardShortcut("c")

                Menu {
                    Button("Copy Paths", systemImage: "link") {
                        store.copyPaths(selectedItems)
                    }

                    Button("Reveal in Finder", systemImage: "finder") {
                        store.revealInFinder(selectedItems)
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
                .help("More Actions")

                Button(role: .destructive) {
                    let items = selectedItems
                    selectedIDs.removeAll()
                    selectionMode = false
                    store.delete(items)
                } label: {
                    Image(systemName: "trash")
                }
                .help("Delete Selection")
                .keyboardShortcut(.delete, modifiers: [])

                Button {
                    selectedIDs.removeAll()
                } label: {
                    Image(systemName: "xmark")
                }
                .help("Clear Selection")
            }
            .buttonStyle(.bordered)
        }
        .font(.caption)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.quaternary.opacity(0.35), in: RoundedRectangle(cornerRadius: 14))
    }

    private var selectionSummaryText: String {
        selectedItems.count == 1 ? "1 selected" : "\(selectedItems.count) selected"
    }

    private func toggleSelection(for item: ScreenshotItem) {
        activeItemID = item.id

        if selectedIDs.contains(item.id) {
            selectedIDs.remove(item.id)
        } else {
            selectedIDs.insert(item.id)
        }
    }

    private func installKeyboardMonitor() {
        guard keyMonitor == nil else {
            return
        }

        keyMonitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            handleKeyEvent(event)
        }
        syncActiveItem()
    }

    private func removeKeyboardMonitor() {
        guard let keyMonitor else {
            return
        }

        NSEvent.removeMonitor(keyMonitor)
        self.keyMonitor = nil
    }

    private func handleKeyEvent(_ event: NSEvent) -> NSEvent? {
        guard shouldHandleKeyEvent else {
            return event
        }

        let commandPressed = event.modifierFlags.intersection(.deviceIndependentFlagsMask).contains(.command)

        if commandPressed, event.charactersIgnoringModifiers?.lowercased() == "c" {
            copyFocusedItems()
            return nil
        }

        switch event.keyCode {
        case 123:
            moveActiveItem(horizontalStep: -1)
            return nil
        case 124:
            moveActiveItem(horizontalStep: 1)
            return nil
        case 125:
            moveActiveItem(verticalStep: columns.count)
            return nil
        case 126:
            moveActiveItem(verticalStep: -columns.count)
            return nil
        case 49:
            quickLookFocusedItem()
            return nil
        case 36, 76:
            revealFocusedItem()
            return nil
        case 51, 117:
            deleteFocusedItems()
            return nil
        default:
            return event
        }
    }

    private var shouldHandleKeyEvent: Bool {
        guard visibleItems.isEmpty == false else {
            return false
        }

        if renameTarget != nil {
            return false
        }

        if let firstResponder = NSApp.keyWindow?.firstResponder, firstResponder is NSTextView {
            return false
        }

        return true
    }

    private func syncActiveItem() {
        guard visibleItems.isEmpty == false else {
            activeItemID = nil
            return
        }

        if let activeItemID, visibleItems.contains(where: { $0.id == activeItemID }) {
            return
        }

        activeItemID = visibleItems.first?.id
    }

    private func moveActiveItem(horizontalStep: Int = 0, verticalStep: Int = 0) {
        guard visibleItems.isEmpty == false else {
            return
        }

        let currentIndex = visibleItems.firstIndex { $0.id == activeItemID } ?? 0
        let rawTarget = currentIndex + horizontalStep + verticalStep
        let clampedIndex = min(max(rawTarget, 0), visibleItems.count - 1)
        activeItemID = visibleItems[clampedIndex].id
    }

    private var focusedItem: ScreenshotItem? {
        visibleItems.first { $0.id == activeItemID } ?? visibleItems.first
    }

    private func copyFocusedItems() {
        if selectionMode, selectedItems.isEmpty == false {
            store.copyFiles(selectedItems)
            return
        }

        guard let focusedItem else {
            return
        }

        store.copyFiles([focusedItem])
    }

    private func quickLookFocusedItem() {
        if selectionMode, selectedItems.isEmpty == false {
            store.quickLook(selectedItems, current: focusedItem ?? selectedItems.first)
            return
        }

        guard let focusedItem else {
            return
        }

        store.quickLook(focusedItem)
    }

    private func revealFocusedItem() {
        if selectionMode, selectedItems.isEmpty == false {
            store.revealInFinder(selectedItems)
            return
        }

        guard let focusedItem else {
            return
        }

        store.revealInFinder(focusedItem)
    }

    private func deleteFocusedItems() {
        if selectionMode, selectedItems.isEmpty == false {
            let items = selectedItems
            selectedIDs.removeAll()
            selectionMode = false
            store.delete(items)
            return
        }

        guard let focusedItem else {
            return
        }

        activeItemID = nil
        store.delete(focusedItem)
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
