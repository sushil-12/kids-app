# BrightMind Kids — AI + Backend Core Plan

Planning doc for the intelligent layer. Pairs with `CLAUDE.md` (architecture) and
the Phase 1 spec (features). This defines **what to decide, set up, and build**
to add AI + a backend *cheaply* and *safely* for a children's app.

---

## 0. Guiding principle (read first)

Cost is decided by *where* AI runs, not *whether* you use it. Push every feature
to the cheapest tier that can do the job:

| Tier | Cost | Use for | Privacy |
|------|------|---------|---------|
| **1. Batch / precompute** | ~one-time, trivial | Coloring pages, packs, stories, translations, TTS audio | No child data involved |
| **2. On-device ML** | Free, offline | Adaptive difficulty, scribble/speech recognition, photo→coloring | Nothing leaves the device |
| **3. Cached server proxy** | Fractions of a cent | Parent reports, suggestions | Parent data only, never child PII |

**Live, per-action LLM calls for kids = the thing we are avoiding.** Real-time
model calls are reserved for low-frequency, parent-facing tasks only.

Two hard rules everything else hangs off:
- **The app never calls an AI API directly.** All model calls go through a
  server proxy (auth → rate-limit → moderate → cache → model). Keys live there.
- **Children's data stays on-device** (Hive). Backend holds parent accounts +
  anonymous aggregates only.

---

## 1. Target architecture

```
FLUTTER APP
  ├─ On-device ML ........ adaptive difficulty, scribble/speech, photo→coloring   [free, private]
  ├─ Hive ................ ALL child data (name, progress, art) stays local       [COPPA/DPDP]
  ├─ RevenueCat .......... subscriptions (already planned)
  └─ Network calls ONLY for: parent auth, content sync, AI proxy

BACKEND (serverless BaaS)
  ├─ Auth ................ parent accounts only
  ├─ DB .................. parent profile, entitlements, ANONYMOUS aggregate stats
  ├─ Storage/CDN ......... batch-generated content packs
  ├─ Remote Config ....... feature flags + content drop toggles (no app update)
  └─ AI Proxy Function ... auth → quota → moderate → CACHE → cheapest model → moderate output
```

---

## 2. Prerequisites

### 2A. Decisions to lock before building (with recommendation)

1. **BaaS provider** — Firebase *(rec: fastest Flutter integration, Auth +
   Firestore + Functions + Remote Config + Storage, real free tier)* vs Supabase
   *(SQL, cheaper at scale)*. **Pick one now.**
2. **Data residency** — you're in India; the DPDP Act may push for in-region
   storage. Choose a region accordingly (Firebase `asia-south1`, or Supabase
   Mumbai). **Confirm with the compliance step (2C) before finalizing.**
3. **On-device ML framework** — Google **ML Kit** (drop-in: digital-ink/scribble
   recognition, image segmentation, on-device translation) + **TFLite** for any
   custom model. *(rec: ML Kit first — least effort.)*
4. **LLM tier for the proxy** — a cheap, fast model for parent reports; only
   needed for Tier-3 features. Lock a monthly spend cap from day one.
5. **TTS approach** — batch-generate narration as bundled audio assets
   *(rec)* vs live TTS. Decide voice (human recording vs high-quality TTS).
6. **Adaptive-difficulty method** — start with a transparent heuristic / bandit
   (no ML infra), upgrade to a model later. **Lock: heuristic first.**

### 2B. Accounts & infrastructure to set up

- BaaS project (dev + prod environments).
- AI model API account with **billing alerts + hard spend cap**.
- Secret management for keys (BaaS secrets / env), **never** in the app binary
  or git (`.env`, `key.properties` already gitignored).
- CDN/Storage bucket for content packs.
- CI step: `flutter analyze` + `flutter test` on push (see open `.github/` task).

### 2C. Legal & compliance — GATE before any launch (not optional)

- **COPPA (US)** — verifiable parental consent before collecting anything from
  under-13s; no behavioral ads.
