<!-- gf-brief source=4256f39ae35f2fe2abd01830d9eebfdc2eddba1fbb086d623c1749719a5dd8fd written=2026-10-09T13:29:01+03:00 -->
# Benday

## What it is
Benday is a private year plate for one mark a day. You dip an ink, draw one stroke for today, and the year fills so you can see how the days felt. It is for anyone who wants a quiet daily mark on this device, not a feed or an account.

## Launch and onboarding
A system launch screen appears first. Appearance is light only.

A cold launch may then briefly show a spinner and the line **“Opening the plate.”**

If onboarding is not finished, three pages follow. A page control of three dots is visible and is not tappable. **“Skip”** is on every page and ends onboarding at once.

1. Headline **“One stroke for each day.”** Body **“The year matrix keeps a single mark so you can see how the days felt.”** Button **“Next”**.
2. Headline **“Dip, then lay the stroke.”** Body **“Choose an ink from the tray. The stroke commits when you lift.”** Button **“Next”**.
3. Headline **“Peel only today.”** Body **“A wrong lay clears the same day. Quiet streak counts the laid days you kept.”** Button **“Continue”**.

**“Skip”** or **“Continue”** opens the year with the default tray. While that finishes, the main button shows a spinner and **“Skip”** is disabled.

If onboarding is already finished, the year opens instead.

## Screens

### Year
Title **“Lay today's stroke”**. There are no tabs. This screen stays under every sheet.

The current calendar year is a seven-column grid of days. Today has a highlighted ring. A day you tap gets a second ring. A day that is prepared but not yet kept has a light tint. A kept day shows that day’s stroke as a dotted print in the ink you used. You can pinch the year between one and three times size. The grid scrolls so today is in view.

A number sits next to the caption **“Quiet streak”**. It is the run of consecutive kept days ending today, or yesterday if today is not yet kept. A gap starts the count over.

Two icon controls in the header:
- **“Analytics”** opens the Analytics sheet.
- **“Settings”** opens the Settings sheet.

Under the year is **“Today's cell”**, a square you draw in. It only accepts a stroke after you dip, and only for today. The stroke commits when you lift. If more than one stroke is drawn before you lift, only the last stroke is kept. A short tap is felt when the lay succeeds.

Caption under the cell, depending on today:
- Before a dip: **“Dip an ink from the tray, then draw in today's cell.”**
- After a dip, before a kept stroke: **“Draw in today's cell. The stroke commits when you lift.”**
- After a kept stroke: **“Today's stroke is kept. Peel today if it went wrong.”**

If you have tapped a day, that line is prefixed with the day name VoiceOver also uses, in the form **“{Month} {day}, {open|armed|laid}.”** Month names follow the device calendar. Example: **“October 8, open. Dip an ink from the tray, then draw in today's cell.”**

The ink tray under the cell holds twelve named wells. Tap a name to dip that ink. You may dip a different ink before you start the stroke. The dipped well shows a border. VoiceOver on the dipped well is **“Dipped”**. Default names:

- **“Chalk”**
- **“Clay”**
- **“Ember”**
- **“Moss”**
- **“Tide”**
- **“Dusk”**
- **“Linen”**
- **“Copper”**
- **“Sage”**
- **“Plum”**
- **“Sand”**
- **“Soot”**

**“Peel today”** clears only today’s kept stroke so you can dip and draw again. It is disabled until today is kept. Earlier days stay as they are.

Tapping a day in the year does not lay that day. It scrolls to it and updates the caption. Only today can take a stroke.

Hints that appear under the tray when a move is refused:
- **“Today is laid. Peel today, then dip and draw again.”**
- **“Dip an ink in the tray, then lay the stroke.”**
- **“Finish this stroke before dipping another ink.”**
- **“Lay a stroke before you lift.”**
- **“Dip an ink so today can take a stroke.”**
- **“Peel is ready after today is laid.”**
- **“That ink is not in the tray.”**

Banners that can appear above the year:
- **“A backup plate was opened.”**
- **“The plate could not be read.”**

Until any day in the year has been kept and today is still waiting for a dip, a full-screen empty plate covers the year:
- **“The year is empty.”**
- **“The first stroke is yours.”**
- **“Dip”** dips the first tray ink (**“Chalk”**) and reveals the year.

Hints on **“Today's cell”**:
- After a dip: **“Draw one stroke. It commits when you lift.”**
- After today is kept: **“Today is laid. Peel to draw again.”**
- Before a dip: **“Dip an ink before drawing.”**

### Analytics
Opened from **“Analytics”** as a sheet over the year. There is no separate title bar. Swipe down to close.

When at least one day is kept, two sections:
- **“Quiet streak”** — one row **“Consecutive laid days”** with the streak number.
- **“Ink mix”** — one row per tray ink, name on the left, how many kept days used that ink on the right. All twelve names appear, including zeros.

