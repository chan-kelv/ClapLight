# ClapLight — Project Plan

> Full breakdown of every ticket organized by epic. Issues mirror these in GitHub once `scripts/bootstrap-issues.sh` has been run.

Companion docs:

- [`architecture.md`](architecture.md) — tech stack, data model, key decisions
- [`api-reference.md`](api-reference.md) — every endpoint, payload, mode integer, and source link

## Goals

- **v1**: one-touch multi-device scene application from home screen / Quick Settings, including direct 4D screen-mirror mode switching
- **v2**: custom effect authoring, dynamic shortcuts, polish
- **Future**: UDP streaming control, Sync+ awareness

## Epics

| Epic | Theme | Tickets | Milestone |
|---|---|---|---|
| F — Foundation | Project setup, networking, permissions | F-01, F-02, F-03, F-04 | v1 |
| D — Device Management | Discovery, pairing, persistence | D-01 → D-07 | v1 |
| C — Core Control | State, effects, basic UI | C-01 → C-05 | v1 |
| S — Scenes | Multi-device presets | S-01 → S-04 | v1 |
| H — Home Screen Surfaces | Widget, QS tile | H-01, H-02, H-03 | v1 |
| E — 4D Emersion | Screen-mirror mode switching | E-01, E-02, E-03 | v1 |
| H+ — Shortcuts & Assistant | Dynamic shortcuts | H-04 | v2 |
| P — Polish | Error handling, theme, distribution | P-01, P-02, P-03 | v2 |

## Suggested build order

1. **F-01 → F-04** scaffolding so everything after lands cleanly
2. **D-01 → D-07** get a real device on screen end-to-end (most learning happens here)
3. **C-01 → C-05** control one device; defer scenes
4. **S-01 → S-04** scenes on top of working single-device control
5. **E-01 → E-03** add 4D mode (small surface, isolated from rest)
6. **H-01 → H-03** widgets and tiles on top of working scenes
7. **H-04, P-01 → P-03** v2 polish for personal use / sideload

## Status legend (GitHub label conventions)

| Label | Meaning |
|---|---|
| `status/todo` | Not started (default for open issues) |
| `status/in-progress` | Actively being worked |
| `status/blocked` | Waiting on something; note in issue body |
| `priority/high` | Critical for milestone |
| `priority/med` | Important |
| `priority/low` | Nice-to-have |
| `epic/foundation` etc. | Epic grouping |
| `estimate/S` (~1–3h) | Sizing |
| `estimate/M` (~3–8h) | |
| `estimate/L` (~1–3d) | |

## Open questions to revisit

- Single shared app+widget process, or split for ANR safety? (default: single, with strict timeouts)
- Backup of scenes across reinstall? (default: no for v1, export JSON in v2)
- Multi-user (e.g., partner's phone with same scenes)? (default: no)
