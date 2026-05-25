# Wikato — Offline Modification Plan

Companion to `documentation.md`. The UI-phased plan still stands. This file covers everything that changes now that Wikato is a **paid, offline, store-distributed app** with **zero development cost**.

## Decision summary (2026-05-17)
- **Distribution:** one-time-payment paid app on Google Play + App Store.
- **Connectivity:** fully offline at runtime. No backend, no sign-in, no per-user cloud data.
- **Development cost: $0.** No paid APIs. No paid services. Only free tools and free packages.
- **"AI" clarified:** in this project, "AI" means *the app teaches from the developer's own curated content*. The app does **not** call any AI service at runtime, and the developer does **not** call any paid AI API at build time.
- **Content authoring:** hand-written JSON, optionally drafted with free chat tools (ChatGPT free tier, Claude.ai free tier, Claude Code CLI). Copy-paste workflow — no API keys, no scripts that cost money.
- **Progress:** stored locally on device only.
- **Monetization:** paid up-front via store listing. No IAP in v1, no ads.

## Cost reality check
The only money you spend is publishing — not building.

| Item | Cost | When |
|---|---|---|
| Flutter SDK | Free | Always |
| All pub packages used here (`drift`, `flutter_tts`, `go_router`, `flutter_bloc`, `animations`, `audioplayers`) | Free | Always |
| GitHub repo | Free | Always |
| AI help with content drafting (Claude.ai free, ChatGPT free, Claude Code CLI) | Free | Build time |
| **Google Play Developer account** | **$25 one-time** | At publish |
| **Apple Developer Program** | **$99 per year (recurring!)** | At publish + every year |
| App review fees | $0 | Both stores |

> **Heads-up:** You said "one-time payment". Google Play is genuinely one-time ($25). Apple is **$99/year** — that's the only recurring cost. If you want to skip iOS entirely, you can launch Android-only and add iOS later.

## Architecture (offline, hand-authored content)

```
Build time (your laptop)             Runtime (user's phone)
────────────────────                 ──────────────────────
You write JSON files                 assets/content/*.json (read-only)
(optionally drafted with             drift (SQLite) for progress
free chat tools, pasted in)          flutter_tts for pronunciation
commit to git                        no network calls
```

No scripts that call paid APIs. No keys to manage. No environment files.

## What changes from the original plan
- **Phase 5 (Saved phrases / Settings / Progress):** local DB replaces "in-memory list". Use `drift` (free SQLite).
- **Mock data policy:** still inline `const` for early phases, but each inline list gets replaced by a JSON-asset read in Phase 7. Repositories load from `assets/content/*.json`, not from a backend.
- **Audio:** was a non-functional UI affordance. Now decided: `flutter_tts` only. No paid TTS, no bundled MP3s (since generating them costs money).
- **Out-of-scope items now permanently out of scope for v1:** sign-in, server, sync, leaderboards, push notifications, multi-device progress, any AI API call.

## New phases (slot in after Phase 6 polish)

### Phase 7 — Content authoring (free workflow)
You write the data the app ships with. No scripts. No API calls.

- New folder: `assets/content/` containing `lessons.json`, `phrases.json`, `scenarios.json`.
- **Workflow for drafting content:**
  1. Decide a category (e.g. "Greetings").
  2. Ask a free chat tool (Claude.ai, ChatGPT free, or this Claude Code CLI) to draft 10 phrases in the target native language with English meaning + romanization + example sentence, in the JSON schema below.
  3. Review for accuracy (you are the native-language expert).
  4. Paste into the JSON file. Commit.
- **No `tools/` folder. No `.env` files. No API keys.** This is the cheap, free, low-tech version of content generation.
- Recommend a `content_seed.md` doc inside `assets/content/` listing every category + topic still to write — keeps content work visible.

### Phase 8 — Asset-backed repositories
Swap inline mock lists for repositories that read the JSON assets.
- `lib/data/content_repository.dart` — loads + caches `lessons.json`, `phrases.json`, `scenarios.json` via `rootBundle.loadString`.
- Update each screen built in Phases 2–4 to consume the repository instead of inline `const` lists.
- Widget trees stay untouched (per original "Mock data policy" in `documentation.md`).

### Phase 9 — Local progress DB
Replace the in-memory saved-phrases list with persistent storage.
- Add `drift` (preferred — typed SQL, free) OR `isar` (simpler if you dislike SQL, free).
- Tables: `saved_phrases` (phrase_id, saved_at), `lesson_progress` (lesson_id, completed_at, score), `settings` (key/value: selected_language, sound_on, etc.).
- `ProgressRepository` wraps the DB; the UI talks only to the repository.
- Migration plan from in-memory → drift: keep the same repository interface used in Phase 5, only the implementation changes.

### Phase 10 — Pronunciation audio (free path only)
- Use [`flutter_tts`](https://pub.dev/packages/flutter_tts). It uses the platform's built-in TTS engine — free on both Android and iOS.
- **Caveat:** TTS quality depends on the phone AND the target language. If the language has no built-in voice on the device, the audio button should be hidden or disabled gracefully.
- **Decision gate:** if TTS doesn't support the target language at all, **defer audio to v2** instead of paying for ElevenLabs / Google Cloud TTS. Audio is not a v1 blocker.
- Show a settings toggle: "Sound on/off" — respect it everywhere.

### Phase 11 — Store release readiness
Everything required to actually publish — keeping costs minimal.
- App icons (already partially configured via `flutter_launcher_icons`).
- Splash via `flutter_native_splash` (free).
- Real app name, bundle ID (e.g. `com.afterdarksociety.wikato`).
- Privacy policy hosted on a **free** static site (GitHub Pages — free, required by both stores even for offline apps).
- **Google Play Console:** $25 one-time, set as paid app, target API level current.
- **App Store Connect:** $99/year — only if you ship iOS. **Recommended: Android first**, see if it sells, then decide on iOS.
- Screenshots (free — take from emulator), store listing copy, ASO keywords.
- Test build via Play internal testing track (free) before submitting for review.

## Data shape (target schema)
Sketch — finalize in Phase 7 before you start authoring.

```jsonc
// lessons.json
[
  { "id": "greetings", "title": "...", "category": "...", "phrase_ids": ["p_001", "p_002"] }
]

// phrases.json
[
  {
    "id": "p_001",
    "native": "...",          // target language phrase
    "english": "...",         // meaning
    "romanization": "...",    // optional pronunciation guide
    "example": "..."          // example usage sentence
    // no "audio" field — TTS generates audio at runtime
  }
]

// scenarios.json
[
  {
    "id": "s_market",
    "title": "Buying at the market",
    "context": "...",
    "useful_phrase_ids": ["p_001", "p_014"],
    "sample_reply": "..."
  }
]
```

## Open decisions (need user input)
- **Target native language?** Drives TTS feasibility *and* who you ask to help review content.
- **Android-only at launch, or both stores?** Avoids the $99/year Apple cost if Android-only.
- **Local DB choice:** `drift` (typed SQL, more powerful) vs. `isar` (simpler, NoSQL-feel). Default: `drift`.
- **Price point:** USD $1.99, $2.99, $4.99? Default suggestion: $2.99 launch, raise later.

## Permanently out of scope for v1
Sign-in, accounts, cloud sync, multi-device progress, leaderboards, social features, IAP, ads, push notifications, server-side analytics, any LLM API call, any paid TTS service. All deferred — possibly forever, since the model is intentionally offline, paid, and zero-cost to develop.
