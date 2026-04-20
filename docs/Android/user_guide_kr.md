# GhostPass Android SDK — 개발자 문서

> **버전** 1.0.0 · **지원 플랫폼** Android API 24+ · **배포 형식** Maven repository
> **최종 업데이트** 2026년 4월 17일

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

GhostPass SDK는 Android 앱에 **비접촉 생체 정보 인식 인증**을 손쉽게 통합할 수 있는 보안 SDK입니다.
Liveness Detection(위조 방지), 얼굴 특징 추출, 서버 연동을 모두 내부에서 처리하므로, 파트너 개발자가 직접 다뤄야 할 것은 **딱 3가지**입니다.

```
initialize(apiKey, context)  →  registerBioData(faceImage, ...)  →  (필요시) removeBioData()
```

### 1.2 주요 기능

| 기능 | 설명 |
|------|------|
| 생체 정보 등록 | 카메라 이미지로부터 생체 정보 특징 벡터 추출 및 로컬 저장 |
| Liveness Detection | NV21 기반 안티 스푸핑으로 사진·영상 위조 방지 |
| 생체 정보 인증 | 등록된 특징 벡터와 실시간 생체 정보 비교 |
| 보안 저장 | 모든 민감 데이터는 Android Keystore + 암호화된 SharedPreferences에만 저장 |

### 1.3 동작 흐름

GhostPass SDK는 **API Key 한 줄**로 연동을 시작하며, 내부 보안 처리(기기 검증, 암호화, 인증 세션 관리)는 모두 SDK가 자동으로 수행합니다.

```
① 서비스 등록 (1회)
   GhostPass 담당자에게 패키지명 전달 → API Key 수령

② SDK 초기화 (앱 실행 시 1회)
   initialize(apiKey, context) 호출 → SDK 내부 보안 채널 자동 수립

③ 얼굴 등록 (사용자당 1회)
   registerBioData(faceImage, ...) 호출 → 생체 정보 추출 + Liveness 검사 + 특징 추출 + 안전 저장

④ 자동 인증 (키오스크 근접 시 자동 동작)
   키오스크 비콘 감지 → 인증 세션 수립 → 기기 내 얼굴 매칭
```

#### 파트너사에서 직접 구현할 것

| 단계 | 호출 | SDK 동작 |
|------|------|---------------|
| 초기화 | `initialize(apiKey, context)` 1회 | 기기 검증 · 보안 채널 수립 · 내부 키 관리 |
| 생체 데이터 등록 여부 | `hasBioData()` | 생체 데이터 존재 여부 반환 |
| 생체 정보 등록 | `registerBioData(faceImage, ...)` | 생체 정보 추출 · Liveness 검사 · 특징 추출 · 안전한 저장 |
| 생체 정보 삭제 | `removeBioData()` | 생체 정보 삭제 · 비콘 스캔 종료 |
| SDK 초기화 상태 복구 | `reset()` | 모든 SDK 데이터 초기화 · 비콘 스캔 종료 |

### 1.4 최소 요구 사항

| 항목 | 최솟값 |
|------|--------|
| Android `minSdk` | 24 |
| Android `compileSdk` | 35 |
| Kotlin | 2.x 권장 |
| Java / JVM | 17 |
| 아키텍처 | `arm64-v8a` (실기기 전용, 에뮬레이터 미지원) |
| 카메라 입력 | NV21 포맷 프레임 |
| Google Play Services | 필수 (Play Integrity 사용) |

### 1.5 파트너사 앱 설정 요구사항

SDK Manifest에 필요한 권한이 모두 포함되어 있어 **별도 권한 선언은 불필요**합니다 (빌드 시 자동 머지).
다만 아래 **Dangerous 권한은 런타임에 사용자 승인이 필요**하므로, `initialize()` 호출 전에 `requestPermissions()`를 완료하세요.

#### 런타임 권한 요청 (호스트 앱 책임)

