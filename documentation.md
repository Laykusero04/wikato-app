# Wikato MVP — UI/UX-Focused Phased Plan (Flutter)

Goal: build the look, feel, and flow first. No repositories, no JSON loading, no persistence yet — just screens, widgets, navigation, and inline mock data only where a screen literally cannot render without it.

## Phase 1 — Design system & navigation shell
The visual foundation everything else inherits.

- Extend `lib/colors/app_colors.dart` with the palette from the diagram: green (screens / CTA), purple (lessons), orange (Real Situation Mode — accent), yellow (saved / progress), neutral grays.
- Create `lib/theme/app_theme.dart` — `ThemeData` with text styles (display / title / body / caption), spacing tokens, radius tokens, elevations.
- Set up `go_router` in `lib/app.dart` with stub routes: `/splash`, `/language`, `/home`, `/lessons`, `/lessons/:id`, `/scenarios`, `/scenarios/:id`, `/saved`, `/settings`. Each stub is a `Scaffold` with a title.
- Build reusable widgets in `lib/widgets/`: `AppScaffold`, `SectionHeader`, `CategoryCard`, `PhraseCard`, `BadgeChip` (for the KEY differentiator badge), `ProgressPill`. Promote `lib/components/primary_button.dart` into the theme.

## Phase 2 — Onboarding flow visuals
- `SplashScreen` — Wikato logo, tagline, subtle fade / scale animation, auto-advances after 1.2s.
- `LanguageSelectScreen` — grid of language cards (flag + name), selected state, "Continue" CTA. Mock list inline: 6 languages.
- `HomeScreen` — greeting header, progress strip placeholder, three big entry tiles (Lessons / Real Situation Mode / Saved), settings icon top-right. The Real Situation Mode tile gets the orange accent + KEY badge, visually heavier than the others.
- Page transitions: shared-axis between Home → feature screens.

## Phase 3 — Lessons UI
- `LessonsListScreen` — sectioned list of categories (Greetings, Common phrases, Asking for help, Food / ordering) with phrase counts. Inline `const` mock list of 4 categories — no JSON yet.
- `LessonDetailScreen` — horizontally swipeable `PhraseCard` deck (`PageView`), card flip animation to reveal translation + pronunciation, audio button as a non-functional UI affordance (icon + ripple, no playback).
- `TranslationExerciseScreen` — MCQ layout: prompt at top, 4 option buttons, correct / incorrect visual feedback states. Hardcode one example exchange so the screen renders end-to-end.
- Bottom sheet for "save phrase" interaction — purely visual toggle for now.

## Phase 4 — Real Situation Mode UI (the differentiator — make it shine)
This is the screen that sells Wikato. Spend extra time here.

- `ScenariosListScreen` — full-bleed scenario cards with situation imagery / illustration placeholder, orange accent borders, large title + situation summary. 3 mock scenarios inline.
- `ScenarioDetailScreen` — hero header with situation context, "Useful phrases" stack, "Sample reply" highlighted card, all in the orange visual language. Distinct from lesson screens so users feel they entered a different mode.
- Subtle parallax or sticky header on scroll to elevate the feel.

## Phase 5 — Saved phrases, Settings, Progress visuals
- `SavedPhrasesScreen` — list of saved phrase rows with swipe-to-remove gesture (UI only, removes from local in-memory list). Empty state illustration + CTA back to Lessons.
- `SettingsScreen` — language row (taps back to language select), reset row with confirmation dialog (UI only), about row.
- Home progress strip — animated progress bar + "X phrases saved · Y lessons completed" using mock counts.

## Phase 6 — Polish pass
- Loading skeletons for list screens (even though no async work yet — they'll plug into real data later).
- Empty states for every list screen.
- Hero animations between list and detail screens.
- Haptics on key actions (save phrase, complete exercise).
- Run on a physical device or emulator and tune spacing / typography until it reads cleanly.

## Mock data policy
- Inline `const` lists at the top of the screen file that needs them. No `assets/`, no JSON, no repositories.
- Once UI is locked, models / repositories / persistence slot in by replacing the inline lists with repository calls — the widget tree stays untouched.

## Out of scope until UI is signed off
Models, JSON assets, `SharedPreferences`, real audio playback, real MCQ scoring logic, multi-language content. All deferred until the design is approved.
