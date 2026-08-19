import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// 今の段階では「オーバーレイが配信画面の上に正しく乗っているか」を
/// 目視確認するためだけの、当たり判定なしのマーカーです。
struct OverlayRootView: View {
    var body: some View {
        GeometryReader { geo in
            Circle()
                .fill(Color.green.opacity(0.6))
                .frame(width: 24, height: 24)
                .position(x: geo.size.width - 30, y: 30)
        }
        .allowsHitTesting(false) // まだタッチは奪わない
    }
}
