import SwiftUI
import UIKit

@objc public enum OverlayButton: Int {
    case a, b, x, y
    case dpadUp, dpadDown, dpadLeft, dpadRight
    case lb, rb
    case start, back
}

extension OverlayButton {
    static let allAssignable: [OverlayButton] = [.a, .b, .x, .y, .lb, .rb, .start, .back, .dpadUp, .dpadDown, .dpadLeft, .dpadRight]

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
        case .start: return "start"
        case .back: return "back"
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
        case .start: return "St"
        case .back: return "Bk"
        }
    }

    static func from(mappingKey: String) -> OverlayButton {
        allAssignable.first { $0.mappingKey == mappingKey } ?? .a
    }
}

/// L2/R2（アナログトリガー）用。ボタン系のフラグとは別経路(updateLeftTrigger/updateRightTrigger)で送る。
@objc public enum OverlayTrigger: Int {
    case left, right
}

@objc public protocol OverlayContainerDelegate: AnyObject {
    func overlayButtonChanged(_ button: OverlayButton, pressed: Bool)
    func overlayLeftStickChanged(x: Float, y: Float)
    func overlayRightStickChanged(x: Float, y: Float)
    func overlayTriggerChanged(_ trigger: OverlayTrigger, pressed: Bool)
}

@objc(OverlayContainerViewController)
public class OverlayContainerViewController: UIViewController {

    @objc public weak var delegate: OverlayContainerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true

        let rootView = OverlayRootView(
            onButtonChanged: { [weak self] button, pressed in
                self?.delegate?.overlayButtonChanged(button, pressed: pressed)
            },
            onLeftStickChanged: { [weak self] x, y in
                self?.delegate?.overlayLeftStickChanged(x: x, y: y)
            },
            onRightStickChanged: { [weak self] x, y in
                self?.delegate?.overlayRightStickChanged(x: x, y: y)
            },
            onTriggerChanged: { [weak self] trigger, pressed in
                self?.delegate?.overlayTriggerChanged(trigger, pressed: pressed)
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
