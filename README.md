# EDFViewer-MacOS

A native macOS SwiftUI viewer for EDF/BDF biomedical signal files — free, open source, and built for clinicians, researchers, and patients.

> Licensed under the [MIT License](LICENSE). Free to use, modify, and distribute.

---

## App Preview

![EDF Viewer main screen](docs/images/app-main.png)

---

## Why This Exists

[EDFbrowser](https://www.teuniz.net/edfbrowser/) is a widely used open source EDF viewer but requires Qt and does not feel native on macOS. This project brings EDF/BDF viewing to macOS as a first-class native app — no Java, no Wine, no Qt. Just Swift and SwiftUI.

---

## Features

- Native macOS app built with SwiftUI (macOS 13+)
- Opens real EDF and BDF files with a pure Swift parser
- Channel sidebar for selection and navigation
- Waveform rendering using min/max downsampling for smooth zoomed-out views
- Reader abstraction that allows swapping parsers without touching the UI
- Test suite covering parsing, signal processing, and end-to-end waveform reading

---

## Architecture

The project follows a layered architecture with a clean protocol boundary between the parser and the UI.

```
┌─────────────────────────────────────────┐
│                  UI Layer               │
│  ContentView · ViewerViewModel          │
│  WaveformMinMaxView · SettingsView      │
└────────────────┬────────────────────────┘
                 │ EDFReading protocol
┌────────────────▼────────────────────────┐
│               Core Layer                │
│                                         │
│  EDFReading (protocol)                  │
│  ├── MockEDFReader   synthetic data     │
│  ├── RealEDFReader   pure Swift parser  │
│  └── EDFlibReader    (planned, C-based) │
│                                         │
│  SignalProcessing    min/max downsample │
│  Models              ChannelInfo        │
│                      WaveformWindow     │
│                      DownsampledWaveform│
└─────────────────────────────────────────┘
```

### Key Design Decisions

**Protocol-driven reader (`EDFReading`)** — The UI never knows which parser is active. Any conforming reader can be swapped in at the factory level without touching a single view.

**Pure Swift parser (`RealEDFReader`)** — Parses EDF/BDF headers and data records natively. No C dependencies, no bridging headers. Supports both EDF (2-byte samples) and BDF (3-byte samples) with correct digital-to-physical calibration.

**Min/max downsampling (`SignalProcessing`)** — Renders millions of samples at any zoom level by computing per-bucket min and max values. This preserves signal peaks that naive decimation would miss.

**XCGen (`project.yml`)** — The Xcode project is generated from `project.yml` using [XcodeGen](https://github.com/yonaskolb/XcodeGen). Do not edit the `.xcodeproj` directly.

### Source Layout

```
Sources/EDFViewerMac/
├── App/
│   └── EDFViewerMacApp.swift      app entry point and scene setup
├── Core/
│   ├── Models.swift               ChannelInfo, WaveformWindow, DownsampledWaveform
│   ├── EDFReader.swift            EDFReading protocol + MockEDFReader
│   ├── RealEDFReader.swift        pure Swift EDF/BDF parser
│   └── SignalProcessing.swift     min/max downsampling
└── UI/
    ├── ContentView.swift          root layout with sidebar
    ├── ViewerViewModel.swift      state management and reader coordination
    ├── WaveformMinMaxView.swift   Canvas-based waveform renderer
    └── SettingsView.swift         user preferences
Tests/EDFViewerMacTests/
├── EDFReaderTests.swift           unit tests for Mock and Real readers
├── EDFReadIntegrationTests.swift  end-to-end parse and downsample tests
├── SignalProcessingTests.swift    downsampling correctness
└── ViewerViewModelTests.swift     ViewModel state tests
```

---

## Getting Started

### Prerequisites

- macOS 13 or later
- Xcode 15 or later
- [XcodeGen](https://github.com/yonaskolb/XcodeGen) — generates the `.xcodeproj` from `project.yml`

> **Note:** `.xcodeproj` is not committed to the repo. You must generate it locally before opening in Xcode.

---

### Setup

**1. Install XcodeGen**

```bash
brew install xcodegen
```

**2. Clone the repo**

```bash
git clone https://github.com/your-org/EDFViewer-MacOS.git
cd EDFViewer-MacOS
```

**3. Generate the Xcode project**

```bash
xcodegen generate
```

This reads `project.yml` and produces `EDFViewerMac.xcodeproj`. Re-run this any time `project.yml` changes (e.g. after pulling new files or adding targets).

**4. Open in Xcode and run**

```bash
open EDFViewerMac.xcodeproj
```

Press `Cmd+R` to build and run.

**5. Try the sample file**

A sample EDF file is included in `Samples/combined-sample.edf`. Use **File → Open** in the app to load it and verify everything is working.

---

### Run Tests

```bash
xcodebuild test -project EDFViewerMac.xcodeproj -scheme EDFViewerMac
```

---

## Release DMG (Developer ID + Notarization)

This repo includes XcodeGen signing config files and a release script:

- `configs/Debug.xcconfig`
- `configs/Release.xcconfig`
- `scripts/release/release_dmg.sh`

Required environment variables:

```bash
export APPLE_TEAM_ID="YOUR_TEAM_ID"
export APPLE_ID="your-apple-id@example.com"
export APPLE_APP_SPECIFIC_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

Build, sign, notarize, and staple a DMG:

```bash
./scripts/release/release_dmg.sh
```

Output:

- `build/release/EDFViewer.dmg`

### GitHub Actions release (signed DMG)

The workflow at `.github/workflows/release.yml` will:

- build an unsigned DMG if signing secrets are missing
- build, sign, notarize, and staple the DMG if secrets are present

Add these repository secrets:

- `APPLE_TEAM_ID`
- `APPLE_ID`
- `APPLE_APP_SPECIFIC_PASSWORD`
- `MACOS_CERT_P12_BASE64`
- `MACOS_CERT_PASSWORD`
- `MACOS_KEYCHAIN_PASSWORD` (optional, recommended)

Create `MACOS_CERT_P12_BASE64` from your Developer ID certificate export:

1. Open **Keychain Access**
2. Export your **Developer ID Application** cert + private key as `.p12`
3. Convert to base64:

```bash
base64 -i developer_id_application.p12 | pbcopy
```

Paste that copied value into `MACOS_CERT_P12_BASE64`.

Flow:

- `develop` branch pushes -> temporary DMG workflow (`release-temp-dmg.yml`)
- `main` tags (`v*`) -> signed + notarized release workflow (`release.yml`)

### Temporary DMG pipeline (no Apple notarization)

Use workflow:

- `.github/workflows/release-temp-dmg.yml`

How to run:

1. GitHub -> **Actions**
2. Choose **Release Temp DMG** (or push to `develop` to run automatically)
3. Click **Run workflow**
4. Download `temp-dmg` artifact

This build is ad-hoc signed for testing only and may show Gatekeeper warnings on other Macs.

---

## Roadmap

### Done — Viewer Foundation
- [x] Native SwiftUI macOS app
- [x] Pure Swift EDF/BDF parser with digital-to-physical calibration
- [x] Channel sidebar and waveform rendering
- [x] All Channels stacked montage view
- [x] Min/max downsampling for performant rendering
- [x] Pan with boundary clamping (arrows disable at file edges)
- [x] Time-axis grid overlay
- [x] Unit and integration test suite

### Next — Usable Viewer (Milestone 1)
- [ ] Per-channel amplitude scaling
- [ ] Keyboard navigation (arrow keys, scroll wheel zoom)
- [ ] Large-file IO redesign (mmap + LRU cache)
- [ ] Header inspector panel

### Then — Annotations + Measurement (Milestones 2–3)
- [ ] EDF+ annotation channel parsing (TAL)
- [ ] Annotation overlay, list panel, and editor
- [ ] Crosshair cursor with time + amplitude readout
- [ ] Rectangle zoom

### Later — Processing + Clinical (Milestones 4–6)
- [ ] Notch + bandpass filters
- [ ] FFT / power spectrum view
- [ ] Montage editor with 10-20 EEG presets
- [ ] Pan-Tompkins QRS detector

See [ROADMAP.md](ROADMAP.md) for the full milestone plan and EDFbrowser feature comparison.

---

## Contributing

Pull requests are welcome. Please open an issue first for significant changes.

The `EDFReading` protocol is the right place to add new parser backends — conform to it and update `EDFReaderFactory`. The UI does not need to change.

---

## License

MIT License. See [LICENSE](LICENSE) for details.

`edflib.c` and `edflib.h` by Teunis van Beelen are licensed under BSD 3-clause and retain their original copyright headers.

---

*"Whatever you do, work at it with all your heart, as working for the Lord, not for human masters."*
— Colossians 3:23

*"Heal the sick, cleanse the lepers, raise the dead, cast out devils: freely ye have received, freely give."*
— Matthew 10:8

---

## Sponsor

[![Sponsor](https://img.shields.io/badge/Sponsor-zywkloo-ea4aaa?logo=githubsponsors)](https://github.com/sponsors/zywkloo)
