import SwiftUI
import UIKit

/// Objective-C側 (StreamFrameViewController) から生成・アタッチするための
/// SwiftUIオーバーレイのコンテナ。ジェネリクスを含む UIHostingController を
/// 直接 Objective-C に見せられないため、この非ジェネリックなラッパーを介する。
@objc(OverlayContainerViewController)
public class OverlayContainerViewController: UIViewController {

    public override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .clear
        view.isUserInteractionEnabled = false // Step2ではまだ入力を奪わない

        let hosting = UIHostingController(rootView: OverlayRootView())
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
