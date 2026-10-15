import SwiftUI
import UIKit

enum Brand {
    // A darker teal in Light Mode and a lighter teal in Dark Mode.
    static let accent = Color(
        uiColor: UIColor { traits in
            if traits.userInterfaceStyle == .dark {
                return UIColor(
                    red: 0.35,
                    green: 0.85,
                    blue: 0.76,
                    alpha: 1
                )
            }

            return UIColor(
                red: 0.00,
                green: 0.40,
                blue: 0.34,
                alpha: 1
            )
        }
    )

    static let background = Color(
        uiColor: .systemGroupedBackground
    )

    static let cardBackground = Color(
        uiColor: .secondarySystemGroupedBackground
    )

    static let separator = Color(
        uiColor: .separator
    )

    static let cornerRadius: CGFloat = 20
}

// A custom SwiftUI modifier shared by dashboard and goal cards.
struct StudyCardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Brand.cardBackground)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: Brand.cornerRadius,
                    style: .continuous
                )
            )
    }
}

extension View {
    func studyCard() -> some View {
        modifier(StudyCardModifier())
    }
}