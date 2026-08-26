import SwiftUI
import UniformTypeIdentifiers

public struct BackgroundInspectorView: View {
    @Binding var template: QSLCardTemplate
    public var lang: AppLanguage = .english
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text(L10n.tr(lang, "Card Background & Canvas", "Karten-Hintergrund & Layout"))
                    .font(.headline)
                
                // Template Name Field
                VStack(alignment: .leading, spacing: 4) {
                    Text(L10n.tr(lang, "Template Name", "Vorlagenname"))
                        .font(.subheadline.bold())
                    TextField(L10n.tr(lang, "Template Name", "Vorlagenname"), text: $template.name)
                        .textFieldStyle(.roundedBorder)
                }
                
                Divider()
                
                // Aspect Ratio Picker
                Picker(L10n.tr(lang, "Card Dimensions", "Kartenformat"), selection: $template.aspectRatio) {
                    ForEach(CardAspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                
                // Solid Background Color
                HStack {
                    Text(L10n.tr(lang, "Canvas Background Color", "Hintergrundfarbe"))
                        .font(.subheadline.bold())
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: template.backgroundColorHex) },
                        set: { template.backgroundColorHex = $0.toHex() }
                    ), supportsOpacity: true)
                    .labelsHidden()
                }
                
                Divider()
                
                // Background Image
                Text(L10n.tr(lang, "Background Picture (Optional)", "Hintergrundbild (optional)"))
                    .font(.subheadline.bold())
                
                if let path = template.backgroundImagePath, !path.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(URL(fileURLWithPath: path).lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Button(L10n.tr(lang, "Remove Picture", "Bild entfernen"), role: .destructive) {
                            template.backgroundImagePath = nil
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text(L10n.tr(lang, "No picture selected (using solid canvas color)", "Kein Bild gewählt (einfarbiger Hintergrund)"))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: selectImage) {
                    Label(L10n.tr(lang, "Choose Background Photo...", "Hintergrundfoto wählen..."), systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if let path = template.backgroundImagePath, !path.isEmpty {
                    // Image Fit
                    Picker(L10n.tr(lang, "Image Scaling", "Bild-Skalierung"), selection: $template.backgroundFit) {
                        ForEach(BackgroundFit.allCases, id: \.self) { fit in
                            Text(fit.rawValue).tag(fit)
                        }
                    }
                }
                
                Divider()
                
                // Darken / Tint Overlay Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text(L10n.tr(lang, "Darken Overlay: \(Int(template.backgroundDarkenOpacity * 100))%", "Abdunkeln: \(Int(template.backgroundDarkenOpacity * 100))%"))
                            .font(.caption)
                        Spacer()
                    }
                    Slider(value: $template.backgroundDarkenOpacity, in: 0.0...0.8, step: 0.05)
                }
            }
            .padding()
        }
    }
    
    private func selectImage() {
        let panel = NSOpenPanel()
        panel.allowedContentTypes = [.jpeg, .png, .heic, .image]
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        if panel.runModal() == .OK, let url = panel.url {
            template.backgroundImagePath = url.path
        }
    }
}