| 권한 | 대상 | 비고 |
|------|------|------|
| `CAMERA` | 전 버전 | 생체 정보 등록 시 카메라 사용 |
| `ACCESS_FINE_LOCATION` | 전 버전 | BLE 스캔 필수 |
| `ACCESS_COARSE_LOCATION` | 전 버전 | 위치 권한 기본 |
| `ACCESS_BACKGROUND_LOCATION` | Android 10+ | 위치 **'항상 허용'** 필요. FINE 승인 후 별도 요청 |
| `BLUETOOTH_SCAN` | Android 12+ | BLE 비콘 스캔 |
| `POST_NOTIFICATIONS` | Android 13+ | FCM 푸시 알림 표시 |

추가 참고:

- `CAMERA` 권한은 생체 정보 등록 시 호스트 앱에서 카메라를 직접 사용하므로 호스트 앱 Manifest에 선언 + 런타임 요청 필요
- 위치 권한은 **'항상 허용'** 상태여야 백그라운드 비콘 탐지가 정상 동작
- `INTERNET` · `FOREGROUND_SERVICE` · `BLUETOOTH` 등 Normal 권한은 SDK Manifest에서 자동 머지되며 런타임 요청 불필요

#### Gradle 의존성

```kotlin
dependencies {
    implementation("com.ghostpass:gopass-user-sdk:<version>")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
```

---

## 2. 설치

GhostPass SDK는 **Maven 저장소**를 통해 배포됩니다.

### 2.1 저장소 설정

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

### 2.2 의존성 추가

`app/build.gradle.kts`

```kotlin
android {
    defaultConfig {
        minSdk = 24
        ndk { abiFilters += "arm64-v8a" }
    }
    compileSdk = 35
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
}

dependencies {
    implementation("com.ghostpass:gopass-user-sdk:<version>")
    implementation("org.jetbrains.kotlinx:kotlinx-coroutines-android:1.9.0")
}
```

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
| 패키지명 | `applicationId` | `com.company.myapp` |
| 환경 | 개발(dev) / 운영(prod) 구분 | dev, prod |
| 담당자 이메일 | API Key 수령 이메일 | dev@company.com |

> **팁**: **개발용·운영용 패키지명이 다르다면 환경을 구분하여 각각 요청**하세요. GhostPass는 환경별로 격리된 API Key를 발급합니다.

#### Step 2. API Key 수령

등록 요청을 처리한 뒤 GhostPass 담당자가 보안 채널(이메일 암호화 또는 지정 메신저)로 아래 정보를 전달합니다.

```
API_KEY  : gp_dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx  (공개용 — 앱에 포함)
```

> **주의**: `APP_SECRET`(서버 내부 키)은 앱에 포함되지 않으며 파트너사에 전달되지 않습니다. SDK가 최초 실행 시 서버와 ECDH 프로토콜을 통해 안전하게 파생합니다.

#### Step 3. API Key 앱에 적용

소스 코드에 하드코딩하지 않고 **빌드 환경변수**로 분리하는 것을 강력 권장합니다.

**방법 A — `local.properties` (권장)**

```properties
# local.properties  ← .gitignore에 반드시 포함
GHOSTPASS_API_KEY=gp_dev_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
```

`app/build.gradle.kts`에서 참조:

```kotlin
val localProperties = Properties().apply {
    rootProject.file("local.properties").inputStream().use { load(it) }
}

android {
    defaultConfig {
        buildConfigField("String", "GHOSTPASS_API_KEY",
            "\"${localProperties.getProperty("GHOSTPASS_API_KEY")}\"")
    }
}
```

Kotlin 코드에서 SDK에 전달:

```kotlin
val result = GoPassSDK.initialize(
    apiKey = BuildConfig.GHOSTPASS_API_KEY,
    context = applicationContext
)
```

**방법 B — CI/CD 환경 변수 (GitHub Actions 등)**

```yaml
- name: Build
  env:
    GHOSTPASS_API_KEY: ${{ secrets.GHOSTPASS_API_KEY }}
  run: ./gradlew assembleRelease
```

