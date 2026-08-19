import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step3-2: 押している間だけAボタンの色が変わることで、
/// タップ/リリースイベントが正しく検知できているかを目視確認する。
struct OverlayRootView: View {
    var onButtonAChanged: (Bool) -> Void

    @State private var isPressed = false

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 疎通確認用の緑丸（Phase2から残置）
                Circle()
                    .fill(Color.green.opacity(0.6))
                    .frame(width: 24, height: 24)
                    .position(x: geo.size.width - 30, y: 30)
                    .allowsHitTesting(false)

                // Aボタン：押している間は赤、離すと白に戻る
                ZStack {
                    Circle().fill(isPressed ? Color.red.opacity(0.8) : Color.white.opacity(0.35))
                    Text("A")
                        .foregroundColor(.white)
                        .font(.headline)
                }
                .frame(width: 64, height: 64)
                .position(x: geo.size.width - 60, y: geo.size.height - 100)
                .gesture(
                    DragGesture(minimumDistance: 0)
                        .onChanged { _ in
                            if !isPressed {
                                isPressed = true
                                onButtonAChanged(true)
                            }
                        }
                        .onEnded { _ in
                            isPressed = false
                            onButtonAChanged(false)
                        }
                )
            }
        }
    }
}
