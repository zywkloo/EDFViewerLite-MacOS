# EDFViewer-MacOS

A native macOS SwiftUI viewer for EDF/BDF biomedical signal files — free, open source, and built for clinicians, researchers, and patients.

> Licensed under the [MIT License](LICENSE). Free to use, modify, and distribute.

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

## Roadmap

### Now — Solid Foundation
- [x] Native SwiftUI macOS app
- [x] Pure Swift EDF/BDF parser
- [x] Channel sidebar and waveform rendering
- [x] Min/max downsampling for performant rendering
- [x] Unit and integration test suite

### Next — Parser and UX
- [ ] Integrate `edflib.c` (BSD 3-clause) as a fallback parser for edge-case EDF files
- [ ] `EDFReaderFactory` with automatic parser selection
- [ ] Time-axis labels and grid overlay
- [ ] Keyboard navigation (pan, zoom)
- [ ] Channel amplitude scaling per channel

### Later — Distribution
- [ ] Notarized `.dmg` releases via GitHub Actions
- [ ] GitHub Releases for direct download (no App Store required)
- [ ] Mac App Store submission (Apple Developer Program)
- [ ] Multi-file session support

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
