# Wikato — Development Phasing (build-only)

The master "how to build it" checklist. Covers **development only** — no Play Store, no App Store, no marketing. For publishing steps see Phase 11 in `offline_plan.md`.

Reads top-to-bottom. Don't skip ahead — each phase relies on the previous one.

Companion docs:
- `documentation.md` — original UI phases 1–6
- `offline_plan.md` — full offline architecture & cost reality

---

## Phase 0 — Project hygiene (do this first, ~1 hour)
Foundation that the rest of the work depends on. Boring but mandatory.

- [ ] Confirm Flutter SDK works: `flutter doctor` shows no red issues.
- [ ] Confirm you can run on **an Android emulator AND a physical Android device**. (Physical device matters — emulator hides perf/TTS issues.)
- [ ] Decide and commit a folder structure:
  ```
  lib/
    app.dart
    colors/
    theme/
    widgets/         (reusable, no business logic)
    screens/         (one folder per feature optional)
    data/            (NEW — repositories live here)
    models/          (NEW — plain Dart classes for Phrase, Lesson, Scenario)
  assets/
    content/         (NEW — JSON content lives here)
    images/
  ```
- [ ] `.gitignore` includes `build/`, `.dart_tool/`, IDE files. (Already done.)
- [ ] Run `flutter analyze` — fix any warnings before continuing.

**Exit criteria:** app runs on emulator + real device, no analyzer warnings.

---

## Phase 1 — Design system & navigation shell (from `documentation.md`)
- [ ] `lib/colors/app_colors.dart` — palette: green / purple / orange / yellow / neutrals.
- [ ] `lib/theme/app_theme.dart` — text styles, spacing tokens, radius tokens, elevations.
- [ ] `go_router` set up in `lib/app.dart` with stub routes: `/splash`, `/language`, `/home`, `/lessons`, `/lessons/:id`, `/scenarios`, `/scenarios/:id`, `/saved`, `/settings`.
- [ ] Reusable widgets: `AppScaffold`, `SectionHeader`, `CategoryCard`, `PhraseCard`, `BadgeChip`, `ProgressPill`.

**Exit criteria:** every route opens to a scaffolded screen with title; theme is consistent.

---

## Phase 2 — Onboarding flow visuals (from `documentation.md`)
- [ ] `SplashScreen` — logo, tagline, fade/scale, auto-advance 1.2s.
- [ ] `LanguageSelectScreen` — grid of 6 language cards (inline mock), "Continue" CTA.
- [ ] `HomeScreen` — greeting, progress strip placeholder, 3 entry tiles. Real Situation Mode tile gets orange + KEY badge.
- [ ] Shared-axis page transitions for Home → feature screens.

**Exit criteria:** you can swipe through Splash → Language → Home and tap each tile.

---

## Phase 3 — Lessons UI (from `documentation.md`)
- [ ] `LessonsListScreen` — 4 sectioned categories, phrase counts, inline mock list.
- [ ] `LessonDetailScreen` — swipeable `PhraseCard` deck (`PageView`), flip animation, audio button affordance (no playback yet).
- [ ] `TranslationExerciseScreen` — MCQ layout with 4 options, correct/incorrect feedback states. Hardcode one exchange.
- [ ] Save-phrase bottom sheet (visual toggle only).

**Exit criteria:** the lesson flow is browsable end-to-end with mock data.

---

## Phase 4 — Real Situation Mode UI (from `documentation.md`)
This is the differentiator — spend extra time.
- [ ] `ScenariosListScreen` — full-bleed scenario cards, orange accent borders, 3 mock scenarios inline.
- [ ] `ScenarioDetailScreen` — hero header with situation context, "Useful phrases" stack, "Sample reply" card, all in orange visual language.
- [ ] Subtle parallax or sticky header.

**Exit criteria:** Real Situation Mode visibly feels like a different mode from Lessons.

---

## Phase 5 — Saved phrases, Settings, Progress visuals (from `documentation.md`)
- [ ] `SavedPhrasesScreen` — swipe-to-remove (in-memory only for now), empty state.
- [ ] `SettingsScreen` — language row, reset confirmation dialog, about row.
- [ ] Home progress strip — animated bar + counts (mock).

**Exit criteria:** every screen mentioned in `documentation.md` is reachable and visually polished.

---

## Phase 6 — Polish pass (from `documentation.md`)
- [ ] Loading skeletons on list screens.
- [ ] Empty states everywhere.
- [ ] Hero animations list ↔ detail.
- [ ] Haptics on key actions (save phrase, complete exercise).
- [ ] Tune spacing/typography on a real device until it reads cleanly.

**Exit criteria:** UI is sign-off ready. Now you can swap in real data without touching widgets.

---

## Phase 7 — Content authoring (the "AI = your data" phase)
**Free, no API calls.** Just write JSON. Optionally draft with free chat tools.

