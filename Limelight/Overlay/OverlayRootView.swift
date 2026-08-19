import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step4-3: 編集モードでのドラッグ移動＋ピンチリサイズ、通常モードでの長押しキー割り当て変更に対応。
struct OverlayRootView: View {
    let gameID: String
    var onButtonChanged: (OverlayButton, Bool) -> Void
    var onLeftStickChanged: (Float, Float) -> Void

    @State private var layout: OverlayLayout
    @State private var isEditing = false
    @State private var activeResizeKeyPath: WritableKeyPath<OverlayLayout, OverlayElementLayout>?
    @State private var resizeBaseScale: CGFloat = 1.0

    init(gameID: String,
         layout: OverlayLayout,
         onButtonChanged: @escaping (OverlayButton, Bool) -> Void,
         onLeftStickChanged: @escaping (Float, Float) -> Void) {
        self.gameID = gameID
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
                        PadButton(slot: "dpad_up", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        HStack(spacing: 4) {
                            PadButton(slot: "dpad_left", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                            PadButton(slot: "dpad_right", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        }
                        PadButton(slot: "dpad_down", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                    }
                    .scaleEffect(layout.dpad.scale)
                }

                draggableGroup(size: geo.size, keyPath: \.abxy) {
                    VStack(spacing: 4) {
                        PadButton(slot: "abxy_top", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        HStack(spacing: 4) {
                            PadButton(slot: "abxy_left", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                            PadButton(slot: "abxy_right", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        }
                        PadButton(slot: "abxy_bottom", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                    }
                    .scaleEffect(layout.abxy.scale)
                }

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

    private func saveLayout() {
        OverlayLayoutStore.shared.save(layout, gameID: gameID)
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
                .allowsHitTesting(false)
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Color.yellow, lineWidth: 2).padding(-8))
                .contentShape(Rectangle().size(width: 110, height: 110))
                .position(position)
                .gesture(
                    DragGesture(minimumDistance: 0, coordinateSpace: .named("overlay"))
                        .onChanged { value in
                            updatePosition(keyPath: keyPath, dragLocation: value.location, size: size)
                        }
                        .onEnded { _ in saveLayout() }
                )
                .simultaneousGesture(
                    MagnificationGesture()
                        .onChanged { value in
                            if activeResizeKeyPath == nil {
                                activeResizeKeyPath = keyPath
                                resizeBaseScale = layout[keyPath: keyPath].scale
                            }
                            if activeResizeKeyPath == keyPath {
                                var element = layout[keyPath: keyPath]
                                element.scale = min(2.0, max(0.5, resizeBaseScale * value))
                                layout[keyPath: keyPath] = element
                            }
                        }
                        .onEnded { _ in
                            activeResizeKeyPath = nil
                            saveLayout()
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

/// 押している間だけ色が変わり、長押しで割り当て変更メニューを出すボタン。
private struct PadButton: View {
    let slot: String
    @Binding var mapping: [String: String]
    let onButtonChanged: (OverlayButton, Bool) -> Void
    let onMappingChanged: () -> Void

    @State private var isPressed = false

    private var assignedButton: OverlayButton {
        OverlayButton.from(mappingKey: mapping[slot] ?? "")
    }

    var body: some View {
        ZStack {
            Circle().fill(isPressed ? Color.red.opacity(0.8) : Color.white.opacity(0.35))
            Text(assignedButton.displayLabel).foregroundColor(.white).font(.headline)
        }
        .frame(width: 50, height: 50)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onButtonChanged(assignedButton, true)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onButtonChanged(assignedButton, false)
                }
        )
        .contextMenu {
            ForEach(OverlayButton.allAssignable, id: \.mappingKey) { candidate in
                Button(candidate.displayLabel) {
                    mapping[slot] = candidate.mappingKey
                    onMappingChanged()
                }
            }
        }
    }
}
