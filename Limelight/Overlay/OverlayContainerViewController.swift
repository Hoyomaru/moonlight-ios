import SwiftUI
import UIKit

/// Objective-C側に伝える論理ボタン種別。
/// Swiftの@objc enumはObjective-C側で OverlayButtonA のような名前になる。
@objc public enum OverlayButton: Int {
    case a, b, x, y
    case dpadUp, dpadDown, dpadLeft, dpadRight
    case lb, rb
}

extension OverlayButton {
    static let allAssignable: [OverlayButton] = [.a, .b, .x, .y, .lb, .rb, .dpadUp, .dpadDown, .dpadLeft, .dpadRight]

    var mappingKey: String {
        switch self {
        case .a: return "a"
        case .b: return "b"
        case .x: return "x"
        case .y: return "y"
        case .dpadUp: return "dpadUp"
        case .dpadDown: return "dpadDown"
        case .dpadLeft: return "dpadLeft"
        case .dpadRight: return "dpadRight"
        case .lb: return "lb"
        case .rb: return "rb"
        }
    }

    var displayLabel: String {
        switch self {
        case .a: return "A"
        case .b: return "B"
        case .x: return "X"
        case .y: return "Y"
        case .dpadUp: return "▲"
        case .dpadDown: return "▼"
        case .dpadLeft: return "◀"
        case .dpadRight: return "▶"
        case .lb: return "LB"
        case .rb: return "RB"
        }
    }

    static func from(mappingKey: String) -> OverlayButton {
        allAssignable.first { $0.mappingKey == mappingKey } ?? .a
    }
}

/// Objective-C側がボタン/スティックのイベントを受け取るためのデリゲート。
@objc public protocol OverlayContainerDelegate: AnyObject {
    func overlayButtonChanged(_ button: OverlayButton, pressed: Bool)
    func overlayLeftStickChanged(x: Float, y: Float)
}

/// Objective-C側 (StreamFrameViewController) から生成・アタッチするための
/// SwiftUIオーバーレイのコンテナ。
@objc(OverlayContainerViewController)
public class OverlayContainerViewController: UIViewController {

    @objc public weak var delegate: OverlayContainerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let rootView = OverlayRootView(
            layout: OverlayLayoutStore.shared.load(),
            onButtonChanged: { [weak self] button, pressed in
                self?.delegate?.overlayButtonChanged(button, pressed: pressed)
            },
            onLeftStickChanged: { [weak self] x, y in
                self?.delegate?.overlayLeftStickChanged(x: x, y: y)
            }
        )
        let hosting = UIHostingController(rootView: rootView)
        hosting.view.backgroundColor = .clear

        addChild(hosting)
        view.addSubview(hosting.view)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        hosting.didMove(toParent: self)
    }
}
