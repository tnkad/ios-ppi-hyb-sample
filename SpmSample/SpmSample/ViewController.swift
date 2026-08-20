import UIKit
import TnkPpiHyb

/// 오퍼월 진입 두 가지 방식을 보여준다.
///  1. 풀스크린 모달  — 가장 일반적
///  2. 화면 안 삽입    — 매체 탭 안에 오퍼월을 넣는 경우
final class ViewController: UIViewController {

    private var embedded: TnkOfferwallView?

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TnkPpiHyb 샘플"
        view.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [
            button("오퍼월 열기 (풀스크린)", #selector(openFullscreen)),
            button("오퍼월 열기 (헤더 숨김)", #selector(openHideHeader)),
            button("화면 안에 삽입", #selector(openEmbedded)),
        ])
        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24),
        ])
    }

    /// iOS 14 를 지원하므로 UIButton.Configuration(iOS 15+)은 쓰지 않는다.
    private func button(_ title: String, _ action: Selector) -> UIButton {
        let b = UIButton(type: .system)
        b.setTitle(title, for: .normal)
        b.setTitleColor(.white, for: .normal)
        b.titleLabel?.font = .systemFont(ofSize: 16, weight: .medium)
        b.backgroundColor = .systemBlue
        b.layer.cornerRadius = 10
        b.heightAnchor.constraint(equalToConstant: 48).isActive = true
        b.addTarget(self, action: action, for: .touchUpInside)
        return b
    }

    // MARK: - 1. 풀스크린 모달

    @objc private func openFullscreen() {
        TnkPpiHybSdk.shared.openOfferwall(from: self)
    }

    /// 매체가 자체 헤더를 쓰는 경우 오퍼월 상단 바를 숨긴다.
    @objc private func openHideHeader() {
        TnkPpiHybSdk.shared.openOfferwall(from: self, extraParams: ["hideHeader": "1"])
    }

    // MARK: - 2. 화면 안 삽입

    /// TnkOfferwallView 는 UIView 라 원하는 위치에 넣을 수 있다.
    /// ⚠️ 삽입해도 표시되는 것은 오퍼월 전체 화면이다. 특정 광고만 노출하는
    ///    플레이스먼트 뷰는 제공하지 않는다.
    @objc private func openEmbedded() {
        let host = EmbeddedViewController()
        navigationController?.pushViewController(host, animated: true)
    }
}

/// 오퍼월을 화면 일부로 품는 예시.
final class EmbeddedViewController: UIViewController {

    private var offerwall: TnkOfferwallView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "삽입형"
        view.backgroundColor = .systemBackground

        offerwall = TnkOfferwallView(frame: .zero)
        offerwall.translatesAutoresizingMaskIntoConstraints = false
        offerwall.onCloseRequested = { [weak self] in
            self?.navigationController?.popViewController(animated: true)
        }
        // 웹이 상태바 색을 요청하면 호스트가 반영해준다.
        offerwall.onStatusBarStyleChanged = { [weak self] _ in
            self?.setNeedsStatusBarAppearanceUpdate()
        }
        view.addSubview(offerwall)

        NSLayoutConstraint.activate([
            offerwall.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            offerwall.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor),
            offerwall.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            offerwall.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])

        offerwall.loadOfferwall(TnkPpiHybSdk.shared.buildOfferwallURL())
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        offerwall?.requestedStatusBarStyle ?? .default
    }

    deinit {
        offerwall?.cleanup()
    }
}
