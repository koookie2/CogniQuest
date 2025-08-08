CogniQuest (iOS)

CogniQuest is a SwiftUI-based iOS app that guides a user through a short cognitive screening exam and generates a shareable report (PDF). It focuses on a clean, accessible UX and a maintainable architecture.

Features
- Configurable per-question timer and education level adjustment
- Multi-step exam with typed answers and scoring (30-point scale)
- Text-to-speech narration for number series prompts (AVFoundation)
- Clock drawing, shape identification, and story recall inputs
- Results screen with interpretation (Normal / Mild / Likely Dementia)
- In-app PDF report export via the iOS Share Sheet

Requirements
- Xcode 16.x
- iOS 17.0+ (deployment target)

Getting Started
1) Open `CogniQuest.xcodeproj` in Xcode 16 or newer.
2) Select a simulator (iPhone) or a connected device.
3) If building for device, update the signing team in the target settings.
4) Build and Run (Cmd+R).

To run unit tests: Product → Test (Cmd+U).

Architecture
The app uses a lightweight MVVM structure:
- Models: Typed question and answer domain models
- ViewModels: Screen state, navigation, timer, scoring
- Services: Side-effectful or shared modules (TTS, scoring)
- Views: SwiftUI screens and subviews (Exam, Results, Report, Shared)

Key types
- `Question` and `QuestionType` define the exam items
- `Answer` is a strongly-typed enum with associated values for safety
- `ExamViewModel` owns exam flow, timing, narration phase, and result
- `ScoringService` computes the final score from typed answers
- `SpeechManager` manages TTS and audio session lifecycle

Project Structure
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

Scoring
The scoring logic is encapsulated in `ScoringService`. Inputs are normalized (e.g., trimmed/lowercased where needed), and each question contributes to the 30-point total. Interpretation is adjusted based on education level.

Accessibility & Internationalization
- Core interactive views expose accessibility labels and hints
- Dynamic Type and contrast-aware UI where possible
- Strings are currently inline; migration to String Catalog is recommended
- TTS voice is locale-aware (falls back to en-US)

PDF Report
`ReportView` renders a structured summary and per-question responses. Export uses `UIGraphicsPDFRenderer` to produce text-crisp PDFs and shares a temporary file URL via `UIActivityViewController`.

Testing
- `ScoringServiceTests` includes an initial unit test scaffold (XCTest)
- Suggested next tests: edge cases for scoring, `ExamViewModel` navigation and timer behavior

Roadmap (Suggestions)
- Add a simple History screen (previous attempts) using SwiftData
- Externalize strings for localization
- Expand unit and UI tests (timer expiry, TTS/narration gating)
- Persist and optionally render clock drawings in the report

Privacy
- The app does not collect analytics or transmit data by default
- Text-to-speech does not require microphone permissions

Contributing
- Use Swift format/style consistent with the project
- Prefer small, well-named files and testable units
- Submit PRs with a brief description and screenshots for UI changes

License
This project is licensed under the MIT License. See `LICENSE` for details.


