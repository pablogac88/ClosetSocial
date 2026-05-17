import SwiftUI

public struct MetricCard: View {
    private let title: String
    private let value: String

    public init(title: String, value: String) {
        self.title = title
        self.value = value
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title)
                .font(DSFont.footnoteBold)
                .foregroundStyle(.secondary)
            Text(value)
                .font(DSFont.metric)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(DSColor.surface, in: RoundedRectangle(cornerRadius: 22, style: .continuous))
    }
}
