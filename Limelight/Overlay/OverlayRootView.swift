import SwiftUI

/// オーバーレイの中身（SwiftUI側）。
/// Step C: 右スティック・LB/RB・LT/RT・Start/Backを追加したフルボタン版。
struct OverlayRootView: View {
    var onButtonChanged: (OverlayButton, Bool) -> Void
    var onLeftStickChanged: (Float, Float) -> Void
    var onRightStickChanged: (Float, Float) -> Void
    var onTriggerChanged: (OverlayTrigger, Bool) -> Void

    @State private var currentProfile: String
    @State private var layout: OverlayLayout
    @State private var isEditing = false
    @State private var activeResizeKeyPath: WritableKeyPath<OverlayLayout, OverlayElementLayout>?
    @State private var resizeBaseScale: CGFloat = 1.0

    @State private var showRenameAlert = false
    @State private var renameTarget = ""
    @State private var renameText = ""

    init(onButtonChanged: @escaping (OverlayButton, Bool) -> Void,
         onLeftStickChanged: @escaping (Float, Float) -> Void,
         onRightStickChanged: @escaping (Float, Float) -> Void,
         onTriggerChanged: @escaping (OverlayTrigger, Bool) -> Void) {
        let profile = OverlayProfileStore.shared.currentProfileName
        _currentProfile = State(initialValue: profile)
        _layout = State(initialValue: OverlayProfileStore.shared.load(profile: profile))
        self.onButtonChanged = onButtonChanged
        self.onLeftStickChanged = onLeftStickChanged
        self.onRightStickChanged = onRightStickChanged
        self.onTriggerChanged = onTriggerChanged
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                draggableGroup(size: geo.size, keyPath: \.leftStick) {
                    VirtualStick(onChange: onLeftStickChanged)
                        .scaleEffect(layout.leftStick.scale)
                }

                draggableGroup(size: geo.size, keyPath: \.rightStick) {
                    VirtualStick(onChange: onRightStickChanged)
                        .scaleEffect(layout.rightStick.scale)
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

                // LB + LT
                draggableGroup(size: geo.size, keyPath: \.leftShoulder) {
                    VStack(spacing: 4) {
                        PadButton(slot: "left_shoulder_lb", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        TriggerButton(label: "LT", trigger: .left, onChanged: onTriggerChanged)
                    }
                    .scaleEffect(layout.leftShoulder.scale)
                }

                // RB + RT
                draggableGroup(size: geo.size, keyPath: \.rightShoulder) {
                    VStack(spacing: 4) {
                        PadButton(slot: "right_shoulder_rb", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        TriggerButton(label: "RT", trigger: .right, onChanged: onTriggerChanged)
                    }
                    .scaleEffect(layout.rightShoulder.scale)
                }

                // Start + Back
                draggableGroup(size: geo.size, keyPath: \.menu) {
                    HStack(spacing: 4) {
                        PadButton(slot: "menu_back", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                        PadButton(slot: "menu_start", mapping: $layout.buttonMapping, onButtonChanged: onButtonChanged) { saveLayout() }
                    }
                    .scaleEffect(layout.menu.scale)
                }

                // 編集モード切り替えボタン
                Circle()
                    .fill(isEditing ? Color.orange.opacity(0.85) : Color.green.opacity(0.6))
                    .frame(width: 36, height: 36)
                    .overlay(Text(isEditing ? "済" : "編").foregroundColor(.white).font(.caption))
                    .position(x: geo.size.width - 30, y: 30)
                    .onTapGesture { isEditing.toggle() }

                // プロファイル切り替えボタン
                Circle()
                    .fill(Color.blue.opacity(0.7))
                    .frame(width: 36, height: 36)
                    .overlay(Text("P").foregroundColor(.white).font(.caption))
                    .position(x: geo.size.width - 30, y: 74)
                    .contextMenu {
                        ForEach(OverlayProfileStore.shared.listProfiles(), id: \.self) { name in
                            Menu(name == currentProfile ? "✓ \(name)" : name) {
                                Button("これに切り替え") { switchProfile(to: name) }
                                Button("名前を変更") {
                                    renameTarget = name
                                    renameText = name
                                    showRenameAlert = true
                                }
                                Button("削除", role: .destructive) { deleteProfile(name) }
                            }
                        }
                        Button("新規プロファイルを作成") { createNewProfile() }
                    }

                Text(currentProfile)
                    .font(.caption2)
                    .foregroundColor(.white.opacity(0.6))
                    .position(x: geo.size.width - 30, y: 96)
            }
            .coordinateSpace(name: "overlay")
        }
        .alert("プロファイル名を変更", isPresented: $showRenameAlert) {
            TextField("名前", text: $renameText)
            Button("変更") {
                OverlayProfileStore.shared.rename(renameTarget, to: renameText)
                if currentProfile == renameTarget {
                    currentProfile = OverlayProfileStore.shared.currentProfileName
                }
            }
            Button("キャンセル", role: .cancel) {}
        }
    }

    private func saveLayout() {
        OverlayProfileStore.shared.save(layout, profile: currentProfile)
    }

    private func switchProfile(to name: String) {
        currentProfile = name
        OverlayProfileStore.shared.currentProfileName = name
        layout = OverlayProfileStore.shared.load(profile: name)
    }

    private func createNewProfile() {
        let existing = Set(OverlayProfileStore.shared.listProfiles())
        var index = 1
        var candidate = "profile\(index)"
        while existing.contains(candidate) {
            index += 1
            candidate = "profile\(index)"
        }
        OverlayProfileStore.shared.save(layout, profile: candidate)
        switchProfile(to: candidate)
    }

    private func deleteProfile(_ name: String) {
        let remaining = OverlayProfileStore.shared.listProfiles().filter { $0 != name }
        guard !remaining.isEmpty else { return }
        OverlayProfileStore.shared.delete(profile: name)
        if currentProfile == name {
            let newCurrent = OverlayProfileStore.shared.currentProfileName
            currentProfile = newCurrent
            layout = OverlayProfileStore.shared.load(profile: newCurrent)
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

/// L2/R2用。押している間は最大値、離すと0を送る（アナログの踏み込み具合は今回非対応）。
private struct TriggerButton: View {
    let label: String
    let trigger: OverlayTrigger
    let onChanged: (OverlayTrigger, Bool) -> Void

    @State private var isPressed = false

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isPressed ? Color.red.opacity(0.8) : Color.white.opacity(0.25))
            Text(label).foregroundColor(.white).font(.caption).bold()
        }
        .frame(width: 50, height: 34)
        .gesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        isPressed = true
                        onChanged(trigger, true)
                    }
                }
                .onEnded { _ in
                    isPressed = false
                    onChanged(trigger, false)
                }
        )
    }
}