> **주의**: API Key를 소스 코드에 **직접 커밋하지 마세요**. 노출 시 즉시 GhostPass 담당자에게 Key 폐기 및 재발급을 요청하세요.

#### API Key 운영 정책

| 항목 | 내용 |
|------|------|
| 발급 주체 | GhostPass 담당자 직접 생성 후 전달 |
| 유효 기간 | 계약 기간 연동 (만료 30일 전 사전 안내) |
| 환경 분리 | 개발(dev) / 운영(prod) Key 별도 발급 |
| Key 폐기·재발급 | GhostPass 담당자에게 요청 (즉시 처리) |

---

### 3.2 런타임 권한 요청

BLE · 위치 관련 권한은 SDK Manifest에서 자동 머지되므로 **호스트 앱 Manifest에 별도 선언이 불필요**합니다.
단, `CAMERA`는 호스트 앱이 카메라를 직접 사용하므로 호스트 앱에서 선언해야 합니다.

```xml
<!-- 호스트 앱에서 선언 필요 -->
<uses-permission android:name="android.permission.CAMERA" />
```

아래 Dangerous 권한은 `initialize()` 호출 전에 런타임 요청을 완료해야 합니다.

```kotlin
// 1단계: 기본 권한 (카메라 + 위치 + BLE + 알림)
val permissions = mutableListOf(
    Manifest.permission.CAMERA,
    Manifest.permission.ACCESS_FINE_LOCATION,
    Manifest.permission.ACCESS_COARSE_LOCATION,
).apply {
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {         // Android 12+
        add(Manifest.permission.BLUETOOTH_SCAN)
    }
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {  // Android 13+
        add(Manifest.permission.POST_NOTIFICATIONS)
    }
}
requestPermissions(permissions.toTypedArray(), REQUEST_CODE)

// 2단계: 위치 '항상 허용' — FINE_LOCATION 승인 후 별도 요청
// (시스템 정책상 1단계와 동시에 요청할 수 없음)
if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
    requestPermissions(
        arrayOf(Manifest.permission.ACCESS_BACKGROUND_LOCATION),
        REQUEST_CODE_BG
    )
}
```

> **참고**: 위치 권한은 **'항상 허용'** 상태여야 백그라운드 비콘 탐지가 정상 동작합니다. '앱 사용 중에만 허용'은 앱이 포그라운드일 때만 동작하므로 사용자에게 '항상 허용' 선택을 안내하세요.

> **주의**: 권한 미획득 상태에서 `initialize()`를 호출하면 비콘 모니터링 시작 시 `GoPassException`이 발생합니다. 초기화 전에 모든 권한 요청을 완료하세요.

---

## 4. API Reference

### 4.1 SDK 초기화

SDK를 사용하기 전 반드시 초기화를 완료해야 합니다. 초기화는 앱 실행 시점 **한 번만** 호출합니다.

#### 4.1.1 API 형태 및 설명

**request**

| 항목 | 타입 | 설명 | 예시 |
|------|------|------|------|
| apiKey | String | `3. 사전 준비` 시 발급 받은 apiKey | `gp_dev_xxxxxx...` |
| context | Context | `applicationContext` 권장 | `applicationContext` |

**response**

| 타입 | 필드 | 설명 | 예시 |
|----|------|------|-----------|
| InitResult | `deviceId` | SDK가 발급한 사용자 식별자. 유저가 파트너사 앱 재설치 시 변경될 수 있습니다. | `"7612bd71dfc485cf..."` |
| | `hasBioData` | 생체 데이터 등록 여부. `true`이면 이미 등록되어 있으므로 `registerBioData()` 호출이 불필요합니다. | `true` / `false` |
| | `registeredAt` | 생체 데이터 등록 일자. 미등록 시 `null`. | `"2026.04.17"` / `null` |

> **추가설명**: 반환된 `deviceId`는 파트너사의 DB 내 유저와 직접 매핑을 진행하여야 합니다. `hasBioData`를 활용하면 이미 등록된 유저에게 불필요한 생체 등록 화면을 건너뛸 수 있습니다.

