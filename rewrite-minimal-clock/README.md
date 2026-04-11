# FloatingClockMac Workspace

This directory is the isolated workspace for the native macOS rewrite of Floating Clock, currently developed under the app name `FloatingClockMac`.

Rules for this rewrite:

- Leave the existing Electron implementation in the repository root unchanged.
- Build the new app here instead of modifying the legacy codebase.
- Keep the feature set focused on the floating clock experience only.
- Keep local planning documents out of GitHub.

Current status:

- Product requirements documented locally in `REQUIREMENTS.md`.
- Technical decisions documented locally in `TECH-DECISIONS.md`.
- Execution steps documented locally in `IMPLEMENTATION-PLAN.md`.
- Native stack chosen: `Swift + AppKit`, with `SwiftUI` for the clock view.
- A runnable macOS app scaffold exists with a translucent floating window and centered `HH:MM:SS` clock.
- The app currently supports always-on-top behavior, Spaces/full-screen presence, resizing, dragging, and frame autosave.
- Automatic theme sampling is wired in with a system-appearance fallback.

Next step:

- Continue polishing the titlebar/chrome behavior and then implement login item support.
