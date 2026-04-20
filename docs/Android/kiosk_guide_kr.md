# GhostPass Android 키오스크 SDK — 개발자 문서

> **버전** 1.0.0 · **지원 플랫폼** Android API 23+ · **배포 형식** Maven repository
> **최종 업데이트** 2026년 4월 17일

---

## 목차

1. [개요](#1-개요)
2. [설치](#2-설치)
3. [사전 준비](#3-사전-준비)
4. [API Reference](#4-api-reference)
5. [운영 및 연동 주의사항](#5-운영-및-연동-주의사항)
6. [에러 처리](#6-에러-처리)
7. [FAQ](#7-faq)

---

## 1. 개요

### 1.1 GhostPass 키오스크 SDK란?

GhostPass 키오스크 SDK는 Android 키오스크 단말에 비접촉 얼굴 인증을 통합하기 위한 보안 SDK입니다. 인증 준비, 얼굴 검출, Liveness Detection, 얼굴 특징 추출, 서버 인증 연동을 SDK 내부에서 처리합니다.

공개 진입점은 아래 5개입니다.

```kotlin
initialize(context, apiKey, kioskId, beaconConfig)
→ detection(faceImage, width, height, rotationDegrees)
→ preparePhoneAuth(faceImage, width, height, rotationDegrees)
→ submitPhoneAuth(deviceId)
→ reset()
```

### 1.2 주요 기능

| 기능 | 설명 |
|------|------|
| 근접 인증 지원 | 사용자 앱이 키오스크 인근에서 인증을 시작할 수 있도록 필요한 준비를 지원 |
| 얼굴 인증 | 카메라 프레임에서 얼굴 검출, Liveness, 특징 추출, 서버 인증까지 수행 |
| 휴대폰 인증 | 얼굴을 먼저 촬영한 뒤 `deviceId` 기반 단일 세션 인증 수행 |
| 인증 준비 상태 관리 | 초기화 후 인증에 필요한 서버 연동 상태를 SDK가 자동으로 유지 |
| 자동 복구 | 네트워크나 블루투스 상태 변화 시 필요한 기능을 자동으로 다시 활성화 |

### 1.3 동작 흐름

```text
① 서비스 등록 (1회)
   GhostPass 담당자에게 키오스크 정보 전달
   → API Key · KioskId · BeaconConfig 수령

② SDK 초기화 (앱 실행 시 1회)
   initialize()
   → 프로비저닝 필요 시 수행
   → FaceSDK 초기화
   → 근접 인증 기능 활성화
   → 인증 준비 완료

③ 얼굴 인증
   detection()
   → 얼굴 검출
   → Liveness 검사
   → 특징 추출
   → 서버 인증 시도

④ 휴대폰 인증
   preparePhoneAuth()
   → 얼굴 검증 및 휴대폰 인증 준비
   submitPhoneAuth(deviceId)
   → 휴대폰 인증 요청 및 결과 확인
```

### 1.4 최소 요구 사항

| 항목 | 값 |
|------|----|
| Android `minSdk` | 23 |
| Android `compileSdk` | 35 |
| Kotlin | 2.1+ 권장 |
| Java / JVM | 17 |
| 네이티브 ABI | `arm64-v8a` |
| 카메라 입력 | NV21 포맷 프레임 |

### 1.5 파트너 앱 설정 요구사항

호스트 앱에서 아래 권한을 선언해야 합니다.

| 권한 | 설명 |
|------|------|
| `INTERNET` | 서버 통신 |
| `BLUETOOTH` | 근접 인증 기능 지원 (Android 11 이하) |
| `BLUETOOTH_ADVERTISE` | 근접 인증 기능 지원 (Android 12+) |
| `CAMERA` | 얼굴 인증 프레임 수집 |

추가 참고:

- `BLUETOOTH_ADVERTISE`는 Android 12 이상에서 런타임 허용이 필요합니다.
- SDK 라이브러리 Manifest에는 `ACCESS_NETWORK_STATE`가 포함되어 있어 네트워크 상태 감지에 사용됩니다.

---

## 2. 설치

현재 배포 정책은 아래와 같습니다.

| 대상 | 배포 Variant | 저장소 | Artifact |
|------|-------------|--------|----------|
| 파트너사 | `prodRelease` | Public Pages | `com.ghostpass:gopass-kiosk-sdk:1.0.0` |

### 2.1 파트너사용 사용자(`prodRelease`)

파트너사 SDK는 모두 Public Pages 저장소를 사용합니다.

`settings.gradle.kts`

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

`app/build.gradle.kts`

운영용(`prodRelease`) 연동:

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-kiosk-sdk:1.0.0")
}
```

개발용 공개 빌드(`devRelease`) 연동:

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-kiosk-sdk-dev:1.0.0")
}
```

### 2.2 사내 전용 사용자(`devDebug`)

사내 개발/테스트용 `devDebug` 아티팩트만 GitHub Packages 인증이 필요합니다.

`~/.gradle/gradle.properties`

```properties
gpr.user=YOUR_GITHUB_USERNAME
gpr.key=YOUR_GITHUB_PAT_CLASSIC
```

`settings.gradle.kts`

```kotlin
dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
        maven {
            url = uri("https://maven.pkg.github.com/ghostpass-ai/ghostpass-sdk-distribution-dev")
            credentials {
                username = providers.gradleProperty("gpr.user").orNull
                    ?: System.getenv("GITHUB_USERNAME")
                password = providers.gradleProperty("gpr.key").orNull
                    ?: System.getenv("GITHUB_TOKEN")
            }
        }
    }
}
```

`app/build.gradle.kts`

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-kiosk-sdk-dev-debug:1.0.0")
}
```

### 2.3 공통 Manifest 예시

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.CAMERA" />
```
> Android 12 (API 31) 이상에서는 `BLUETOOTH_ADVERTISE` 권한을 **런타임**에 직접 요청해야 합니다.

---

## 3. 사전 준비

### 3.1 서비스 등록 및 API Key 발급

GhostPass 담당자에게 다음 정보를 전달합니다.

| 항목 | 예시 |
|------|------|
| 회사명 | (주)고스트패스 |
| 서비스명 | A사 편의점 페이 |
| 환경 | `dev` / `prod` |
| 담당자 이메일 | `dev@company.com` |
| Android `minSdk` | `23` |

발급 정보:

| 항목 | 설명 |
|------|------|
| `API Key` | SDK 초기화에 사용 |
| `KioskId` | 키오스크 고유 식별자 |
| `BeaconConfig` | 근접 인증 기능 설정값 |
| Maven 저장소 주소 | 환경별 저장소 URL |
| Artifact 좌표 | 환경별 dependency 좌표 |

현재 배포 경로 기준 예시는 아래와 같습니다.

| 구분 | 저장소 | Artifact |
|------|--------|----------|
| 파트너사용 | `https://ghostpass-ai.github.io/ghostpass-sdk-distribution/` | `com.ghostpass:gopass-kiosk-sdk:1.0.0` |

### 3.2 API Key 관리

소스 코드에 하드코딩하지 말고 `local.properties`, CI secret, 또는 안전한 런타임 주입 방식을 사용하세요.

```properties
GHOSTPASS_API_KEY=gp_dev_xxxxxxxxxxxxxxxxx
```

```kotlin
GoPassKioskSdk.initialize(
    context = applicationContext,
    apiKey = BuildConfig.GHOSTPASS_API_KEY,
    kioskId = kioskId,
    beaconConfig = beaconConfig
)
```

### 3.3 KioskId · BeaconConfig

#### KioskId

| 필드 | 타입 | 설명 |
|------|------|------|
| `svc` | `String` | 서비스 코드 |
| `region` | `String` | 지역 코드 |
| `branch` | `String` | 지점 코드 |
| `seq` | `String` | 단말 순번 |

#### BeaconConfig

| 필드 | 타입 | 설명 | 범위 |
|------|------|------|------|
| `uuid` | `String` | 표준 UUID 형식 | UUID 문자열 |
| `major` | `Int` | 발급받은 설정값 | `0..65535` |
| `minor` | `Int` | 발급받은 설정값 | `0..65535` |

입력값이 비어 있거나 형식이 맞지 않으면 `initialize()`에서 `GP001`이 발생합니다.

---

## 4. API Reference

### 4.1 `initialize()`

```kotlin
@Throws(GoPassSdkException::class)
suspend fun initialize(
    context: Context,
    apiKey: String,
    kioskId: KioskId,
    beaconConfig: BeaconConfig
): Boolean
```

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `context` | `Context` | `applicationContext` 권장 |
| `apiKey` | `String` | 발급받은 API Key |
| `kioskId` | `KioskId` | 키오스크 식별자 |
| `beaconConfig` | `BeaconConfig` | 근접 인증 기능 설정 |

반환:

- `true`: 초기화 성공

동작:

- 입력값 검증
- 필요 시 프로비저닝 수행
- FaceSDK 초기화
- 근접 인증 기능 활성화
- 인증 가능 상태 준비

특징:

- 멱등성을 보장합니다. 동시에 여러 번 호출되어도 실제 초기화는 한 번만 수행됩니다.
- 실패 시 내부 상태를 정리하고 재시도가 가능합니다.

### 4.2 서버 연결 동작

`initialize()` 성공 후 인증 준비 상태와 서버 연결은 SDK가 자동 관리합니다.

현재 2.0.0 기준:

- 별도의 연결 상태 조회 API는 제공하지 않습니다.
- 앱에서는 `initialize()` 성공 여부와 `detection()`/`submitPhoneAuth()` 결과만 기준으로 연동하면 됩니다.
- 연결이 일시적으로 불안정해져도 SDK가 자동으로 복구를 시도합니다.

### 4.3 `detection()`

```kotlin
@Throws(GoPassSdkException::class)
suspend fun detection(
    faceImage: ByteArray?,
    width: Int,
    height: Int,
    rotationDegrees: Int
): GoPassAuthResult
```

요청:

| 파라미터 | 타입 | 설명 |
|----------|------|------|
| `faceImage` | `ByteArray?` | NV21 프레임 |
| `width` | `Int` | 프레임 너비 |
| `height` | `Int` | 프레임 높이 |
| `rotationDegrees` | `Int` | CameraX 회전 각도 |

응답:

```kotlin
sealed class GoPassAuthResult {
    data class PrecheckGuide(val reasons: List<FailReason>) : GoPassAuthResult()
    data object Success : GoPassAuthResult()
    data class ServerAuthFailed(
        val message: String,
        val errorCode: ErrorCode
    ) : GoPassAuthResult()
}
```

`PrecheckGuide`의 주요 이유:

| FailReason | 설명 |
|------------|------|
| `NO_FACE` | 얼굴 미검출 |
| `INVALID_POSE_ROLL` | 얼굴 기울기 불량 |
| `INVALID_POSE_PITCH` | 상하 각도 불량 |
| `INVALID_POSE_YAW` | 좌우 각도 불량 |
| `INVALID_POSITION` | 얼굴 위치 불량 |
| `INVALID_SIZE_MAX` | 너무 가까움 |
| `INVALID_SIZE_MIN` | 너무 멂 |
| `LOW_LANDMARK_CONFIDENCE` | 랜드마크 신뢰도 낮음 |
| `LIVENESS_NOT_CONFIRMED` | Liveness 수집 중 |
| `LIVENESS_TX_FAILED` | Liveness 실패 |
| `NO_SESSION` | 인증 대기 세션 없음 |
| `ALREADY_IN_PROGRESS` | 다른 인증 진행 중 |
| `OOM` | 메모리 부족 |
| `UNKNOWN` | 기타 일시 오류 |

참고:

- 인증 가능한 사용자가 없으면 `NO_SESSION`이 반환될 수 있습니다.
- 인증 실패 후에는 다음 프레임에서 다시 시도할 수 있습니다.

### 4.4 `preparePhoneAuth()`

```kotlin
@Throws(GoPassSdkException::class)
suspend fun preparePhoneAuth(
    faceImage: ByteArray?,
    width: Int,
    height: Int,
    rotationDegrees: Int
): GoPassAuthResult
```

용도:

- 휴대폰 인증에 필요한 얼굴 검증 단계만 먼저 수행합니다.
- 성공 시 `submitPhoneAuth(deviceId)`를 호출할 수 있는 상태가 됩니다.
- 이후 `submitPhoneAuth(deviceId)`를 호출할 수 있습니다.

동작 제약:

- 준비 상태의 유효 시간은 30초입니다.
- 결과 타입은 `detection()`과 동일하게 `GoPassAuthResult`입니다.
- 네트워크가 끊겨 있으면 `ServerAuthFailed(GP901)`가 반환될 수 있습니다.

### 4.5 `submitPhoneAuth()`

```kotlin
@Throws(GoPassSdkException::class)
suspend fun submitPhoneAuth(deviceId: String): GoPassAuthResult
```

용도:

- `preparePhoneAuth()` 이후 `deviceId`를 사용해 휴대폰 인증을 완료합니다.
- `deviceId` 기준으로 휴대폰 인증 요청을 전송하고 결과를 반환합니다.

반환 규칙:

| 결과 | 설명 |
|------|------|
| `Success` | 휴대폰 인증 성공 |
| `PrecheckGuide(ALREADY_IN_PROGRESS)` | 다른 인증과 충돌 |
| `ServerAuthFailed(GP101)` | 결과 대기 시간 초과 |
| `ServerAuthFailed(GP102)` | 인증 거절 |
| `ServerAuthFailed(GP103)` | 기타 인증 흐름 오류 |
| `ServerAuthFailed(GP201)` | 저장 랜드마크 만료 |

추가 참고:

- 결과 대기 시간은 현재 8초입니다.
- `preparePhoneAuth()`가 먼저 성공해야 합니다.
- 준비 상태가 없거나 이미 정리된 상태면 `GP103`이 반환될 수 있습니다.

### 4.6 `reset()`

```kotlin
@Throws(GoPassSdkException::class)
suspend fun reset(): Boolean
```

동작:

- SDK가 사용 중인 자원을 정리합니다.
- 이후 다시 `initialize()`를 호출해 재초기화할 수 있습니다.

반환:

- `true`: 정상 정리 완료

권장 호출 시점:

- 다른 `KioskId` 또는 `BeaconConfig`로 재초기화해야 할 때
- 앱에서 SDK 상태를 완전히 초기화해야 할 때
- 복구 불가 상태에서 명시적으로 자원을 정리할 때

---

## 5. 운영 및 연동 주의사항

### 5.1 카메라 입력 처리

- `detection()`과 `preparePhoneAuth()`는 메인 스레드가 아니라 별도 analyzer/executor에서 호출하세요.
- 이전 호출이 끝나기 전에 다음 프레임을 보내지 않도록 중복 호출 방지 처리를 권장합니다.
- 권장 입력 해상도는 `960x1280`입니다.
- 입력 프레임은 NV21 변환 후 전달하세요.

### 5.2 자동 복구 정책

- 블루투스가 꺼지면 근접 인증 관련 기능이 제한될 수 있습니다.
- 블루투스나 네트워크가 복구되면 필요한 기능을 자동으로 다시 활성화할 수 있습니다.
- 앱에서 별도의 복구 로직을 강제하지 않도록 설계되어 있습니다.

### 5.3 시간 정책

| 항목 | 값 |
|------|----|
| 휴대폰 인증 준비 유효 시간 | 30초 |
| 휴대폰 인증 결과 대기 시간 | 8초 |

### 5.4 Fatal 예외가 발생하는 경우

아래 경우에는 `GoPassSdkException`이 바로 발생할 수 있습니다.

- `initialize()` 이전에 `detection()` 호출
- `initialize()` 이전에 `preparePhoneAuth()` 호출
- `initialize()` 이전에 `submitPhoneAuth()` 호출
- `initialize()` 이전에 `reset()` 호출
- 초기화 중 입력값 검증 실패
- 필수 블루투스 권한 부족, 블루투스 비활성, 지원되지 않는 기기 환경

---

## 6. 에러 처리

### 6.1 `GoPassSdkException`

```kotlin
class GoPassSdkException(
    val code: String,
    override val message: String,
    val causeCode: String?
) : Exception(message)
```

- `code`: 외부 에러 코드
- `causeCode`: 내부 원인 코드

### 6.2 외부 에러 코드

#### 초기화 관련

| 코드 | Enum | 설명 |
|------|------|------|
| `GP001` | `INVALID_ARGUMENT` | 입력값 오류 |
| `GP002` | `KIOSK_ALREADY_ENROLLED` | 이미 등록된 키오스크 |
| `GP003` | `KIOSK_NOT_FOUND` | 키오스크 미등록 |
| `GP004` | `KIOSK_INACTIVE` | 비활성 키오스크 |
| `GP005` | `KIOSK_INVALID_ID_FORMAT` | 키오스크 ID 형식 오류 |
| `GP006` | `INIT_FAILED` | 초기화 실패 |
| `GP007` | `BLUETOOTH_DISABLED` | 블루투스 꺼짐 |
| `GP008` | `BLUETOOTH_PERMISSION_DENIED` | 필수 블루투스 권한 거부 |
| `GP009` | `BLUETOOTH_UNSUPPORTED_DEVICE` | 지원되지 않는 블루투스 환경 |

#### 얼굴/휴대폰 인증 관련

| 코드 | Enum | 설명 |
|------|------|------|
| `GP101` | `AUTH_TIMEOUT` | 인증 시간 초과 |
| `GP102` | `AUTH_REJECTED` | 인증 거절 |
| `GP103` | `AUTH_ERROR` | 인증 흐름 오류 |
| `GP201` | `PHONE_AUTH_LANDMARK_EXPIRED` | 휴대폰 인증용 랜드마크 만료 |

#### 공통

| 코드 | Enum | 설명 |
|------|------|------|
| `GP901` | `NETWORK_ERROR` | 네트워크 오류 |
| `GP902` | `SERVER_ERROR` | 서버 오류 |
| `GP903` | `INVALID_API_KEY` | API Key 오류 |
| `GP904` | `INTERNAL_ERROR` | 내부 오류 |
| `GP905` | `RESET_FAILED` | reset 실패 |
| `GP999` | `UNKNOWN` | 알 수 없는 오류 |

### 6.3 처리 예시

```kotlin
try {
    GoPassKioskSdk.initialize(
        context = applicationContext,
        apiKey = BuildConfig.GHOSTPASS_API_KEY,
        kioskId = kioskId,
        beaconConfig = beaconConfig
    )
} catch (e: GoPassSdkException) {
    Log.e(TAG, "code=${e.code}, causeCode=${e.causeCode}, message=${e.message}")
}
```

```kotlin
when (val result = GoPassKioskSdk.detection(nv21, width, height, rotation)) {
    is GoPassAuthResult.Success -> handleSuccess()
    is GoPassAuthResult.PrecheckGuide -> showGuide(result.reasons.firstOrNull()?.message.orEmpty())
    is GoPassAuthResult.ServerAuthFailed -> showError(result.message)
}
```

---

---

## 7. FAQ

**Q1. `initialize()` 호출 후 근접 인증 기능이 정상 동작하지 않습니다.**
A. Android 12 이상에서는 `BLUETOOTH_ADVERTISE` 런타임 권한이 허용되어 있어야 합니다. 초기화 호출 전에 권한 요청을 완료했는지 확인하세요.

---

**Q2. `PrecheckGuide`에 `NO_SESSION`이 계속 반환됩니다.**
A. 현재 인증 가능한 사용자가 준비되지 않은 상태일 때 반환됩니다. 인증 시작 조건이 충족된 뒤 다시 시도해 주세요.

---

**Q3. `detection()` 호출 시 `ALREADY_IN_PROGRESS`가 반환됩니다.**
A. 이전 `detection()` 호출이 아직 처리 중인 상태입니다. 중복 호출이 발생하지 않도록 한 번에 하나의 요청만 처리하세요.

---

**Q4. 에뮬레이터에서 테스트할 수 있나요?**
A. 에뮬레이터는 블루투스와 카메라 기능이 제한적이므로 정상 동작을 보장하지 않습니다. 반드시 **실기기**에서 테스트하세요.

---

**Q5. `initialize()`를 여러 번 호출하면 어떻게 되나요?**
A. 이미 초기화가 진행 중이거나 완료된 경우 내부적으로 중복 실행을 방지합니다. 단, 초기화 실패 후에는 재시도가 가능합니다.

---

**Q6. `reset()`은 언제 호출해야 하나요?**
A. 다른 `KioskId`/`BeaconConfig` 로 재초기화해야 하거나, 앱에서 SDK 상태를 완전히 정리한 뒤 다시 시작해야 할 때 호출합니다. `reset()` 이후에는 `initialize()` 를 다시 호출해야 합니다.

---

**Q7. 문의 시 어떤 정보를 전달해야 하나요?**
A. `GoPassSdkException`의 `code`와 `causeCode`를 함께 전달해 주세요.

```kotlin
// 로그 예시
Log.e(TAG, "code=${e.code}, causeCode=${e.causeCode}, message=${e.message}")
// → "code=GP006, causeCode=IN-1101, message=초기화 중 문제가 발생하였습니다."
```

---

*© GhostPass AI. All rights reserved.*