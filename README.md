# GhostPass SDK — Distribution Repository

**지원 플랫폼**

| 플랫폼 | 최소 버전 |
|------|------|
| iOS | 15.0+ |
| Android | API 23+ |

**배포 방식**

| 플랫폼 | 방식 |
|------|------|
| iOS | SPM (Swift Package Manager) · CocoaPods |
| Android | Maven repository (GitHub Pages) |

---

## 저장소 구조

```
ghostpass-sdk-distribution-dev/
├── docs/
│   ├── iOS/
│   │   └── user_guide_kr.md        # iOS 유저 SDK 연동 가이드
│   ├── Android/
│   │   └── kiosk_guide_kr.md          # Android 키오스크 SDK 연동 가이드
│   │   └── user_guide_kr.md          # Android 유저 SDK 연동 가이드
│   └── error_codes.md                 # 에러 코드 목록 및 처리 방법
└── LICENSE
```

---

## 1. 시작하기

SDK를 연동하기 전에 아래 단계를 먼저 완료해야 합니다.

```
관리 포털 가입 → 서비스 등록 + API Key 발급 → (선택) Webhook 설정 → SDK 연동 시작
```

### 1.1 관리 포털 가입

GhostPass는 파트너사별 전용 관리 포털([sdk-admin.ghostpass.ai](https://sdk-admin.ghostpass.ai/login))을 제공합니다.

| 단계 | 설명 |
|------|------|
| **1. 초대 수신** | GhostPass 담당자가 파트너사 담당자 이메일로 초대를 발송합니다. |
| **2. 가입** | 이메일의 초대 링크를 클릭하고, 이름 · 이메일 · 비밀번호를 입력하여 가입합니다. |
| **3. 로그인** | 가입 완료 후 관리 포털에 로그인합니다. |

> 💡 **초대 코드는 7일간 유효**합니다. 만료된 경우 GhostPass 담당자에게 재발송을 요청하세요.

### 1.2 서비스 등록 및 API Key 발급

관리 포털에서 서비스를 등록하면 **API Key**가 발급됩니다.

**등록 시 필요한 정보:**

| 항목 | 필수 | 설명 | 예시 |
|------|:----:|------|------|
| 서비스 코드 | ✅ | 파트너사 식별자 (영문 대문자) | `PARTNER_A` |
| 서비스명 | ✅ | 서비스 표시 이름 | `A사 편의점 페이` |
| Beacon UUID | ✅ | 키오스크 BLE 비콘 UUID | GhostPass 담당자가 안내 |
| iOS Team ID | ⚠️ | Apple Developer Team ID (iOS App Attest 검증용) | `ABCDE12345` |
| iOS Bundle ID | ⚠️ | iOS 앱 Bundle Identifier (iOS App Attest 검증용) | `com.partner.app` |
| Android Package Name | ⚠️ | Android 앱 패키지명 (Play Integrity 검증용) | `com.partner.app` |
| Webhook URL | ❌ | 인증 결과 수신 URL | `https://api.partner.com/webhook` |

> ⚠️ **Device Attestation (강력 권장)**: iOS App Attest 및 Android Play Integrity를 통해 SDK가 정품 디바이스에서 실행 중인지 서버가 검증합니다.
> 등록 시 필수는 아니지만, **프로덕션 환경에서는 반드시 설정해야 합니다.**
> 미설정 시 변조된 클라이언트의 요청을 차단할 수 없어 심각한 보안 위험이 발생합니다.
>
> | 연동 플랫폼 | 필요한 값 |
> |------------|----------|
> | iOS | `iOS Team ID` + `iOS Bundle ID` |
> | Android | `Android Package Name` |
> | 양쪽 모두 | 위 세 가지 모두 등록 |

**등록 완료 후 발급되는 정보:**

| 항목 | 용도 | 주의 사항 |
|------|------|----------|
| `API Key` | SDK 초기화 시 사용 (앱에 포함) | 포털에서 언제든 확인 가능 |
| `Webhook Secret` | Webhook 서명 검증 키 | ⚠ **등록 시 1회만 표시** — 반드시 복사하여 안전하게 보관 |

> ⚠ **중요**: `Webhook Secret`은 서비스 등록 직후 화면에서만 확인할 수 있습니다.
> 분실 시 서비스를 재등록해야 하므로 반드시 즉시 복사하세요.

### 1.3 Webhook 연동 (선택)

Webhook을 설정하면 GhostPass 서버가 인증 결과를 파트너 서버로 **실시간 HTTP POST**합니다.

```
키오스크(얼굴 캡처) → 유저 폰(로컬 매칭) → GhostPass 서버(세션 종료)
                                                     ↓
                                             파트너 서버 (Webhook)
```

**Webhook이 필요한 경우:**
- 결제 승인 / 포인트 적립
- 출입 게이트 개방
- 출석 체크 기록
- 기타 인증 결과에 따른 서버 사이드 비즈니스 로직

Webhook URL은 관리 포털의 서비스 등록 시 입력하거나, 이후 서비스 수정에서 변경할 수 있습니다.

#### Payload

인증 완료 시 등록된 URL로 아래 JSON이 `POST`로 전송됩니다.

```json
{
  "event": "auth.result",
  "sessionId": "550e8400-e29b-41d4-a716-446655440000",
  "deviceId": "a1b2c3d4e5f6abcdef1234567890abcd",
  "success": true,
  "status": "COMPLETED",
  "terminatedAt": "2026-03-05T14:30:00",
  "timestamp": "2026-03-05T05:30:00.123Z"
}
```

| 필드 | 타입 | 설명 |
|------|------|------|
| `event` | `string` | 항상 `"auth.result"` |
| `sessionId` | `string` | 인증 세션 UUID |
| `deviceId` | `string` | SDK 디바이스 식별자 (1.4 매핑 참고) |
| `success` | `boolean` | 인증 성공 여부 |
| `status` | `string` | `"COMPLETED"` (성공) 또는 `"ERROR"` (실패) |
| `terminatedAt` | `string` | 세션 종료 시각 (ISO 8601) |
| `timestamp` | `string` | Webhook 발송 시각 (ISO 8601) |

#### 서명 검증

모든 Webhook 요청에는 HMAC-SHA256 서명이 포함됩니다. **반드시 검증하세요.**

| HTTP 헤더 | 설명 |
|-----------|------|
| `X-GhostPass-Signature` | HMAC-SHA256 서명 (hex lowercase) |
| `X-GhostPass-Timestamp` | 서명 생성 시각 (epoch seconds) |

**검증 절차:**

1. 서명 대상 문자열 구성: `{timestamp}.{requestBody}`
2. `webhookSecret`을 키로 HMAC-SHA256 계산
3. hex(lowercase) 인코딩 후 `X-GhostPass-Signature`와 비교
4. `X-GhostPass-Timestamp`가 현재 시각 기준 **5분 이내**인지 확인

**Python**

```python
import hmac, hashlib, time

def verify_webhook(body: str, signature: str, timestamp: str, secret: str) -> bool:
    if abs(int(time.time()) - int(timestamp)) > 300:
        return False
    message = f"{timestamp}.{body}"
    expected = hmac.new(
        secret.encode(), message.encode(), hashlib.sha256
    ).hexdigest()
    return hmac.compare_digest(expected, signature)
```

**Node.js**

```javascript
const crypto = require('crypto');

function verifyWebhook(body, signature, timestamp, secret) {
  if (Math.abs(Math.floor(Date.now() / 1000) - parseInt(timestamp)) > 300) return false;
  const expected = crypto
    .createHmac('sha256', secret)
    .update(`${timestamp}.${body}`)
    .digest('hex');
  return crypto.timingSafeEqual(Buffer.from(expected, 'hex'), Buffer.from(signature, 'hex'));
}
```

**Java**

```java
import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.util.HexFormat;

public boolean verifyWebhook(String body, String signature, String timestamp, String secret) {
    long current = System.currentTimeMillis() / 1000;
    if (Math.abs(current - Long.parseLong(timestamp)) > 300) return false;
    String message = timestamp + "." + body;
    Mac mac = Mac.getInstance("HmacSHA256");
    mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
    byte[] hash = mac.doFinal(message.getBytes(StandardCharsets.UTF_8));
    String expected = HexFormat.of().withLowerCase().formatHex(hash);
    return MessageDigest.isEqual(expected.getBytes(), signature.getBytes());
}
```

#### 응답 및 재시도

| 항목 | 요구사항 |
|------|----------|
| 성공 응답 | HTTP `200` 반환 |
| 응답 시간 | 5초 이내 권장 |
| 재시도 | `200` 이외 응답 또는 타임아웃 시 최대 **3회** 재시도 |
| 최종 실패 | 모든 재시도 실패 시 해당 Webhook 폐기 |

> 💡 Webhook 수신 후 무거운 비즈니스 로직은 **비동기로 처리**하고, 즉시 `200 OK`를 반환하세요.

#### 보안 가이드

**필수:**
- ✅ 모든 Webhook에 대해 `X-GhostPass-Signature` 서명 검증
- ✅ Webhook URL은 반드시 `https://` 사용
- ✅ `webhookSecret`은 환경 변수 또는 Secret Manager에 저장 (하드코딩 금지)
- ✅ `X-GhostPass-Timestamp` 5분 초과 시 요청 거부 (Replay Attack 방지)

**권장:**
- 동일 `sessionId`에 대한 중복 처리 방지 (멱등성 보장)
- 수신 로그 기록 (`sessionId`, `timestamp`, 검증 결과)

### 1.4 deviceId와 유저 매핑

GhostPass SDK는 디바이스별 고유 식별자(`deviceId`)를 발급합니다.
이 값은 파트너사의 유저 ID와 별개이므로, **파트너 서버에서 매핑을 직접 관리**해야 합니다.

#### 매핑 시점

SDK 초기화(`initialize`) 완료 시 `deviceId`가 반환됩니다.
이 시점에 파트너 앱이 자사 서버로 `deviceId`를 전송하여 매핑을 등록합니다.

```
[유저 앱]
  SDK.initialize(apiKey) → deviceId 반환
    → 파트너 서버 API 호출: POST /users/me/device { deviceId: "..." }

[파트너 서버]
  deviceId 매핑 저장 (1회)

[이후 Webhook 수신 시]
  payload.deviceId로 매핑된 파트너 계정 조회 → 비즈니스 로직 처리
```

> 💡 **매핑은 SDK 초기화 성공 후 1회만 등록**하면 됩니다.
> 앱 재설치 시 새로운 `deviceId`가 발급되므로, 이 경우 재매핑이 필요합니다.

---

## 2. Android 키오스크

### 2.1 빠른 시작

GhostPass 담당자에게 서비스 등록을 요청하면 **API Key** 및 키오스크 정보를 발급해 드립니다.

**담당자에게 전달할 정보:**

| 항목 | 설명 |
|------|------|
| 회사명 / 서비스명 | 파트너사 식별에 사용 |
| 담당자 이메일 | 연동 안내 수신 |
| 사용할 Android `minSdk` 버전 | SDK 빌드 기준 확인 |

**발급되는 정보:**

| 항목 | 용도 |
|------|------|
| `API Key` | SDK 초기화 시 사용 |
| `KioskId` | 키오스크 고유 식별자 (`svc` / `region` / `branch` / `seq`) |
| `BeaconConfig` | BLE 비콘 설정값 (`uuid` / `major` / `minor`) |
| Maven 저장소 | `https://ghostpass-ai.github.io/ghostpass-sdk-distribution/` |
| Artifact 좌표 | `com.ghostpass:gopass-kiosk-sdk:{version}` |

### 2.2 설치

**1.** 프로젝트의 `settings.gradle.kts` 에 Maven 저장소를 추가합니다.

```kotlin
pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://ghostpass-ai.github.io/ghostpass-sdk-distribution/")
        }
    }
}
```

**2.** `app/build.gradle.kts` 에 의존성을 추가합니다.

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-kiosk-sdk:1.0.0")
}
```

**3.** `AndroidManifest.xml` 에 권한을 추가합니다.

```xml
<!-- 네트워크 -->
<uses-permission android:name="android.permission.INTERNET" />

<!-- 카메라 (얼굴 인증) -->
<uses-permission android:name="android.permission.CAMERA" />
```

> Android 12 (API 31) 이상에서는 `BLUETOOTH_ADVERTISE` 권한을 **런타임**에 직접 요청해야 합니다.

### 2.3 SDK 초기화

`GoPassKioskSdk.initialize()` 는 `suspend` 함수입니다. 코루틴 안에서 호출하세요.

```kotlin
val kioskId = KioskId(
    svc    = "PARTNER_A",   // GhostPass 담당자 안내
    region = "SEOUL",
    branch = "GANGNAM_01",
    seq    = "02"
)

val beaconConfig = BeaconConfig(
    uuid  = "550e8400-e29b-41d4-a716-446655440000",  // GhostPass 담당자 안내
    major = 1,
    minor = 1
)

CoroutineScope(Dispatchers.IO).launch {
    try {
        GoPassKioskSdk.initialize(
            context      = applicationContext,
            apiKey       = "YOUR_API_KEY",
            kioskId      = kioskId,
            beaconConfig = beaconConfig
        )
        // 초기화 완료 — 인증 준비 상태 
    } catch (e: GoPassSdkException) {
        Log.e(TAG, "초기화 실패: code=${e.code}, message=${e.message}")
    }
}
```

초기화 성공 후 키오스크는 BLE 비콘을 광고하고, GhostPass 서버 연결을 자동으로 수립합니다.

### 2.4 얼굴 인증

카메라에서 추출한 YUV 프레임을 `GoPassKioskSdk.detection()` 에 지속적으로 전달합니다.

```kotlin
// CameraX ImageAnalysis.Analyzer 구현 예시
override fun analyze(image: ImageProxy) {
    if (image.format != ImageFormat.YUV_420_888) { image.close(); return }

    val nv21 = convertToNV21(image)  // YUV → NV21 변환
    val width = image.width
    val height = image.height
    val rotation = image.imageInfo.rotationDegrees
    image.close()

    analyzerScope.launch {
        val result = GoPassKioskSdk.detection(
            faceImage       = nv21,
            width           = width,
            height          = height,
            rotationDegrees = rotation
        )

        when (result) {
            is GoPassAuthResult.Success -> {
                // 인증 완료 → 게이트 개방, 결제 승인 등
            }
            is GoPassAuthResult.PrecheckGuide -> {
                // 얼굴 검출 실패 → 사용자 안내 메시지 표시
                val message = result.reasons.firstOrNull()?.message ?: ""
                showGuideText(message)
            }
            is GoPassAuthResult.ServerAuthFailed -> {
                // 서버 인증 실패 (타임아웃, 앱 거절 등)
                showErrorText(result.message)
            }
        }
    }
}
```

`GoPassAuthResult` 타입:

| 타입 | 설명 |
|------|------|
| `Success` | 최종 인증 성공 |
| `PrecheckGuide(reasons)` | 얼굴 검출 실패 — `reasons[0].message` 를 화면에 표시 |
| `ServerAuthFailed(message)` | 서버 인증 실패 (앱 거절 · 타임아웃 등) |

### 2.5 휴대폰 인증

  휴대폰 인증은 preparePhoneAuth() 와 submitPhoneAuth() 의 2단계로 진행합니다.

  1. preparePhoneAuth() 로 얼굴 검증을 수행합니다.
  2. Success 가 반환되면 submitPhoneAuth(deviceId) 를 호출합니다.
```kotlin
  override fun analyze(image: ImageProxy) {
      if (image.format != ImageFormat.YUV_420_888) {
          image.close()
          return
      }

      val nv21 = convertToNV21(image)
      val width = image.width
      val height = image.height
      val rotation = image.imageInfo.rotationDegrees
      image.close()

      analyzerScope.launch {
          val prepareResult = GoPassKioskSdk.preparePhoneAuth(
              faceImage = nv21,
              width = width,
              height = height,
              rotationDegrees = rotation
          )

          when (prepareResult) {
              is GoPassAuthResult.Success -> {
                  val submitResult = GoPassKioskSdk.submitPhoneAuth(
                      deviceId = "USER_DEVICE_ID"
                  )

                  when (submitResult) {
                      is GoPassAuthResult.Success -> {
                          // 휴대폰 인증 완료
                      }
                      is GoPassAuthResult.PrecheckGuide -> {
                          val message = submitResult.reasons.firstOrNull()?.message ?: ""
                          showGuideText(message)
                      }
                      is GoPassAuthResult.ServerAuthFailed -> {
                          showErrorText(submitResult.message)
                      }
                  }
              }

              is GoPassAuthResult.PrecheckGuide -> {
                  val message = prepareResult.reasons.firstOrNull()?.message ?: ""
                  showGuideText(message)
              }

              is GoPassAuthResult.ServerAuthFailed -> {
                  showErrorText(prepareResult.message)
              }
          }
      }
  }
```
휴대폰 인증 참고 사항:

| 항목 | 설명 |
|------|------|
| preparePhoneAuth() | 얼굴 검증을 먼저 수행하고, 성공 시 휴대폰 인증 요청이 가능한 상태가 됩니다 |
| submitPhoneAuth(deviceId) | deviceId 기준으로 휴대폰 인증을 요청하고 결과를 반환합니다 |
| 준비 유효 시간 | preparePhoneAuth() 성공 후 30초 이내에 submitPhoneAuth() 를 호출해야 합니다 |
| 결과 대기 시간 | submitPhoneAuth() 는 현재 최대 8초 동안 결과를 기다립니다 |

> 📄 상세한 API Reference와 에러 처리는 [Android 키오스크 연동 가이드](docs/Android/kiosk_guide_kr.md)를 참고하세요.     

---

## 3. iOS 유저앱

> iOS는 현재 유저앱 SDK만 제공됩니다.

### 3.1 빠른 시작

GhostPass 담당자에게 아래 정보를 전달해 주세요.

- GitHub 계정 이메일 (또는 username)
- 회사명 / 서비스명 / Bundle ID
- 담당자 이메일

### 3.2 설치

#### Swift Package Manager (SPM)

**1.** Xcode → **File → Add Package Dependencies...**

**2.** 검색창에 아래 URL을 입력합니다.

```
https://github.com/ghostpass-ai/ghostpass-sdk-distribution-dev
```

**3.** 버전 규칙을 선택하고 **Add Package** 를 클릭합니다.

**4.** `GoPassSDK` 라이브러리를 앱 타깃에 추가합니다.

#### CocoaPods

**1.** `Podfile` 에 아래 내용을 추가합니다.

```ruby
target 'YourApp' do
  use_frameworks!
  pod 'GoPassSDK-Dev', '~> {VERSION}'
end
```

**2.** 터미널에서 설치합니다.

```bash
pod install
```

**3.** 이후 `.xcworkspace` 파일로 프로젝트를 엽니다.

**4.** Xcode → **Target → Build Settings → Other Linker Flags** 에 `$(inherited)` 가 포함되어 있는지 확인합니다.

> `$(inherited)` 가 없으면 CocoaPods 의존성이 링커에 정상적으로 전달되지 않아 빌드 에러가 발생할 수 있습니다.

### 3.3 SDK 초기화

```swift
let result = try await GoPass.shared.initialize(apiKey: "YOUR_API_KEY")
// result.deviceId를 파트너 서버 계정과 매핑 (자세한 흐름은 1.4 참고)
// result.hasBioData로 생체 데이터 등록 여부 확인
// result.registeredAt으로 생체 데이터 등록 일자 확인 (미등록 시 nil)
```

### 3.4 생체 데이터 등록 여부 조회

```swift
let result = GoPass.shared.hasBioData()

if result.hasBioData {
    // 이미 등록됨 → 등록 화면 스킵
    // result.registeredAt으로 등록 일자 확인 가능
} else {
    // 미등록 → registerBioData() 호출 필요
}
```

### 3.5 얼굴 등록

```swift
let status = try await GoPass.shared.registerBioData(imageBytes: frameBytes)

switch status {
case .continueCapture(let guide):
    print(guide.code, guide.message) // 예: L1001 얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요.
case .success:
    stopCapture()
}
```

그 이후의 **인증은 SDK가 자동으로 처리**합니다.
키오스크 비콘 감지 시 자동으로 인증 세션이 수립되고, 결과는 Webhook 또는 RTDB를 통해 전달됩니다.

### 3.6 생체 정보 삭제

로그아웃, 회원 탈퇴 등 생체 정보를 제거해야 할 때 사용합니다.

```swift
try await GoPass.shared.removeBioData()
```

### 3.7 SDK 초기화 상태 복구

회원 탈퇴, 계정 전환 등 SDK 전체를 처음 상태로 되돌려야 할 때 사용합니다.

```swift
try await GoPass.shared.reset()
// 이후 SDK를 다시 사용하려면 initialize(apiKey:) 재호출 필요
```

### 3.8 HandsFree 인증 (선택)

키오스크가 생성한 인증 세션을 FCM Push로 수신하여, 사용자 조작 없이 자동으로 인증을 처리합니다.

#### 사전 요구사항

| 항목 | 설명 |
|------|------|
| 의존성 | `FirebaseMessaging` (SPM 또는 CocoaPods) |
| Info.plist | `FirebaseAppDelegateProxyEnabled` = `NO` |
| Capabilities | **Push Notifications** + **Background Modes → Remote notifications** |

#### Push Token 등록

FCM 토큰을 GhostPass 서버에 등록합니다. `initialize()` 성공 후 호출하세요.

```swift
try await GoPass.shared.registerToken(token: fcmToken)
```

#### 인증 세션 위임

FCM Push 수신 시 payload를 SDK에 전달합니다. AppDelegate에서 호출하세요.

```swift
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
```

> 📄 상세한 API Reference, 에러 처리, 코드 예시는 [iOS 연동 가이드](docs/iOS/user_guide_kr.md)를 참고하세요.

---

## 4. Android 유저앱

### 4.1 빠른 시작

GhostPass 담당자에게 아래 정보를 전달해 주세요.

- 회사명 / 서비스명
- Android 패키지명 (`applicationId`)
- 담당자 이메일
- 사용할 Android `minSdk` 버전

### 4.2 설치

**1.** 프로젝트의 `settings.gradle.kts` 에 Maven 저장소를 추가합니다.

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://ghostpass-ai.github.io/ghostpass-sdk-distribution/")
        }
    }
}
```

**2.** `app/build.gradle.kts` 에 의존성을 추가합니다.

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-user-sdk:1.0.0")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
```

### 4.3 권한

BLE · 위치 관련 manifest 권한은 SDK manifest에서 자동 머지됩니다.
호스트 앱은 카메라를 직접 사용하므로 `CAMERA` 권한을 선언해야 합니다.
HandsFree 사용 시 `POST_NOTIFICATIONS` 권한도 선언해야 합니다.

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

런타임 권한은 `initialize()` 호출 전에 완료해야 합니다.

```kotlin
val permissions = mutableListOf(
    Manifest.permission.CAMERA,
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION,
).apply {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
        add(Manifest.permission.BLUETOOTH_SCAN)
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
        add(Manifest.permission.POST_NOTIFICATIONS)
    }
}
requestPermissions(permissions.toTypedArray(), REQUEST_CODE)

