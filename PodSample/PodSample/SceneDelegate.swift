import UIKit
import TnkPpiHyb

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

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
        window.rootViewController = UINavigationController(rootViewController: ViewController())
        self.window = window
        window.makeKeyAndVisible()

        // 콜드스타트 딥링크 — 딥링크로 앱이 처음 뜨는 경로
        connectionOptions.urlContexts.forEach { handleDeeplink($0.url) }
    }

    /// 앱이 이미 떠 있을 때 들어오는 딥링크
    func scene(_ scene: UIScene, openURLContexts URLContexts: Set<UIOpenURLContext>) {
        URLContexts.forEach { handleDeeplink($0.url) }
    }

    /// tnkscheme:// 은 SDK 에 위임하고, 나머지는 매체가 직접 처리한다.
    private func handleDeeplink(_ url: URL) {
        if TnkPpiHybSdk.shared.handleScheme(url) { return }
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
