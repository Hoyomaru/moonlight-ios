import CoreGraphics
import Foundation

/// 1つの要素（左スティック／十字キー／ABXY）の位置・サイズ情報。
/// 画面端からのオフセットで保持する（画面サイズが変わっても自然な位置になるように）。
struct OverlayElementLayout: Codable {
    var anchorX: String   // "leading" または "trailing"
    var offsetX: CGFloat
    var anchorY: String   // "top" または "bottom"
    var offsetY: CGFloat
    var scale: CGFloat    // 1.0が標準サイズ
}

/// オーバーレイ全体のレイアウト。ゲームごとのプロファイルはPhase4の後半で対応する。
struct OverlayLayout: Codable {
    var leftStick: OverlayElementLayout
    var dpad: OverlayElementLayout
    var abxy: OverlayElementLayout

    static let defaultLayout = OverlayLayout(
        leftStick: OverlayElementLayout(anchorX: "leading", offsetX: 80, anchorY: "bottom", offsetY: 120, scale: 1.0),
        dpad: OverlayElementLayout(anchorX: "trailing", offsetX: 260, anchorY: "bottom", offsetY: 100, scale: 1.0),
        abxy: OverlayElementLayout(anchorX: "trailing", offsetX: 90, anchorY: "bottom", offsetY: 120, scale: 1.0)
    )

    func resolvedPosition(for element: OverlayElementLayout, in size: CGSize) -> CGPoint {
        let x = element.anchorX == "leading" ? element.offsetX : size.width - element.offsetX
        let y = element.anchorY == "top" ? element.offsetY : size.height - element.offsetY
        return CGPoint(x: x, y: y)
    }
}

/// レイアウトをJSONファイルとして端末に保存・読み込みする。
final class OverlayLayoutStore {
    static let shared = OverlayLayoutStore()

    private let fileURL: URL

    private init() {
        let dir = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        fileURL = dir.appendingPathComponent("overlay_layout.json")
    }

    func load() -> OverlayLayout {
        guard let data = try? Data(contentsOf: fileURL),
              let layout = try? JSONDecoder().decode(OverlayLayout.self, from: data) else {
            return .defaultLayout
        }
        return layout
    }

    func save(_ layout: OverlayLayout) {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        try? data.write(to: fileURL, options: .atomic)
    }
}