- [ ] Create `assets/content/` folder.
- [ ] Register the folder under `flutter.assets` in `pubspec.yaml`:
  ```yaml
  flutter:
    assets:
      - assets/content/
  ```
- [ ] Define the JSON schemas in a comment header inside each file (use the shape in `offline_plan.md`).
- [ ] Author **at least 1 category × 10 phrases** to start (e.g. "Greetings"). Don't try to write everything before testing — small batch first.
- [ ] Author **1 full scenario** (e.g. "Buying at the market") referencing existing phrase IDs.
- [ ] Commit `assets/content/lessons.json`, `phrases.json`, `scenarios.json`.

**Drafting workflow (free):**
- Open Claude.ai (free), ChatGPT free tier, or this Claude Code CLI.
- Prompt: *"Give me 10 Greetings phrases in [target language] as JSON with this shape: { id, native, english, romanization, example }."*
- Review every line yourself — you are the native-language expert.
- Paste into the JSON file.

**Exit criteria:** the 3 JSON files exist, validate as JSON, and contain at least one category's worth of real content.

---

## Phase 8 — Asset-backed repositories
Swap inline mock lists for real reads from `assets/content/`.

- [ ] Create plain Dart models in `lib/models/`: `Phrase`, `Lesson`, `Scenario`. Use `factory fromJson(...)`.
- [ ] Create `lib/data/content_repository.dart`:
  - Loads JSON via `rootBundle.loadString('assets/content/phrases.json')`.
  - Decodes once at app start, caches in memory (offline app, no need to re-read).
  - Exposes: `Future<List<Lesson>> loadLessons()`, `Future<Phrase> getPhrase(String id)`, `Future<List<Scenario>> loadScenarios()`.
- [ ] In every screen built in Phases 2–4, **replace the inline `const` mock list** with a call to the repository. Widget tree stays untouched — only the data source changes.
- [ ] Add a loading state for the first frame (since `rootBundle` is async).

**Exit criteria:** delete all inline mock lists. The app still works, now reading from JSON.

---

## Phase 9 — Local persistence ✅
Persistent storage for saved phrases (and later, lesson progress + settings).

**Implementation:** `shared_preferences`, not `drift`.

We initially planned `drift` (typed SQL) but hit a Dart 3.10 + build_runner native-assets incompatibility. For this app's data scale (~50–200 saved phrase IDs, key/value settings), `shared_preferences` is genuinely the better fit anyway — no codegen, smaller deps, simpler API. If the app ever grows to needing real querying (e.g. spaced-repetition with timestamps and joins), revisit drift.

- [x] Add `shared_preferences` to pubspec.
- [x] `lib/data/progress_store.dart` — singleton with `ValueNotifier<Set<String>> savedPhraseIds` for reactive UI.
- [x] `main.dart` calls `await ProgressStore.init()` after content preload.
- [x] `LessonDetailScreen` reads `ProgressStore.savedPhraseIds` via `ValueListenableBuilder` instead of local `Set`.
- [x] `SavedPhrasesScreen` rebuilt: resolves saved IDs through `ContentRepository`, swipe-to-delete with Undo snackbar, empty-state illustration.
- [x] `SettingsScreen` "Reset progress" wired with confirmation dialog → `ProgressStore.resetAll()`.

**Exit criteria:** ✅ kill the app, reopen it — saved phrases are still there.

**Future additions to `ProgressStore`** (deferred, add when there's UI for them):
- `Map<String, int> lessonProgress` — completed/score per lesson.
- Generic `String?` settings get/set for things like selected language.

---

## Phase 10 — Pronunciation audio — **DEFERRED to v2** (user decision 2026-05-17)
Audio is intentionally out of scope for v1. Volume icons in the UI stay as visual affordances + haptic feedback so the layout is consistent and a future drop-in works.

When picking this up later:
- Add `flutter_tts`. Set language to `tl-PH`.
- Wire the existing `onPlay` callbacks on `PhraseCard` and the scenario phrase rows.
- Test on a real Android device AND a real iPhone before shipping; if quality is poor on either, that's the gate to consider bundled audio.

---

## Phase 11+ — Out of scope here
Store submission, ASO, screenshots, store accounts → see `offline_plan.md` Phase 11.

---

## Order of operations cheat sheet
```
0. Hygiene           → flutter doctor, folder layout, gitignore
1–6. UI              → from documentation.md, mostly already in progress
7. Content           → write JSON, no code yet
8. Repositories      → swap mocks for JSON reads
9. Local DB          → persistence
10. TTS              → audio (optional)
```

Build width-first within each phase, not depth-first. Don't go back and "polish" Phase 1 while you're in Phase 5 — make a note and fix it in Phase 6.

## What to ask me when you're stuck
- "Set up Phase 7 with my first 10 phrases in [language]"
- "Generate the `drift` database scaffold for Phase 9"
- "Wire `flutter_tts` into `PhraseCard`"
- "Make `content_repository.dart` and replace the mocks in `LessonsListScreen`"

I can do any of those whenever you're ready.
