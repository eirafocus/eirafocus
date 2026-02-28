Eirafocus App Development Instructions
Overview
This document consolidates the feature set, architectural decisions, and step-by-step instructions for building Eirafocus, an Android app for meditation and breathing exercises. As a senior engineer, I'll critique the requirements upfront: Building a full-featured app with modern UI elements while aiming for near-zero development cost is ambitious but feasible using open-source tools like Flutter. However, "cost almost nothing" implies no paid assets, no cloud services, and self-development or agent-assisted coding—anything else adds hidden costs in time or maintenance. I'll prioritize simplicity to avoid unnecessary complexity, which could bloat the app and increase bugs.
Trade-offs:

Chosen: Local-first design with all data stored on-device. This optimizes for privacy, zero operational costs, and offline functionality.
Not chosen: Cloud sync or user accounts. Why? Adds complexity (authentication, servers), privacy risks (data off-device), and costs (even free tiers have limits). If sync is later needed, it can be added as an optional feature.
Chosen: Flutter for cross-platform potential (though focused on Android). It's free, has built-in modern UI widgets, and allows single-codebase development.
Not chosen: Native Android (Kotlin/Java). Why? Slower development, no cross-platform reuse, higher learning curve if expanding to iOS later.
Optimization: Minimal dependencies, embedded database (SQLite via sqflite), no analytics tracking to preserve privacy and avoid outbound calls.

The app will be a single-binary APK for Android, built with Flutter. Core business logic (e.g., breathing timers, analytics calculations) will be in plain Dart, separable from UI for reusability (e.g., future CLI tool). UI will use Material Design for a clean, modern Android look—avoiding custom themes to keep development simple and cost-free. Icons will use Flutter's built-in Material Icons or free packages like font_awesome_flutter for polish without expense.
If any part is unclear (e.g., specific meditation audio needs), clarify before proceeding. This is a solid starting point, but over-featuring could make it unmaintainable—let's keep it lean.
Feature Set
I've expanded the breathing features you mentioned and proposed a simple meditation section. Critique: Your breathing ideas are straightforward and valuable, but meditation is vague—I've kept it minimal to avoid bloat. No audio-guided meditations, as that requires assets (costly to produce) or external APIs (privacy risk, outbound calls). Instead, focus on timer-based and text-prompt features, which are cheap and local.
Core Features

Onboarding: Simple splash screen and one-time intro tutorial (text-based, no videos to keep size small).
Dashboard: Home screen showing quick access to breathing/meditation, recent sessions, and basic stats (e.g., sessions this week).
Settings: Toggle dark mode, sound/vibration feedback, privacy notice (emphasizing local data). No analytics opt-in—secure by default.

Breathing Section

Predefined methods:
Equal Breathing: Inhale/exhale equally (e.g., 4s each), with customizable duration.
Box Breathing: 4s inhale, 4s hold, 4s exhale, 4s hold.
4-7-8 Breathing: 4s inhale, 7s hold, 8s exhale.
Breath Hold Test: Timer to measure max hold time, with safety warnings.

Custom Breathing: User defines inhale/hold/exhale/hold durations and cycles.
Session Controls: Animated circle for breathing guidance, timer, pause/resume, end early.
Feedback: Optional vibration or subtle sounds (using device defaults, no custom audio to avoid size/cost).

Meditation Section

Timer: Set duration for silent meditation, with start/pause/end.
Text Prompts: Basic guided text (e.g., "Focus on your breath" displayed at intervals). Store a few static prompts in code—customizable by user.
Daily Streaks: Track consecutive days of meditation.
No advanced features like ambient sounds—why? Requires assets or streaming, adding complexity and potential outbound calls. Suggest users play their own music externally.

Analytics

Track: Total sessions, total minutes, sessions/minutes per day/week/month, average session length, most used method.
Visualization: Simple charts (using fl_chart package—free and lightweight).
Storage: All local—no export unless user-initiated (e.g., CSV share).
Privacy: Data never leaves device; deletable via settings.

Trade-offs in features:

Chosen: Focus on core breathing/meditation without social sharing or leaderboards. Why? Keeps app simple, privacy-first, no network needs.
Not chosen: Integration with wearables (e.g., heart rate). Why? Adds permissions, dependencies, and testing complexity without clear value.
If this feels incomplete, propose alternatives: Option 1 (lean, as above); Option 2 (add basic journaling for reflections—text notes stored locally). I'll pick Option 1 for minimalism.

Architectural Decisions: Using Dart and Flutter
Flutter (with Dart) is ideal here—free, open-source, and excels at modern UIs with animations. Critique: Flutter can lead to larger APKs if not optimized, but we'll minimize that. No backend needed; everything on-device.

Language/Framework: Dart for all logic, Flutter for UI. Core logic (timers, analytics) in pure Dart classes—framework-agnostic for reuse (e.g., extract to a Dart package).
UI Design: Material 3 (Flutter's modern Android style) for clean, responsive look. Use ThemeData for consistency. Icons: MaterialIcons for basics; add font_awesome_flutter for premium feel (free, no cost).
State Management: Riverpod (simple, no boilerplate) over Bloc—trade-off: Riverpod is lighter for this scale, avoids over-engineering.
Storage: sqflite (SQLite wrapper) for sessions/analytics. Why not shared_preferences? Insufficient for structured data like session history.
Dependencies: Minimal—flutter, sqflite, path_provider, fl_chart, font_awesome_flutter, intl (for dates). No more to keep build fast and app small.
Build/Deployment: Flutter build for Android APK. Use Docker for reproducible builds if needed, but not runtime. One-command local setup: flutter run.
Testing: Unit tests for core logic (Dart only); widget tests for UI. No integration tests initially—add if bugs arise.
Security/Privacy: No permissions beyond vibration (optional). No internet permission—app offline. Secrets? None needed.

Trade-offs:

Chosen: Single-module Flutter app. Why? Simplest structure.
Not chosen: Modular federation or plugins. Why? Unnecessary for this scope, adds build complexity.
Prod setup: Same as local—build APK, sideload or Google Play (free tier possible, but publishing has review costs—consider F-Droid for zero cost).
