# EDFViewer-MacOS — Roadmap

This roadmap maps the path from the current foundation to a native macOS alternative to EDFbrowser. Features are grouped into milestones ordered by user impact. Each milestone should be shippable on its own.

---

## Completed — Foundation

| Feature | Notes |
|---|---|
| Native SwiftUI macOS app | macOS 13+, no external dependencies |
| Pure Swift EDF/BDF parser | Digital-to-physical calibration, 2- and 3-byte samples |
| Channel sidebar | Selection and navigation |
| Min/max downsampling renderer | Preserves peaks at any zoom level |
| Protocol-driven reader (`EDFReading`) | Parser-agnostic UI |
| Unit and integration test suite | Parser, signal processing, ViewModel |
| All Channels montage view | Stacked scrollable view of every channel |
| Pan boundary clamping | Arrows disable at t=0 and file end |
| File duration display | Shown in sidebar under "All Channels" |

---

## Milestone 1 — Usable Viewer

**Goal:** A viewer a clinician or researcher can open on day one and trust.

> **Priority:** This is the "make it real" milestone. Everything here turns the current MVP into a tool people actually want to keep open.

### Viewing Experience
- [ ] **Per-channel amplitude scaling** — drag or scroll on the y-axis of a channel to scale it independently
- [ ] **Keyboard navigation** — arrow keys to pan; `+`/`-` or scroll wheel to zoom; spacebar to jump forward one page
- [ ] **Current time indicator** — a vertical cursor showing playback position in the time axis

### Large-File IO (critical engineering upgrade)

The current `RealEDFReader` loads the entire file into memory with `Data(contentsOf:)`. This works for small files but will fail or become sluggish on long PSG/EEG recordings (often 500 MB–2 GB+). This is one of the highest-leverage upgrades.

- [ ] **Memory-mapped IO** — replace `Data(contentsOf:)` with `mmap` or `FileHandle`-based reads
- [ ] **LRU record cache** — cache decoded data records; evict least-recently-used when memory pressure rises
- [ ] **Background decoding pipeline** — decode records off the main thread so the UI stays responsive during pan/zoom

### Parser
- [ ] **`edflib.c` integration as `EDFlibReader`** — BSD 3-clause C library as a fallback for files the Swift parser rejects
- [ ] **`EDFReaderFactory`** — automatically select the best available parser; surface parse errors to the user

### File Info
- [ ] **Header inspector panel** — show patient info, recording info, start date/time, sample rates per channel, physical unit, digital/physical min/max

---

## Milestone 2 — EDF+ Annotations (core, not optional)

**Goal:** Match EDFbrowser's annotation handling so EDF+/BDF+ files are fully usable.

> **Priority:** Annotations are a defining EDFbrowser feature. Without them, EDF+ files with events/sleep stages are essentially broken. This is the single biggest functional gap.

- [ ] **EDF+ annotation channel parsing** — read `EDF Annotations` signal records (TAL: time-stamped annotation lists); display as timestamped labels on the waveform
- [ ] **Annotation overlay** — render annotation markers as vertical lines / shaded regions with hover-to-read labels
- [ ] **Annotation list panel** — sortable table of all annotations with timestamp, duration, and description; click to jump to that time
- [ ] **Annotation editor** — add, edit, and delete annotations; write them back to the EDF+ file
- [ ] **Import/export annotations** — plain-text (TSV/CSV) round-trip for use with Python or R

---

## Milestone 3 — Precision Measurement Tools

**Goal:** Precise signal measurement without leaving the app. These features transform "toy viewer" into "real lab tool".

- [ ] **Crosshair cursor** — show exact timestamp and amplitude at the mouse position
- [ ] **Two-point measurement** — click to place two crosshairs; display the delta time and delta amplitude between them
- [ ] **Rectangle zoom** — drag a selection rectangle to zoom into a region (matching EDFbrowser behavior)
- [ ] **Amplitude ruler** — a draggable scale bar per channel showing physical unit per division

---

## Milestone 4 — Signal Processing

**Goal:** Built-in filtering so users don't need an external tool for basic preprocessing.

> **Priority:** Even a minimal filter panel (notch + bandpass) plus an FFT view covers ~80% of perceived "power user" needs.

### Filters
- [ ] **Notch filter** — 50 Hz and 60 Hz with adjustable Q-factor; essential for powerline interference
- [ ] **Butterworth bandpass / highpass / lowpass** — 1st–8th order; per-channel toggle
- [ ] **Moving average filter** — simple smoothing
- [ ] **Spike / artifact rejection filter** — remove fast transients and pacemaker spikes

### Spectral Analysis
- [ ] **Power spectrum (FFT) view** — windowed FFT (Hann, Hamming, Blackman) with selectable window length; shown in a split panel or separate window
- [ ] **Color Density Spectral Array (CDSA) / spectrogram** — time-frequency heatmap for EEG montages

---

## Milestone 5 — Montages and Multi-Channel Views

**Goal:** Clinical EEG and ECG workflows require channel derivations and custom layouts.

> **Priority:** For EEG users, montage support is "table stakes". Without re-referencing, bipolar chains, and standard 10-20 layouts, the app cannot serve EEG clinicians.

