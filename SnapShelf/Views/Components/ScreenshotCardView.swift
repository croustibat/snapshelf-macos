import AppKit
import SwiftUI

struct ScreenshotCardView: View {
    let item: ScreenshotItem
    let isSelected: Bool
    let selectionMode: Bool
    let onSelect: () -> Void
    let onCopyImage: () -> Void
    let onCopyPath: () -> Void
    let onDelete: () -> Void
    let onMove: () -> Void
    let onRename: () -> Void
    let onReveal: () -> Void

    @State private var thumbnail: NSImage?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 14)
                    .fill(.quaternary.opacity(0.35))

                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    ProgressView()
                        .controlSize(.small)
                }
            }
            .frame(height: 126)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .topTrailing) {
                Menu {
                    Button("Copy Image", systemImage: "doc.on.doc", action: onCopyImage)
                    Button("Copy File Path", systemImage: "link", action: onCopyPath)
                    Divider()
                    Button("Rename", systemImage: "pencil", action: onRename)
                    Button("Move", systemImage: "folder", action: onMove)
                    Button("Reveal in Finder", systemImage: "finder", action: onReveal)
                    Divider()
                    Button("Delete", systemImage: "trash", role: .destructive, action: onDelete)
                } label: {
                    Image(systemName: "ellipsis.circle.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.white, .black.opacity(0.45))
                        .padding(8)
                }
                .menuStyle(.borderlessButton)
            }
            .overlay(alignment: .topLeading) {
                if selectionMode {
                    Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundStyle(isSelected ? .white : .secondary, isSelected ? Color.accentColor : .clear)
                        .padding(8)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(item.filename)
                    .font(.system(size: 13, weight: .semibold))
                    .lineLimit(1)

                Text(item.createdAt, format: .dateTime.hour().minute())
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(8)
        .background(selectionBackground, in: RoundedRectangle(cornerRadius: 16))
        .contentShape(RoundedRectangle(cornerRadius: 16))
        .onTapGesture {
            guard selectionMode else { return }
            onSelect()
        }
        .draggable(item.url) {
            dragPreview
        }
        .task(id: item.url) {
            thumbnail = await ThumbnailService.shared.thumbnail(for: item.url)
        }
    }

    private var selectionBackground: some ShapeStyle {
        isSelected ? AnyShapeStyle(Color.accentColor.opacity(0.18)) : AnyShapeStyle(.clear)
    }

    @ViewBuilder
    private var dragPreview: some View {
        VStack(alignment: .leading, spacing: 8) {
            Group {
                if let thumbnail {
                    Image(nsImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.quaternary)
                }
            }
            .frame(width: 160, height: 96)
            .clipShape(RoundedRectangle(cornerRadius: 10))

            Text(item.filename)
                .font(.caption.weight(.semibold))
                .lineLimit(1)
        }
        .padding(10)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 14))
        .frame(width: 180)
    }
}

struct ScreenshotCardView_Previews: PreviewProvider {
    static var previews: some View {
        ScreenshotCardView(
            item: PreviewSampleData.items.first!,
            isSelected: false,
            selectionMode: false,
            onSelect: {},
            onCopyImage: {},
            onCopyPath: {},
            onDelete: {},
            onMove: {},
            onRename: {},
            onReveal: {}
        )
        .padding()
        .frame(width: 240)
    }
}
