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
    var rightStick: OverlayElementLayout
    var dpad: OverlayElementLayout
    var abxy: OverlayElementLayout
    var leftShoulder: OverlayElementLayout   // LB + LT
    var rightShoulder: OverlayElementLayout  // RB + RT
    var menu: OverlayElementLayout           // Start + Back
    var buttonMapping: [String: String]

    private enum CodingKeys: String, CodingKey {
        case leftStick, rightStick, dpad, abxy, leftShoulder, rightShoulder, menu, buttonMapping
    }

    init(leftStick: OverlayElementLayout, rightStick: OverlayElementLayout, dpad: OverlayElementLayout,
         abxy: OverlayElementLayout, leftShoulder: OverlayElementLayout, rightShoulder: OverlayElementLayout,
         menu: OverlayElementLayout, buttonMapping: [String: String]) {
        self.leftStick = leftStick
        self.rightStick = rightStick
        self.dpad = dpad
        self.abxy = abxy
        self.leftShoulder = leftShoulder
        self.rightShoulder = rightShoulder
        self.menu = menu
        self.buttonMapping = buttonMapping
    }

    /// 古いバージョンで保存された（新項目を含まない）JSONも壊さず読めるように、
    /// 足りない項目はデフォルト値で補って読み込む。
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        let d = OverlayLayout.defaultLayout
        leftStick = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .leftStick) ?? d.leftStick
        rightStick = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .rightStick) ?? d.rightStick
        dpad = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .dpad) ?? d.dpad
        abxy = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .abxy) ?? d.abxy
        leftShoulder = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .leftShoulder) ?? d.leftShoulder
        rightShoulder = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .rightShoulder) ?? d.rightShoulder
        menu = try c.decodeIfPresent(OverlayElementLayout.self, forKey: .menu) ?? d.menu
        buttonMapping = try c.decodeIfPresent([String: String].self, forKey: .buttonMapping) ?? OverlayLayout.defaultButtonMapping
    }

    static let defaultButtonMapping: [String: String] = [
        "abxy_top": "y", "abxy_left": "x", "abxy_right": "b", "abxy_bottom": "a",
        "dpad_up": "dpadUp", "dpad_down": "dpadDown", "dpad_left": "dpadLeft", "dpad_right": "dpadRight",
        "left_shoulder_lb": "lb", "right_shoulder_rb": "rb",
        "menu_start": "start", "menu_back": "back"
    ]

    static let defaultLayout = OverlayLayout(
        leftStick: OverlayElementLayout(anchorX: "leading", offsetX: 80, anchorY: "bottom", offsetY: 120, scale: 1.0),
        rightStick: OverlayElementLayout(anchorX: "trailing", offsetX: 200, anchorY: "bottom", offsetY: 260, scale: 1.0),
        dpad: OverlayElementLayout(anchorX: "trailing", offsetX: 260, anchorY: "bottom", offsetY: 100, scale: 1.0),
        abxy: OverlayElementLayout(anchorX: "trailing", offsetX: 90, anchorY: "bottom", offsetY: 120, scale: 1.0),
        leftShoulder: OverlayElementLayout(anchorX: "leading", offsetX: 60, anchorY: "top", offsetY: 60, scale: 1.0),
        rightShoulder: OverlayElementLayout(anchorX: "trailing", offsetX: 60, anchorY: "top", offsetY: 150, scale: 1.0),
        menu: OverlayElementLayout(anchorX: "leading", offsetX: 60, anchorY: "bottom", offsetY: 280, scale: 1.0),
        buttonMapping: defaultButtonMapping
    )

    func resolvedPosition(for element: OverlayElementLayout, in size: CGSize) -> CGPoint {
        let x = element.anchorX == "leading" ? element.offsetX : size.width - element.offsetX
        let y = element.anchorY == "top" ? element.offsetY : size.height - element.offsetY
        return CGPoint(x: x, y: y)
    }
}

/// レイアウトを「手動で選んだプロファイル名」ごとにJSON保存・読込する。
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
        if profiles.isEmpty {
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

    func delete(profile: String) {
        try? FileManager.default.removeItem(at: fileURL(for: profile))
        if currentProfileName == profile {
            currentProfileName = "default"
        }
    }

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
