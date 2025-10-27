# Beatle

A retro-inspired drum machine app for iOS, built with SwiftUI and AudioKit.

## Features

### ✅ Sample Library & Import
- **Multi-format support**: Import WAV, AIFF, M4A, MP3, and more
- **Auto-processing**: All samples are automatically:
  - Resampled to 48 kHz
  - Converted to mono with -3 dB gain compensation
  - Peak-normalized to -1.0 dBFS
- **Library views**: Browse by All, Folders, Favourites, Recents, or Unassigned
- **Waveform previews**: Visual waveforms for quick sample identification
- **Smart storage**: Samples organized in `/Documents/Samples/` with content hashing for duplicate detection

### ✅ Pad Editor
- **Sample assignment**: Replace or clear samples on pads
- **Playback modes**: 
  - **One-shot**: Plays full sample on trigger
  - **Gate**: Plays only while held, stops on release
- **Choke groups**: Pads in same group stop each other (None, 1-4)
- **Gain control**: Linear slider from 0.0 to 1.5
- **Pitch adjustment**: ±12 semitones in 1-semitone steps
- **Color picker**: Choose from 10 retro color swatches
- **Favourites**: Star samples for quick access

### ✅ Kit Save/Load
- **Auto-save**: Kits auto-save on pad changes (debounced)
- **Last kit restore**: Automatically reopens last used kit on launch
- **Storage**: Kits saved as JSON in `/Documents/Kits/`
- **Future**: Ready for `.beatlekit` format (zip of JSON + samples)

### ✅ Edit Mode
- **Tab re-tap**: Double-tap the Pads tab (within 0.5s) to toggle edit mode
- **Visual feedback**: Pads flip to show config chips (mode, choke, color)
- **Edit access**: Tap a pad in edit mode to open full editor

### ✅ Audio Engine
- **Low latency**: 48 kHz engine optimized for responsive triggering
- **Choke groups**: Automatic stopping of conflicting pads
- **Gate mode**: Real-time start/stop on finger press/release
- **Gain & pitch**: Per-pad controls applied to audio engine

## Architecture

```
Beatle/
├── Audio/
│   └── AudioEngineService.swift     # AudioKit engine, players, mixers
├── BeatleTheme/
│   └── MPCPad.swift                  # Pad UI component with gate support
├── Kits/
│   ├── KitModel.swift                # Kit data model
│   └── KitService.swift              # Kit persistence
├── Library/
│   ├── ImportPipeline.swift          # 48k+mono+normalize processing
│   ├── SampleModel.swift             # Sample & folder models
│   ├── SampleIndex.swift             # Sample library index
│   ├── WaveformPreviewer.swift       # Waveform generation
│   ├── LibraryViewModel.swift        # Library view model
│   └── LibraryTabView.swift         # Library UI
├── Pads/
│   ├── PadStore.swift                # Pad state management
│   ├── MPCPadCard.swift              # Pad card with flip animation
│   ├── PadEditorView.swift           # Full pad editor UI
│   └── BeatlePalette.swift           # Color swatches
├── Pages/
│   └── PadsPage.swift                # Main pads grid with edit mode
├── Storage/
│   └── Paths.swift                   # Storage path utilities
└── Services/
    ├── PadStateStore.swift           # Legacy state (deprecated)
    └── SampleLibrary.swift           # Legacy sample loader (deprecated)
```

## Import Pipeline Details

### Processing Steps
1. **Copy**: Source file copied to temp location
2. **Decode**: `AVAudioFile` reads original format
3. **Resample**: `AVAudioConverter` resamples to 48 kHz
4. **Mono sum**: Stereo channels summed with -3 dB (prevent clipping)
5. **Normalize**: Peak normalize to -1.0 dBFS
6. **Analyze**: Calculate duration, RMS, peak level
7. **Write**: Save as WAV/CAF in organized folder structure
8. **Waveform**: Generate 200-point envelope for preview

### Storage Layout
```
~/Documents/
├── Samples/
│   ├── folder1/
│   │   └── abc123_sample.wav
│   └── unassigned/
│       └── def456_sample.wav
├── Kits/
│   └── kitId.json
└── Previews/
    └── sampleId.waveform
```

### Adding New Swatches
Edit `Beatle/Beatle/Pads/BeatlePalette.swift`:
```swift
static let newColor = "#RRGGBB"
static let allSwatches: [(hex: String, name: String)] = [
    // ... existing swatches ...
    (newColor, "Color Name")
]
```

## Testing

### Verifying Acceptance Criteria

1. **Import multiple files**:
   - Tap "+" in Library → Select multiple audio files
   - Confirm 48k/mono/normalized files appear in chosen folder

2. **Library views**:
   - Switch between All/Folders/Favourites/Recents/Unassigned
   - Star samples and verify persistence

3. **Edit mode toggle**:
   - Double-tap Pads tab (within 0.5s) → Edit mode toggles
   - Pads flip to show chips, empty pads show "+"

4. **Pad editor**:
   - Tap filled pad in edit mode → Editor opens
   - Adjust Replace, Clear, ★, One-shot/Gate, Choke 0-4, Gain, Pitch, Colour
   - Changes persist

5. **Choke groups**:
   - Set pads to same choke group
   - Trigger pad → confirms other pads in group stop

6. **Gate vs One-shot**:
   - Gate: Trigger and hold → plays until release
   - One-shot: Trigger → plays full sample regardless of finger

7. **Kit save/load**:
   - Configure pads → exits app
   - Reopens → last kit restored

8. **Missing sample handling**:
   - Delete sample file externally
   - Reopen app → pad marked as empty gracefully

## Exporting Logs

If imports fail, export console logs:
1. Connect device via USB
2. Xcode → Window → Devices and Simulators
3. Select device → View Device Logs
4. Filter by "Beatle"
5. Export relevant session

## Future Enhancements

### .beatlekit Export Format
- ZIP archive containing:
  - `kit.json` (pad configs)
  - `Samples/` (copies of sample files referenced by kit)
- Single file sharing between devices
- Cloud sync preparation

### Recommended TODOs
- [ ] Add trim/edit functionality in pad editor
- [ ] Implement kit import/export (.beatlekit)
- [ ] Add pad velocity sensitivity
- [ ] MIDI file export
- [ ] Pattern sequencer
- [ ] Effects processing (reverb, delay, etc.)

## License

Copyright 2025 Sam Missing
