import SwiftUI
import UniformTypeIdentifiers
import AppKit

public struct StickerPickerView: View {
    @EnvironmentObject public var appState: AppState
    @Environment(\.dismiss) private var dismiss
    
    public var onSelectSticker: (StickerItem) -> Void
    
    @State private var searchText: String = ""
    @State private var selectedCategory: String = "All"
    @State private var hoveredStickerId: UUID? = nil
    @State private var stickerToDelete: StickerItem? = nil
    @State private var isDeleteConfirmationPresented: Bool = false
    
    // Import Dialog State
    @State private var isImportSheetPresented: Bool = false
    @State private var importedImageURL: URL? = nil
    @State private var importedBadgeName: String = ""
    
    private var categories: [String] {
        var set = Set<String>()
        set.insert("All")
        for item in appState.stickerCollection {
            if !item.category.isEmpty {
                set.insert(item.category)
            }
        }
        return ["All"] + set.filter { $0 != "All" }.sorted()
    }
    
    private var filteredStickers: [StickerItem] {
        appState.stickerCollection.filter { item in
            let matchesCategory = selectedCategory == "All" || item.category == selectedCategory
            let matchesSearch = searchText.isEmpty ||
                item.name.localizedCaseInsensitiveContains(searchText) ||
                item.category.localizedCaseInsensitiveContains(searchText)
            return matchesCategory && matchesSearch
        }
    }
    
    public init(onSelectSticker: @escaping (StickerItem) -> Void) {
        self.onSelectSticker = onSelectSticker
    }
    
