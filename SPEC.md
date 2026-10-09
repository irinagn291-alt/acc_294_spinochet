# Benday — Build Specification

> Portfolio app 164, batch pending. This document is the complete brief for
> building this application. Read all of it before writing any code. Anything
> not specified here is your decision, but must stay consistent with section 3.

**One-line positioning:** Mark how each day felt with one brushstroke on a year-long grid.

| Field | Value |
| --- | --- |
| Product name | Benday |
| Bundle identifier | `com.benday.matrix` |
| Domain | https://benday-matrix.pro |
| Contact URL | https://benday-matrix.pro/contact-us |
| Deployment target | iOS 17.0 |
| Swift version | 6.2, strict concurrency `complete` |
| Devices | iPhone and iPad, portrait |
| Interface style | Light |
| Asset prefix | `bdy_` |
| User-Agent | `Benday/1.0 (iOS; +https://benday-matrix.pro)` |

---

## 1. Non-negotiable constraints

1. **No CocoaPods.** Dependencies come from Swift Package Manager, a local
   in-repo package, a vendored source folder, or nothing at all — per section 3.
2. **No shared code with other portfolio apps.** Business rules are re-implemented
   here under this app's own type names.
3. **All code, identifiers, comments, UI copy and the README are in English.**
4. **No launch gate, no WebView shell, no remote configuration, no analytics.**
   Guideline 4.2 (Minimum Functionality): this is a native SwiftUI product, not
   a web browsing experience. WKWebView / SFSafariViewController as UI is a
   reject. Push notifications, Core Location, and sharing do not make a
   browser or a thin catalog into an App Store app.
5. **Guideline 5.1.1 (Privacy):** never direct the user to grant camera access.
   A pre-permission screen may exist; the proceed button is **Continue** or
   **Next**, never "Allow camera", "Enable camera", "Grant camera", or a bare
   Allow/Enable that triggers `requestAccess`. The system alert is the only Allow.
6. **No CI files.** No `bitrise.yml`, no `Scripts/`, no `metadata/` folder.
7. **Assets are AI-generated.** No stock photography. SF Symbols may support
   small affordances but must never be the primary iconography.
8. **The app must build clean** with
   `xcodegen generate && xcodebuild -scheme Benday -destination 'generic/platform=iOS' build`.
9. **Nothing may echo another app in this batch** in naming, layout or visuals.
10. **This is not a calorie meal-slot tracker** unless family is `food_tracker`.
   Do not invent food logging to fill the brief.

---

## 2. Product core

The product is offline-first. No account, no sign-in, no ads, no in-app purchase,
no analytics SDK, no remote config. All user data stays on the device.

A mood keeper dips ink and lays one brushstroke in today's cell so the year matrix shows how each day felt at a glance.

### 2.1 User flow

1. Draw today's stroke in the magnified cell with the already-dipped bristle from the docked ink tray
2. Pinch or scroll the year matrix to see how past strokes sit in their cells
3. Dip a different ink from the tray before laying a new day
4. Open Analytics to read quiet streak and ink mix for the year
5. Peel today's stroke if the lay went wrong, then dip and draw again
6. Adjust tray labels and export from Settings

### 2.2 Essential behaviour

- One MoodEntry per calendar day holding tone id and a single PKDrawing stroke
- Twelve-ink tray docked under today's magnified cell
- Quiet streak: consecutive Laid days ending today or yesterday, no shame UI
- Same-day Peel clears LayMark and restores an Open cell
- Year matrix renders halftone-styled stroke thumbnails per cell
- Local-only persistence; no account or social layer

---

## 3. Uniqueness assignment for Benday

