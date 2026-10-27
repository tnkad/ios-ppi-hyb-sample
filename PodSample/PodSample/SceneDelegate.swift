import UIKit
import TnkPpiHyb

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    /// 샘플 편의 기능용 — 첫 화면 참조. SDK 연동과 무관하다.
    private weak var home: ViewController?

    /// ATT 프롬프트는 1회만. sceneDidBecomeActive 는 포그라운드 복귀마다 불린다.
    private var didRequestATT = false

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        // ── SDK 초기화 (앱 시작 시 1회) ────────────────────────────────
        let sdk = TnkPpiHybSdk.shared
        sdk.enableLogging(true)
        sdk.configure(appId: "발급받은-앱-아이디")
        sdk.setUserName("매체측-사용자-식별값")   // 보상 지급 대상 식별값
        sdk.applicationStarted()

        // 보상 지급 완료 콜백 — 항상 메인 스레드
        sdk.setRewardListener { reward in
            print("[Sample] 보상 지급: \(reward.appId) / \(reward.payPoint)\(reward.pointUnit ?? "")")
        }

        let window = UIWindow(windowScene: windowScene)
        let home = ViewController()
        self.home = home
        window.rootViewController = UINavigationController(rootViewController: home)
        self.window = window
        window.makeKeyAndVisible()

        // 콜드스타트 딥링크 — 딥링크로 앱이 처음 뜨는 경로.
        // 앱이 막 시작되는 시점이라 오퍼월을 띄울 화면(window.rootViewController)을 함께 넘긴다.
        connectionOptions.urlContexts.forEach { handleDeeplink($0.url, from: window.rootViewController) }
    }

    /// 앱이 이미 떠 있을 때 들어오는 딥링크
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { handleDeeplink($0.url, from: window?.rootViewController) }
    }

    /// tnkscheme:// 은 SDK 에 위임하고, 나머지는 매체가 직접 처리한다.
    /// 앱이 꺼진 상태에서 실행될 때(willConnectTo)와 앱이 떠 있을 때(openURLContexts, 백그라운드 복귀 포함) 모두
    /// `presenter` 로 오퍼월을 띄울 화면을 넘긴다. 알림·모달을 띄워 둔 상태는 README §4 참고.
    private func handleDeeplink(_ url: URL, from presenter: UIViewController? = nil) {
        if TnkPpiHybSdk.shared.handleScheme(url, from: presenter) {
            // 샘플 편의 기능 — SDK 기능 아님. 딥링크로 연 오퍼월 위에도 "뒤로" 플로팅 버튼을 띄운다. 연동에 필요한 코드는 아니다.
            home?.showFloatingBackToHome(in: window?.windowScene)
            return
        }
        print("[Sample] 매체가 처리할 딥링크: \(url)")
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // ATT 는 앱이 active 일 때만 프롬프트가 뜬다.
        guard !didRequestATT else { return }
        didRequestATT = true
        TnkPpiHybSdk.shared.requestTrackingAuthorization { granted in
            print("[Sample] ATT granted=\(granted)")
        }
    }
}
