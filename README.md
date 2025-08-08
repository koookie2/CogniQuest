## CogniQuest 🧠 (iOS)

An interactive, voice-guided iOS implementation of the SLUMS cognitive screening exam, built with SwiftUI. The app focuses on a clean, accessible UX and a maintainable, testable architecture.

### Overview
CogniQuest digitizes the Saint Louis University Mental Status (SLUMS) examination, a public domain tool used for cognitive screening. It was developed as a learning project to explore modern iOS development (SwiftUI, state management, AVFoundation) while producing a practical, polished app. Users can complete the full flow and share a PDF summary of results.

### Features
- Voice-driven prompts for the number series (AVFoundation TTS)
- Audio visualizer synchronized with narration
- Configurable per-question timer and education level adjustment
- Interactive drawing for the clock-drawing task (Canvas-based) with Clear
- Shape identification and story recall inputs
- Typed answers with safe, strongly-typed models
- Automatic scoring with interpretation aligned to SLUMS guidance
- Modern SwiftUI UI/UX with smooth, direction-aware navigation
- Shareable PDF report via the native iOS Share Sheet

### Tech Stack
- Swift, SwiftUI
- AVFoundation (text-to-speech)
- Xcode 16+

### Requirements
- Xcode 16.x
- iOS 17.0+ (deployment target)

### How to Run
1. Open `CogniQuest.xcodeproj` in Xcode 16 or newer
2. Select a simulator (iPhone) or a connected device
3. If building for device, set your signing team in target settings
4. Build and run (Cmd+R)

To run unit tests: Product → Test (Cmd+U)

### Architecture
Lightweight MVVM with clear separation of concerns:
- Models: `Question`, `Answer` and related domain types
- ViewModels: `ExamViewModel` (state, navigation, timer, narration phase)
- Services: `SpeechManager` (TTS + audio session), `ScoringService` (score calc)
- Views: Exam flow, inputs, results, report, and shared components

### Project Structure
- `CogniQuest/Models/`
  - `Question.swift`, `Answer.swift`
- `CogniQuest/ViewModels/`
  - `ExamViewModel.swift`
- `CogniQuest/Services/`
  - `SpeechManager.swift`, `ScoringService.swift`
- `CogniQuest/Views/`
  - `Exam/` – `ExamView.swift`, inputs, drawing and shapes
  - `Results/` – `ResultsView.swift`, `ReportView.swift`, `ShareSheet.swift`
  - `Shared/` – cross-cutting views (e.g., `AudioVisualizerView.swift`)
- `CogniQuest/ContentView.swift` – Home screen that navigates to the exam

### Scoring
Encapsulated in `ScoringService`. Inputs are normalized (e.g., trimming/casing where needed) and mapped to a 30-point total, with interpretation adjusted by education level in line with SLUMS guidance.

### PDF Report
`ReportView` renders a detailed summary (questions, answers, score, interpretation). PDF export uses `UIGraphicsPDFRenderer` for crisp text and shares a temporary file URL via `UIActivityViewController`.

### Accessibility & Internationalization
- Accessibility labels/hints on interactive controls
- Dynamic Type-friendly layouts and contrast-aware styling where possible
- Locale-aware TTS voice (falls back to en-US)
- Strings currently inline; migrating to a String Catalog is recommended

### Project Status & Roadmap
Current app is fully functional for the SLUMS flow.
- Potential enhancements:
  - Results history using SwiftData
  - String Catalog for localization
  - Expanded unit/UI tests (timer expiry, narration gating, edge cases)
  - iPad-optimized layout
  - Persist and optionally render drawings within the report
  - Complete any remaining optional practice prompts if applicable

### Privacy & Disclaimer
- The app does not collect analytics or transmit data by default
- TTS does not require microphone permission

Disclaimer: CogniQuest is a screening aid, not a diagnostic instrument. It is not a substitute for professional medical advice, diagnosis, or treatment. Always seek the advice of a qualified healthcare provider with questions regarding a medical condition.

### Contributing
- Keep changes small and well-tested; match existing style
- Prefer typed models and testable units
- Include brief descriptions and screenshots for UI changes in PRs

### License
Licensed under the MIT License. See `LICENSE` for details.
