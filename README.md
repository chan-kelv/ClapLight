# ClapLight

A local-network Android controller for Nanoleaf devices. Skip the cloud, skip the official app's quirks, and put your favorite scenes one tap away on the home screen and Quick Settings.

## Why

Nanoleaf's official app is fine for setup but heavyweight for everyday use. ClapLight is purpose-built for two things:

- **Multi-device scenes** — define a target state (effect, color, brightness, or 4D mirror mode) per device, apply it all at once
- **One-touch surfaces** — home screen widget and Quick Settings tiles so you can fire a scene without unlocking the phone

Everything is local. No cloud accounts, no telemetry, no auth servers — just direct HTTP calls to your devices on Wi-Fi.

## Status

🚧 Pre-alpha. Active development. Not ready for general use.

## Planned features

### v1 (in progress)

- mDNS device discovery + manual IP fallback
- Pairing flow for both legacy (Panels/Shapes/Lines) and Essentials (4D/Skylight) APIs
- Encrypted token storage per device
- Per-device on/off, brightness, color (HSB), color temperature
- Activate saved effects already loaded on the device
- Multi-device scenes ("Movie Night", "Focus", "All Off", etc.)
- Direct 4D screen-mirror mode switching (1D / 2D / 3D / 4D) on `NL69` controllers
- Home screen widget with configurable scene grid
- Quick Settings tile for primary scene

### v2 / future

- Custom effect authoring (push your own animations via `effects/write`)
- UDP streaming control for real-time multi-device sync
- Sync+ awareness for 4D
- Dynamic shortcuts + Assistant integration

## Compatibility

- Android 8.0+ (min SDK 26)
- Target SDK 36 (Android 16) — uses the new local-network access runtime permission
- Targeted device families: Light Panels, Shapes, Lines, 4D Screen Mirror, Essentials
- Phone and Nanoleaf devices must be on the same Wi-Fi network

## Architecture & docs

- [`docs/architecture.md`](docs/architecture.md) — tech stack, data model, key decisions
- [`docs/api-reference.md`](docs/api-reference.md) — every Nanoleaf endpoint ClapLight uses, with payload shapes and source links
- [`docs/project-plan.md`](docs/project-plan.md) — full task breakdown by epic
- GitHub Issues — live task tracking (see milestones for v1 / v2)

## Building

```bash
git clone https://github.com/<you>/ClapLight.git
cd ClapLight
./gradlew assembleDebug
adb install app/build/outputs/apk/debug/app-debug.apk
```

Release builds require a signing keystore — see [`docs/project-plan.md`](docs/project-plan.md) ticket `P-03`.

## A note on the 4D Emersion endpoint

Direct screen-mirror mode switching (the `activateScreenMirror` write) is **not** in Nanoleaf's official documentation. It was reverse-engineered by [jonathanrobichaud4](https://github.com/jonathanrobichaud4) in 2024 and is used in production by the [aionanoleaf2](https://pypi.org/project/aionanoleaf2/) Python library (and the Home Assistant integration built on it). It works on current firmware but may break if Nanoleaf changes the protocol. ClapLight gracefully handles failures and won't break other features if it does.

## Credits & references

- [Nanoleaf OpenAPI](https://support.nanoleaf.me/hc/en-us/articles/46020382680468-API-Nanoleaf-OpenAPI-Documentation-Forum-Guidelines) — official docs
- [aionanoleaf2](https://github.com/loebi-ch/nanoleaf) — reference implementation for the Essentials API and 4D emersion modes
- [nanoleafapi](https://github.com/MylesMor/nanoleafapi) — Python wrapper for the legacy API

## License

MIT — see [`LICENSE`](LICENSE).
