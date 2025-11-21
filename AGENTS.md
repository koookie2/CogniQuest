# Repository Guidelines

## Project Structure & Module Organization
CogniQuest follows a lightweight MVVM layout. Core app sources live in `CogniQuest/`, with feature folders for `Models/`, `ViewModels/`, `Services/`, and `Views/`. `ContentView.swift` hosts navigation into the exam flow, while `Assets.xcassets` holds colors, symbols, and sound wave imagery. Unit tests reside in `CogniQuestTests/` and validate scoring, narration, and model logic. UI regression checks belong in `CogniQuestUITests/`, including `CogniQuestUITestsLaunchTests.swift` for launch smoke coverage.

## Build, Test, and Development Commands
Use Xcode 16+ for day-to-day work. Useful CLI equivalents:
```bash
open CogniQuest.xcodeproj                           # launch in Xcode
xcodebuild -scheme CogniQuest -destination 'platform=iOS Simulator,name=iPhone 15' build
xcodebuild test -scheme CogniQuest -destination 'platform=iOS Simulator,name=iPhone 15'
```
The app targets iOS 17; update the deployment target consistently if you introduce new minimum OS APIs.

## Coding Style & Naming Conventions
Adhere to standard Swift style: 4-space indentation, braces on the same line, and `camelCase` for variables/functions with `UpperCamelCase` types. Prefer SwiftUI composition over UIKit shims, and keep ViewModels free of view logic. Re-run Xcode’s “Editor ▸ Format” before committing; avoid introducing trailing whitespace. Group extensions by responsibility (`// MARK:`) mirroring existing files.

## Testing Guidelines
XCTest backs both unit and UI suites. Co-locate new unit specs under `CogniQuestTests/` with filenames ending in `Tests.swift` and mirror the source module path (e.g., `Services/ScoringServiceTests.swift`). Target meaningful scenarios—edge scoring, narration fallbacks, timer expiry—rather than duplicating SwiftUI rendering. For UI tests, favor deterministic flows with stubbed data where possible. Aim to keep new features covered by at least one automated test, and run `xcodebuild test …` before opening a PR.

## Commit & Pull Request Guidelines
Commits in this repo use short, imperative subject lines (“Add enhanced clock drawing”). Scope each commit to one logical change and reference tickets in the body if applicable. Pull requests should include: a concise summary, testing notes (commands run, simulators used), and screenshots or screen recordings for UI-facing work. Flag any follow-up tasks explicitly so reviewers can track them.
