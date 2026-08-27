# TnkPpiHyb 연동 샘플 (iOS)

TnkFactory 하이브리드 오퍼월 SDK를 **매체사가 실제로 붙이는 방식 그대로** 구성한 예제입니다.
SDK 소스는 들어 있지 않고, 배포된 바이너리를 SPM · CocoaPods로 받아 씁니다.

- SDK 저장소: [tnkad/ios-ppi-hyb-sdk](https://github.com/tnkad/ios-ppi-hyb-sdk)
- 📖 연동 가이드 전문: https://tnkfactory.gitbook.io/sdk-docs/ios
- 최소 지원: **iOS 14.0**

---

## 두 가지 예제

| 디렉토리 | 의존성 관리 | 여는 파일 |
| --- | --- | --- |
| `SpmSample/` | Swift Package Manager | `SpmSample.xcodeproj` |
| `PodSample/` | CocoaPods | `PodSample.xcworkspace` (⚠️ `pod install` 후 생성) |

두 앱의 **소스 코드는 동일**합니다. 의존성을 가져오는 방법만 다릅니다.
편한 쪽 하나만 보시면 됩니다.

### SpmSample 실행

```sh
open SpmSample/SpmSample.xcodeproj
```

Xcode가 패키지를 자동으로 내려받습니다. 별도 설치 과정이 없습니다.

패키지 참조는 프로젝트에 이렇게 박혀 있습니다.

```
https://github.com/tnkad/ios-ppi-hyb-sdk   —   Up to Next Major Version: 0.1.0
```

### PodSample 실행

```sh
cd PodSample
pod install
open PodSample.xcworkspace     # .xcodeproj 가 아님에 주의
```

```ruby
# Podfile
platform :ios, '14.0'

target 'PodSample' do
  use_frameworks!
  pod 'TnkPpiHyb', '~> 0.1.0'
end
```

---

## 예제가 보여주는 것

### 1. 초기화 — `SceneDelegate.swift`

```swift
let sdk = TnkPpiHybSdk.shared
sdk.configure(appId: "발급받은-앱-아이디")
sdk.setUserName("매체측-사용자-식별값")   // 보상 지급 대상 식별값
sdk.applicationStarted()

sdk.setRewardListener { reward in
    // 서버 지급 성공 시 호출. 항상 메인 스레드.
}
```

`setUserName` 값이 **보상 지급의 기준**입니다. 매체사 회원 ID 등 사용자를 고유하게
식별할 수 있는 값을 넣으세요.

### 2. ATT 동의 — `SceneDelegate.swift`

**앱이 활성 상태일 때만** 프롬프트가 뜹니다. `sceneDidBecomeActive`에서 1회 호출합니다.

```swift
TnkPpiHybSdk.shared.requestTrackingAuthorization { granted in ... }
```

동의를 받지 않으면 참여 가능한 광고가 크게 줄어듭니다.

### 3. 오퍼월 띄우기 — `ViewController.swift`

```swift
// 풀스크린 모달 (일반적)
TnkPpiHybSdk.shared.openOfferwall(from: self)

// 매체가 자체 헤더를 쓰는 경우 오퍼월 상단 바를 숨긴다
TnkPpiHybSdk.shared.openOfferwall(from: self, extraParams: ["hideHeader": "1"])
```

화면 안에 삽입하는 방식은 `EmbeddedViewController`를 참고하세요.

> ⚠️ 삽입해도 표시되는 것은 **오퍼월 전체 화면**입니다.
> 특정 카테고리나 광고 상세만 노출하는 플레이스먼트 뷰는 제공하지 않습니다.

### 4. 딥링크 — `SceneDelegate.swift`

`Info.plist`에 `tnkscheme`를 등록하고 진입점에서 SDK에 넘깁니다.

```swift
func scene(_ scene: UIScene, openURLContexts contexts: Set<UIOpenURLContext>) {
    contexts.forEach { TnkPpiHybSdk.shared.handleScheme($0.url) }
}
```

콜드스타트(딥링크로 앱이 처음 뜨는 경우)는 `willConnectTo`의 `connectionOptions.urlContexts`를
넘기면 됩니다. 앱 부팅 중 도착한 딥링크는 SDK가 큐에 담았다가 웹이 준비되면 전달합니다.

```sh
# 시뮬레이터에서 테스트
xcrun simctl openurl booted "tnkscheme://select_menu?cat_id=3&filter_id=1"
```

> iOS 18+는 외부에서 커스텀 스킴을 열 때 확인 팝업을 띄웁니다. **[열기]를 탭해야** 앱에 전달됩니다.

---

## 실행 전 설정

예제의 앱 ID는 자리표시자입니다. 실제로 광고를 받으려면 발급받은 값으로 바꾸세요.

```swift
// SceneDelegate.swift
sdk.configure(appId: "발급받은-앱-아이디")
sdk.setUserName("매체측-사용자-식별값")
```

`Info.plist`에는 아래가 이미 들어 있습니다.

| 키 | 용도 |
| --- | --- |
| `NSUserTrackingUsageDescription` | ATT 동의 팝업 문구 |
| `NSPhotoLibraryUsageDescription` · `NSCameraUsageDescription` | 광고 참여 시 이미지 첨부 |
| `NSMicrophoneUsageDescription` | 동영상 촬영형 광고 |
| `CFBundleURLTypes` | `tnkscheme` 딥링크 수신 |

---

## 버전 올리기

SDK 새 버전이 나오면 두 곳을 고칩니다.

| | 위치 |
| --- | --- |
| SPM | Xcode → Package Dependencies → `ios-ppi-hyb-sdk` → Version 변경 |
| CocoaPods | `PodSample/Podfile` 의 `pod 'TnkPpiHyb', '~> x.y.z'` 후 `pod update TnkPpiHyb` |

문의: tech@tnkfactory.com