if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
    requestPermissions(
        arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
        REQUEST_CODE_BG
    )
}
```

### 4.4 SDK 초기화

`GoPassSDK.initialize()` 는 `suspend` 함수입니다. 코루틴 안에서 호출하세요.

```kotlin
val result = GoPassSDK.initialize(
    apiKey = BuildConfig.GHOSTPASS_API_KEY,
    context = applicationContext
)

val deviceId = result.deviceId
val hasBioData = result.hasBioData
val registeredAt = result.registeredAt
```

`deviceId`는 파트너 서버 계정과 직접 매핑해야 합니다.

### 4.5 생체 데이터 등록 여부 조회

```kotlin
val result = GoPassSDK.hasBioData()

if (result.hasBioData) {
    // 이미 등록됨
} else {
    // 미등록
}
```

### 4.6 얼굴 등록

카메라에서 추출한 NV21 프레임을 `GoPassSDK.registerBioData(...)` 에 전달합니다.

```kotlin
when (
    val status = GoPassSDK.registerBioData(
        faceImage = nv21Bytes,
        width = width,
        height = height,
        rotation = rotationDegrees
    )
) {
    is BioDataFrameStatus.Success -> {
        // 등록 완료
    }
    is BioDataFrameStatus.ContinueCapture -> {
        // 가이드 메시지 표시
        val message = status.reason.message
        showGuide(message)
    }
}
```

### 4.7 생체 정보 삭제

```kotlin
val removed = GoPassSDK.removeBioData()
```

### 4.8 SDK 초기화 상태 복구

```kotlin
GoPassSDK.reset()
```

### 4.9 HandsFree 인증 (선택)

HandsFree를 사용하는 경우 Firebase Cloud Messaging 설정이 필요합니다.

#### Push Token 등록

```kotlin
val token = FirebaseMessaging.getInstance().token.await()
GoPassSDK.registerFcmToken(token)
```

#### 인증 세션 위임

```kotlin
override fun onMessageReceived(message: RemoteMessage) {
    val json = JSONObject(message.data as Map<*, *>).toString()

    CoroutineScope(Dispatchers.IO).launch {
        try {
            GoPassSDK.delegateAuthSession(json, applicationContext)
        } catch (e: GoPassException) {
            Log.e(TAG, "delegateAuthSession 실패: code=${e.code}, message=${e.message}")
        }
    }
}
```

> 📄 상세한 API Reference, 에러 처리, 코드 예시는 [Android 유저 연동 가이드](docs/Android/user_guide_kr.md)를 참고하세요.

---

## 문서

| 문서 | 내용 |
|------|------|
| [Android 키오스크 연동 가이드](docs/Android/kiosk_guide_kr.md) | 설치, 초기화, 얼굴 인증, API Reference |
| [Android 유저 연동 가이드](docs/Android/user_guide_kr.md) | 설치, 초기화, 생체 등록, HandsFree, API Reference |
| [iOS 유저 연동 가이드](docs/iOS/user_guide_kr.md) | 설치, 초기화, 얼굴 등록·인증, API Reference |
| [에러 코드](docs/error_codes.md) | 에러 타입별 설명 및 처리 방법 |

---

## 지원

연동 문의 및 기술 지원: **sdk-support@ghostpass.ai**
