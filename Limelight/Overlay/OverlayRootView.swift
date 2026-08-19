import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step3-1: 「Aボタン」を1つだけ配置し、押下/離上のイベントが
/// 正しくObjective-C側に届くかを確認する。
struct OverlayRootView: View {
    var onButtonAChanged: (Bool) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 疎通確認用の緑丸（Phase2から残置）
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .position(x: geo.size.width - 30, y: 30)
                    .allowsHitTesting(false)

                // Aボタン（仮の見た目・仮の位置。Phase4のレイアウトエディタで可変にする）
                ZStack {
                    Circle().fill(Color.white.opacity(0.35))
                    Text("A")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(width: 64, height: 64)
                .position(x: geo.size.width - 60, y: geo.size.height - 100)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in onButtonAChanged(true) }
                        .onEnded { _ in onButtonAChanged(false) }
                )
            }
        }
    }
}
