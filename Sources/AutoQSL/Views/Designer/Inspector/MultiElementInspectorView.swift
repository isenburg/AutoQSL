import SwiftUI

public enum MultiAlignment {
    case left, centerH, right, top, centerV, bottom
}

public struct MultiElementInspectorView: View {
    public let count: Int
    public let lang: AppLanguage
    public var onAlign: (MultiAlignment) -> Void
    public var onDistribute: (Axis) -> Void
    public var onDuplicate: () -> Void
    public var onToggleLock: () -> Void
    public var onToggleVisibility: () -> Void
    public var onDelete: () -> Void
    
    public init(
        count: Int,
        lang: AppLanguage = .english,
        onAlign: @escaping (MultiAlignment) -> Void,
        onDistribute: @escaping (Axis) -> Void,
        onDuplicate: @escaping () -> Void,
        onToggleLock: @escaping () -> Void,
        onToggleVisibility: @escaping () -> Void,
        onDelete: @escaping () -> Void
    ) {
        self.count = count
        self.lang = lang
        self.onAlign = onAlign
        self.onDistribute = onDistribute
        self.onDuplicate = onDuplicate
        self.onToggleLock = onToggleLock
        self.onToggleVisibility = onToggleVisibility
        self.onDelete = onDelete
    }
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header Banner
                HStack(spacing: 8) {
                    Image(systemName: "square.grid.3x3.fill.square")
                        .font(.title2)
                        .foregroundColor(.accentColor)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(lang == .german ? "\(count) Elemente ausgewählt" : "\(count) Elements Selected")
                            .font(.headline)
                        Text(lang == .german ? "Gemeinsam verschieben & anordnen" : "Move & align together")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                .padding(.bottom, 4)
                
                Divider()
                
                // Alignment Tools Group
                GroupBox(label: Text(lang == .german ? "Ausrichtung (Align)" : "Alignment Tools").font(.subheadline.bold())) {
                    VStack(spacing: 8) {
                        // Horizontal Alignment Row
                        HStack(spacing: 6) {
                            Button(action: { onAlign(.left) }) {
                                Label(lang == .german ? "Links" : "Left", systemImage: "align.horizontal.left.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Linksbündig ausrichten" : "Align left edges")
                            
                            Button(action: { onAlign(.centerH) }) {
                                Label(lang == .german ? "Zentriert" : "Center", systemImage: "align.horizontal.center.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Horizontal zentrieren" : "Align horizontal centers")
                            
                            Button(action: { onAlign(.right) }) {
                                Label(lang == .german ? "Rechts" : "Right", systemImage: "align.horizontal.right.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Rechtsbündig ausrichten" : "Align right edges")
                        }
                        
                        // Vertical Alignment Row
                        HStack(spacing: 6) {
                            Button(action: { onAlign(.top) }) {
                                Label(lang == .german ? "Oben" : "Top", systemImage: "align.vertical.top.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Obenbündig ausrichten" : "Align top edges")
                            
                            Button(action: { onAlign(.centerV) }) {
                                Label(lang == .german ? "Mitte" : "Middle", systemImage: "align.vertical.center.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Vertikal zentrieren" : "Align vertical centers")
                            
                            Button(action: { onAlign(.bottom) }) {
                                Label(lang == .german ? "Unten" : "Bottom", systemImage: "align.vertical.bottom.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Untenbündig ausrichten" : "Align bottom edges")
                        }
                    }
                    .padding(4)
                }
                
                // Distribution Tools Group (if 3 or more elements)
                if count >= 3 {
                    GroupBox(label: Text(lang == .german ? "Gleichmäßig verteilen" : "Distribute Spacing").font(.subheadline.bold())) {
                        HStack(spacing: 8) {
                            Button(action: { onDistribute(.horizontal) }) {
                                Label(lang == .german ? "Horizontal" : "Horizontal", systemImage: "distribute.horizontal.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Horizontal gleichmäßig verteilen" : "Distribute horizontally")
                            
                            Button(action: { onDistribute(.vertical) }) {
                                Label(lang == .german ? "Vertikal" : "Vertical", systemImage: "distribute.vertical.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            .help(lang == .german ? "Vertikal gleichmäßig verteilen" : "Distribute vertically")
                        }
                        .padding(4)
                    }
                }
                
                // Batch Actions Group
                GroupBox(label: Text(lang == .german ? "Massenaktionen" : "Batch Actions").font(.subheadline.bold())) {
                    VStack(spacing: 8) {
                        Button(action: onDuplicate) {
                            Label(lang == .german ? "Auswahl duplizieren" : "Duplicate Selected", systemImage: "plus.square.on.square")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        
                        HStack(spacing: 8) {
                            Button(action: onToggleLock) {
                                Label(lang == .german ? "Sperren / Entsperren" : "Lock / Unlock", systemImage: "lock.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                            
                            Button(action: onToggleVisibility) {
                                Label(lang == .german ? "Ein-/Ausblenden" : "Show / Hide", systemImage: "eye.fill")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .padding(4)
                }
                
                // Tips info box
                GroupBox {
                    VStack(alignment: .leading, spacing: 4) {
                        Label(lang == .german ? "Tipp:" : "Tip:", systemImage: "lightbulb.fill")
                            .font(.caption.bold())
                            .foregroundColor(.orange)
                        Text(lang == .german ?
                            "Bewege beliebige der markierten Objekte per Maus oder Pfeiltasten, um die gesamte Gruppe gemeinsam zu verschieben." :
                            "Drag any of the selected objects with your mouse or use arrow keys to move the entire group together.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(2)
                }
                
                Spacer()
                
                Divider()
                
                // Delete All Selected Button
                Button(role: .destructive, action: onDelete) {
                    Label(lang == .german ? "\(count) Elemente löschen" : "Delete \(count) Elements", systemImage: "trash.fill")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .tint(.red)
                .controlSize(.regular)
            }
            .padding(14)
        }
    }
}
