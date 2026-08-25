import SwiftUI
import AppKit

public struct FullSizeCardModalView: View {
    public let template: QSLCardTemplate
    public let settings: AppSettings
    public let qso: QSO?
    public var onDismiss: (() -> Void)? = nil
    @Environment(\.dismiss) private var dismiss
    
    @State private var zoomScale: CGFloat = 1.0
    @GestureState private var pinchMagnification: CGFloat = 1.0
    
    private var baseWidth: CGFloat { CGFloat(template.aspectRatio.widthPoints) }
    private var baseHeight: CGFloat { CGFloat(template.aspectRatio.heightPoints) }
    
    public init(
        template: QSLCardTemplate,
        settings: AppSettings,
        qso: QSO? = nil,
        onDismiss: (() -> Void)? = nil
    ) {
        self.template = template
        self.settings = settings
        self.qso = qso
        self.onDismiss = onDismiss
    }
    
    public var body: some View {
        let currentScale = zoomScale * pinchMagnification
        let scaledW = baseWidth * currentScale
        let scaledH = baseHeight * currentScale
        
        VStack(spacing: 0) {
            // Header Bar
            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 22, height: 22)
                    .foregroundColor(.accentColor)
                
                HStack(spacing: 8) {
                    Text("Original Size QSL Card – \(qso?.dxCall.isEmpty == false ? qso!.dxCall : "Preview")")
                        .font(.headline)
                    
                    Text("\(Int(baseWidth))×\(Int(baseHeight)) pt • \(template.aspectRatio.rawValue)")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(Color.secondary.opacity(0.12))
                        .cornerRadius(4)
                }
                
                Spacer()
                
                // Zoom Controls
                HStack(spacing: 6) {
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            zoomScale = max(zoomScale - 0.15, 0.25)
                        }
                    }) {
                        Image(systemName: "minus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Zoom Out (⌘-)")
                    .keyboardShortcut("-", modifiers: .command)
                    
                    Text("\(Int(currentScale * 100))%")
                        .font(.caption.monospacedDigit().bold())
                        .frame(width: 48)
                    
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            zoomScale = min(zoomScale + 0.15, 3.5)
                        }
                    }) {
                        Image(systemName: "plus.magnifyingglass")
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Zoom In (⌘+)")
                    .keyboardShortcut("+", modifiers: .command)
                    
                    Button("100%") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            zoomScale = 1.0
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("100% Original Size (⌘0)")
                    .keyboardShortcut("0", modifiers: .command)
                    
                    Button("Fit") {
                        withAnimation(.easeInOut(duration: 0.15)) {
                            zoomScale = 0.80
                        }
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.small)
                    .help("Fit to View")
                }
                
                Divider()
                    .frame(height: 20)
                    .padding(.horizontal, 4)
                
                Button("Done") {
                    closeModal()
                }
                .keyboardShortcut(.cancelAction)
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 10)
            .background(Color(NSColor.windowBackgroundColor))
            
            Divider()
            
            // Viewport
            GeometryReader { geo in
                let viewW = geo.size.width
                let viewH = geo.size.height
                
                ScrollView([.horizontal, .vertical], showsIndicators: true) {
                    ZStack {
                        Color(NSColor.underPageBackgroundColor)
                        
                        CardCanvasView(
                            template: template,
                            settings: settings,
                            qso: qso,
                            isInteractive: false
                        )
                        .frame(width: baseWidth, height: baseHeight)
                        .scaleEffect(currentScale)
                        .shadow(color: .black.opacity(0.45), radius: 16, x: 0, y: 6)
                        .padding(40)
                    }
                    .frame(
                        width: max(viewW, scaledW + 80),
                        height: max(viewH, scaledH + 80)
                    )
                }
                .gesture(
                    MagnificationGesture()
                        .updating($pinchMagnification) { val, state, _ in
                            state = val
                        }
                        .onEnded { val in
                            zoomScale = min(max(zoomScale * val, 0.25), 3.5)
                        }
                )
            }
        }
        .frame(minWidth: 850, idealWidth: 1120, maxWidth: .infinity, minHeight: 580, idealHeight: 760, maxHeight: .infinity)
    }
    
    private func closeModal() {
        if let onDismiss = onDismiss {
            onDismiss()
        } else {
            dismiss()
        }
    }
}
