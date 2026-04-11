import SwiftUI

struct ClockView: View {
    @ObservedObject var themeModel: ClockThemeModel
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            GeometryReader { geometry in
                let fontSize = clockFontSize(for: geometry.size)
                let horizontalPadding = clockHorizontalPadding(for: geometry.size)
                let foreground = clockForeground
                let border = clockBorder

                ZStack {
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20, style: .continuous)
                                .strokeBorder(border, lineWidth: 1)
                        )

                    Text(timeString(from: context.date))
                        .font(.system(size: fontSize, weight: .bold, design: .default))
                        .monospacedDigit()
                        .kerning(fontSize * 0.015)
                        .foregroundStyle(foreground)
                        .lineLimit(1)
                        .minimumScaleFactor(0.7)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                        .padding(.horizontal, horizontalPadding)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .preferredColorScheme(themeModel.preferredColorScheme)
    }

    private var clockForeground: Color {
        colorScheme == .dark ? Color.white.opacity(0.96) : Color.black.opacity(0.88)
    }

    private var clockBorder: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.08)
    }

    private func clockFontSize(for size: CGSize) -> CGFloat {
        let widthDriven = size.width * 0.155
        let heightDriven = size.height * 0.52
        return max(15, min(widthDriven, heightDriven))
    }

    private func clockHorizontalPadding(for size: CGSize) -> CGFloat {
        min(20, max(8, size.width * 0.06))
    }

    private func timeString(from date: Date) -> String {
        let components = Calendar.current.dateComponents([.hour, .minute, .second], from: date)
        return String(
            format: "%02d:%02d:%02d",
            components.hour ?? 0,
            components.minute ?? 0,
            components.second ?? 0
        )
    }
}
