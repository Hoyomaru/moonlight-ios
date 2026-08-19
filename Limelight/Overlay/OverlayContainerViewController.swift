import SwiftUI
import UIKit

/// Objective-C側から押下/離上イベントを受け取るためのデリゲート。
@objc public protocol OverlayContainerDelegate: AnyObject {
    func overlayButtonAChanged(_ pressed: Bool)
}

/// Objective-C側 (StreamFrameViewController) から生成・アタッチするための
/// SwiftUIオーバーレイのコンテナ。
@objc(OverlayContainerViewController)
public class OverlayContainerViewController: UIViewController {

    @objc public weak var delegate: OverlayContainerDelegate?

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true // Step3: タップを受け付け始める

        let rootView = OverlayRootView(onButtonAChanged: { [weak self] pressed in
            self?.delegate?.overlayButtonAChanged(pressed)
        })
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
