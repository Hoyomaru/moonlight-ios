import CoreGraphics
import Foundation

/// 1つの要素（左スティック／十字キー／ABXY）の位置・サイズ情報。
struct OverlayElementLayout: Codable {
    var anchorX: String
    var offsetX: CGFloat
    var anchorY: String
    var offsetY: CGFloat
    var scale: CGFloat
}

/// オーバーレイ全体のレイアウト。
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

/// レイアウトを「ゲームごとに」JSONファイルとして端末に保存・読み込みする。
/// gameIDが空、または該当ゲーム用の保存ファイルがまだ無い場合は defaultLayout を返す
/// （他ゲームの設定を勝手に流用しない）。
final class OverlayLayoutStore {
    static let shared = OverlayLayoutStore()

    private func fileURL(for gameID: String) -> URL {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let safeName = gameID.isEmpty ? "default" : gameID
        return dir.appendingPathComponent("overlay_layout_\(safeName).json")
    }

    func load(gameID: String) -> OverlayLayout {
        guard let data = try? Data(contentsOf: fileURL(for: gameID)),
              let layout = try? JSONDecoder().decode(OverlayLayout.self, from: data) else {
            return .defaultLayout
        }
        return layout
    }

    func save(_ layout: OverlayLayout, gameID: String) {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        try? data.write(to: fileURL(for: gameID), options: .atomic)
    }
}