```kotlin
suspend fun initialize(apiKey: String, context: Context): InitResult

data class InitResult(
    val deviceId: String,
    val hasBioData: Boolean,
    val registeredAt: String?
)
```

#### 4.1.2 예시

```kotlin
fun startSDK() {
    lifecycleScope.launch {
        try {
            val result = GoPassSDK.initialize(
                apiKey = BuildConfig.GHOSTPASS_API_KEY,
                context = applicationContext
            )
            /* result.deviceId를 파트너사 유저와 매핑하는 로직 */

            if (result.hasBioData) {
                // 이미 생체 데이터가 등록됨 → 등록 화면 스킵
            } else {
                // 생체 데이터 미등록 → registerBioData() 호출 필요
            }
        } catch (e: GoPassException) {
            Log.e(TAG, "${e.code} ${e.message}")
        }
    }
}
```

---

### 4.2 생체 정보 등록

카메라로 촬영한 이미지에서 생체 정보 특징 벡터를 추출하여 로컬에 안전하게 저장하고 비콘 탐지를 시작하는 과정입니다.

#### 4.2.1 API 형태 및 설명

**request**

| 항목 | 타입 | 설명 |
|------|------|------|
| faceImage | ByteArray | NV21 포맷 프레임 |
| width | Int | 프레임 너비 |
| height | Int | 프레임 높이 |
| rotation | Int | CameraX 회전 각도 (0, 90, 180, 270) |

**response**

| 타입 | 값 | 권장 처리 |
|----|------|-----------|
| BioDataFrameStatus | ContinueCapture(reason: CaptureGuide) | 가이드 메시지를 표시하고 카메라 캡처 유지 |
| | Success | 저장 완료. 카메라 캡처 중지 |

```kotlin
suspend fun registerBioData(
    faceImage: ByteArray,
    width: Int,
    height: Int,
    rotation: Int
): BioDataFrameStatus

sealed interface BioDataFrameStatus {
    data class ContinueCapture(val reason: CaptureGuide) : BioDataFrameStatus
    object Success : BioDataFrameStatus
}

enum class CaptureGuide(val code: String, val message: String) {
    NO_FACE_DETECTED("L1001", "얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요."),
    INVALID_POSE_ROLL("L1002", "고개를 삐딱하지 않게 똑바로 세워주세요."),
    INVALID_POSE_PITCH("L1003", "고개를 숙이거나 들지 말고 정면을 바라봐 주세요."),
    INVALID_POSE_YAW("L1004", "옆을 보지 말고 정면을 바라봐 주세요."),
    INVALID_POSITION("L1005", "얼굴 위치가 화면 중앙에서 벗어났습니다."),
    FACE_TOO_SMALL("L1006", "얼굴이 너무 멀리 있습니다. 카메라에 가까이 다가가 주세요."),
    FACE_TOO_BIG("L1007", "얼굴이 너무 가까이 있습니다. 한 걸음 뒤로 물러나 주세요."),
    LOW_CONFIDENCE("L1008", "얼굴 인식이 불안정합니다."),
    COLLECTING_FRAMES("L1009", "인증을 진행하고 있습니다..."),
    LIVENESS_NOT_CONFIRMED("L1010", "실제 사람인지 확인 중입니다. 잠시 멈춰주세요."),
    ALREADY_COMPLETED("L1011", "이미 완료되었습니다.")
}
```

#### 4.2.2 예시

> **권장 사항**:
> 1. **전용 Executor 생성**: `ImageAnalysis`의 analyzer는 반드시 별도의 single-thread executor에서 실행하세요. 메인 스레드를 사용하면 UI가 차단됩니다.
> 2. **Guard Flag 생성**: 카메라는 초당 30프레임 이상을 전송하므로, 이전 `registerBioData` 호출이 완료되기 전에 다음 프레임이 도착하면 호출이 중첩됩니다. `isProcessing` 플래그를 두어 처리 중인 동안 들어오는 프레임을 스킵하세요.

