import UIKit
import TnkPpiHyb

/// 오퍼월 진입 두 가지 방식과 개인정보 동의 철회를 보여준다.
///  1. 풀스크린 모달  — 가장 일반적
///  2. 화면 안 삽입    — 매체 탭 안에 오퍼월을 넣는 경우
///  3. 동의 철회      — 매체 앱의 "개인정보 동의 철회" 동작에서 호출 (SDK 1.0.5 이상)
final class ViewController: UIViewController {

    private var embedded: TnkOfferwallView?

    /// 샘플 편의 기능 — SDK 기능 아님. 파일 아래쪽 `FloatingBackButton` 참고.
    private let floatingBack = FloatingBackButton()

    /// 이 화면이 한 번이라도 나타났는지. 딥링크로 앱이 처음 뜨는 경우 버튼 요청이 첫 화면이 나타나기 전에 들어온다.
    private var hasAppeared = false
    /// 첫 화면이 나타나기 전에 들어온 버튼 요청 — 나타난 뒤에 띄운다. (아래 viewDidAppear 의 hide() 에 곧바로 지워지지 않게)
    private var pendingScene: UIWindowScene?

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        // 이 화면이 완전히 다시 보이면 플로팅 버튼도 치운다. (오퍼월 X·내비게이션 뒤로 버튼·스와이프로 돌아온 경우 모두.
        // 가장자리 스와이프를 하다 취소하면 이 메서드가 불리지 않으므로 버튼이 그대로 남는다.)
        floatingBack.hide()
        hasAppeared = true
        if let scene = pendingScene {
            pendingScene = nil
            showFloatingBackToHome(in: scene)
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "TnkPpiHyb 샘플"
        view.backgroundColor = .systemBackground

        let stack = UIStackView(arrangedSubviews: [
            button("오퍼월 열기 (풀스크린)", #selector(openFullscreen)),
            button("오퍼월 열기 (헤더 숨김)", #selector(openHideHeader)),
            button("화면 안에 삽입", #selector(openEmbedded)),
            button("개인정보 동의 철회", #selector(revokeConsent)),
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

    /// 기존 UIButton 스타일 API 로 구성한다. (UIButton.Configuration 을 써도 되지만 샘플은 단순함을 위해 쓰지 않는다.)
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

        // 샘플 편의 기능 — SDK 기능 아님. 풀스크린 오퍼월 위에 "뒤로" 플로팅 버튼을 띄운다.
        // 누르면 오퍼월 안의 이전 페이지가 아니라 샘플 메인 화면으로 바로 돌아간다. (이 화면이 자기가 띄운 오퍼월을 닫는다.)
        floatingBack.show(in: view.window?.windowScene) { [weak self] in
            self?.dismiss(animated: true)
        }
    }

    /// 매체가 자체 헤더를 쓰는 경우 오퍼월 상단 바를 숨긴다.
    /// 풀스크린 모달로 띄우면 헤더가 없어 닫을 방법이 없으므로, 앱 내비게이션 스택에 push 해서
    /// 앱의 내비게이션 바(뒤로 버튼)와 왼쪽 가장자리 스와이프로 돌아오게 한다.
    @objc private func openHideHeader() {
        let host = EmbeddedViewController()
        host.title = "헤더 숨김"
        host.extraParams = ["hideHeader": "1"]
        navigationController?.pushViewController(host, animated: true)
        showFloatingBackToHome()
    }

    // MARK: - 2. 화면 안 삽입

    /// TnkOfferwallView 는 UIView 라 원하는 위치에 넣을 수 있다.
    /// ⚠️ 삽입해도 표시되는 것은 오퍼월 전체 화면이다. 특정 광고만 노출하는
    ///    플레이스먼트 뷰는 제공하지 않는다.
    @objc private func openEmbedded() {
        let host = EmbeddedViewController()
        navigationController?.pushViewController(host, animated: true)
        showFloatingBackToHome()
    }

    /// 샘플 편의 기능 — SDK 기능 아님. push 한 오퍼월 화면(헤더 숨김·삽입)과 딥링크로 연 오퍼월 위에 "뒤로" 플로팅 버튼을 띄운다.
    /// 누르면 오퍼월 안의 이전 페이지가 아니라 샘플 메인 화면으로 바로 돌아간다. 연동에 필요한 코드는 아니다.
    /// 딥링크는 이 화면이 가려져 있어도 들어오므로, 창(scene)은 호출하는 쪽이 넘긴다.
    func showFloatingBackToHome(in scene: UIWindowScene? = nil) {
        let scene = scene ?? view.window?.windowScene
        guard hasAppeared else {
            pendingScene = scene   // 첫 화면이 아직 나타나기 전 — 나타난 뒤 띄운다
            return
        }
        floatingBack.show(in: scene) { [weak self] in
            self?.floatingBack.hide()   // 화면이 안 떠 있어도 버튼은 치운다
            // 위에 떠 있는 화면이 있으면 먼저 닫고 홈으로
            self?.dismiss(animated: false)
            self?.navigationController?.popToRootViewController(animated: true)
        }
    }

    // MARK: - 3. 개인정보 동의 철회

    /// 사용자가 앱에서 "동의 철회"를 눌렀을 때만 호출한다. 반환값은 없고 SDK 가 화면을 띄우지도 않는다.
    /// ⚠️ 앱 시작·화면 복귀(viewDidAppear, sceneDidBecomeActive 등)에서 자동으로 부르지 않는다.
    ///    호출할 때마다 열려 있는 오퍼월이 첫 화면으로 다시 로드된다.
    /// ⚠️ 철회한 사용자에게 `setAgreePrivacy(true)` 를 다시 부르면 철회가 취소된다.
    @objc private func revokeConsent() {
        TnkPpiHybSdk.shared.revokePrivacyConsent()

        // 반환값이 없으므로 샘플은 호출했다는 사실만 보여준다.
        let alert = UIAlertController(
            title: "동의 철회",
            message: "개인정보 동의를 철회했습니다.\n이후 오퍼월에 들어가면 동의 팝업이 먼저 나옵니다.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "확인", style: .default))
        present(alert, animated: true)
    }
}

/// 오퍼월을 화면 일부로 품는 예시.
final class EmbeddedViewController: UIViewController {

    /// 오퍼월 주소에 덧붙일 쿼리 파라미터. 예: `["hideHeader": "1"]`
    var extraParams: [String: String]?

    private var offerwall: TnkOfferwallView!

    override func viewDidLoad() {
        super.viewDidLoad()
        title = title ?? "삽입형"
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

        offerwall.loadOfferwall(TnkPpiHybSdk.shared.buildOfferwallURL(extraParams: extraParams))
    }

    override var preferredStatusBarStyle: UIStatusBarStyle {
        offerwall?.requestedStatusBarStyle ?? .default
    }

    deinit {
        offerwall?.cleanup()
    }
}

// MARK: - 샘플 편의 기능 (SDK 기능 아님)

/// 오퍼월 위에 "뒤로" 플로팅 버튼 하나를 띄우는 샘플 전용 도우미.
/// 샘플이 직접 만든 투명한 UIWindow 안의 버튼일 뿐이며, SDK 가 띄운 화면에는 접근하지 않는다.
/// SDK 연동에 필요한 코드는 아니다.
final class FloatingBackButton {

    private var window: UIWindow?

    func show(in scene: UIWindowScene?, onTap: @escaping () -> Void) {
        guard let scene else { return }
        hide()   // 남아 있는 버튼이 있으면 치우고 새 onTap 으로 다시 띄운다

        let root = UIViewController()
        root.view.backgroundColor = .clear

        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "chevron.backward"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 22
        button.accessibilityLabel = "뒤로"
        button.addAction(UIAction { _ in onTap() }, for: .touchUpInside)
        button.translatesAutoresizingMaskIntoConstraints = false
        root.view.addSubview(button)

        // 왼쪽 아래 — 오퍼월 상단의 닫기(X)·탭과 겹치지 않는 자리
        NSLayoutConstraint.activate([
            button.widthAnchor.constraint(equalToConstant: 44),
            button.heightAnchor.constraint(equalToConstant: 44),
            button.leadingAnchor.constraint(equalTo: root.view.safeAreaLayoutGuide.leadingAnchor, constant: 16),
            button.bottomAnchor.constraint(equalTo: root.view.safeAreaLayoutGuide.bottomAnchor, constant: -16),
        ])

        let window = PassthroughWindow(windowScene: scene)
        window.windowLevel = .normal + 1      // 오퍼월(일반 창) 위
        window.backgroundColor = .clear
        window.rootViewController = root
        window.isHidden = false               // makeKeyAndVisible 은 부르지 않는다 — 키 창은 그대로 둔다
        self.window = window
    }

    func hide() {
        window?.isHidden = true
        window = nil
    }
}

/// 버튼 바깥 터치는 아래의 오퍼월로 그대로 통과시키는 창.
private final class PassthroughWindow: UIWindow {
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        let hit = super.hitTest(point, with: event)
        return hit === rootViewController?.view ? nil : hit
    }
}
