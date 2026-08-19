import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step3-4: 左スティック＋ABXY＋十字キーのフル仮想パッド。
/// 位置・見た目はまだ仮固定（Phase4のレイアウトエディタで可変にする）。
struct OverlayRootView: View {
    var onButtonChanged: (OverlayButton, Bool) -> Void
    var onLeftStickChanged: (Float, Float) -> Void

    var body: some View {
        GeometryReader { geo in
            ZStack {
                // 左スティック
                VirtualStick(onChange: onLeftStickChanged)
                    .position(x: 80, y: geo.size.height - 120)

                // 十字キー
                VStack(spacing: 4) {
                    PadButton(label: "▲") { onButtonChanged(.dpadUp, $0) }
                    HStack(spacing: 4) {
                        PadButton(label: "◀") { onButtonChanged(.dpadLeft, $0) }
                        PadButton(label: "▶") { onButtonChanged(.dpadRight, $0) }
                    }
                    PadButton(label: "▼") { onButtonChanged(.dpadDown, $0) }
                }
                .position(x: geo.size.width - 260, y: geo.size.height - 100)

                // ABXY（右側ダイヤモンド配置）
                VStack(spacing: 4) {
                    PadButton(label: "Y") { onButtonChanged(.y, $0) }
                    HStack(spacing: 4) {
                        PadButton(label: "X") { onButtonChanged(.x, $0) }
                        PadButton(label: "B") { onButtonChanged(.b, $0) }
                    }
                    PadButton(label: "A") { onButtonChanged(.a, $0) }
                }
                .position(x: geo.size.width - 90, y: geo.size.height - 120)
            }
        }
    }
}

/// ドラッグで倒す仮想スティック。倒した方向・強さを-1〜1で通知する。
private struct VirtualStick: View {
    var onChange: (Float, Float) -> Void
    private let radius: CGFloat = 50

    @State private var knobOffset: CGSize = .zero

    var body: some View {
        ZStack {
            Circle().fill(Color.white.opacity(0.15)).frame(width: radius * 2, height: radius * 2)
            Circle().fill(Color.white.opacity(0.5)).frame(width: 44, height: 44)
                .offset(knobOffset)
        }
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { value in
                    let dx = value.translation.width
                    let dy = value.translation.height
                    let distance = min(radius, sqrt(dx * dx + dy * dy))
                    let angle = atan2(dy, dx)
                    let clampedX = cos(angle) * distance
                    let clampedY = sin(angle) * distance
                    knobOffset = CGSize(width: clampedX, height: clampedY)
                    // SwiftUIのY軸は下向きが正なので、上向きを正にするため反転する
                    onChange(Float(clampedX / radius), Float(-clampedY / radius))
                }
                .onEnded { _ in
                    knobOffset = .zero
                    onChange(0, 0)
                }
        )
    }
}

/// 押している間だけ色が変わる単一ボタン。
private struct PadButton: View {
    let label: String
    let onChanged: (Bool) -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            Circle().fill(isPressed ? Color.red.opacity(0.8) : Color.white.opacity(0.35))
            Text(label).foregroundColor(.white).font(.headline)
        }
        .frame(width: 50, height: 50)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onChanged(true)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onChanged(false)
                }
        )
    }
}
