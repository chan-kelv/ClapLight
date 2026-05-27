---
tags: [nanoleaf-app, reference]
type: api-reference
---

# Nanoleaf API Reference

Everything we've validated for this project, with sources. Base path is `http://<ip>:16021/api/v1/<token>` unless noted.

## Discovery

- **Protocol**: mDNS (Bonjour)
- **Service name**: `_nanoleafapi._tcp`
- **Port**: `16021`
- **Android**: `NsdManager.discoverServices()` — needs `MulticastLock` held during discovery
- **Manual fallback**: user enters IP (find in router UI; MAC starts with `00:55:DA`)

> [!note] Source
> Nanoleaf Quick Start Guide — https://support.nanoleaf.me/hc/en-us/articles/41105798500628-API-Quick-Start-Guide

## Authentication

### Pairing — legacy devices (Panels, Shapes, Lines, Canvas, Elements)

1. User holds power button on controller for 5–7s until LED flashes
2. App POSTs `http://<ip>:16021/api/v1/new` within 30s
3. Response: `{"auth_token": "<32-char string>"}`

### Pairing — Essentials devices (4D, Skylight, Essentials bulbs/strips)

1. User opens Nanoleaf app → Device Settings → "Connect to API" on the device
2. Same POST to `/api/v1/new` within 30s

### Token properties

- Persists until factory reset
- Multiple apps can each pair their own token
- Errors:
  - `401` token missing/invalid → re-pair
  - `403` re-pair to refresh
  - `404` wrong IP/port

> [!note] Source
> Authentication & Security — https://support.nanoleaf.me/hc/en-us/articles/41108368751892-API-Authentication-Security

## State control

### Power

```http
PUT /state
Content-Type: application/json

{"on": {"value": true}}
```

### Brightness (0–100)

```json
{"brightness": {"value": 50}}
{"brightness": {"value": 50, "duration": 10}}  // 10s transition
```

### Hue / Saturation / Color Temperature

```json
{"hue": {"value": 200}}                  // 0–360
{"sat": {"value": 80}}                   // 0–100
{"ct":  {"value": 4000}}                 // 1200–6500 K
```

### GET full state

```http
GET /
```

Returns full device info including `state`, `effects.select`, `effects.effectsList`, `panelLayout`, model, firmware.

## Effects (saved/built-in presets)

### List saved effects on the device

```http
GET /effects/effectsList
```

Returns `["Northern Lights", "Forest", ...]` — names exactly as in the Nanoleaf app.

### Activate by name

```http
PUT /effects/select

{"select": "Northern Lights"}
```

### Selected effect string conventions

- Normal effect → effect name
- Streaming mode active → `*ExtControl*`
- Screen mirror active → `*Emersion*`
- Static color → `*Static*`, `*Solid*`, `*Dynamic*`

## Identify (flash device for setup)

```http
PUT /identify
```

Empty body. Useful in pairing wizard to confirm which physical device is being added.

## 4D Emersion (screen mirror modes) — **UNDOCUMENTED**

> [!warning] Undocumented endpoint
> Not in Nanoleaf's official docs. Reverse-engineered by jonathanrobichaud4 (2024) and exposed by the `aionanoleaf2` Python library used by Home Assistant integrations. Stable in practice but could break on firmware updates.

### Gate by model

Only call on devices reporting `model == "NL69"` (4D controller).

### Mode integer mapping

| Mode | Integer |
|---|---|
| 1D | `6` |
| 2D | `2` |
| 3D | `3` |
| 4D | `5` |

Note that 4D ≠ 4 — get this wrong and you'll silently select the wrong mode.

### Get current mode

```http
PUT /effects

{"write": {"command": "getScreenMirrorMode"}}
```

Response includes `screenMirrorMode: <int>`.

### Activate a mode (e.g. 4D)

```http
PUT /effects

{"write": {"command": "activateScreenMirror", "screenMirrorMode": 5}}
```

When active, `effects.select` reads `*Emersion*`.

> [!note] Source
> aionanoleaf2 source — https://pypi.org/project/aionanoleaf2/
> Diff that introduced it — https://github.com/milanmeu/aionanoleaf/pull/18/files

## ExtControl (UDP streaming) — **future, v3+**

Enable streaming mode:

```http
PUT /effects

{"write": {"command": "display", "animType": "extControl", "extControlVersion": "v2"}}
```

Then send UDP packets to `<ip>:60222` with per-panel RGBW + transition bytes. ~10–30 Hz comfortably.

> [!note] Source
> Forum thread — https://forum.nanoleaf.me/forum/community-support/anyone-gotten-external-control-working
> Streaming protocol writeup — https://rjbs.cloud/blog/2023/08/nanoleaf-streaming-updates/

## Sources index

- Quick Start: https://support.nanoleaf.me/hc/en-us/articles/41105798500628-API-Quick-Start-Guide
- Auth & Security: https://support.nanoleaf.me/hc/en-us/articles/41108368751892-API-Authentication-Security
- OpenAPI doc hub: https://support.nanoleaf.me/hc/en-us/articles/46020382680468-API-Nanoleaf-OpenAPI-Documentation-Forum-Guidelines
- Essentials API (Confluence): https://nanoleaf.atlassian.net/wiki/spaces/nlapid/pages/2296381472/Nanoleaf+Matter+WiFi+Essentials+Open+API+Documentation
- aionanoleaf2 (Python ref impl): https://pypi.org/project/aionanoleaf2/
- HA integration with 4D: https://github.com/loebi-ch/nanoleaf
- nanoleafapi (Python, legacy-only): https://pypi.org/project/nanoleafapi/
