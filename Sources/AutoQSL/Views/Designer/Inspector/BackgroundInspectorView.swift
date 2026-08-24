import SwiftUI
import UniformTypeIdentifiers

public struct BackgroundInspectorView: View {
    @Binding var template: QSLCardTemplate
    
    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Card Background & Canvas")
                    .font(.headline)
                
                // Aspect Ratio Picker
                Picker("Card Dimensions", selection: $template.aspectRatio) {
                    ForEach(CardAspectRatio.allCases, id: \.self) { ratio in
                        Text(ratio.rawValue).tag(ratio)
                    }
                }
                
                // Solid Background Color
                HStack {
                    Text("Canvas Background Color")
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
                Text("Background Picture (Optional)")
                    .font(.subheadline.bold())
                
                if let path = template.backgroundImagePath, !path.isEmpty {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(URL(fileURLWithPath: path).lastPathComponent)
                            .font(.caption)
                            .lineLimit(1)
                        
                        Button("Remove Picture", role: .destructive) {
                            template.backgroundImagePath = nil
                        }
                        .buttonStyle(.bordered)
                    }
                } else {
                    Text("No picture selected (using solid canvas color)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Button(action: selectImage) {
                    Label("Choose Background Photo...", systemImage: "photo.on.rectangle")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                
                if let path = template.backgroundImagePath, !path.isEmpty {
                    // Image Fit
                    Picker("Image Scaling", selection: $template.backgroundFit) {
                        ForEach(BackgroundFit.allCases, id: \.self) { fit in
                            Text(fit.rawValue).tag(fit)
                        }
                    }
                }
                
                Divider()
                
                // Darken / Tint Overlay Slider
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Darken Overlay: \(Int(template.backgroundDarkenOpacity * 100))%")
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
