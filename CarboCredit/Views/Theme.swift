import SwiftUI

enum CarboTheme {
    static let background = Color(red: 0.965, green: 0.945, blue: 0.918)
    static let surface = Color(red: 0.937, green: 0.906, blue: 0.867)
    static let surfaceStrong = Color(red: 0.898, green: 0.855, blue: 0.800)
    static let text = Color(red: 0.184, green: 0.169, blue: 0.145)
    static let mutedText = Color(red: 0.427, green: 0.396, blue: 0.345)
    static let tabUnselected = Color(red: 0.514, green: 0.443, blue: 0.345)
    static let accent = Color(red: 0.471, green: 0.525, blue: 0.420)
    static let protein = Color(red: 0.435, green: 0.529, blue: 0.588)
    static let caution = Color(red: 0.722, green: 0.541, blue: 0.267)
    static let ldl = Color(red: 0.651, green: 0.369, blue: 0.306)
}

extension View {
    func cardStyle() -> some View {
        padding(14)
            .background(CarboTheme.surface)
            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
    }
}

extension Double {
    var clean: String {
        if rounded() == self {
            return String(format: "%.0f", self)
        }
        return String(format: "%.1f", self)
    }
}
