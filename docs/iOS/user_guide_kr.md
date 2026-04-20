# GhostPass iOS SDK — 개발자 문서

> **버전** 1.0.0 · **지원 플랫폼** iOS 15.0+ · **배포 형식** SPM, CocoaPod  
> **최종 업데이트** 2026년 4월 20일

---

## 목차

1. [개요](#1-개요)
2. [설치](#2-설치)
3. [사전 준비](#3-사전-준비)
4. [API Reference](#4-api-reference)
5. [HandsFree 연동 (선택)](#5-handsfree-연동-선택)
6. [에러 처리](#6-에러-처리)
7. [FAQ](#7-faq)

---

## 1. 개요

### 1.1 GhostPass SDK란?

GhostPass SDK는 iOS 앱에 **비접촉 생체 정보 인식 인증**을 손쉽게 통합할 수 있는 보안 SDK입니다.  
Liveness Detection(위조 방지), 얼굴 특징 추출, 서버 연동을 모두 내부에서 처리하므로, 파트너 개발자가 직접 다뤄야 할 것은 **딱 3가지**입니다.

```
initialize(apiKey:)  →  registerBioData(imageBytes:)  →  (필요시) removeBioData()
```

### 1.2 주요 기능

| 기능 | 설명 |
|------|------|
| 생체 정보 등록 | 카메라 이미지로부터 생체 정보 특징 벡터 추출 및 Keychain 저장 |
| Liveness Detection | BGR 기반 안티 스푸핑으로 사진·영상 위조 방지 |
| 생체 정보 인증 | 등록된 특징 벡터와 실시간 생체 정보 비교 |
| 보안 저장 | 모든 민감 데이터는 iOS Keychain에만 저장 |

### 1.3 동작 흐름

GhostPass SDK는 **API Key 한 줄**로 연동을 시작하며, 내부 보안 처리(기기 검증, 암호화, 인증 세션 관리)는 모두 SDK가 자동으로 수행합니다.

```
① 서비스 등록 (1회)
   GhostPass 담당자에게 Bundle ID 전달 → API Key 수령

② SDK 초기화 (앱 실행 시 1회)
   initialize(apiKey:) 호출 → SDK 내부 보안 채널 자동 수립

③ 얼굴 등록 (사용자당 1회)
   registerBioData(imageBytes:) 호출 → 생체 정보 추출 + Liveness 검사 + 특징 추출 + 안전 저장

④ 자동 인증 (키오스크 근접 시 자동 동작)
   키오스크 비콘 감지 → 인증 세션 수립 → 기기 내 얼굴 매칭
```

#### 파트너사에서 직접 구현할 것

| 단계 | 호출 | SDK 동작 |
|------|------|---------------|
| 초기화 | `initialize(apiKey:)` 1회 | 기기 검증 · 보안 채널 수립 · 내부 키 관리 |
| 생체 데이터 등록 여부 | `hasBioData()` | 생체 데이터 등록 여부 및 등록 일자 반환 |
| 생체 정보 등록 | `registerBioData(imageBytes:)` | 생체 정보 추출 · Liveness 검사 · 특징 추출 · 안전한 저장 |
| 생체 정보 삭제 | `removeBioData()` | 생체 정보 삭제 · 비콘 스캔 종료 |
| SDK 초기화 상태 복구 | `reset()` | 모든 SDK 데이터 초기화 · 비콘 스캔 종료 |
| 에러 리스너 | `NotificationCenter` 옵저버 등록 | 비콘 스캔 · 근접 인증 등 SDK 자율 동작 중 발생한 에러를 앱에 통지 |

### 1.4 최소 요구 사항
SDK 바이너리가 동작하기 위한 조건
| 항목 | 최솟값 |
|------|--------|
| iOS | 15.0+ |
| Swift | 5.9+ |
| Xcode | 15.0+ |
| 아키텍처 | arm64 (실기기 전용, 시뮬레이터 미지원) |
| 카메라 | 전면 카메라 필수 |

### 1.5 파트너사 앱 설정 요구사항

SDK가 정상 동작하려면 파트너사앱에 아래 설정이 **반드시** 적용되어야 합니다.

#### Info.plist 권한

| 항목 | 설명 | Info.plist Key |
|------|------|----------------|
| 카메라 | 생체 정보 추출 시 필수 | `NSCameraUsageDescription` |
| Bluetooth | 비콘 탐지 시 필수 | `NSBluetoothAlwaysUsageDescription` |
| 위치 (사용 중) | 비콘 기능 사용 시 필수 | `NSLocationWhenInUseUsageDescription` |
| 위치 (항상) | 백그라운드 비콘 탐지 시 필수 | `NSLocationAlwaysAndWhenInUseUsageDescription` |

#### Signing & Capabilities — Background Modes

| 항목 | 설명 |
|------|------|
| Background fetch | 백그라운드 데이터 갱신 |
| Background processing | 백그라운드 작업 처리 |
| Location updates | 백그라운드 위치 업데이트 |

> Xcode → Target → **Signing & Capabilities → + Capability → Background Modes** 에서 해당 항목을 체크하세요.

---

## 2. 설치

GhostPass SDK는 **GitHub 저장소**를 통해 배포됩니다.  

### 2.1 SPM (Swift Package Manager)
#### Step 1. Swift Package Manager로 SDK 추가

1. Xcode에서 프로젝트를 열고 **File → Add Package Dependencies...** 를 선택합니다.
2. 검색창에 아래 저장소 URL을 입력합니다.

```
https://github.com/ghostpass-ai/ghostpass-sdk-distribution
```

3. **Dependency Rule**을 선택합니다. (권장: `Up to Next Major Version`)
4. **Add Package** 버튼을 클릭하고, `GoPassSDK` 라이브러리를 앱 타깃에 추가합니다.

> ⚠️ **주의**: 저장소가 목록에 표시되지 않는 경우, 저장소 URL이 정확한지 확인하세요.
> 

### 2.2 CocoaPods
#### Step 1. Podfile 설정 및 설치

1. 프로젝트 루트 폴더의 `Podfile`을 열고 아래와 같이 GoPassSDK 저장소를 추가합니다.

```ruby
# Podfile
target 'YourAppTarget' do
 use_frameworks!

 pod 'GoPassSDK', '~> {SDK_VERSION}'
end
```
3. 터미널에서 아래 명령어를 실행하여 SDK를 설치합니다.
``` bash
pod install
```
**Other Linker Flags 설정**

CocoaPods 설치 후 빌드 오류가 발생하는 경우, Build Settings → Other Linker Flags에 $(inherited)가 포함되어 있는지 확인하세요.

1. Xcode에서 타깃을 선택합니다.
2. Build Settings → Other Linker Flags 항목을 찾습니다.
3. 값이 비어있다면 $(inherited)를 추가합니다.

> ⚠️ **주의**: $(inherited)가 없으면 CocoaPods이 설정한 링커 플래그가 무시되어 빌드 오류가 발생할 수 있습니다.

---

## 3. 사전 준비
### 3.1 서비스 등록 및 API Key 발급

GhostPass SDK를 사용하려면 서비스를 등록하고 **API Key**를 발급받아야 합니다.  
API Key는 SDK가 GhostPass 서버와 통신 시 서비스를 식별하는 핵심 인증 정보로, **GhostPass 담당자가 직접 생성하여 전달**합니다.

#### Step 1. 서비스 등록 요청

GhostPass 담당자(이메일 등 지정 채널)에게 아래 정보를 전달합니다.

| 항목 | 내용 | 예시 |
|------|------|------|
| 회사명 | 귀사 법인명 | (주)고스트패스 |
| 서비스명 | SDK를 적용할 앱 이름 | A사 편의점 페이 |
| Bundle ID | Xcode Bundle Identifier | `com.company.myapp` |
| 환경 | 개발(dev) / 운영(prod) 구분 | dev, prod |
| 담당자 이메일 | API Key 수령 이메일 | dev@company.com |

> 💡 **팁**: **개발용·운영용 Bundle ID가 다르다면 환경을 구분하여 각각 요청**하세요. GhostPass는 환경별로 격리된 API Key를 발급합니다.

#### Step 2. API Key 수령

등록 요청을 처리한 뒤 GhostPass 담당자가 보안 채널(이메일 암호화 또는 지정 메신저)로 아래 정보를 전달합니다.

```
API_KEY  : gp_dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  (공개용 — 앱에 포함)
```

> ⚠️ **주의**: `APP_SECRET`(서버 내부 키)은 앱에 포함되지 않으며 파트너사에 전달되지 않습니다. SDK가 최초 실행 시 서버와 ECDH 프로토콜을 통해 안전하게 파생합니다.

#### Step 3. API Key 앱에 적용

소스 코드에 하드코딩하지 않고 **빌드 환경변수**로 분리하는 것을 강력 권장합니다.

**방법 A — `.xcconfig` 파일 (권장)**

```bash
# Debug.xcconfig  ← .gitignore에 반드시 추가
GHOSTPASS_API_KEY = gp_dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Release.xcconfig  ← .gitignore에 반드시 추가
GHOSTPASS_API_KEY = gp_prod_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`Info.plist`에서 참조:
``` xml
<key>GhostPassAPIKey</key>
<string>$(GHOSTPASS_API_KEY)</string>
```

Swift 코드에서 읽어 SDK에 전달:
``` swift
let apiKey = Bundle.main.object(forInfoDictionaryKey: "GhostPassAPIKey") as? String ?? ""
try await GoPass.shared.initialize(apiKey: apiKey)
```

**방법 B — CI/CD 환경 변수 (GitHub Actions / Xcode Cloud)**

``` yaml
# .github/workflows/build.yml
- name: Build
  env:
    GHOSTPASS_API_KEY: ${{ secrets.GHOSTPASS_API_KEY }}
  run: xcodebuild ...
```

> ⚠️ **주의**: API Key를 소스 코드에 **직접 커밋하지 마세요**. 노출 시 즉시 GhostPass 담당자에게 Key 폐기 및 재발급을 요청하세요.

#### API Key 운영 정책

| 항목 | 내용 |
|------|------|
| 발급 주체 | GhostPass 담당자 직접 생성 후 전달 |
| 유효 기간 | 계약 기간 연동 (만료 30일 전 사전 안내) |
| 환경 분리 | 개발(dev) / 운영(prod) Key 별도 발급 |
| Key 폐기·재발급 | GhostPass 담당자에게 요청 (즉시 처리) |

---

### 3.2 Info.plist 권한 설정

정상적인 SDK 구동을 위해 아래 키를 `Info.plist`에 반드시 추가해야 합니다.

``` xml
<!-- 카메라: 생체 정보 추출 기능 사용 시 필수 -->
<key>NSCameraUsageDescription</key>
<string>생체 정보 추출을 위해 카메라 접근이 필요합니다.</string>

<!-- Bluetooth: 비콘 탐지 시 필수 -->
<key>NSBluetoothAlwaysUsageDescription</key>
<string>근처 키오스크 감지를 위해 Bluetooth 접근이 필요합니다.</string>

<!-- 위치 (사용 중): 비콘 기능 사용 시 필수 -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>근처 키오스크 감지를 위해 위치 접근이 필요합니다.</string>

<!-- 위치 (항상): 백그라운드 비콘 탐지 시 필수 -->
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>백그라운드에서도 키오스크를 감지하기 위해 항상 위치 접근이 필요합니다.</string>
```

> ⚠️ **주의**: 권한 설명 문자열을 누락하거나 너무 모호하게 작성하면 App Store 심사에서 거부될 수 있습니다. 사용하는 정확한 이유를 명시해주세요.

---

## 4. API Reference
### 4.1 SDK 초기화

SDK를 사용하기 전 반드시 초기화를 완료해야 합니다. 초기화는 앱 실행 시점 **한 번만** 호출합니다.

#### 4.1.1 API 형태 및 설명
**request**

| 항목 | 타입 | 설명 | 예시 |
|------|------|------|------|
| apiKey | String | `3. 사전 준비` 시 발급 받은 apiKey | `gp_dev_xxxxxx...` |

**response**

| 타입 | 필드 | 설명 | 예시 |
|----|------|------|-----------|
| InitResult | `deviceId` | SDK가 발급한 사용자 식별자. 유저가 파트너사 앱 재설치시 변경될 수 있습니다. | `"7612bd71dfc485cfaf375374ed57..."` |
| | `hasBioData` | 생체 데이터 등록 여부. `true`이면 이미 등록되어 있으므로 `registerBioData()` 호출이 불필요합니다. | `true` / `false` |
| | `registeredAt` | 생체 데이터 등록 일자 (`yyyy.MM.dd`). 생체 데이터가 없으면 `nil`입니다. | `"2026.04.20"` / `nil` |

> 💡 **추가설명**: 반환된 `deviceId`는 파트너사의 DB 내 유저와 직접 매핑을 진행하여야합니다. `hasBioData`를 활용하면 이미 등록된 유저에게 불필요한 생체 등록 화면을 건너뛸 수 있습니다.
   
``` swift
// SDK 시스템 초기화
public func initialize(apiKey: String) async throws -> InitResult

public struct InitResult {
    public let deviceId: String
    public let hasBioData: Bool
    public let registeredAt: String?
}
```

#### 4.1.2 예시

```swift
func startSDK() {
    Task {
        do {
            let result = try await GoPass.shared.initialize(apiKey: "YOUR_API_KEY")
            /* result.deviceId를 파트너사 유저와 매핑하는 로직 */

            if result.hasBioData {
                // 이미 생체 데이터가 등록됨 → 등록 화면 스킵
                // result.registeredAt으로 등록 일자 확인 가능 (예: "2026.04.20")
            } else {
                // 생체 데이터 미등록 → registerBioData() 호출 필요
            }
        } catch let error as SDKError {
            print(error.code, error.message)
        }
    }
}
```

---

### 4.2 생체 정보 등록

카메라로 촬영한 이미지에서 생체 정보 특징 벡터를 추출하여 기기의 Keychain에 저장하고 Beacon 탐지를 시작하는 과정입니다.

#### 4.2.1 API 형태 및 설명
**request**

| 항목 | 설명 | 예시 |
|------|------|------|
| imageBytes | 카메라 프레임(`CMSampleBuffer`)을 직접 전달하지 않으며, JPEG/PNG 데이터로 변환 후 전달해야 합니다. | `[0xFF, 0xD8, 0xFF, ...]` |

**response**

| 타입 | 값 | 권장 처리 |
|----|------|-----------|
| BioDataFrameStatus | continueCapture(guide: CaptureGuide) | 가이드 메시지를 표시하고 카메라 캡처 유지 |
| | success | 저장 완료. 카메라 캡쳐 중지 |
   
``` swift
// 생체 정보 데이터 등록
public func registerBioData(imageBytes: [UInt8]) async throws -> BioDataFrameStatus

public enum BioDataFrameStatus {
    case continueCapture(guide: CaptureGuide)
    case success
}

public enum CaptureGuide: Sendable {
    case noFaceDetected
    case invalidPose
    case invalidPosition
    case faceTooSmall
    case faceTooBig
    case collectingFrames
    case livenessNotConfirmed
}
```

#### 4.2.2 예시
> 🗒️ **권장 사항**:  
> 1. captureOutput 전용 Serial Queue 생성  
>    AVCaptureVideoDataOutput의 샘플 버퍼 델리게이트는 반드시 별도의 Serial Queue를 지정해야 합니다. 메인 큐를 사용하면 UI 업데이트가 차단되고, Concurrent Queue를 사용하면 프레임이 순서 없이 처리되어 예기치 않은 동작이 발생할 수 있습니다. 전용 Serial Queue를 사용하면 프레임이 순서대로 처리되며 메인 스레드의 부하를 줄일 수 있습니다.
> 2. Guard Flag(isProcessingFrame) 생성  
>    카메라는 초당 30프레임 이상을 전송하므로, 이전 registerBioData 호출이 완료되기 전에 다음 프레임이 도착하면 호출이 중첩되어 콜스택에 누적됩니다. 이는 메모리 부하 및 예기치 않은 동작으로 이어질 수 있습니다.
>    isProcessingFrame 플래그를 두어 처리 중인 동안 들어오는 프레임을 스킵하고, registerBioData 완료 후 반드시 false로 초기화해야 다음 프레임 처리가 가능합니다.


``` swift
private let videoQueue = DispatchQueue(label: "biodata.videoQueue", qos: .userInitiated)
private var frameCount = 0
private var isProcessingFrame = false // registerBioData 처리중일 때 frame을 무시하기 위한 flag
private let frameInterval = 20

func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
    frameCount += 1
    guard frameCount >= frameInterval else { return }  // 프레임 생성 속도가 매우 빨라 20프레임마다 처리 (파트너사의 선택)
    frameCount = 0

    guard !isProcessingFrame else { return }           // 이전 요청 처리 중이면 스킵
    guard let frameBytes = imageBytes(from: sampleBuffer) else { return }

    isProcessingFrame = true

    Task { [weak self] in
        guard let self else { return }
        defer { self.videoQueue.async { self.isProcessingFrame = false } } // Task 종료 후 isProcessingFrame false 변경

        do {
            let status = try await GoPass.shared.registerBioData(imageBytes: frameBytes)
            switch status {
            case .continueCapture(let guide):
                print(guide.code, guide.message)      // 예: L1001, 얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요.
                break

            case .success:
                DispatchQueue.main.async {
                    self.stopCapture()
                }

            @unknown default:
                break
            }
        } catch let sdkError as SDKError {
            DispatchQueue.main.async {
                self.stopCapture()
            }
            print(sdkError.code, sdkError.message)
        }
    }
}

// MARK: - CMSampleBuffer → JPEG [UInt8]
private func imageBytes(from sampleBuffer: CMSampleBuffer) -> [UInt8]? {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return nil }
    let ciImage = CIImage(cvPixelBuffer: pixelBuffer)
        .oriented(.right)   // 전면 카메라 세로 방향 보정
    let uiImage = UIImage(ciImage: ciImage)
    guard let jpegData = uiImage.jpegData(compressionQuality: 0.9) else { return nil }
    return [UInt8](jpegData)
}
```
> 💡 **팁**: 등록 시 밝은 조명에서 정면을 바라보도록 UI 가이드를 제공하면 등록 성공률이 크게 향상됩니다.

---

### 4.3 생체 정보 삭제

로그아웃, 회원탈퇴, 유저의 선택과 같은 상황에 생체 정보를 삭제할 수 있습니다.

#### 4.3.1 API 형태 및 설명
   
``` swift
// 생체 정보 데이터 삭제
public func removeBioData() async throws
```

#### 4.3.2 예시
``` swift
func removeBioData() {
    Task {
        do {
            try await GoPass.shared.removeBioData()
        } catch let sdkError as SDKError {
            print(sdkError.code, sdkError.message)
        }
    }
}
```

### 4.4 생체 데이터 등록 여부 조회

생체 데이터의 등록 여부와 등록 일자를 조회합니다.

#### 4.4.1 API 형태 및 설명

**response**

| 타입 | 필드 | 설명 | 예시 |
|----|------|------|-----------|
| HasBioDataResult | `hasBioData` | 생체 데이터 등록 여부 | `true` / `false` |
| | `registeredAt` | 생체 데이터 등록 일자 (`yyyy.MM.dd`). 생체 데이터가 없으면 `nil`입니다. | `"2026.04.20"` / `nil` |

``` swift
// 생체 데이터 등록 여부 조회
public func hasBioData() -> HasBioDataResult

public struct HasBioDataResult {
    public let hasBioData: Bool
    public let registeredAt: String?
}
```

#### 4.4.2 예시
``` swift
let result = GoPass.shared.hasBioData()

if result.hasBioData {
    // 이미 등록됨 → 등록 화면 스킵
    // result.registeredAt으로 등록 일자 확인 가능 (예: "2026.04.20")
} else {
    // 미등록 → registerBioData() 호출 필요
}
```

---

### 4.5 SDK 초기화 상태 복구

SDK 내부 데이터(생체 데이터, 보안 채널, 세션 등)를 모두 삭제하고 초기 상태로 복구합니다.  
회원 탈퇴, 계정 전환 등 SDK 전체를 처음 상태로 되돌려야 할 때 사용합니다.

> ⚠️ **주의**: `reset()` 호출 후 SDK를 다시 사용하려면 `initialize(apiKey:)`를 재호출해야 합니다.

#### 4.5.1 API 형태 및 설명

``` swift
// SDK 전체 초기화 상태 복구
public func reset() async throws
```

#### 4.5.2 예시
``` swift
func resetSDK() {
    Task {
        do {
            try await GoPass.shared.reset()
            // 초기화 상태로 복구 완료 → 필요시 initialize() 재호출
        } catch let sdkError as SDKError {
            print(sdkError.code, sdkError.message)
        }
    }
}
```

---

### 4.6 에러 리스너

비콘 탐지 및 인증을 수행하며 발생할 수 있는 에러를 구독하여 리스닝합니다.  
[6.1.1 GP0xx](#611-gp0xx--백그라운드-서비스-onserviceerror)에 해당하는 에러에 대하여 모두 addObserver를 세팅합니다.

#### 4.6.1 API 형태 및 설명
``` swift
NotificationCenter.default.addObserver(forName: .onServiceError, object: nil, queue: .main) { }
```

#### 4.6.2 예시
``` swift
NotificationCenter.default.addObserver(
    forName: .onServiceError,
    object: nil,
    queue: .main
) { [weak self] notification in
    guard let self,
          let code = notification.userInfo?[GoPassNotificationKey.code] as? String,
          let message = notification.userInfo?[GoPassNotificationKey.message] as? String else { return }

    switch code {
    case "GP001":   // bluetoothDisabled
        self.showAlert(
            title: "블루투스 비활성화",
            message: "비콘 감지를 위해 블루투스를 활성화해 주세요."
        )
    case "GP003":   // locationPermissionDenied
        self.showAlert(
            title: "위치 권한 필요",
            message: "비콘 감지를 위해 위치 권한이 필요합니다. 설정에서 '항상 허용'으로 변경해 주세요.",
            action: ("설정으로 이동", {
                UIApplication.shared.open(URL(string: UIApplication.openSettingsURLString)!)
            })
        )
    default:
        print("[\(code)] \(message)")
    }
}
```
---

## 5. HandsFree 연동 (선택)

키오스크가 생성한 인증 세션을 **FCM Push**로 수신하여, 사용자 조작 없이 자동으로 인증을 처리하는 기능입니다.  
이 기능은 선택 사항이며, 사용하지 않는 경우 이 장을 건너뛰어도 됩니다.

### 5.1 사전 요구사항

HandsFree 연동을 위해 아래 항목이 추가로 필요합니다.

#### 의존성

`FirebaseMessaging` SDK를 프로젝트에 추가해야 합니다.

**SPM**
```
https://github.com/firebase/firebase-ios-sdk
```
> `FirebaseMessaging` 라이브러리를 앱 타깃에 추가하세요.

**CocoaPods**
```ruby
pod 'FirebaseMessaging'
```

#### Info.plist

Firebase의 메서드 스위즐링을 비활성화해야 합니다.

```xml
<key>FirebaseAppDelegateProxyEnabled</key>
<false/>
```

> ⚠️ **주의**: 이 설정이 없으면 APNs 토큰이 Firebase에 정상 전달되지 않아 Push 수신이 실패할 수 있습니다.

#### Signing & Capabilities

기존 설정([1.5 파트너사 앱 설정 요구사항](#15-파트너사-앱-설정-요구사항))에 아래 항목을 추가하세요.

| 항목 | 설명 |
|------|------|
| **Push Notifications** | Xcode → Target → Signing & Capabilities → + Capability → Push Notifications |
| **Remote notifications** | Background Modes → Remote notifications 체크 |

#### Firebase 프로젝트 설정

1. [Firebase Console](https://console.firebase.google.com/)에서 iOS 앱을 등록합니다.
2. `GoogleService-Info.plist`를 다운로드하여 앱 타깃에 포함합니다.
3. **Project Settings → Cloud Messaging → Apple app configuration**에서 APNs Authentication Key (.p8)를 업로드합니다.

---

### 5.2 Push Token 등록

FCM 토큰을 GhostPass 서버에 등록합니다. `initialize()` 성공 후 호출하세요.

#### 5.2.1 API 형태 및 설명

**request**

| 항목 | 타입 | 설명 |
|------|------|------|
| token | String | Firebase Messaging에서 발급받은 FCM 토큰 |

```swift
public func registerToken(token: String) async throws
```

빈 문자열이나 공백만 있는 토큰을 전달하면 `GP103 (invalidParameters)` 에러가 발생합니다.

#### 5.2.2 예시

```swift
import FirebaseMessaging

func registerPushToken() {
    Task {
        do {
            let fcmToken = try await Messaging.messaging().token()
            try await GoPass.shared.registerToken(token: fcmToken)
        } catch let error as SDKError {
            print(error.code, error.message)
        }
    }
}
```

---

### 5.3 인증 세션 위임

FCM Push 수신 시 payload를 SDK에 전달하여 인증을 자동 처리합니다.

#### 5.3.1 API 형태 및 설명

**request**

| 항목 | 타입 | 설명 |
|------|------|------|
| session | String | Push notification의 `userInfo`를 JSON 문자열로 변환한 값 |

```swift
public func delegateAuthSession(session: String) async throws
```

#### 5.3.2 AppDelegate 설정

HandsFree Push를 수신하려면 `AppDelegate`에 아래 설정이 필요합니다.

```swift
import UIKit
import GoPassSDK
import FirebaseCore
import FirebaseMessaging

class AppDelegate: UIResponder, UIApplicationDelegate {

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        FirebaseApp.configure()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self

        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { _, _ in }
        application.registerForRemoteNotifications()

        return true
    }

    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        Messaging.messaging().apnsToken = deviceToken
    }

    // Background / Terminated 상태에서 Push 수신 시 자동 호출
    func application(_ application: UIApplication,
                     didReceiveRemoteNotification userInfo: [AnyHashable: Any],
                     fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        guard let jsonData = try? JSONSerialization.data(withJSONObject: userInfo),
              let jsonString = String(data: jsonData, encoding: .utf8) else {
            completionHandler(.noData)
            return
        }

        Task {
            do {
                try await GoPass.shared.delegateAuthSession(session: jsonString)
                completionHandler(.newData)
            } catch {
                completionHandler(.failed)
            }
        }
    }
}

// MARK: - MessagingDelegate
extension AppDelegate: MessagingDelegate {
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        // FCM 토큰 갱신 시 처리
    }
}
```

> 💡 **팁**: FCM 토큰은 앱 재설치, Firebase SDK 업데이트 등으로 변경될 수 있습니다. `MessagingDelegate`의 `didReceiveRegistrationToken`에서 갱신된 토큰을 `registerToken(token:)`으로 재등록하세요.

---

## 6. 에러 처리

### 6.1 에러 코드 정의
Ghostpass SDK를 사용하며 발견될 수 있는 에러 코드입니다.

#### 6.1.1 GP0xx — 백그라운드 서비스 (`onServiceError`)

백그라운드 서비스 에러는 `BackgroundServiceError` 타입으로, `NotificationCenter`를 통해 `code`와 `message`로 전달됩니다.

| 에러 코드 | BackgroundServiceError case | 설명 |
|-----------|----------------------------|------|
| GP001 | `.bluetoothDisabled` | 블루투스를 활성화해주세요. |
| GP002 | `.bluetoothPermissionDenied` | 블루투스 권한이 필요합니다. |
| GP003 | `.locationPermissionDenied` | 위치 서비스 권한이 필요합니다. |
| GP004 | `.locationPermissionInsufficient` | 위치 서비스 권한이 부족합니다. |
| GP005 | `.beaconUuidNotFound` | 인증 정보를 확인할 수 없습니다. |
| GP006 | `.networkDisconnected` | 네트워크 연결을 확인해주세요. |

#### 6.1.2 GP1xx — `initialize(apiKey:)`

| 에러 코드 | SDKError case | 설명 |
|-----------|---------------|------|
| GP101 | `.initializationFailed` | 초기화를 실패했습니다. |
| GP102 | `.updateSDK` | SDK 버전이 최신이 아닙니다. |
| GP103 | `.invalidParameters` | 요청 파라미터가 올바르지 않습니다. |

#### 6.1.3 GP2xx — `registerBioData(imageBytes:)` / `removeBioData()`

| 에러 코드 | SDKError case | 설명 |
|-----------|---------------|------|
| GP201 | `.registerBioDataFailed` | 생체 데이터 등록에 실패했습니다. |
| GP202 | `.removeBioDataFailed` | 생체 데이터 삭제에 실패했습니다. |
| GP203 | `.invalidImageBytes` | 입력 이미지가 비어 있거나 손상되었습니다. |
| GP204 | `.livenessNotSatisfied` | 라이브니스 검증을 통과하지 못했습니다. |

#### 6.1.4 GP3xx — `reset()`

| 에러 코드 | SDKError case | 설명 |
|-----------|---------------|------|
| GP301 | `.resetFailed` | 초기 상태 복구에 실패했습니다. |

#### 6.1.5 L10xx — 얼굴 등록 가이드 (`CaptureGuide`)

`registerBioData(imageBytes:)`가 `continueCapture(guide:)`를 반환하는 경우, 아래 가이드 코드를 사용해 UI 메시지를 표시할 수 있습니다.

| 가이드 코드 | CaptureGuide case | 설명 |
|-----------|-------------------|------|
| L1001 | `.noFaceDetected` | 얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요. |
| L1002 | `.invalidPose` | 고개를 똑바로 세우고 정면을 바라봐 주세요. |
| L1003 | `.invalidPosition` | 얼굴 위치가 화면 중앙에서 벗어났습니다. |
| L1004 | `.faceTooSmall` | 얼굴이 너무 멀리 있습니다. 카메라에 가까이 다가가 주세요. |
| L1005 | `.faceTooBig` | 얼굴이 너무 가까이 있습니다. 한 걸음 뒤로 물러나 주세요. |
| L1006 | `.collectingFrames` | 잠시만 유지해 주세요. |
| L1007 | `.livenessNotConfirmed` | 실제 사람인지 확인 중입니다. 잠시 멈춰주세요. |

#### 6.1.6 GP4xx — HandsFree 인증

| 에러 코드 | SDKError case | 설명 |
|-----------|---------------|------|
| GP401 | `.delegateAuthSessionFailed` | 핸즈프리 인증 처리에 실패했습니다. |

#### 6.1.7 GP9xx — 서버

| 에러 코드 | SDKError case | 설명 |
|-----------|---------------|------|
| GP901 | `.sdkServiceNotFound` | SDK 서비스를 찾을 수 없습니다. |
| GP902 | `.sdkServiceInactive` | 비활성화된 SDK 서비스입니다. |
| GP903 | `.sdkServiceCodeDuplicate` | 이미 사용 중인 서비스 코드입니다. |
| GP904 | `.sdkAPIKeyDuplicate` | 이미 사용 중인 API Key입니다. |
| GP905 | `.serverError` | 서버의 응답이 비정상적입니다. |
| GP906 | `.internalError` | 내부 처리 중 오류가 발생했습니다. |

---

### 6.2 에러 처리 예시 코드

```swift
// function
do {
    let result = try await GoPass.shared.initialize(apiKey: key)
} catch let error as SDKError {
    print(error.code)     // "GP101(IN-107)"  ← 문의 시 에러 코드 전달
    print(error.message)  // "초기화를 실패했습니다."

    switch error {
    case .initializationFailed: showRetryAlert()
    case .updateSDK:            showUpdateAlert()
    case .invalidParameters:    showParamError()
    case .invalidImageBytes:    showImageRetryAlert()
    case .livenessNotSatisfied: showLivenessGuide()
    default: break
    }
}

// onServiceError
NotificationCenter.default.addObserver(
    forName: .onServiceError,
    object: nil,
    queue: .main
) { notification in
    guard let code = notification.userInfo?[GoPassNotificationKey.code] as? String,
          let message = notification.userInfo?[GoPassNotificationKey.message] as? String else { return }
    print("[\(code)] \(message)")   // "[GP001] 블루투스를 활성화해주세요."
}
```

---

## 7. FAQ

**Q1. 비콘이 감지되지 않습니다.**  
A. 생체 정보 인증 데이터가 저장되어 있는지 확인해주세요. 생체 정보가 없으면 비콘 감지를 시작하지 않습니다.

---

**Q2. 시뮬레이터에서 빌드 오류가 발생합니다.**  
A. `GoPassSDK`는 **arm64** 아키텍처만 지원하므로 시뮬레이터(x86_64 / arm64 시뮬레이터)에서는 동작하지 않습니다. 반드시 **실기기**에서 테스트하세요.

---

**Q3. 얼굴 등록 후 앱을 삭제하면 어떻게 되나요?**  
A. 얼굴 특징 벡터는 iOS Keychain에 저장됩니다. 앱을 삭제해도 Keychain 데이터는 유지될 수 있으며, 재설치시 SDK 내부에서 자동으로 생체 정보를 삭제합니다.

---

**Q4. CocoaPods으로 설치 후 빌드 오류가 발생합니다.**  
A. `Podfile`에 아래 옵션을 추가 후 `pod install`을 다시 실행해보세요. GoPassSDK에 포함된 XCFramework와 Xcode 빌드 시스템 간 스크립트 단계 충돌로 발생할 수 있습니다.

```ruby
install! 'cocoapods', :disable_input_output_paths => true
```

---

**Q5. initialize가 너무 오래 걸립니다.**  
A. initialize는 SDK 사용을 위해 필수적으로 필요한 단계입니다. 앱 런치시 initialize를 호출한다면 **Splash View**를, 앱 사용중 호출한다면 **Progress View** 활용을 추천드립니다.

---

*© GhostPass AI. All rights reserved.*
