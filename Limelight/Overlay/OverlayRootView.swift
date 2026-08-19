import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step4-2: 右上のボタンで編集モードに切り替え、各グループをドラッグで移動→自動保存できるようにする。
struct OverlayRootView: View {
    var onButtonChanged: (OverlayButton, Bool) -> Void
    var onLeftStickChanged: (Float, Float) -> Void

    @State private var layout: OverlayLayout
    @State private var isEditing = false

    init(layout: OverlayLayout,
         onButtonChanged: @escaping (OverlayButton, Bool) -> Void,
         onLeftStickChanged: @escaping (Float, Float) -> Void) {
        _layout = State(initialValue: layout)
        self.onButtonChanged = onButtonChanged
        self.onLeftStickChanged = onLeftStickChanged
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                draggableGroup(size: geo.size, keyPath: \.leftStick) {
                    VirtualStick(onChange: onLeftStickChanged)
                        .scaleEffect(layout.leftStick.scale)
                }

                draggableGroup(size: geo.size, keyPath: \.dpad) {
                    VStack(spacing: 4) {
                        PadButton(label: "▲") { onButtonChanged(.dpadUp, $0) }
                        HStack(spacing: 4) {
                            PadButton(label: "◀") { onButtonChanged(.dpadLeft, $0) }
                            PadButton(label: "▶") { onButtonChanged(.dpadRight, $0) }
                        }
                        PadButton(label: "▼") { onButtonChanged(.dpadDown, $0) }
                    }
                    .scaleEffect(layout.dpad.scale)
                }

                draggableGroup(size: geo.size, keyPath: \.abxy) {
                    VStack(spacing: 4) {
                        PadButton(label: "Y") { onButtonChanged(.y, $0) }
                        HStack(spacing: 4) {
                            PadButton(label: "X") { onButtonChanged(.x, $0) }
                            PadButton(label: "B") { onButtonChanged(.b, $0) }
                        }
                        PadButton(label: "A") { onButtonChanged(.a, $0) }
                    }
                    .scaleEffect(layout.abxy.scale)
                }

                // 編集モード切り替えボタン
                Circle()
                    .fill(isEditing ? Color.orange.opacity(0.85) : Color.green.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .overlay(Text(isEditing ? "済" : "編").foregroundColor(.white).font(.caption))
                    .position(x: geo.size.width - 30, y: 30)
                    .onTapGesture {
                        isEditing.toggle()
                    }
            }
            .coordinateSpace(name: "overlay")
        }
    }

    @ViewBuilder
    private func draggableGroup<Content: View>(
        size: CGSize,
        keyPath: WritableKeyPath<OverlayLayout, OverlayElementLayout>,
        @ViewBuilder content: () -> Content
    ) -> some View {
        let position = layout.resolvedPosition(for: layout[keyPath: keyPath], in: size)

        if isEditing {
            content()
                .allowsHitTesting(false) // 編集中はボタンとしての反応を止める
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow, lineWidth: 2).padding(-8))
                .contentShape(Rectangle().size(width: 100, height: 100))
                .position(position)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("overlay"))
                        .onChanged { value in
                            updatePosition(keyPath: keyPath, dragLocation: value.location, size: size)
                        }
                        .onEnded { _ in
                            OverlayLayoutStore.shared.save(layout)
                        }
                )
        } else {
            content()
                .position(position)
        }
    }

    private func updatePosition(keyPath: WritableKeyPath<OverlayLayout, OverlayElementLayout>, dragLocation: CGPoint, size: CGSize) {
        var element = layout[keyPath: keyPath]
        element.offsetX = element.anchorX == "leading" ? dragLocation.x : size.width - dragLocation.x
        element.offsetY = element.anchorY == "top" ? dragLocation.y : size.height - dragLocation.y
        layout[keyPath: keyPath] = element
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
