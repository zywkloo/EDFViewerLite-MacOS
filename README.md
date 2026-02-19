# EDFViewer-MacOS

A macOS SwiftUI viewer scaffold for EDF/BDF files inspired by EDFbrowser.

## What is included

- Native macOS app entry point using `SwiftUI`.
- Sidebar for channel list and channel selection.
- Waveform pane rendered with min/max downsampling (`Canvas`) for responsive zoomed-out views.
- Reader abstraction (`EDFReading`) so you can swap in a pure C EDFlib-backed implementation without changing the UI.
- Temporary `MockEDFReader` that generates deterministic synthetic EEG-like waveforms so the UI can run before EDFlib wiring is complete.

## Project layout

- `Package.swift`: Swift Package config for a macOS executable app target.
- `Sources/EDFViewerMac/App`: app lifecycle and scene setup.
- `Sources/EDFViewerMac/Core`: models, reader protocol, and signal processing.
- `Sources/EDFViewerMac/UI`: SwiftUI screens and waveform rendering.

## Run locally on macOS

```bash
swift run EDFViewerMac
```

> This command requires a macOS environment with Xcode/Apple SDKs installed.

## Next step: EDFlib integration

1. Vendor `edflib.c` and `edflib.h` into the repository.
2. Add a C target (for example `CEDFlib`) in `Package.swift`.
3. Implement an `EDFlibReader` that conforms to `EDFReading`.
4. Update `EDFReaderFactory` to construct `EDFlibReader` for real EDF/BDF files.

This keeps the core parser layer independent from Qt while preserving a native SwiftUI macOS UI.