```kotlin
private val cameraExecutor = Executors.newSingleThreadExecutor()

@Volatile
private var isProcessing = false

@Volatile
private var isDone = false

override fun analyze(image: ImageProxy) {
    if (isDone || isProcessing || image.format != ImageFormat.YUV_420_888) {
        image.close()
        return
    }

    isProcessing = true

    val nv21 = toNv21(image)
    val width = image.width
    val height = image.height
    val rotation = image.imageInfo.rotationDegrees
    image.close()

    scope.launch {
        try {
            val result = GoPassSDK.registerBioData(
                faceImage = nv21,
                width = width,
                height = height,
                rotation = rotation
            )

            when (result) {
                is BioDataFrameStatus.Success -> {
                    isDone = true
                    withContext(Dispatchers.Main) { onRegisterSuccess() }
                }
                is BioDataFrameStatus.ContinueCapture -> {
                    // 예: L1001, 얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요.
                    Log.v(TAG, "${result.reason.code} ${result.reason.message}")
                }
            }
        } catch (e: GoPassException) {
            Log.e(TAG, "${e.code} ${e.message}")
        } finally {
            isProcessing = false
        }
    }
}
```

> **팁**: 등록 시 밝은 조명에서 정면을 바라보도록 UI 가이드를 제공하면 등록 성공률이 크게 향상됩니다.

---

### 4.3 생체 정보 삭제

로그아웃, 회원탈퇴, 유저의 선택과 같은 상황에 생체 정보를 삭제할 수 있습니다.

#### 4.3.1 API 형태 및 설명

```kotlin
suspend fun removeBioData(): Boolean
```

#### 4.3.2 예시

```kotlin
fun removeBioData() {
    lifecycleScope.launch {
        try {
            val isDeleted = GoPassSDK.removeBioData()
        } catch (e: GoPassException) {
            Log.e(TAG, "${e.code} ${e.message}")
        }
    }
}
```

---

### 4.4 생체 데이터 등록 여부 조회

`initialize()` 이후 언제든 생체 데이터가 등록되어 있는지 동기적으로 확인할 수 있습니다.
`initialize()` 반환값인 `InitResult.hasBioData`와 동일한 정보를 실시간으로 조회합니다.

#### 4.4.1 API 형태 및 설명

```kotlin
fun hasBioData(): HasBioDataResult

data class HasBioDataResult(
    val hasBioData: Boolean,
    val registeredAt: String?   // "yyyy.MM.dd" 형식 또는 null
)
```

| 반환값 | 설명 |
|--------|------|
| `hasBioData = true` | 생체 데이터가 저장되어 있음 |
| `hasBioData = false` | 생체 데이터가 없음 (등록 필요) |

#### 4.4.2 예시

```kotlin
val result = GoPassSDK.hasBioData()
if (result.hasBioData) {
    // 이미 등록됨 → 등록 화면 스킵
} else {
    // 미등록 → registerBioData() 호출 필요
}
```

---

### 4.5 SDK 초기화 상태 복구

SDK 내부 데이터(생체 데이터, 보안 채널, 세션 등)를 모두 삭제하고 초기 상태로 복구합니다.
회원 탈퇴, 계정 전환 등 SDK 전체를 처음 상태로 되돌려야 할 때 사용합니다.

> **주의**: `reset()` 호출 후 SDK를 다시 사용하려면 `initialize()`를 재호출해야 합니다.

#### 4.5.1 API 형태 및 설명

```kotlin
suspend fun reset()
```

#### 4.5.2 예시

```kotlin
fun resetSDK() {
    lifecycleScope.launch {
        try {
            GoPassSDK.reset()
            // 초기화 상태로 복구 완료 → 필요시 initialize() 재호출
        } catch (e: GoPassException) {
            Log.e(TAG, "${e.code} ${e.message}")
        }
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

`firebase-messaging` SDK를 프로젝트에 추가해야 합니다.

`app/build.gradle.kts`

```kotlin
plugins {
    id("com.google.gms.google-services")
}