    public var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack(alignment: .center, spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Badges & Stickers Collection")
                        .font(.title3.bold())
                    Text("Select a sticker to place on the QSL card, or manage your collection.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Add Sticker & Menu
                HStack(spacing: 8) {
                    Button(action: {
                        promptImportCustomBadge()
                    }) {
                        Label("Add Sticker...", systemImage: "plus.circle.fill")
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                    
                    Menu {
                        Button(action: {
                            promptImportCustomBadge()
                        }) {
                            Label("Import Custom PNG / Image...", systemImage: "photo.badge.plus")
                        }
                        
                        Button(action: {
                            openBadgesFolderInFinder()
                        }) {
                            Label("Open Badges Folder in Finder", systemImage: "folder")
                        }
                        
                        Divider()
                        
                        Button(role: .destructive, action: {
                            appState.restoreDefaultStickers()
                        }) {
                            Label("Restore Built-in Badges", systemImage: "arrow.counterclockwise")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                    .menuStyle(.borderlessButton)
                    .frame(width: 24, height: 24)
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 16)
            .padding(.bottom, 12)
            
            // Search & Filter Bar
            HStack(spacing: 12) {
                HStack(spacing: 6) {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.secondary)
                    TextField("Search badges...", text: $searchText)
                        .textFieldStyle(.plain)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.secondary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 5)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(7)
                .overlay(RoundedRectangle(cornerRadius: 7).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                
                // Category Pills
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(categories, id: \.self) { cat in
                            Button(action: {
                                selectedCategory = cat
                            }) {
                                Text(cat)
                                    .font(.caption.weight(selectedCategory == cat ? .semibold : .regular))
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(selectedCategory == cat ? Color.accentColor : Color(NSColor.controlBackgroundColor))
                                    .foregroundColor(selectedCategory == cat ? .white : .primary)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(selectedCategory == cat ? Color.clear : Color.secondary.opacity(0.2), lineWidth: 1)
                                    )
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 12)
            
            Divider()
            
            // Stickers Grid Content
            ScrollView {
                if filteredStickers.isEmpty {
                    VStack(spacing: 12) {
                        Image(systemName: "shield.slash")
                            .font(.system(size: 40))
                            .foregroundColor(.secondary.opacity(0.6))
                            .padding(.top, 40)
                        Text("No badges found")
                            .font(.headline)
                            .foregroundColor(.secondary)
                        Button("Import Custom Badge...") {
                            promptImportCustomBadge()
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: .infinity, minHeight: 200)
                } else {
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 110, maximum: 130), spacing: 14)], spacing: 14) {
                        ForEach(filteredStickers) { item in
                            stickerCard(item: item)
                        }
                    }
                    .padding(20)
                }
            }
            .background(Color(NSColor.windowBackgroundColor).opacity(0.5))
            
            Divider()
            
            // Footer
            HStack {
                Text("\(appState.stickerCollection.count) Badges in collection")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.bordered)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
        }
        .frame(width: 520, height: 480)
        // Confirmation Dialog for Deleting
        .confirmationDialog(
            "Delete '\(stickerToDelete?.name ?? "Badge")'?",
            isPresented: $isDeleteConfirmationPresented,
            titleVisibility: .visible
        ) {
            Button("Delete from Collection", role: .destructive) {
                if let toDelete = stickerToDelete {
                    appState.deleteSticker(id: toDelete.id)
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will remove this badge from your collection. Existing QSL templates that already use this badge will not be modified.")
        }
        // Sheet for Custom Name on Import
        .sheet(isPresented: $isImportSheetPresented) {
            importBadgeSheet
        }
    }
    
    // MARK: - Sticker Tile Card
    @ViewBuilder
    private func stickerCard(item: StickerItem) -> some View {
        let isHovered = hoveredStickerId == item.id
        
        ZStack(alignment: .topTrailing) {
            Button(action: {
                onSelectSticker(item)
            }) {
                VStack(spacing: 8) {
                    // Badge Graphic Thumbnail
                    ZStack {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(NSColor.controlBackgroundColor))
                        
                        StickerElementView(
                            stickerType: item.type,
                            customImagePath: item.customImagePath
                        )
                        .frame(width: 56, height: 56)
                        .padding(6)
                    }
                    .frame(height: 70)
                    
                    // Title Label
                    Text(item.name)
                        .font(.caption.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .help(item.name)
                }
                .padding(8)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(isHovered ? Color.accentColor.opacity(0.12) : Color(NSColor.controlBackgroundColor))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(isHovered ? Color.accentColor : Color.secondary.opacity(0.2), lineWidth: isHovered ? 1.5 : 1)
                )
                .shadow(color: isHovered ? Color.accentColor.opacity(0.25) : Color.black.opacity(0.04), radius: isHovered ? 4 : 2, x: 0, y: 1)
            }
            .buttonStyle(.plain)
            .contextMenu {
                Button {
                    onSelectSticker(item)
                } label: {
                    Label("Place on QSL Card", systemImage: "plus.rectangle.on.rectangle")
                }
                
                if let customPath = item.customImagePath {
                    Button {
                        NSWorkspace.shared.selectFile(customPath, inFileViewerRootedAtPath: "")
                    } label: {
                        Label("Show in Finder", systemImage: "folder")
                    }
                }
                
                Divider()
                
                Button(role: .destructive) {
                    stickerToDelete = item
                    isDeleteConfirmationPresented = true
                } label: {
                    Label("Delete from Collection", systemImage: "trash")
                }
            }
            
            // Hover Quick-Delete Button (visible on hover)
            if isHovered {
                Button(action: {
                    stickerToDelete = item
                    isDeleteConfirmationPresented = true
                }) {
                    Image(systemName: "trash.circle.fill")
                        .symbolRenderingMode(.multicolor)
                        .font(.system(size: 18))
                        .background(Circle().fill(Color(NSColor.windowBackgroundColor)))
                }
                .buttonStyle(.plain)
                .offset(x: 4, y: -4)
                .help("Delete from collection")
            }
        }
        .onHover { hovering in
            hoveredStickerId = hovering ? item.id : nil
        }
    }
    
    // MARK: - Import Custom Badge
    private func promptImportCustomBadge() {
        let panel = NSOpenPanel()
        panel.title = "Import Custom Badge / Sticker"
        panel.prompt = "Import"
        panel.allowedContentTypes = [.png, .jpeg, .image, .svg, .webP, .tiff]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        
        if panel.runModal() == .OK, let url = panel.url {
            self.importedImageURL = url
            self.importedBadgeName = url.deletingPathExtension().lastPathComponent
            self.isImportSheetPresented = true
        }
    }
    
    @ViewBuilder
    private var importBadgeSheet: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Add Badge to Collection")
                .font(.headline)
            
            if let url = importedImageURL, let nsImage = NSImage(contentsOf: url) {
                HStack(spacing: 16) {
                    Image(nsImage: nsImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 70, height: 70)
                        .background(Color(NSColor.controlBackgroundColor))
                        .cornerRadius(8)
                        .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.secondary.opacity(0.2), lineWidth: 1))
                    
                    VStack(alignment: .leading, spacing: 6) {
                        Text("Badge Display Name:")
                            .font(.caption)
                            .foregroundColor(.secondary)
                        TextField("Enter name...", text: $importedBadgeName)
                            .textFieldStyle(.roundedBorder)
                    }
                }
            }
            
            HStack {
                Spacer()
                Button("Cancel") {
                    isImportSheetPresented = false
                }
                .keyboardShortcut(.cancelAction)
                
                Button("Add to Collection") {
                    if let url = importedImageURL {
                        appState.addCustomSticker(name: importedBadgeName, sourceURL: url)
                    }
                    isImportSheetPresented = false
                }
                .buttonStyle(.borderedProminent)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 380)
    }
    
    private func openBadgesFolderInFinder() {
        let dir = PersistenceService.shared.stickersDirectory(for: appState.settings.storageLocation)
        NSWorkspace.shared.selectFile(nil, inFileViewerRootedAtPath: dir.path)
    }
}