- **GDPR-K (EU)** — parental consent, data minimization.
- **India DPDP Act 2023** — processing a child's data (under 18) generally
  requires **verifiable parental consent**, and **bars tracking / behavioral
  monitoring and targeted advertising directed at children**. Implementation
  rules have been evolving — **verify the current requirements with a lawyer
  before launch.** (I'm not a lawyer; treat this as a checklist item, not advice.)
- Practical consequences baked into the design: child data on-device only;
  parent consent flow before any photo/AI feature; photos discarded immediately
  after on-device processing; AI output moderated; no open-ended chatbot for kids.
- **Deliverables:** privacy policy URL, consent flow, data-deletion path
  (your Settings "Delete Profile & Data" already exists — make it real).

### 2D. In-app technical prerequisites

- **Feature-flag layer** (Remote Config) so AI features can be toggled per
  region/version — essential while compliance is being confirmed.
- **Network/service layer** in `core/` (you have none yet — currently offline).
  Add `core/services/` with a typed API client + the proxy client.
- **Consent + account state** in Riverpod + Hive.
- **Graceful offline degradation** — every AI feature must have a non-AI
  fallback so the app fully works offline (it does today; keep it that way).

### 2E. Content & assets

- Line-art generation pipeline (closed-region SVG → region masks → template).
- Moderation pass on all generated content before it ships.
- Asset packaging + versioned manifest for content drops.

---

## 3. Feature workstreams & what each needs

### W1 — Batch content engine (Tier 1)
*Endless fresh pages/packs, near-zero marginal cost. Biggest retention lever.*
- Needs: generation pipeline, region-mask tooling, moderation, CDN, content
  manifest + Remote Config toggle, in-app pack download/cache.
- Output: themed packs (space, dinosaurs, Diwali/Holi), seasonal drops.

### W2 — On-device intelligence (Tier 2)
*Makes the app feel smart; free; private.*
- **Adaptive difficulty** (heuristic first) — needs local progress signals
  (already in view-models) + a difficulty policy module.
- **Scribble recognition** ("I see a cat!") — ML Kit digital-ink.
- **Speech games** ("say the color") — on-device speech recognition + mic
  permission + parent consent.
- **Photo→coloring** — ML Kit segmentation/edge detection; **consent gate +
  discard image after processing**.

### W3 — Parent-facing AI (Tier 3, via proxy)
*Justifies the subscription; microscopic cost.*
- **Weekly progress report** — 1 cheap model call/child/week, generated from
  *on-device* aggregates sent without identity. Needs the proxy + a prompt
  template + caching.
- **Next-activity suggestions** — derived from local progress.
- Needs: AI proxy (§4), parent account, quota.

### W4 — Magic polish (Tier 1)
- Pre-generated TTS narration + name callouts as bundled audio.
- Region "color reaction" sounds (already specced).

---

## 4. The AI Proxy (shared critical component)

A single serverless function fronts every model call. Build this **before** any
Tier-3 feature; it is the cost-control and safety chokepoint.

Pipeline:
```
request → verify parent auth/session
        → enforce per-account rate limit + monthly quota
        → moderate INPUT
        → check CACHE (hash of normalized input)  ── hit ─→ return cached (free)
        → call cheapest capable model
        → moderate OUTPUT
        → store in cache → return
```
Prerequisites: BaaS function runtime, cache store (KV/Firestore/Redis), model
API key in secrets, structured logging (no child PII in logs), spend cap alarms.

---

## 5. Data model & privacy boundaries

| Data | Where it lives | Notes |
|------|----------------|-------|
| Child name, age band, progress, artwork | **Device (Hive) only** | Never uploaded |
| Parent account, email, entitlement | Backend | Standard auth + RevenueCat sync |
| Aggregate/anonymous stats | Backend | No identifiers tying to a child |
| Content packs | CDN | Public, versioned |
| AI cache | Backend | Keyed by hashed, de-identified input |

If a feature needs child data to leave the device, the default answer is **no** —
find an on-device way or drop it.

---

## 6. Rough cost model

- **Tier 1 & 4:** one-time generation cost, then $0 marginal. Mostly CDN egress.
- **Tier 2:** $0 runtime (on-device).
- **Tier 3:** ~one cheap call per paying family per week + cache hits → cents per
  family per month. Cap it at the proxy.
- **Backend idle:** ≈ $0 on serverless free tiers until meaningful scale.
- Net: AI/backend cost should stay a tiny fraction of subscription revenue if the
  tiering is respected. **Set billing alerts anyway.**

---

## 7. Build sequence

1. **Compliance gate (2C)** + lock decisions (2A). *Nothing ships until this.*
   — ML framework locked: **ML Kit** (2A.3); difficulty method locked:
   **heuristic first** (2A.6). BaaS/region/model-tier/TTS still open.
2. ✅ **In-app service + feature-flag layer (2D)** — *done.* `core/services/`
   (`ApiClient` offline seam + Riverpod/Hive feature flags). Backend/AI-proxy
   features ship behind flags that default off.
3. ✅ **W2: on-device adaptive difficulty** — *done (foundation).*
   `features/adaptive/` heuristic engine, wired into Count & Tap + Odd-One-Out;
   remaining games adopt the same pattern next.
4. **W1: batch content engine** — retention + freshness.
5. **Backend + parent auth + AI proxy (§4)**.
6. **W3: weekly parent report** — the premium justifier.
7. **W2: photo→coloring** — the viral installer (consent-gated).
8. **W4 + W2 speech/scribble** polish — ML Kit digital-ink next (flag
   `scribbleRecognition` already reserved).

---

## 8. Risks & mitigations

- **Runaway AI cost** → hard spend caps, quotas, caching, tiering. Live calls
  parent-only.
- **Compliance misstep** (highest risk for kids' apps) → on-device child data,
  consent gates, no behavioral tracking, legal review before launch.
- **Open-ended kid chatbot risk** → don't build free chat for children; constrain
  AI to small, fixed slots with moderation.
- **Key leakage** → no keys in app; proxy only.
- **Offline breakage** → every AI feature has a non-AI fallback.

---

## 9. Success metrics

- AI/backend cost per paying family per month (target: a few cents).
- Retention lift from fresh content drops (W1) — D7/D30.
- Subscription conversion lift attributable to parent reports (W3).
- Install lift attributable to photo→coloring shares (W2).
- Crash-free + offline-functional rate (must stay high).

---

## 10. Immediate next actions

- [~] Lock decisions in §2A — **ML framework (ML Kit)** and **difficulty
  (heuristic)** locked; BaaS, region, model tier, TTS still open.
- [ ] Start compliance review (§2C), especially India DPDP children's provisions.
- [x] Add `core/services/` (API client seam) + feature flags to the app.
      *(Remote Config still to back the flag store when the BaaS lands.)*
- [x] Ship on-device adaptive difficulty (W2) — heuristic engine + first two
      games wired. Roll out to the other five games.
- [ ] Spec the content-generation pipeline (W1) and the AI proxy (§4) in detail.
- [ ] Set model-API billing alerts + hard cap.
- [x] Fold this plan's status into `CLAUDE.md` so Claude Code builds toward it.S