When no day has been kept:
- **“No ink has been laid.”**
- **“Dip an ink and lay today's stroke.”**
- **“Lay today's stroke”** closes the sheet and returns to the year.

If the plate could not be opened:
- **“The plate could not be read.”**
- The same notice line as on the year, when one is set.
- **“Try again”** reloads the plate.

### Settings
Opened from **“Settings”** as a sheet over the year. Swipe down to close.

Title **“Tray ink names”**.
Line **“These names sit on the ink tray under the year. Tap one to rename it.”**

Each ink is a row with its colour, its current name, and **“Rename this ink”**. The control name is **“Rename tray ink {name}”**.

Rename alert:
- Title **“Rename {name}”**
- **“This word is the name on that tray ink.”**
- A text field filled with the current name
- **“Cancel”**
- **“Save name”**

A blank or spaces-only name is ignored; the old name stays. A name is kept up to 32 characters; extra characters are dropped.

Then three buttons:
- **“Export plate”** opens the system share sheet with a copy of the plate. If export fails: **“The plate could not be exported. Try again.”** and **“Try again”** runs export again.
- **“Reset plate”** shows **“Reset the Benday plate?”** and **“This wipe removes every laid day on the plate.”** with **“Cancel”** and **“Reset plate”**. Confirming wipes the year, dismisses the sheet, and returns you to onboarding.
- **“Contact Benday”** opens the support page outside the app.

If the tray has no inks:
- **“The tray has no inks.”**
- **“Return to the year and dip a well.”**
- **“Back to the year”** closes the sheet.

If the plate could not be opened and onboarding is not finished:
- The notice line
- **“Try again”** reloads the plate

## Features
- One stroke for each day on a year matrix
- Dip an ink from the tray, then lay the stroke in today’s cell
- The stroke commits when you lift
- Peel only today
- Quiet streak of laid days you kept
- Analytics: consecutive laid days and ink mix
- Twelve tray inks you can rename
- Export plate
- Reset plate
- Contact Benday
- Pinch to look closer at the year
- Work stays on this device across launches

## Behaviours that can look like bugs
- **“Peel today”** stays dim until today’s stroke is kept. Lay today, then peel.
- **“Today's cell”** does not take a finger until you dip. Dip a tray ink first, or tap **“Dip”** on the empty year.
- Tray inks go dim and ignore taps once a stroke is started and not yet lifted. Lift to commit, or you will see **“Finish this stroke before dipping another ink.”**
- After today is kept, drawing is ignored until you **“Peel today”**. The caption says **“Today's stroke is kept. Peel today if it went wrong.”**
- A second stroke before you lift replaces the first. Only the last stroke is kept.
- Tapping another day only focuses it. You cannot lay yesterday or tomorrow. A day you dipped but did not keep stays tinted and cannot be finished after the calendar day has passed.
- The grid shows only the current calendar year. Earlier years are not a separate screen.
- If you peel the only kept day, **“The year is empty.”** covers the year again. Tap **“Dip”**.
- **“Save name”** with an empty field does nothing. Type at least one character. A name longer than 32 characters is shortened without a warning.
- **“Skip”** is disabled while onboarding is finishing. Wait for the year.
- Analytics shows **“No ink has been laid.”** until one day is kept. Use **“Lay today's stroke”** to go back and dip and draw.
- Quiet streak can stay on yesterday’s run until you lay today. A missed day starts the count at zero.
- After **“Reset plate”**, onboarding runs again. That is the wipe.
- **“A backup plate was opened.”** or **“The plate could not be read.”** can appear after a bad open. Use **“Try again”** where it is shown, or continue on the restored plate.

## Starter content and resume
The tray always starts with **“Chalk”**, **“Clay”**, **“Ember”**, **“Moss”**, **“Tide”**, **“Dusk”**, **“Linen”**, **“Copper”**, **“Sage”**, **“Plum”**, **“Sand”**, and **“Soot”**. The year starts with no laid days.

Unfinished work resumes. Laid days, today’s dipped ink, a stroke started but not lifted, renamed inks, and finished onboarding come back on the next launch. **“Reset plate”** clears the year and onboarding.

## Permissions
None.

## Absent
Login or accounts, in-app purchase, ads, tracking analytics (the **“Analytics”** control is a local count of your plate only), public user-generated content, an account deletion flow, and an App Tracking Transparency prompt are absent. **“Reset plate”** is the local wipe.

## Data and support
Data stays on this device unless you tap **“Export plate”** and share the copy yourself. **“Contact Benday”** on Settings opens the support page.

## Scanning and health
None. The app does not scan barcodes or QR codes. It does not show health, medical, or product-health information.

## Platform
Copy is English. The year, first weekday, month names, and numbers follow the device calendar and region. Portrait only, on iPhone and iPad. Light appearance. Minimum iOS 17.0.

## Category
Lifestyle