| Axis | Assigned value |
| --- | --- |
| Architecture | **Bristle-lay fold (Open | Armed | Laid); YearMatrix holds Cells keyed by YYYYMMDD; Dip writes Ink on Bristle and folds today's Open Cell to Armed; Sketch appends one PKDrawing while Armed; pen-up writes LayMark and MoodEntry and folds Armed to Laid; Peel on today removes MoodEntry and folds Laid to Open; Sketch on Laid is refused; Dip while Armed with a nonempty path is refused until Peel; empty matrix renders Gesso; views observe one YearMatrix** |
| UI approach | **Programmatic UIKit · canvas-first** |
| Naming convention | **Halftone / comic-plate lexicon** |
| File organization | **By bristle role (YearMatrix, Cell, Ink, Bristle, LayMark, PeelMark, Well)** |
| Dependency strategy | **None (zero external dependencies) · no SPM entry, no CocoaPods, no vendored source; UIKit, Core Graphics, AVFoundation and URLSession only** |
| Design direction | **claude · tray-plus-canvas · mid** |
| Typography | **Verdana** |
| Navigation pattern | **Matrix-locked chrome (the 365 matrix never leaves; Analytics and Settings arrive as sheets; the ink tray stays docked under today's magnified cell)** |
| AI art style | **Comic halftone pop art · abstract** |
| Functional twist | **Ink-then-lay (Dip arms today; one stroke commits on pen-up with LayMark; Peel clears same day; quiet streak counts consecutive Laid days)** |
| Persistence | **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark** |
| Screen composition | see 3.6 |

### 3.0 Product concept

This is the product the contracts below are assigned to. Do not substitute another.

**Family** — year_mood_canvas

**Core** — A mood keeper dips ink and lays one brushstroke in today's cell so the year matrix shows how each day felt at a glance.

**Audience** — People who want a tactile year diary—a single mark per day—not a numeric mood score, a pet, a feed, or a tone-only heatmap.

**User flow**

1. Draw today's stroke in the magnified cell with the already-dipped bristle from the docked ink tray
2. Pinch or scroll the year matrix to see how past strokes sit in their cells
3. Dip a different ink from the tray before laying a new day
4. Open Analytics to read quiet streak and ink mix for the year
5. Peel today's stroke if the lay went wrong, then dip and draw again
6. Adjust tray labels and export from Settings

**Essential features**

- One MoodEntry per calendar day holding tone id and a single PKDrawing stroke
- Twelve-ink tray docked under today's magnified cell
- Quiet streak: consecutive Laid days ending today or yesterday, no shame UI
- Same-day Peel clears LayMark and restores an Open cell
- Year matrix renders halftone-styled stroke thumbnails per cell
- Local-only persistence; no account or social layer

**Twist** — Ink-then-lay. Home is the 365-cell matrix with the ink tray docked below today's magnified cell. Dip writes Ink on the Bristle and folds today's cell from Open to Armed when no MoodEntry exists for that daykey. Sketch appends exactly one continuous PencilKit stroke while Armed; pen-up writes LayMark, stores MoodEntry keyed as Int YYYYMMDD, and folds Armed to Laid. Peel on today removes MoodEntry and folds Laid back to Open. Sketch on Laid is refused until Peel. Dip while Armed with a nonempty path is refused. Analytics counts quiet streak and ink histogram, not ridge topology or neighbor bleed. Seed already Laid yesterday and leaves today Armed with bristle dipped so the opening gesture is draw-the-stroke. Home verb: lay-the-stroke—not set-the-tone and not commit-the-wash. Local only.

**Why this is not a repeat** — Isopleth already ships set-the-tone with contour ridges and no drawable stroke. Washfolio (provisional) commits neighbor-bleed washes, not a single PK stroke per cell. This product keeps the family invariant—one mark per startOfDay and twelve tones—but the persisted verb is dip-then-lay brushwork on a UIKit canvas, with halftone presentation and matrix-locked chrome, so it is not a reskin of ridge terrain or wash bleed.

### 3.0a Craft from the shipped portfolio

Full craft is in KNOWLEDGE.md. Follow it. Do not copy type names or layouts.
- Home: 365-cell year canvas. Tap today → radial tone picker → one stroke.
- Invariant: One MoodEntry per startOfDay. Quiet streak = consecutive days ending today or yesterday; a gap restarts, no broken-streak theatre. 12 tones.
- Never: Not a journal feed. Not Moodling's pet.
- Taste DNA is section 7.6. Do not invent a second look.
- A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.
- Mini-ref `ZenTigers`: steal Daily mark, streak, calendar, empty journal. Local only. Never Wrapper, OneSignal, fortune/wealth as a bet. Not a chatty feed. New types and layout — do not reskin.

### 3.1 Architecture contract

YearMatrix is the single model every screen observes, and it stores Cells keyed by an Int day key in YYYYMMDD form taken from Calendar.current.startOfDay. Each Cell folds through Open, Armed, and Laid. Dip writes the chosen Ink onto the Bristle and, when today has no MoodEntry, folds that Open Cell to Armed. Sketch appends exactly one continuous PKDrawing while Armed, and pen-up writes a LayMark, stores one MoodEntry for that day key, and folds Armed to Laid. Peel on today removes that day's MoodEntry and folds today back to Open, leaving earlier Laid cells in place. Sketch on a Laid cell is refused, Dip is refused while Armed when the path is already nonempty, and a matrix with no Laid cells renders Gesso.

Put a short comment block at the top of each principal type stating the role it
plays in this architecture. The README must justify the pattern for this product.

### 3.2 UI contract

Programmatic UIKit, canvas-first, with no storyboards and no SwiftUI screens. The matrix view fills the device, today's cell is magnified and hosts one PKCanvasView with anyInput so a finger can lay the stroke, and the Well of twelve named inks stays docked beneath that cell. Tone choice is a dip in that tray. Halftone thumbnails of laid strokes are Core Graphics on the matrix view only, which is the single custom-rendered surface. Analytics and Settings are stock UIKit sheets, and the ink mix is twelve stock rows of NumberFormatter counts. Primary actions use one bordered-prominent button style with default, pressed, disabled, and loading states. Peel uses a separate destructive style. Every control is at least 44 points and the hit area covers the whole chrome. Radii are 32 and 16 through one accessor, elevation is material, and the live lay verb wears the accent. Motion is a 180ms ease-out cross-fade, the magnified cell is the one playful moment, and Reduce Motion swaps instantly. One haptic fires when pen-up writes the LayMark. Each well shows its tray label, and every icon-only control has a VoiceOver label. Gesso is a full-page empty state with generated art, one headline, one line, and a full-width bottom action. Colour comes only from DesignTokens.

### 3.3 Naming contract

Convention: Halftone / comic-plate lexicon.

Examples to follow: `YearMatrix`, `LayMark`, `dipInk(_:)`, `peelToday()`

### 3.4 Dependency contract

Zero external dependencies. No Swift Package Manager entry, no CocoaPods, and no vendored source, so project.yml has no packages key. Linked system frameworks are UIKit, Core Graphics, and PencilKit, because the stroke is a PKDrawing. URLSession is the only permitted networking stack and this product makes no request. The camera is unused, so AVFoundation is not imported.

### 3.5 Navigation contract

Matrix-locked chrome: the 365-cell year matrix never leaves the window. Analytics and Settings arrive as sheets from the matrix chrome, and the ink tray stays docked under today's magnified cell. There is no tab bar and no chronological feed. After onboarding completes, read ProcessInfo arguments once. The launch key today shows the matrix, log presents the Analytics sheet, and goals presents the Settings sheet. Those three keys open three different frames.

### 3.6 Screen composition contract

The year matrix never leaves. Today's cell magnifies for PencilKit drawing; the twelve-ink tray stays docked beneath it. Analytics and Settings arrive as sheets from the matrix chrome. No tab bar and no chronological feed.

Physical screens:
1. Onboarding. Three or four full-page plates before the matrix. Each page fills the device. The proceed control is Continue or Next, full width, along the bottom. Skip still writes defaults. Re-run from Settings. This gate is not a chrome destination.
2. Canvas, the matrix home and the only root view. The year grid fills the width on iPhone and iPad. Today's cell is magnified and holds the PencilKit canvas. The Well of twelve inks is docked under that cell. Pinch or scroll visits past cells. Peel for today lives here. Gesso is the full-page empty state when no cell is Laid and today is still Open: headline "The year is empty.", line "The first stroke is yours.", and a full-width Dip action at the bottom. The Simulator seed is a used plate, with yesterday Laid and today Armed.
3. Analytics sheet. Quiet streak and the year's ink mix, in stock rows. No second drawing canvas.
4. Settings sheet. Tray labels, export of the plate, re-run onboarding, a confirmed reset that names the plate and the wipe, and the contact link https://benday-matrix.pro/contact-us.

Launch arguments are read once after onboarding and are not tabs. today opens Canvas with the lay gesture enabled. log opens the Analytics sheet. goals opens the Settings sheet.

Section 5 lists the logical functions that must exist. This section decides how
they are grouped into actual screens. Where the two disagree, this section wins.

A TabView with exactly three tabs is the factory stamp — use two or four-to-five destinations, or a different chrome. `-ReviewScreen today|log|goals` are launch keys, not tabs.

---

## 4. Target file organization

Scheme: **By bristle role (YearMatrix, Cell, Ink, Bristle, LayMark, PeelMark, Well)**

```
Benday/
  YearMatrix/YearMatrix.swift
YearMatrix/Cell.swift
YearMatrix/MoodEntry.swift
YearMatrix/MatrixViewController.swift
YearMatrix/GessoView.swift
Ink/Ink.swift
Ink/Well.swift
Ink/WellTrayView.swift
Bristle/Bristle.swift
LayMark/LayMark.swift
PeelMark/PeelMark.swift
Store/PlateStore.swift
Sheets/AnalyticsSheet.swift
Sheets/SettingsSheet.swift
Onboarding/OnboardingViewController.swift
  Assets.xcassets/
```

Adapt the leaf files to the architecture, but the top-level shape is fixed. Do
not create a `Utils/` or `Helpers/` dumping ground.

---

## 5. Screens

Build the screens named in section 3.6. The labels below are logical;
actual type names follow this app's naming convention.

### 5.1 Onboarding
Three to four pages. Explains the product, writes initial settings, sets a
completion flag. Skip still writes sensible defaults. Re-runnable from Settings.

### 5.2 Canvas
A first-class screen for **Canvas**. Must render empty, populated and error states.

### 5.3 Analytics
A first-class screen for **Analytics**. Must render empty, populated and error states.

### 5.4 Settings
A first-class screen for **Settings**. Must render empty, populated and error states.

### 5.5 Settings
Holds: re-run onboarding, reset all data (confirmed), and the contact link to
the domain contact-us URL.

### 5.6 Twist screen
See section 12. The twist needs at least one screen of its own plus a surface on the home screen.


---

## 6. Domain model

Minimum entities, named per this app's convention:

- **MoodEntry** — named per this app's convention.
- Plus whatever the twist in section 12 requires.


---

## 7. Design system

Direction: **claude · tray-plus-canvas · mid**

### 7.1 Palette

| Token | Hex | Use |
| --- | --- | --- |
| `background` | `#D8DADE` | Screen background |
| `surface` | `#ECEDEF` | Cards, rows, sheets |
| `ink` | `#15181E` | Primary text and icons |
| `accent` | `#2253B4` | Primary action, key figure, progress fill |
| `muted` | `#53565A` | Secondary text, dividers, disabled |

The scaffold already wrote these exact values to `Benday/DesignTokens.swift`
(`DesignTokens.bg`, `.surface`, `.ink`, `.accent`, `.muted`, plus
`DesignTokens.fontFamily`). Reach every colour through `DesignTokens` — a
typed accessor on top of it is fine. Keep the file and its hex values; do not
move them into `Assets.xcassets` and never hard-code a hex string anywhere else.

### 7.2 Typography

Family: **Verdana**

Verdana is the only text face, reached through one accessor: Verdana for body and captions, Verdana-Bold for titles and the lay verb. Six steps only: display, title, headline, body, caption, micro. Body is about 17pt, display stays one or two short lines, and every step tracks Dynamic Type through UIFontMetrics. No step uses a raw point literal in a view, none exceed 34pt, and none sit below 12pt. Streak counts, ink-mix totals, and any day shown to the reader go through NumberFormatter. Numerals use monospaced digits so the matrix chrome stays still when a count ticks. At the largest accessibility size, titles remain fully visible.

Define a type scale of at most six steps behind one accessor and use only those
steps. Text stays legible at the largest Dynamic Type size.

### 7.3 Layout

- One base spacing unit (4 or 8 pt); only multiples of it.
- Corner radius and elevation are fixed by section 7.4, not chosen per screen.
- Every interactive element is at least 44x44 pt.

### 7.4 Component contract

Corner radius: **32pt** for cards, sheets and primary surfaces; **16pt** for chips, badges and small controls. Reach both through one accessor. Never a bare literal number, and never zero — a hard edge is not this app's design direction.

Elevation: **material** — SwiftUI `Material` (`.regularMaterial` / `.thinMaterial`), reused everywhere a surface sits above another.

Primary control: **bordered prominent** — primary actions use `.buttonStyle(.borderedProminent)` or an equivalent filled, bordered shape.

This is arithmetic, not a suggestion: every card, sheet, chip and button in this app uses these two radii and this elevation style. Do not introduce a second radius or a second elevation style.

### 7.5 Custom rendering scope

This app's `ui` axis is **Programmatic UIKit · canvas-first**.

If that approach uses anything beyond stock SwiftUI/UIKit controls — `Canvas`, `CALayer`, Metal, SceneKit, SpriteKit, RealityKit, a hand-drawn `UIViewRepresentable`, or any other pixel-level custom rendering — confine it to exactly one hero surface on one screen (the mechanic's home view, or the one screen this axis exists to showcase). Every other screen — every list, every settings screen, every sheet, every secondary surface — is built from stock components: `List`, `Form`, `NavigationStack`, `TabView`, `Button`, `.sheet`, native `Text`/`Image`. A second custom-rendered surface elsewhere in the app is a defect, not a stylistic choice.

If **Programmatic UIKit · canvas-first** is already fully native (no custom drawing layer), this section is satisfied automatically — there is nothing to confine.

The `ui` axis value is an implementation choice. It must never appear as a user-visible section title or label.

### 7.6 Taste DNA

Aesthetic: **warm** (Warm soft: friendly radii, comfortable pad, one playful moment.)

Reference system: **claude** — steal rhythm and restraint, not their colours or logos.

Mood: **Anthropic's AI assistant. Warm terracotta accent, clean editorial layout.**.

Home rhythm (`tray-plus-canvas`, comfortable): Tray of materials, canvas of the work.

Warm soft: friendly radii, comfortable pad, one playful moment. Layout `tray-plus-canvas`, density comfortable. Kit 32/16, material, bordered prominent. Palette recipe `mid`. Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap. Reduce Motion: fade only. Do not invent a second radius or a second accent.

Type move: Mono numerals, humanist body, no poster type. Reference type feel: warm.

Motion (`quiet`): Almost no travel. Cross-fade 180ms ease-out. Numbers tick, they do not fly. Reduce Motion: instant swap.

Voice (`editorial`): Complete sentences, no slang, no hype. Captions are real lines.

Anti-slop from KNOWLEDGE.md applies. Taste never overrides contrast, 44pt hits, VoiceOver labels, or Reduce Motion.

---

## 8. UI and UX quality bar

Every item here is a defect if it is missing. Do not treat this as advice.

**Layout**

- Respect safe areas on every screen. Nothing sits under the notch, the Dynamic
  Island or the home indicator.
- The app is portrait-only on iPhone. Lock it in the Info settings and do not
  write rotation-dependent layout.
- No layout shift when asynchronous data arrives. Reserve the final size up
  front, or use a redacted placeholder of the same dimensions.
- Long product names must truncate gracefully, never push a number off screen.
  Numbers win; names truncate.
- Sibling cards, images and titles never overlap. Each cell owns its frame;
  `scaledToFill` is clipped to that cell. A chopped headline or two canvases
  in one slot is a defect, not a collage.
- Minimum tap target 44x44 pt for every interactive element, including small
  icon buttons and list accessories.
- Pick one base spacing unit and use only multiples of it. No arbitrary values.

**Keyboard**

- The grams field uses `.decimalPad`, and the decimal separator matches the
  user's locale.
- Content scrolls out from under the keyboard. The focused field is always
  visible.
- Tapping outside the field, or scrolling, dismisses the keyboard.
- Validate on the fly: reject negative and non-numeric input rather than
  crashing the parser later.

**Loading and state**

- Every asynchronous operation has a visible loading state.
- Guard against the spinner flash: if the work finishes in under 150 ms, do not
  show a spinner at all.
- Every list has a designed empty state containing a primary action, not just a
  sentence of text.
- Every error state offers a retry, and states plainly what failed.
- Disable the primary button while its action is in flight so it cannot be
  double-tapped into a double push or a duplicate entry.

**Typography and accessibility**

- All text scales with Dynamic Type. Verify at the largest accessibility size:
  nothing may clip or overlap.
- Every icon-only control has an `accessibilityLabel`. Decorative images are
  marked as decorative so VoiceOver skips them.
- Colour is never the only signal. Pair it with a label, a shape or an icon.
- Honour Reduce Motion: replace movement-heavy transitions with a fade.
- Meet contrast requirements against the palette in section 7. Check the muted
  colour against the background specifically; that is where these palettes fail.

**Formatting**

- Format every number with `NumberFormatter`, never string interpolation. Group
  separators and decimal separators must follow the locale.
- Energy is shown as a whole number of kcal. Macros are shown with at most one
  decimal place.
- Round only at the point of display. Stored values keep full precision.
- Day boundaries use `Calendar.current.startOfDay(for:)` in the user's current
  time zone. Handle the day changing while the app is open, and handle the
  short and long days that daylight saving produces.
- Unknown macro values render as a dash or the word "unknown", never as 0.

**Motion and feedback**

- One haptic on a successful commit (a food logged, a target saved). No haptic
  on navigation.
- Animations are short (0.2 to 0.35 s) and use a single shared easing curve.
- Nothing animates on first appearance of a screen except an intentional entry
  transition.

**Navigation**

- Back always works and never loses entered data without asking.
- A destructive action (delete a log row, reset all data) is confirmed.
- Modal sheets can always be dismissed; there is no dead end.
- Deep state is restorable: relaunching returns the user to a sane screen.


Every item here is a defect if it is missing. Section 7.4 fixed the numbers —
this is where they have to show up on screen.

**Hierarchy and density**

- Every screen has exactly one dominant element (a hero number, a canvas, a
  primary card) that the eye lands on first. A screen where every element has
  equal weight reads as a spreadsheet, not a product.
- Related content is grouped into a card or a section with the elevation
  style from 7.4, not left floating on the bare background.
- Unused flat background is not "minimal" — see the density rule in
  `KNOWLEDGE.md`. If a screen has room left after the mechanic and the
  content, add a secondary surface (a stat strip, a recent-activity card, a
  related-item row), not a `Spacer`.

**Components**

- Every card, sheet, chip, row and button in the app uses the corner radius
  and elevation from section 7.4. No screen introduces its own radius or its
  own shadow value "just for this one card".
- Buttons have a pressed state (`ButtonStyle` with a scale or opacity change
  on `isPressed`) and a disabled state that is visibly different, not just
  non-interactive.
- Chips and badges are pill or rounded-rect shaped per 7.4, never a bare
  `Text` with no background sitting where a control is expected.
- A functional control (add, filter, sort, close, more, share, delete) is an
  SF Symbol inside a properly hit-targeted `Button`. SF Symbols are fine and
  expected here — section 16 only bans them as the app's primary brand
  iconography (app icon, empty-state hero, onboarding art), which is what the
  generated assets in section 13 are for.

**Depth and material**

- At least one surface in the app (a sheet, a modal, a floating toolbar) uses
  the elevation style from 7.4 to visibly sit above the content behind it.
  A flat app with no depth anywhere reads as a wireframe.
- Icons and generated art sit on the surface colour from 7.1, never directly
  on a colour that makes their edges disappear.

**Motion as feedback, not decoration**

- The one dominant element in a screen (7.4's primary control, the mechanic's
  hero) responds visibly to touch: a scale, a colour shift, a haptic — pick
  at least one. A control that looks identical pressed and unpressed reads as
  broken, not calm.

**Taste DNA (section 7.6)**

- Home uses the assigned layout family and density. Three identical equal-weight
  cards, a leftover bento hole, or a second column structure copied down the
  page is a defect.
- Copy follows the assigned voice. No em-dash, no elevate/unlock/seamless, no
  emoji, no SECTION 01 labels.
- Motion follows the assigned personality and honours Reduce Motion with a fade.
  One signature motion per view. No glow stacked on glass stacked on spring.
- Tokens by intent: the live verb wears accent; delete does not wear primary.


---

## 9. Concurrency

The target builds with Swift 6.2 and `SWIFT_STRICT_CONCURRENCY = complete`. It
must compile with **zero concurrency warnings**. Warnings here become crashes
later, so they are not negotiable.

- All UI types are `@MainActor`. Annotate the type, not individual methods.
- Any value crossing an actor boundary is `Sendable`. Prefer immutable structs
  of primitives.
- Do not use `@unchecked Sendable`. If it is genuinely unavoidable, it needs a
  comment explaining what guarantees the safety.
- No mutable global state. No `static var` that is written after launch.
- Networking and storage APIs are `async` and honour cancellation. When the
  search query changes, cancel the in-flight task; do not let a stale response
  overwrite fresh results.
- Use structured concurrency. Avoid `Task.detached` unless there is a stated
  reason. Never fire a `Task` that outlives the view without owning it.
- Never use `DispatchQueue.main.asyncAfter` to paper over an ordering problem.
  Fix the ordering.
- `Timer` and notification observers are invalidated in `deinit` or on
  disappear.


---

## 10. Persistence engineering

Chosen technology: **UserDefaults+Codable · one Chart root record holding Islands, Books, Sessions, Runs and Rhumbs, encoded under a single key with a debounced save after each mark**

The store is one Codable Plate, the single root record, encoded as JSON under one UserDefaults key. Plate holds the YearMatrix of Cells, the Well of twelve Inks, the Bristle, each LayMark, and each PeelMark. schemaVersion starts at 1. Each MoodEntry stores an ink id and one PKDrawing data blob under its Int YYYYMMDD day key. Saves debounce after Dip, pen-up, and Peel, then flush when the scene becomes inactive or enters the background, and flush immediately after Peel or resetAllData(). Encode off the main thread. The matrix reads the in-memory Plate only. If decoding fails, restore the previous blob from a backup key, otherwise open on Gesso and tell the reader the plate could not be read. resetAllData() removes the key and is available from Settings. The Simulator seed runs once behind the versioned demo key bdy.demo.v1, marks onboarding complete, lays yesterday, and leaves today Armed with the bristle dipped. It never runs on a device.

This app persists to **files on disk**. The following are mandatory.

- Write atomically. Either `Data.write(to:options: .atomic)` or write to a
  temporary file and `FileManager.replaceItemAt`. A non-atomic write that is
  interrupted leaves a truncated file and the app will not launch.
- Create the containing directory with
  `withIntermediateDirectories: true` before the first write.
- Every document carries a `schemaVersion` field from version 1, and the decoder
  switches on it.
- Decoding failure must be recoverable: keep the previous good file as a
  `.backup`, fall back to it, and if that also fails start from empty state and
  tell the user. Never crash on a corrupt file.
- All file IO happens off the main thread. The main thread never blocks on disk.
- Debounce writes during rapid edits, but force a flush when `scenePhase`
  becomes `.inactive` or `.background`, and after any destructive action.
- Exclude caches from backup with `URLResourceValues.isExcludedFromBackup` where
  appropriate; user data belongs in Application Support and should be backed up.
- Keep an explicit in-memory source of truth and treat the file as a projection
  of it, so a failed write never leaves the UI showing data that does not exist.


Regardless of technology:

- One seam between domain logic and storage; the UI never touches storage types.
- Writes survive a force-quit. Do not rely on `applicationWillTerminate`.
- Provide `resetAllData()`, used by tests and reachable from Settings.

---

## 11. Networking

- One client type owns both Open Food Facts endpoints.
- Set `User-Agent` on every request. Open Food Facts throttles clients that do
  not identify themselves.
- 15 second timeout. One retry on a transient transport failure, then a typed
  error. Do not retry a 404.
- Cancel the in-flight search when the query changes. Debounce input by roughly
  300 ms.
- Decode into DTO types that mirror the JSON exactly, then map to domain types.
  Never decode straight into your domain model.
- Dedicated `JSONDecoder` with `.useDefaultKeys`. Never `convertFromSnakeCase` —
  Open Food Facts keys like `energy-kcal_100g` break snake_case conversion.
- Resolve a scanned code with `GET /api/v2/product/<barcode>.json`, not a search.
- Open Food Facts data is user-contributed and frequently incomplete. Every
  numeric field is optional. A product with no energy value is a normal case
  that the UI must present, not an error.
- Some numeric fields arrive as strings. The decoder must accept both a number
  and a numeric string for every nutriment.
- `status` of `0` in the product response means not found. Map it to a distinct
  error case so the UI can offer manual entry.
- Never crash on malformed JSON. A decoding failure is a handled error.
- Cache every resolved product locally on success, so the app degrades to a
  working offline catalogue.


Set `User-Agent: Benday/1.0 (iOS; +https://benday-matrix.pro)` on every request. Never reuse another app's string.
No required remote catalog. Network only if this product actually needs it.

---

## 11b. App Store readiness

The app must be submittable without further work.

- `PrivacyInfo.xcprivacy` in the target, declaring the UserDefaults access API
  reason `CA92.1` and the file timestamp reason `C617.1`, with
  `NSPrivacyTracking` false and no collected data types.
- `INFOPLIST_KEY_ITSAppUsesNonExemptEncryption = NO` in the pbxproj so TestFlight
  does not sit on Missing Compliance.
- `NSCameraUsageDescription` written specifically for this app. Generic strings
  get rejected.
- `LSApplicationCategoryType` of `public.app-category.healthcare-fitness`.
- Portrait only, iPhone and iPad (`TARGETED_DEVICE_FAMILY = "1,2"`).
- No account, no sign-in, no delete-account flow, no in-app purchase, no ads, no
  user-generated content, and therefore no report or block UI.
- App Tracking Transparency is never invoked.
- The camera is the only sensitive permission requested.
- Guideline 5.1.1 (Privacy): do not encourage or direct the user to grant camera
  access. A pre-permission screen may exist, but the proceed button must be
  **Continue** or **Next** — never "Allow camera", "Enable camera",
  "Grant camera", or a bare Allow/Enable that calls `requestAccess`. The
  system dialog is the only Allow. Denied/restricted offers Open Settings.
- The app must not present itself as a clinician or as medical advice.
- Guideline 4.2 (Design — Minimum Functionality): the binary must be a native
  product, not a web browsing experience. No WKWebView / SFSafariViewController
  / UIWebView as home, a tab, or the primary UX. A content catalog, article
  reader, or site wrapper that could be a website is a reject. Push
  notifications, Core Location, and sharing do not make that acceptable.
- Guideline 1.4.1 (Safety — Physical Harm): if the binary shows health or
  medical recommendations, body-based targets, dosages, "you should" guidance,
  or product health claims (food, drink, supplement, remedy), put citations
  in the app. Tappable links to the sources, easy to find: same screen as the
  claim, or a Sources row one tap from Settings. Name the source (Open Food
  Facts, USDA FoodData Central, WHO, NIH MedlinePlus, …) and link it. A
  "not medical advice" footer without sources is a reject. A personal log
  that never advises does not invent claims to cite.
- Nutrition catalog data is credited to the database this app actually uses
  (Open Food Facts unless the spec names another). Credit is a tappable link,
  not a dead "OpenFoodFacts" label.


### First minute on a clean install (Guideline 2.1)

A reviewer judges completeness (Guideline 2.1) in the first minute on a clean
install. The loop must finish there without knowing the app's rules. Long form:
`docs/REVIEW-LESSONS-2026-09-25.md`.

- The home verb writes a visible object on the first tap of a clean install:
  a row, a card, a mark on the dial. No second screen needed to see it.
- Never leave the home control disabled until an unexplained condition holds
  ("two links first", "long press first", "add a volume first"). Accept the
  first input with sane defaults and show the rule afterwards.
- The twist fires after a successful write, as a visible consequence (a highlight,
  a caption, a next step), never instead of the write.
- A refusal is allowed only after the first success, and it must name the next
  tap that works.
- Nothing in the first session waits for midnight, a second day, a second item or
  a streak. A screen that can only fill later shows its action, not a wait.
- Every empty state names one action, and that action completes on the spot.
- Next to home there is at least one more screen that works on a clean install.
- The subtitle and the first description line name an everyday action a stranger
  understands. Coined words may decorate labels; each primary button still says
  what it does.
- A failed network lookup falls back to local data or typed input with a message;
  the loop still finishes offline.


Ignore the food-log and Open Food Facts lines above when they conflict with this
family. Category for this app is `public.app-category.lifestyle`. Camera permission only if the
product actually captures.

Project settings that follow from the above:

```yaml
INFOPLIST_KEY_UIUserInterfaceStyle: Light
INFOPLIST_KEY_UISupportedInterfaceOrientations: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad: UIInterfaceOrientationPortrait
INFOPLIST_KEY_UIRequiresFullScreen: YES
INFOPLIST_KEY_ITSAppUsesNonExemptEncryption: NO
INFOPLIST_KEY_LSApplicationCategoryType: public.app-category.lifestyle
TARGETED_DEVICE_FAMILY: "1,2"
SWIFT_STRICT_CONCURRENCY: complete
```

---

## 12. Functional twist: Ink-then-lay (Dip arms today; one stroke commits on pen-up with LayMark; Peel clears same day; quiet streak counts consecutive Laid days)

Home is the ink-then-lay mechanic: the 365-cell matrix stays up, today's cell is magnified, and the twelve-ink tray stays docked under it. Dip arms today by putting Ink on the Bristle, and the persisted commit is pen-up, which writes one LayMark and one MoodEntry for that Int day key. A further sketch on a Laid day is refused until Peel, and Peel clears only today so the cell returns to Open. Quiet streak is the count of consecutive Laid days ending today or yesterday, a gap restarts that count, and Analytics shows the streak beside the year's ink mix. The home verb is lay the stroke, and the Simulator seed lays yesterday and leaves today Armed with the bristle already dipped, so the first gesture is drawing the stroke. A unit test locks one MoodEntry per day key, the streak rule, and the refusals for sketching a Laid cell and for dipping over a nonempty Armed path.

This is the app's marketed differentiator. It must be:

- visible on the home screen, not buried in settings;
- backed by real persisted data, not a cosmetic flourish;
- covered by at least one unit test;
- described in the README as the reason a user would pick this app.

---

## 13. AI-generated assets

Art style: **Comic halftone pop art · abstract**


Base prompt, reused and extended for every asset:

```
Abstract comic-plate pop art. Benday halftone dots, a printed screen, flat graphic shapes, and one brushstroke as the subject. Paper grain and a registration crop sit in the atmosphere. No letters, no words, no faces, and no photoreal scene.
```

All 12 images below are required. Generate each one, export
as PNG, and add it to `Assets.xcassets` as its own image set named exactly as
given. Every name carries the `bdy_` prefix.

### 13.1 App icon rules (strict)

The icon is rejected by App Store Connect if any of these are wrong:

- Exactly **1024 x 1024 px**.
- **No alpha channel.**
- sRGB colour profile, 8 bits per channel, PNG.
- **No text and no words** in the artwork.
- **No rounded corners and no built-in mask.**
- The subject stays inside the middle 80%.

### 13.2 Full asset list

| # | Image set | Size (px) | Alpha | Purpose |
| --- | --- | --- | --- | --- |
| 1 | `bdy_AppIcon` | 1024x1024 | **NO** | App Store icon. NO alpha channel, NO transparency, NO text, NO rounded corners, NO drop shadow outside the canvas. |
| 2 | `bdy_Splash` | 1290x2796 | fill | Launch background. The middle third must stay quiet so the wordmark reads on top. |
| 3 | `bdy_Onboarding1` | 1024x1536 | **required cutout** | Onboarding page 1 illustration: what the app is for. |
| 4 | `bdy_Onboarding2` | 1024x1536 | **required cutout** | Onboarding page 2 illustration: the main verb. |
| 5 | `bdy_Onboarding3` | 1024x1536 | **required cutout** | Onboarding page 3 illustration: why they stay. |
| 6 | `bdy_EmptyHome` | 1024x1024 | **required cutout** | Empty state: the home screen has nothing yet. Calm and inviting, never sad. |
| 7 | `bdy_EmptyList` | 1024x1024 | **required cutout** | Empty state: a secondary list has no rows. |
| 8 | `bdy_CardBackdrop` | 1200x800 | fill | Backdrop art for a primary card. Low contrast so text stays readable. |
| 9 | `bdy_ControlFace` | 512x512 | **required cutout** | Custom control artwork used for the primary interactive element. |
| 10 | `bdy_TwistHero` | 1024x1024 | **required cutout** | Hero art for the 'Ink-then-lay (Dip arms today; one stroke commits on pen-up with LayMark; Peel clears same day; quiet streak counts consecutive Laid days)' feature screen. |
| 11 | `bdy_SuccessMark` | 512x512 | **required cutout** | Shown briefly when the primary action succeeds. |
| 12 | `bdy_HeaderDecor` | 1200x600 | **required cutout** | Decorative header accent on the main screen. |

### Prompt per asset

**`bdy_AppIcon`** — 1024x1024

```
Abstract comic-plate emblem of one brushstroke crossing a field of benday dots, filling the square edge to edge. No text, no letters, no rounded mask, and no alpha.
```

**`bdy_Splash`** — 1290x2796

```
Vertical comic plate with benday atmosphere and a wide quiet center band left clear for a wordmark. No letters in the artwork.
```

**`bdy_Onboarding1`** — 1024x1536

```
A single comic printing plate with one empty cell lifted forward, isolated and solid in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_Onboarding2`** — 1024x1536

```
A dipped brush laying one continuous stroke onto a plate, mid-gesture, isolated and solid in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_Onboarding3`** — 1024x1536

```
A comic plate carrying many small distinct strokes, one per cell, isolated and solid in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_EmptyHome`** — 1024x1024

```
A dry brush resting on a closed gesso ground, solid and waiting, isolated in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_EmptyList`** — 1024x1024

```
A closed tray of twelve dry ink wells, a solid object isolated in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_CardBackdrop`** — 1200x800

```
Abstract benday field meant to sit behind a card, low contrast, full bleed, with no text and no subject competing with type.
```

**`bdy_ControlFace`** — 512x512

```
The round lid of one ink well, a solid physical control face, isolated in the center.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_TwistHero`** — 1024x1024

```
An emblem of one brushstroke ending as a laid mark on a plate, isolated and solid in the center, with no text.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_SuccessMark`** — 512x512

```
A solid filled seal, thick and opaque, occupying the middle of the canvas. A disc of material, not a thin ring and not a hollow outline.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```

**`bdy_HeaderDecor`** — 1200x600

```
A wide ornamental band of benday dots and a registration crop, with no text and no letters.

HARD CUTOUT: isolated SOLID opaque subject on a fully transparent background, occupying the center of the canvas. Real PNG alpha channel. All four corners fully transparent. No square plate, no painted backdrop, no opaque box, no drop shadow that fills the canvas. Not glass, not a hollow frame, not a wire outline, not an empty vitrine — rembg punches through those and the cutout is empty. GenerateImage writes opaque RGB — after copy, convert the PNG to RGBA in place; do not generate it again for alpha.
```


### 13.3 Asset rules

- Cut-outs (everything except AppIcon, Splash, CardBackdrop): isolated subject,
  real PNG alpha, all four corners transparent. No square plate.
- Assets must be semantically different from each other.
- Record the exact prompt used for every asset in the README.
- SF Symbols are permitted only for close, chevron, share and similar system
  affordances.

Scanner frames, reticles, and seamless tiles are drawn in SwiftUI via `Path` or `Shape`. GenerateImage is not used for those. Every other in-app graphic (except AppIcon, Splash, CardBackdrop) is a **cutout**: isolated SOLID opaque subject in the center, real PNG alpha, all four corners transparent. An opaque square plate inside a circle or pentagon is a fail. A hollow glass box or wire frame with a transparent center is a fail.

---

## 14. Demo data

Seed a small local demo dataset for this family's entities so Simulator
screenshots are not empty. The same seed must mark onboarding complete and
fill the primary surface — otherwise `-ReviewScreen` never fires. Never seed
on a physical device. Guard with `#if targetEnvironment(simulator)` and
`bdy.demo.v1`.

Seed the happy path: the home primary verb is enabled. The blocked / gated /
error state is a unit-test fixture, not Simulator home. Home chrome names the
job and the next tap in words a stranger knows. Axis values (`ui`, `naming`,
`architecture`) never become user-visible titles. A card that looks tappable
is a `Button`. A readout does not use button chrome.

---

## 16. Anti-patterns

The following will fail review:

- `try!`, `as!`, or force-unwrapping anything derived from the network, the
  database or a file.
- `fatalError` anywhere reachable at runtime. It is acceptable only for a
  programmer error in an initialiser that cannot fail in practice, and needs a
  comment.
- Swallowing an error with an empty `catch`.
- `print` used as production logging.
- A hard-coded hex colour outside the single colour accessor.
- A hard-coded font name outside the single typography accessor.
- An SF Symbol used as the app's brand iconography — the app icon, the
  empty-state hero, or onboarding art. Those come from section 13. SF Symbols
  are the right choice for every functional control (add, filter, sort,
  close, share, delete) — leaving those as bare text instead of a symbol is
  also a defect.
- Storing a value that can be computed (day totals, remaining budget, macro
  percentages).
- Blocking the main thread on disk or network work.
- `UIScreen.main` for sizing. Use the geometry the layout system gives you.
- Index positions used as list identity. Identity is a stable identifier.
- A view that reaches into the persistence layer directly, bypassing the
  architecture's designated seam.
- Business logic inside a `View` body or a `UIViewController` method, when the
  assigned architecture places it elsewhere.
- Copying a source file from another app in this batch.
- A `TabView` with exactly three tabs. That is the factory stamp — two or
  four-to-five destinations, or a different chrome. ReviewScreen keys are
  not tabs.


---

## 17. Tests

Add a unit test target `BendayTests` covering at minimum:

1. The core domain invariant of this family (the thing that would be wrong if
   the calculator, decay, crate, or log lied).
2. Empty, populated and invalid input paths for the primary verb.
3. The section 12 twist logic.
4. One architecture-specific test proving the pattern holds.
5. A persistence round-trip: write, relaunch-equivalent reload, verify.
6. `Benday/ReviewLaunch.swift` (scaffold, keep it) parses `ProcessInfo.processInfo.arguments`.
   Read `ReviewLaunch.screen` once after onboarding:
   `-ReviewScreen today|log|goals` switches the running app's live navigation. Extra cover slugs open those screens.
   Cover that parser with a unit test. Do not host a `View` in the test.

---

## 18. README.md

Write `README.md` at the app folder root covering:

1. What the app does and who it is for.
2. The architecture used and **why** it suits this product.
3. The unique feature added and how it works.
4. The AI art style and the exact prompt used for every asset.
5. How this app differs from others in the batch.
6. Build instructions.

---

## 19. Definition of done

**Build**
- [ ] `xcodegen generate` succeeds.
- [ ] `xcodebuild -scheme Benday -destination 'generic/platform=iOS' build` succeeds.
- [ ] Zero new compiler warnings.
- [ ] Strict concurrency `complete` compiles clean.
- [ ] Test target passes.

**Function**
- [ ] Onboarding to first successful primary action works on a clean install.
- [ ] Every screen in section 3.6 exists and handles empty / filled / error.
- [ ] Reset and contact link live in Settings.
- [ ] Force-quitting immediately after a write loses nothing.
- [ ] Seeded home names the job and next tap; primary verb enabled.
- [ ] App reads `-ReviewScreen today|log|goals` after onboarding.

**Uniqueness**
- [ ] Architecture matches **Bristle-lay fold (Open | Armed | Laid); YearMatrix holds Cells keyed by YYYYMMDD; Dip writes Ink on Bristle and folds today's Open Cell to Armed; Sketch appends one PKDrawing while Armed; pen-up writes LayMark and MoodEntry and folds Armed to Laid; Peel on today removes MoodEntry and folds Laid to Open; Sketch on Laid is refused; Dip while Armed with a nonempty path is refused until Peel; empty matrix renders Gesso; views observe one YearMatrix** with no leakage across layers.
- [ ] UI approach matches **Programmatic UIKit · canvas-first**.
- [ ] Custom rendering, if any, is confined to one hero surface (section 7.5).
- [ ] Navigation matches **Matrix-locked chrome (the 365 matrix never leaves; Analytics and Settings arrive as sheets; the ink tray stays docked under today's magnified cell)**.
- [ ] Screen composition follows section 3.6.
- [ ] Typography uses **Verdana** and nothing else.
- [ ] Palette matches section 7.1 exactly.
- [ ] Home rhythm and motion match section 7.6. No second look.

**Quality**
- [ ] Section 8 UI/UX bar satisfied end to end.
- [ ] Contact link present.
- [ ] `PrivacyInfo.xcprivacy` present and correct.
- [ ] README complete.

---

## 20. Build commands

```bash
cd Benday
xcodegen generate
xcodebuild build-for-testing -scheme Benday -destination 'generic/platform=iOS Simulator' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.benday.matrix/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES
xcodebuild -scheme Benday -destination 'generic/platform=iOS' -jobs 4 CODE_SIGNING_ALLOWED=NO CODE_SIGNING_REQUIRED=NO -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.benday.matrix/DerivedData' SWIFT_TREAT_WARNINGS_AS_ERRORS=YES build
xcrun simctl list devices available
xcodebuild test-without-building -scheme Benday -destination 'platform=iOS Simulator,id=<UDID>' -jobs 4 -derivedDataPath '/Users/belzephyrus/Documents/gambling-factory/.artifacts/genesis/com.benday.matrix/DerivedData'
```

Signing is off only on that command line. Do not put CODE_SIGNING_ALLOWED, CODE_SIGNING_REQUIRED, CODE_SIGN_IDENTITY, DEVELOPMENT_TEAM, SWIFT_TREAT_WARNINGS_AS_ERRORS or -derivedDataPath in project.yml — they are command-line only. CI signs the archive. Leave CODE_SIGN_STYLE: Automatic as the scaffold set it. The exact simulator does not matter — use any available UDID from the list.
