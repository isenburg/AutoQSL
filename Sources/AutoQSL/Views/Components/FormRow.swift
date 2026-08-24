import SwiftUI

/// A reusable standard form row that guarantees uniform label widths and pixel-perfect
/// left-aligned beginnings for all input fields across the AutoQSL app.
public struct FormRow<Content: View>: View {
    public let label: String
    public var labelWidth: CGFloat
    @ViewBuilder public let content: () -> Content
    
    public init(
        label: String,
        labelWidth: CGFloat = 110,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.label = label
        self.labelWidth = labelWidth
        self.content = content
    }
    
    public var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(width: labelWidth, alignment: .trailing)
            
            content()
            
            Spacer(minLength: 0)
        }
    }
}
