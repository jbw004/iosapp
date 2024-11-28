import SwiftUI

struct ScrollViewOffsetModifier: ViewModifier {
    let onOffsetChange: (CGFloat) -> Void
    
    func body(content: Content) -> some View {
        content
            .background(
                GeometryReader { proxy in
                    Color.clear.preference(
                        key: OffsetPreferenceKey.self,
                        value: proxy.frame(in: .named("scroll")).minY
                    )
                }
            )
            .onPreferenceChange(OffsetPreferenceKey.self) { offset in
                onOffsetChange(offset)
            }
    }
}

struct OffsetPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

extension View {
    func onScrollOffsetChange(action: @escaping (CGFloat) -> Void) -> some View {
        modifier(ScrollViewOffsetModifier(onOffsetChange: action))
    }
}