- [ ] **Montage editor** — define derived channels as linear combinations (e.g., bipolar EEG: `C3 - A2`)
- [ ] **Saved montage presets** — save and reload named montages; ship standard 10-20 EEG montages as defaults
- [ ] **Montage file import** — read EDFbrowser `.mtg` montage files for compatibility
- [ ] **Channel reordering** — drag channels in the sidebar to reorder them in the waveform view

---

## Milestone 6 — Clinical Modules

**Goal:** Specialized views for common clinical signal types.

### EEG
- [ ] **Hypnogram view** — display a sleep-stage timeline alongside the EEG; import stage annotations
- [ ] **Amplitude-integrated EEG (aEEG / CFM)** — compressed trend display with upper/lower envelope bands

### ECG
- [ ] **Pan-Tompkins QRS detector** — automatic beat detection; overlay R-peak markers
- [ ] **RR-interval / heart rate export** — export beat timestamps and RR intervals to CSV
- [ ] **Waveform averaging** — align and average segments triggered by detected beats or annotation events

---

## Milestone 7 — Export and Quick Utilities

**Goal:** The minimum export subset that makes users happy without writing a script.

> **Priority:** These three cover the most common "I need to get data out" requests.

- [ ] **Export visible window to CSV** — export selected channels and time range to CSV/TSV
- [ ] **Export screenshot / PDF of current view** — render the current waveform view to a printable PDF or PNG with header metadata
- [ ] **Crop to new EDF/BDF file** — export a time-range subset as a new EDF file

### Extended File Operations (later)
- [ ] **File splitter** — split by duration or by annotation markers
- [ ] **File combiner** — concatenate multiple EDF files into one
- [ ] **Decimator / resampler** — downsample signals to a lower sample rate and save
- [ ] **BDF to EDF converter** — 24-bit BDF → 16-bit EDF with correct rescaling
- [ ] **EDF+D to EDF+C converter** — convert discontinuous EDF+ to continuous EDF+
- [ ] **ASCII import** — load columnar text data and save as EDF

---

## Milestone 8 — Multi-File and Streaming

**Goal:** Handle real-world workflows where data spans multiple files or is still being recorded.

- [ ] **Multi-file session** — open signals from several files in the same waveform view, time-aligned
- [ ] **Streaming / monitor mode** — poll a growing EDF file and auto-scroll as new data arrives
- [ ] **Recent files** — system-native recent files menu with thumbnail previews

---

## Milestone 9 — Validation and Reports

**Goal:** Help users trust their files.

- [ ] **EDF/BDF compatibility report** — surface header validation issues with plain-language explanations (matching EDFbrowser's validator output)

---

## Milestone 10 — Distribution

**Goal:** Deliver the app to users without requiring Xcode.

- [ ] **GitHub Actions CI** — build and test on every push; block merges on failure
- [ ] **Notarized `.dmg` release** — signed and notarized via GitHub Actions; direct download, no App Store
- [ ] **GitHub Releases page** — versioned release notes and download links
- [ ] **Mac App Store submission** — requires Apple Developer Program enrollment; sandbox-compatible entitlements
- [ ] **Homebrew cask** — `brew install --cask edfviewer-mac` for developer users

---

## Feature Comparison vs EDFbrowser

| EDFbrowser Feature | EDFViewer-MacOS Status |
|---|---|
| EDF / BDF parsing | **Done** |
| Channel sidebar + selection | **Done** |
| All-channels stacked view | **Done** |
| Time-axis grid overlay | **Done** |
| Pan with boundary clamping | **Done** |
| Large-file handling (mmap) | Milestone 1 |
| EDF+ / BDF+ annotation parsing | Milestone 2 |
| Annotation editor | Milestone 2 |
| Header inspector | Milestone 1 |
| Keyboard navigation | Milestone 1 |
| Per-channel amplitude scaling | Milestone 1 |
| Crosshair measurement | Milestone 3 |
| Rectangle zoom | Milestone 3 |
| Notch filter | Milestone 4 |
| Butterworth bandpass | Milestone 4 |
| Power spectrum (FFT) | Milestone 4 |
| CDSA spectrogram | Milestone 4 |
| Montage editor | Milestone 5 |
| Montage presets (10-20 EEG) | Milestone 5 |
| Hypnogram | Milestone 6 |
| aEEG / CFM | Milestone 6 |
| Pan-Tompkins QRS detector | Milestone 6 |
| Waveform averaging | Milestone 6 |
| Export to CSV | Milestone 7 |
| Export to PDF / PNG | Milestone 7 |
| File cropper | Milestone 7 |
| File splitter / combiner | Milestone 7 |
| BDF → EDF converter | Milestone 7 |
| ASCII import/export | Milestone 7 |
| Multi-file session | Milestone 8 |
| Streaming / monitor mode | Milestone 8 |
| EDF validator | Milestone 9 |
| Notarized release | Milestone 10 |

---

## What This App Does That EDFbrowser Does Not

- Native macOS look and feel (SwiftUI, system fonts, Dark Mode, Retina)
- No Qt, no Wine, no installer — one `.app` bundle
- macOS-native file picker, drag-and-drop, Quick Look integration (planned)
- Swift-native test suite with XCTest
- XcodeGen project — reproducible builds without committing `.xcodeproj` contents

---

*"Whatever you do, work at it with all your heart, as working for the Lord, not for human masters."*
— Colossians 3:23
