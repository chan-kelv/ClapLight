---
tags: [nanoleaf-app, reference]
type: architecture
---

# Architecture

## Tech stack

| Layer | Choice | Why |
|---|---|---|
| Language | Kotlin 2.x | Standard |
| UI | Jetpack Compose | Matches modern Android, less boilerplate for personal app |
| Async | Coroutines + Flow | Natural for parallel device calls |
| DI | Hilt | Less ceremony than Dagger for a single-module app |
| Persistence | Room | Devices and Scenes as relational data |
| Networking | Retrofit + OkHttp + Moshi | Codegen for the JSON shapes; OkHttp dispatcher for parallel scene fan-out |
| mDNS | `NsdManager` (system) | No third-party deps; needs `MulticastLock` |
| Secrets | `EncryptedSharedPreferences` | Tokens never in plaintext |
| Background | `WorkManager` | Widget retries on transient failures |
| Min SDK | 26 | Android 8.0; covers ~98% of devices |
| Target SDK | 36 | Android 16 |

## Module structure

Single Gradle module to start. Internal packages:

```
com.kelvin.claplight
├── data
│   ├── api          (Retrofit interfaces, DTOs)
│   ├── db           (Room entities, DAOs)
│   ├── discovery    (NsdManager wrapper)
│   ├── repo         (DeviceRepository, SceneRepository)
│   └── security     (TokenStore)
├── domain
│   ├── model        (Device, Scene, EffectName, EmersionMode)
│   └── usecase      (ApplyScene, PairDevice, ListEffects, ...)
├── ui
│   ├── devices      (list, detail, color picker)
│   ├── scenes       (list, editor)
│   ├── pairing      (discovery + pairing wizard)
│   └── theme
├── widget           (AppWidgetProvider, RemoteViews builders)
├── tile             (QS TileService)
└── di               (Hilt modules)
```

Split into modules if compile time becomes an issue. For personal use, almost certainly not.

## Data model (Room)

### `DeviceEntity`

| field | type | notes |
|---|---|---|
| `id` | `String` PK | UUID generated at pair time |
| `name` | `String` | User-editable; defaults to mDNS instance name |
| `host` | `String` | IPv4; refreshed by mDNS on each app open |
| `port` | `Int` | 16021 default |
| `token` | `String` | Stored encrypted via `TokenStore`, ref by id |
| `apiVariant` | `enum` | `LEGACY` or `ESSENTIALS` |
| `model` | `String` | e.g. `NL69` for 4D detection |
| `firmware` | `String` | for feature gating |
| `lastSeen` | `Long` | epoch ms |

### `SceneEntity`

| field | type | notes |
|---|---|---|
| `id` | `String` PK | UUID |
| `name` | `String` | "Movie Night" etc |
| `iconKey` | `String` | enum-like for widget glyph |
| `orderIndex` | `Int` | for stable display ordering |

### `SceneTargetEntity` (one-to-many on SceneEntity)

| field | type | notes |
|---|---|---|
| `id` | `Long` PK auto | |
| `sceneId` | `String` FK | |
| `deviceId` | `String` FK | |
| `targetType` | `enum` | `POWER_OFF`, `EFFECT`, `HSB`, `CT`, `EMERSION` |
| `effectName` | `String?` | for EFFECT |
| `hue` | `Int?`, `saturation` | for HSB |
| `brightness` | `Int?` | applies to multiple types |
| `ctKelvin` | `Int?` | for CT |
| `emersionMode` | `Int?` | 6, 2, 3, 5 for 1D/2D/3D/4D |

## Networking constraints

- All traffic is `http://` to local IPs. Configure `network_security_config.xml` to allow cleartext to RFC1918 ranges only — never blanket-enable.
- Android 16 requires the **local network access** runtime permission. Request at first launch with rationale.
- `NsdManager` on some OEMs needs `CHANGE_WIFI_MULTICAST_STATE` and an explicitly-held `MulticastLock` during discovery.
- Timeouts: 2s connect, 3s read. Scene fan-out should not block the UI longer than 4s total even if one device is offline.

## Concurrency model

- One `OkHttpClient` instance app-wide (connection pooling)
- Scene application = `coroutineScope { devices.map { async { applyTarget(it) } }.awaitAll() }` — full parallelism, individual failures don't block siblings
- UI uses `StateFlow` from repos; no manual refresh after writes
- Widget click handler uses `goAsync()` + a coroutine on `Dispatchers.IO`; hard-cap the work at 8s

## Two API variants

Both Light Panels/Shapes/Lines and Matter Wi-Fi Essentials (incl. 4D) use the same base URL pattern `http://<ip>:16021/api/v1/<token>/...` but differ in:

- **Pairing trigger** — physical button (legacy) vs in-app "Connect to API" (Essentials)
- **Effect schema** — Essentials uses `plugin`/`extControl` animTypes; legacy has more
- **Emersion endpoints** — only on `NL69`

Modeled as two `Retrofit` services sharing a base interface; `apiVariant` on `DeviceEntity` routes calls. See [API reference](api-reference.md) for endpoint-by-endpoint detail.

## Threat model (such as it is)

- Tokens grant full local control of lights — annoying if leaked, not catastrophic
- App is sideload-only, no Play Store, no analytics, no cloud
- Tokens encrypted at rest, never logged, never sent off-device
- No remote-access feature; if not on home Wi-Fi, app shows "not reachable"