dependencies {
    implementation(platform("com.google.firebase:firebase-bom:<version>"))
    implementation("com.google.firebase:firebase-messaging")
}
```

#### AndroidManifest

```xml
<!-- Android 13+ 푸시 알림 표시 권한 -->
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
```

#### Firebase 프로젝트 설정

1. [Firebase Console](https://console.firebase.google.com/)에서 Android 앱을 등록합니다
2. `google-services.json`을 다운로드하여 `app/` 디렉토리에 배치합니다
3. **Project Settings > Cloud Messaging**에서 서버 키가 활성화되어 있는지 확인합니다

---

### 5.2 Push Token 등록

FCM 토큰을 GhostPass 서버에 등록합니다. `initialize()` 성공 후 호출하세요.

#### 5.2.1 API 형태 및 설명

**request**

| 항목 | 타입 | 설명 |
|------|------|------|
| token | String | Firebase Messaging에서 발급받은 FCM 토큰 |

```kotlin
suspend fun registerFcmToken(token: String)
```

빈 문자열이나 공백만 있는 토큰을 전달하면 `GP103 (INVALID_PARAMETERS)` 에러가 발생합니다.

#### 5.2.2 예시

```kotlin
fun registerPushToken() {
    lifecycleScope.launch {
        try {
            val token = FirebaseMessaging.getInstance().token.await()
            GoPassSDK.registerFcmToken(token)
        } catch (e: GoPassException) {
            Log.e(TAG, "${e.code} ${e.message}")
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
| session | String | Push notification의 `data`를 JSON 문자열로 변환한 값 |
| context | Context | `applicationContext` 권장 |

```kotlin
@Throws(GoPassException::class)
suspend fun delegateAuthSession(session: String, context: Context)
```

#### 5.3.2 FirebaseMessagingService 설정

HandsFree Push를 수신하려면 `FirebaseMessagingService`를 구현해야 합니다.

```kotlin
class AppFirebaseMessagingService : FirebaseMessagingService() {

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    override fun onDestroy() {
        scope.cancel()
        super.onDestroy()
    }

    override fun onNewToken(token: String) {
        scope.launch {
            try {
                GoPassSDK.registerFcmToken(token)
            } catch (e: Throwable) {
                // SDK init 이전 호출 가능 — 무시
            }
        }
    }

    override fun onMessageReceived(message: RemoteMessage) {
        val data = message.data
        when (data["type"]) {
            "SESSION_CREATED" -> handleSessionCreated(data)
        }
    }

    private fun handleSessionCreated(data: Map<String, String>) {
        scope.launch {
            try {
                val json = JSONObject(data).toString()
                GoPassSDK.delegateAuthSession(json, applicationContext)
            } catch (e: GoPassException) {
                Log.e(TAG, "code=${e.code}, message=${e.message}")
            }
        }
    }
}
```

#### AndroidManifest 등록

```xml
<service
    android:name=".AppFirebaseMessagingService"
    android:exported="false">
    <intent-filter>
        <action android:name="com.google.firebase.MESSAGING_EVENT" />
    </intent-filter>
</service>
```

> **팁**: FCM 토큰은 앱 재설치, Firebase SDK 업데이트 등으로 변경될 수 있습니다. `onNewToken()`에서 갱신된 토큰을 `registerFcmToken()`으로 재등록하세요.

---

## 6. 에러 처리

### 6.1 에러 코드 정의

GhostPass SDK를 사용하며 발견될 수 있는 에러 코드입니다.

#### 6.1.1 GP0xx — 기기 환경 및 권한

비콘 탐지 및 인증 수행 중 발생할 수 있는 에러입니다.

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP001 | `BLUETOOTH_DISABLED` | 블루투스를 활성화해주세요 |
| GP002 | `BLUETOOTH_PERMISSION_DENIED` | 블루투스 권한이 필요합니다 |
| GP003 | `LOCATION_PERMISSION_DENIED` | 위치 서비스 권한이 필요합니다 |
| GP004 | `LOCATION_PERMISSION_INSUFFICIENT` | 위치 서비스 권한이 부족합니다 |
| GP005 | `BEACON_UUID_NOT_FOUND` | 인증 정보를 확인할 수 없습니다 |
| GP006 | `NETWORK_DISCONNECTED` | 네트워크 연결을 확인해주세요 |

#### 6.1.2 GP1xx — `initialize()`

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP101 | `INITIALIZATION_FAILED` | 초기화를 실패했습니다 |
| GP102 | `UPDATE_SDK` | SDK 버전이 최신이 아닙니다 |
| GP103 | `INVALID_PARAMETERS` | 요청 파라미터가 올바르지 않습니다 |

#### 6.1.3 GP2xx — `registerBioData()` / `removeBioData()`

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP201 | `REGISTER_BIO_DATA_FAILED` | 생체 데이터 등록에 실패했습니다 |
| GP202 | `REMOVE_BIO_DATA_FAILED` | 생체 데이터 삭제에 실패했습니다 |

#### 6.1.4 GP3xx — `reset()`

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP301 | `RESET_FAILED` | 초기 상태 복구에 실패했습니다 |

#### 6.1.5 L10xx — 얼굴 등록 가이드 (`CaptureGuide`)

`registerBioData()`가 `ContinueCapture`를 반환하는 경우, 아래 가이드 코드를 사용해 UI 메시지를 표시할 수 있습니다.

| 가이드 코드 | CaptureGuide | 설명 |
|-----------|--------------|------|
| L1001 | `NO_FACE_DETECTED` | 얼굴이 감지되지 않았습니다. 정면을 바라봐 주세요 |
| L1002 | `INVALID_POSE_ROLL` | 고개를 삐딱하지 않게 똑바로 세워주세요 |
| L1003 | `INVALID_POSE_PITCH` | 고개를 숙이거나 들지 말고 정면을 바라봐 주세요 |
| L1004 | `INVALID_POSE_YAW` | 옆을 보지 말고 정면을 바라봐 주세요 |
| L1005 | `INVALID_POSITION` | 얼굴 위치가 화면 중앙에서 벗어났습니다 |
| L1006 | `FACE_TOO_SMALL` | 얼굴이 너무 멀리 있습니다. 카메라에 가까이 다가가 주세요 |
| L1007 | `FACE_TOO_BIG` | 얼굴이 너무 가까이 있습니다. 한 걸음 뒤로 물러나 주세요 |
| L1008 | `LOW_CONFIDENCE` | 얼굴 인식이 불안정합니다 |
| L1009 | `COLLECTING_FRAMES` | 인증을 진행하고 있습니다 |
| L1010 | `LIVENESS_NOT_CONFIRMED` | 실제 사람인지 확인 중입니다. 잠시 멈춰주세요 |
| L1011 | `ALREADY_COMPLETED` | 이미 완료되었습니다 |

#### 6.1.6 GP4xx — HandsFree 인증

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP401 | `DELEGATE_AUTH_SESSION_FAILED` | 핸즈프리 인증 처리에 실패했습니다 |

#### 6.1.7 GP9xx — 서버

| 에러 코드 | Enum | 설명 |
|-----------|------|------|
| GP901 | `SDK_SERVICE_NOT_FOUND` | SDK 서비스를 찾을 수 없습니다 |
| GP902 | `SDK_SERVICE_INACTIVE` | 비활성화된 SDK 서비스입니다 |
| GP903 | `SDK_SERVICE_CODE_DUPLICATE` | 이미 사용 중인 서비스 코드입니다 |
| GP904 | `SDK_API_KEY_DUPLICATE` | 이미 사용 중인 API Key입니다 |
| GP905 | `SERVER_ERROR` | 서버의 응답이 비정상적입니다 |
| GP906 | `INTERNAL_ERROR` | 내부 처리 중 오류가 발생했습니다 |

---

### 6.2 에러 처리 예시 코드

```kotlin
// function
try {
    val result = GoPassSDK.initialize(apiKey = key, context = applicationContext)
} catch (e: GoPassException) {
    Log.e(TAG, "${e.code} ${e.message}")
    // → "GP101 초기화를 실패했습니다."  ← 문의 시 에러 코드 전달
}
```

```kotlin
// registerBioData
when (val status = GoPassSDK.registerBioData(nv21, width, height, rotation)) {
    is BioDataFrameStatus.Success -> handleSuccess()
    is BioDataFrameStatus.ContinueCapture -> showGuide(status.reason.message)
}
```

```kotlin
// delegateAuthSession (HandsFree)
try {
    GoPassSDK.delegateAuthSession(json, applicationContext)
} catch (e: GoPassException) {
    Log.e(TAG, "code=${e.code}, message=${e.message}")
    // → "code=GP401, message=핸즈프리 인증 처리에 실패했습니다."
}
```

---

## 7. FAQ

**Q1. 비콘이 감지되지 않습니다.**
A. 생체 정보 인증 데이터가 저장되어 있는지 확인해주세요. 생체 정보가 없으면 비콘 감지를 시작하지 않습니다. 또한 Android 12 이상에서는 `BLUETOOTH_SCAN` + `BLUETOOTH_CONNECT` 런타임 권한이, Android 10 이상에서는 `ACCESS_BACKGROUND_LOCATION`이 필요합니다.

---

**Q2. 에뮬레이터에서 테스트할 수 있나요?**
A. 에뮬레이터는 블루투스와 네이티브 Face SDK(`arm64-v8a`)가 지원되지 않으므로 정상 동작을 보장하지 않습니다. 반드시 **실기기**에서 테스트하세요.

---

**Q3. `initialize()`를 여러 번 호출하면 어떻게 되나요?**
A. 이미 초기화가 진행 중이거나 완료된 경우 내부적으로 중복 실행을 방지합니다. 초기화 실패 후에는 재시도가 가능합니다.

---

**Q4. `reset()`은 언제 호출해야 하나요?**
A. 다른 API Key로 재초기화해야 하거나, 앱에서 SDK 상태를 완전히 정리한 뒤 다시 시작해야 할 때 호출합니다. `reset()` 이후에는 `initialize()`를 다시 호출해야 합니다.

---

**Q5. 앱이 종료된 상태에서 HandsFree 인증이 실패합니다.**
A. 최초 프로세스 기동 시 FaceSDK 네이티브 로드에 ~5초가 소요됩니다. 키오스크 세션 수집 타임아웃이 8초 이상인지 확인하세요. 두 번째 시도부터는 FaceSDK가 메모리에 캐시되어 즉시 처리됩니다.

---

**Q6. FCM 토큰이 갱신되면 어떻게 해야 하나요?**
A. `FirebaseMessagingService.onNewToken()`에서 `GoPassSDK.registerFcmToken(token)`을 호출하세요. SDK init 이전에 호출될 수 있으므로 반드시 try/catch로 감싸세요. SDK init 완료 후 명시적으로 한 번 더 호출하는 것을 권장합니다.

---

**Q7. `initialize()`가 너무 오래 걸립니다.**
A. `initialize()`는 SDK 사용을 위해 필수적으로 필요한 단계입니다. 앱 런치 시 호출한다면 **Splash Screen**을, 앱 사용 중 호출한다면 **ProgressBar** 활용을 추천합니다.

---

**Q8. 문의 시 어떤 정보를 전달해야 하나요?**
A. `GoPassException`의 `code`와 `message`를 함께 전달해 주세요.

```kotlin
// 로그 예시
Log.e(TAG, "code=${e.code}, message=${e.message}")
// → "code=GP401, message=핸즈프리 인증 처리에 실패했습니다."
```

---

*© GhostPass AI. All rights reserved.*