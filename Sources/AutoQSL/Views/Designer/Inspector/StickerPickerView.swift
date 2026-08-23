import SwiftUI
import UniformTypeIdentifiers

public struct StickerPickerView: View {
    public var onSelectSticker: (StickerType, String?) -> Void
    
    @State private var isImportingCustom: Bool = false
    
    public var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Add Badge / Sticker")
                .font(.headline)
            
            // Built-in Badges Grid
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 90))], spacing: 12) {
                stickerCard(title: "ARRL Diamond", type: .arrl)
                stickerCard(title: "POTA Park", type: .pota)
                stickerCard(title: "IOTA Island", type: .iota)
                stickerCard(title: "SOTA Summit", type: .sota)
                stickerCard(title: "CQ WPX/DX", type: .cq)
                stickerCard(title: "WAS State", type: .was)
            }
            
            Divider()
            
            // Custom Sticker Importer
            Button(action: {
                chooseCustomSticker()
            }) {
                Label("Import Custom PNG Badge...", systemImage: "photo.badge.plus")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.bordered)
        }
        .padding()
    }
    
    private func stickerCard(title: String, type: StickerType) -> some View {
        Button(action: {
            onSelectSticker(type, nil)
        }) {
            VStack(spacing: 6) {
                StickerElementView(stickerType: type)
                    .frame(width: 50, height: 50)
                Text(title)
                    .font(.caption2)
                    .lineLimit(1)
            }
            .padding(8)
            .frame(maxWidth: .infinity)
            .background(Color(NSColor.controlBackgroundColor))
            .cornerRadius(8)
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(Color.secondary.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
    
    private func chooseCustomSticker() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.png, .jpeg, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            onSelectSticker(.custom, url.path)
        }
    }
}
