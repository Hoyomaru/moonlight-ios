import CoreGraphics
import Foundation

struct OverlayElementLayout: Codable {
    var anchorX: String
    var offsetX: CGFloat
    var anchorY: String
    var offsetY: CGFloat
    var scale: CGFloat
}

struct OverlayLayout: Codable {
    var leftStick: OverlayElementLayout
    var dpad: OverlayElementLayout
    var abxy: OverlayElementLayout
    var buttonMapping: [String: String]

    static let defaultButtonMapping: [String: String] = [
        "abxy_top": "y", "abxy_left": "x", "abxy_right": "b", "abxy_bottom": "a",
        "dpad_up": "dpadUp", "dpad_down": "dpadDown", "dpad_left": "dpadLeft", "dpad_right": "dpadRight"
    ]

    static let defaultLayout = OverlayLayout(
        leftStick: OverlayElementLayout(anchorX: "leading", offsetX: 80, anchorY: "bottom", offsetY: 120, scale: 1.0),
        dpad: OverlayElementLayout(anchorX: "trailing", offsetX: 260, anchorY: "bottom", offsetY: 100, scale: 1.0),
        abxy: OverlayElementLayout(anchorX: "trailing", offsetX: 90, anchorY: "bottom", offsetY: 120, scale: 1.0),
        buttonMapping: defaultButtonMapping
    )

    func resolvedPosition(for element: OverlayElementLayout, in size: CGSize) -> CGPoint {
        let x = element.anchorX == "leading" ? element.offsetX : size.width - element.offsetX
        let y = element.anchorY == "top" ? element.offsetY : size.height - element.offsetY
        return CGPoint(x: x, y: y)
    }
}

/// レイアウトを「手動で選んだプロファイル名」ごとにJSON保存・読込する。
/// 現在選択中のプロファイル名はUserDefaultsに記憶し、次回起動時も引き継ぐ。
final class OverlayProfileStore {
    static let shared = OverlayProfileStore()

    private let currentProfileKey = "OverlayCurrentProfileName"
    private let filePrefix = "overlay_layout_"

    private var documentsDir: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }

    private func fileURL(for profile: String) -> URL {
        documentsDir.appendingPathComponent("\(filePrefix)\(profile).json")
    }

    var currentProfileName: String {
        get { UserDefaults.standard.string(forKey: currentProfileKey) ?? "default" }
        set { UserDefaults.standard.set(newValue, forKey: currentProfileKey) }
    }

    func listProfiles() -> [String] {
        let names = (try? FileManager.default.contentsOfDirectory(atPath: documentsDir.path)) ?? []
        var profiles = names
            .filter { $0.hasPrefix(filePrefix) && $0.hasSuffix(".json") }
            .map { String($0.dropFirst(filePrefix.count).dropLast(".json".count)) }
        if !profiles.contains("default") {
            profiles.append("default")
        }
        return profiles.sorted()
    }

    func load(profile: String) -> OverlayLayout {
        guard let data = try? Data(contentsOf: fileURL(for: profile)),
              let layout = try? JSONDecoder().decode(OverlayLayout.self, from: data) else {
            return .defaultLayout
        }
        return layout
    }

    func save(_ layout: OverlayLayout, profile: String) {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        try? data.write(to: fileURL(for: profile), options: .atomic)
    }

    /// プロファイルを削除する。削除したものが選択中だった場合はdefaultに切り替える。
    func delete(profile: String) {
        try? FileManager.default.removeItem(at: fileURL(for: profile))
        if currentProfileName == profile {
            currentProfileName = "default"
        }
    }

    /// プロファイル名を変更する。中身はそのまま新しい名前のファイルへ引き継ぐ。
    func rename(_ oldName: String, to newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, trimmed != oldName else { return }

        let layout = load(profile: oldName)
        save(layout, profile: trimmed)
        try? FileManager.default.removeItem(at: fileURL(for: oldName))

        if currentProfileName == oldName {
            currentProfileName = trimmed
        }
    }
}
