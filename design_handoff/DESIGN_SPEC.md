# Najah.ai — Design specification (v1)

Companion to `design/screens/*.dc.html`: each screen below names its reference file. When this spec and a file disagree, this spec wins.

---

## 1. Design tokens

All tokens exist in code in `flutter/lib/core/theme/`.

### Colors

| Token | Hex | Use |
|---|---|---|
| `teal` | `#0E6B5C` | Primary: buttons, links, progress, active student tab |
| `tealDark` | `#0A5247` | Text on teal tints, pressed state |
| `tealTint` | `#E3F0ED` | Success feedback, selected tints, avatar background |
| `ink` | `#10231F` | All main text; parent space accent, parent buttons, dark cards |
| `gold` | `#F5B83D` | XP, streaks, levels, rewards. **Text on gold is always ink, never white** |
| `goldTint` | `#FDF1D8` | Streak chip, trial badge, soft warnings |
| `ivory` | `#F7F5EF` | Formula boxes, info callouts, input prefixes |
| `background` | `#FCFBF8` | Screen background |
| `surface` | `#FFFFFF` | Cards, inputs, bottom bars |
| `line` | `#ECE8DF` | Card borders, input borders |
| `track` | `#F1EEE6` | Progress tracks, dividers, list separators |
| `muted` | `#5B6663` | Secondary text (5.9:1 on background, passes AA) |
| `error` | `#B3261E` | Wrong answers, errors |
| `errorTint` | `#FBEAE8` | Error feedback background |
| `mint` | `#9FD3C7` | Links and accents on ink/dark surfaces |

### Typography

- **Families:** Inter for French/Latin and Cairo for Arabic. Both are bundled in `assets/fonts/` for offline use.
- **Scale:** 11 · 12 · 14 · 16 · 18 · 20 · 24 · 32.
- **Weights:** 800 for hero numbers and titles, 700 for headings and buttons, 600 for labels, 400 for reading text.
- **Line height:** 1.4 for Latin, 1.5 for Arabic.
- **Letter-spacing:** −0.02em on 32 px titles only, and never on Arabic.

| Style | Size / weight | Use |
|---|---|---|
| `display` | 32 / 800 | Celebration and trial titles |
| `title` | 24 / 800 | Screen titles, stat values |
| `titleSmall` | 20 / 800 | Lesson titles, greeting |
| `heading` | 18 / 700 | Section headings |
| `subheading` | 16 / 700 | Card titles, buttons |
| `body` | 16 / 400 | Lesson reading text |
| `bodySmall` | 14 / 400 | Descriptions |
| `label` | 12 / 600 | Captions, stat labels |
| `tab` | 11 / 600, 700 when active | Tab bar (12 in Arabic) |

### Spacing, radius, elevation

- **Spacing:** 4 · 8 · 12 · 16 · 24 · 32.
  - Screen side padding is 20 (24 on centered/hero screens).
  - The gap between sections is 20–24.
  - The gap inside cards is 12.
- **Radius:**
  - 8 for small elements (badges, formula boxes, thumbnails).
  - 12 for cards, buttons and inputs.
  - 20 for dialogs and bottom sheets (top corners only for sheets).
  - Pill (999) for chips.
- **Shadows:**
  - Level 1: `0 1 2 rgba(16,35,31,.06)`.
  - Level 2: level 1 plus `0 6 20 rgba(16,35,31,.05)`. Use it for hero and highlighted cards.
  - Sheet: `0 12 40 rgba(16,35,31,.14)`.
  - Plain cards use a 1 px `line` border instead of a shadow.
- **Touch targets:** at least 44×44.
  - Primary buttons are 52 high.
  - Secondary in-card buttons are 44–48 high.
  - PIN keys are 56 high.
- **Icons:** 24 px line icons with a 1.8 stroke, rounded caps and joins. Use 20 in lists and 18 in buttons.
  - The flame (streak), sparkle (AI) and play icons are filled.
  - Use a single icon set, such as Lucide or Phosphor "regular".

---

## 2. Components

Each component matches a board on the canvas's design system page.

- **NajahButton:** a full-width 52 px button, text 16/700, radius 12, with an optional leading icon (18).
  - **Primary:** teal background, white text.
  - **Secondary:** white background, 1.5 px teal border, teal text.
  - **Ink:** used in the parent space and for "Continuer" after feedback.
  - **Gold:** rewards and subscribe actions, with ink text.
  - **Quiet:** white background, 1.5 px `line` border, ink text.
  - **Disabled:** `#E4E7E5` background with muted text.
  - **Loading:** a spinner replaces the label, and the button keeps its width.
- **NajahTextField:** label 14/600 above the field.
  - The field is 52 high with a 1.5 px `line` border, a teal border on focus, and a red border on error with a red 12/600 hint below.
  - A success hint is teal, e.g. "✓ Disponible".
  - A phone field has a fixed `+222` prefix on ivory and is always LTR.
- **PinBoxes:** 4 boxes (PIN) or 6 (WhatsApp code), each 56 high, spaced 12 (10 when there are 6).
  - A filled PIN box shows a 14 px ink dot; a code box shows its digit at 22/800.
  - The active box has a teal border. Boxes are always LTR.
- **PinPad:** a 3×4 grid with a gap of 8. Keys are 56 high on a white background, digits 24/600.
  - The bottom-left cell is empty and the bottom-right is backspace.
  - Haptic tick on each press. Never use the system keyboard.
- **SubjectCard:** white card with a 1 px `line` border, padding 14.
  - It holds a 52 px mastery ring (stroke 5, `track` background), with the percentage 12/800 centered.
  - Next to the ring: the subject name 14/700 and the lesson count 12 muted.
  - Ring colors alternate teal and ink across the grid.
- **StatTile:** value 24/800 (teal for the main metric), label 12/600 muted, padding 16.
  - The "active days" variant shows 7 mini bars (teal for active days, `#E3E0D7` for inactive).
- **XpBar:** gold fill on a `track` background, 8 high. **ProgressBar:** the same with a teal fill; use ink for alternate subjects.
- **JourneyBar:** pills connected by 3 px lines.
  - Done step: teal tint with a check icon.
  - Active step: solid teal.
  - Upcoming step: white with a `line` border.
- **NajahChip:** height 28–36, text 12/700.
  - Neutral: white with a `line` border.
  - Selected: ink background, white text.
  - Status variants: teal "Actif / Abonnée", gold "Essai / En vérification / À venir", red "Expiré / Refusé".
- **StreakBadge:** a `goldTint` pill with the gold flame (18) and the number 14/800.
- **LevelBadge:** a 40 px gold square, radius 12, with an ink number.
- **FocusModeBar:** a full-width ink bar with a gold target icon and "Mode concentration jusqu'à HH:MM". A "Déverrouiller" pill button sits at the end.
- **OfflineBanner:** an ink bar with a gold wifi-off icon and the message "Hors ligne · tes téléchargements restent disponibles", plus a "Voir" link in mint.
- **Snackbar:** ink background, radius 12, text 14 in white, action in mint 700. It shows for 4 s.
- **Dialog:** radius 20, padding 24, an icon badge at the top, a title of 18–20/800, and the actions stacked.
- **BottomSheet:** radius 20 on the top corners, with a 40×4 handle and a scrim of `rgba(16,35,31,.45)`.
- **Skeleton:** blocks in `#EFECE4` and `#F4F2EC` with the same radius as the real content, shimmering on a 1.2 s loop.
- **EmptyState / ErrorState:** a 64 px round icon badge (teal tint for empty, red tint for error), a title 16/700, text 14 muted, and an optional secondary button.
- **Protected screen:** a full black screen with a lock badge, "Enregistrement d'écran non autorisé" (16/700 white) and the explanation in `#B7C1BE`.
- **Tab bars:** 84 high including the safe area, white with a top `line` border.
  - Active tab: teal for students, ink for parents.
  - Student tabs: Accueil / Matières / Examens / Profil.
  - Parent tabs: Accueil / Abonnement / Profil.

---

## 3. Routes and screens

| # | Route | Screen | Reference file | Role |
|---|---|---|---|---|
| 1 | `/splash` | Splash | `Main.dc.html` | all |
| 2 | `/welcome` | Welcome, role and language | `Welcome.dc.html` | all |
| 3 | `/login/student` | Student login | `StudentLogin.dc.html` | student |
| 4 | `/login/parent` | Parent login | `ParentLogin.dc.html` | parent |
| 5 | `/verify-code` | WhatsApp code | `VerifyCode.dc.html` | both |
| 6 | `/register` | Registration | `Register.dc.html` | both |
| 7 | `/register/trial` | Free-trial offer | `TrialOffer.dc.html` | both |
| 8 | `/claim-invite` | Activate invite | `ClaimInvite.dc.html` | student |
| 9 | `/s/home` | Student home | `StudentHome.dc.html`, `StudentHomeAR.dc.html` | student |
| 10 | `/s/subjects/:id` | Subject: chapters and lessons | `SubjectDetail.dc.html` | student |
| 11 | `/s/lessons/:id/video` | Lesson: video step | `LessonVideo.dc.html`, `LessonVideoAR.dc.html` | student |
| 12 | `/s/lessons/:id/concept/:n` | Lesson: concept and mini-quiz | `LessonConcept.dc.html` | student |
| 13 | `/s/lessons/:id/example` | Worked example | `WorkedExample.dc.html` | student |
| 14 | `/s/lessons/:id/summary` | Revision sheet | `RevisionSheet.dc.html` | student |
| 15 | `/s/qcm/:setId` | QCM session | `QcmSession.dc.html`, `QcmAR.dc.html` | student |
| 16 | `/s/qcm/:setId/result` | Result and streak | `QcmResult.dc.html` | student |
| 17 | `/s/practice/:id` | Open practice | `OpenPractice.dc.html` | student |
| 18 | `/s/helper` | Homework Helper | `HomeworkHelper.dc.html` | student |
| 19 | `/s/exams` | Exams list | `ExamsList.dc.html` | student |
| 20 | `/s/exams/:id` | Exam intro | `ExamIntro.dc.html` | student |
| 21 | `/s/exams/:id/session` | Timed exam | `ExamSession.dc.html` | student |
| 22 | `/s/exams/:id/result` | Exam results | `ExamResults.dc.html` | student |
| 23 | `/s/downloads` | My downloads | `Downloads.dc.html` | student |
| 24 | `/s/profile` | Profile | `Profile.dc.html` | student |
| 25 | `/s/locked` | Subscription ended | `SubscriptionLocked.dc.html` | student |
| 26 | (overlay) | Focus: unlock sheet | `FocusMode.dc.html` | student |
| 27 | (overlay) | Focus: blocked action | `FocusBlocked.dc.html` | student |
| 28 | `/p/home` | Parent home | `ParentHome.dc.html` | parent |
| 29 | `/p/children/new` | Add child | `AddChild.dc.html` | parent |
| 30 | `/p/children/new/done` | Child created | `AddChildSuccess.dc.html` | parent |
| 31 | `/p/children/:id` | Child progress | `ChildProgress.dc.html`, `ChildProgressAR.dc.html` | parent |
| 32 | `/p/children/:id/focus` | Focus-mode settings | `FocusSettings.dc.html` | parent |
| 33 | `/p/subscription` | Plans and children | `Subscription.dc.html`, `SubscriptionAR.dc.html` | parent |
| 34 | `/p/subscription/pay` | Bankily payment | `BankilyPayment.dc.html` | parent |
| 35 | `/p/subscription/status` | Subscription states | `SubscriptionStatus.dc.html` | parent |
| — | — | States reference | `HomeStates.dc.html` | — |
| — | — | Design system | `DesignSystem.dc.html` | — |

Screens without an AR file use the same layout mirrored. There are no separate Android layouts: on Android, use the same screens with the system back gesture and Material ripples.

---

## 4. Screen notes

The copy is in the HTML files and in `app_fr.arb` / `app_ar.arb`. The notes below cover behavior that the static files can't show.

### Launch & onboarding
- **Splash:** white background.
  - The icon appears first, then its gold dot hops twice (0–400 ms).
  - The icon slides toward the start edge (400–800 ms).
  - The wordmark "najah.ai" and "نجاح" unroll from the start edge (800–1200 ms).
  - Then the splash fades to Welcome, or straight to Home if a session exists.
  - Build the animation with the logo SVG parts; the native splash shows the static icon only.
- **Welcome:** the FR/عربي switch changes the locale immediately and is remembered.
  - Two role cards: student is highlighted with a teal border, parent is neutral.
  - "Créer un compte" opens Register.
- **Student login:** username, then a 4-digit PIN entered with PinPad; the button is enabled once 4 digits are in.
  - After 5 wrong PINs, lock for 5 minutes and suggest "Code oublié ? Demande à ton parent".
  - A "Première fois ? Activer mon compte" link opens Claim invite.
- **Parent login:** phone (+222) and PIN. On a new device, send a WhatsApp code and go to Verify code.
- **Verify code:** 6 boxes that auto-advance, and auto-submit on the 6th digit.
  - Pasting a full code fills all boxes.
  - The resend timer is 60 s.
  - "Modifier le numéro" goes back.
- **Register:** a role segmented control.
  - **Student:** full name, cycle (Primaire / Collège / Lycée), then grade chips (P1–P6, C1–C4, L1–L3), WhatsApp number, username with a live availability check, 4-digit PIN, and a terms checkbox. Then the code step, then Trial offer.
  - **Parent:** name, phone, PIN and terms. After the code step, the parent is taken to Add child.
- **Trial offer:** 7 days of full access for the grade, with the price taken from config.
- **Claim invite:** code format `NJH-XXXX`. When the code is valid, show the child preview card, then confirm the PIN, then go to Home.

### Student space
- **Home:**
  - Header: avatar, "Bonjour {prénom}", grade · cycle, StreakBadge and notifications.
  - Level card with XpBar and "Encore {n} XP pour le niveau {n+1}".
  - "Ma semaine": 4 StatTiles (correct %, exercises, active days x/7, study time).
  - "Mes matières": a 2-column SubjectCard grid.
  - The next weekly exam card, then the Homework Helper card (teal).
  - States: skeleton while loading, OfflineBanner when offline (cached data still shown), and an ErrorState in the subjects section if it fails.
- **Subject detail:**
  - A header ring (80 px), and filter chips (Toutes / À revoir / Hors ligne).
  - Chapter cards with progress; the current chapter is expanded to show its lessons.
  - Lesson status icons: filled teal check = mastered, ink ring with dot = viewed, grey ring = not started.
  - A download icon marks offline lessons. There are **no locks**: every lesson is open.
- **Lesson flow:** Video → Concept 1..n → Worked example → Revision sheet → Exercises (QCM). The JourneyBar shows where the student is.
  - **Video:** a 16:9 player at full width that adapts to portrait videos (max height 60% of the screen, letterboxed on ink).
    - Controls: play, seek, time and fullscreen. Landscape rotation goes fullscreen.
    - Also: a download button with its size, a Wi-Fi hint, a playlist with the current item highlighted, and Previous/Continue.
  - **Concept:** a short explanation, a formula box, a "Dans la vraie vie" example card (with a diagram if any), and a mini-quiz.
    - The Next button stays disabled until the quiz is answered correctly.
    - A wrong answer shows a hint and allows a retry.
  - **Worked example:** the statement, numbered steps (ink circles), and a "Erreur fréquente" callout on goldTint.
  - **Revision sheet:** formulas, definitions and key facts, available offline.
- **QCM:**
  - One question per screen, with a top progress bar and n/total.
  - Selecting an option shows a teal border; "Vérifier" checks the answer.
  - **Right:** the option turns teal-tint with a check, and a feedback card shows "+10 XP" plus the explanation.
  - **Wrong:** the chosen option turns red, the right one turns teal, and the feedback card is red-tint.
  - Then "Continuer" (ink). Closing mid-session asks for confirmation in a dialog.
- **Result and streak:**
  - The flame celebration, then "{n} jours de suite", then the week strip with today outlined in ink.
  - Below: score, duration, XP gained, and the level bar.
  - Actions: "Revoir mes erreurs" and "Retour à l'accueil".
  - Show the streak celebration only when the streak increments today; otherwise show the score card alone.
- **Open practice:** a free-text answer box (LTR for math), sent to the AI.
  - The AI card has a verdict chip (Juste / Presque / À revoir), the explanation, and the correct answer.
  - Actions: "Exercice similaire", "Voir la méthode en vidéo", and "Corriger ma réponse".
- **Homework Helper:**
  - The camera opens first. After capture, show the photo preview, the detected subject and topic chips, and a chat.
  - The AI **guides step by step with questions; it never gives the final answer** unless the student has solved it.
  - Input bar at the bottom, with a retake-photo action in the header.
- **Exams:**
  - **List:** a next-exam ink hero card, filter chips, "Cette semaine" and "Résultats récents".
  - **Intro:** duration, question count, max XP and rules.
  - **Session:**
    - Countdown chip that turns goldTint under 5 min and red under 1 min, and a question navigator.
    - No feedback during the exam.
    - Answers are saved locally and synced. When time runs out, the exam is submitted automatically.
  - **Results:** score ring, XP, scores per chapter, and a list of answers.
- **Downloads:**
  - Storage bar and a Wi-Fi-only switch.
  - List by subject with size and delete.
  - Expired items are dimmed with a lock, and a goldTint card offers "Se reconnecter".
  - Downloaded files are encrypted and playable only in the app.
- **Profile:**
  - Header: identity card and subscription card.
  - Settings: language, downloads, and parental control (asks for the parent PIN).
  - Help: FAQ, WhatsApp support, rate, share, and about.
  - Account: log out and delete account. Delete needs confirmation and the parent PIN.
- **Subscription locked:** shown when the trial or plan has ended.
  - Progress is kept.
  - Actions: "Prévenir mon parent sur WhatsApp" (deep link with a prefilled message), "Déjà payé ? Actualiser", and log out.

### Focus mode (student phone)
- While a window is active, FocusModeBar sits at the top of every student screen.
- "Déverrouiller" opens the PinPad sheet. The correct parent PIN ends focus for the current window, and the event is logged.
- Logout, account deletion and the language change are blocked with the FocusBlocked dialog.
- On iPhone, the sheet shows the Guided Access hint.

### Parent space
- **Home:** greeting, a weekly summary (ink card), and children cards.
  - Each card shows the avatar, grade · level, a status chip, streak, weekly time, and a 7-day activity chart.
  - A trial child gets a gold "S'abonner pour {prénom}" button.
  - Last comes the dashed "Ajouter un enfant" button.
- **Add child:** first name, cycle segmented control and grade chips, username (availability check) and a 4-digit PIN. The success screen then shows the credentials on an ink card and the invite code, with Share via WhatsApp and Copy.
- **Child progress:**
  - Identity header and an exam countdown (ink card, gold number). The exam depends on grade: P6 = Concours, C4 = Brevet, L3 = Bac.
  - The AI insight card: dated, 2–3 sentences, with no scores invented beyond the data.
  - 4 stats, subject mastery bars, and links: exam history, lesson-by-lesson, focus mode (with a status chip).
- **Focus settings:**
  - The switch dims the windows section when off.
  - Each window has day chips (44 px circles) and start → end times via the time picker. Windows can be added or deleted.
  - Also: change the parent PIN, and a log with dated events.
- **Subscription:**
  - Plan radio cards (monthly, quarterly "Populaire", yearly) with prices and discounts from the API.
  - Child checkboxes, and a summary with the family discount and total.
  - Then "Payer avec Bankily".
- **Bankily payment:**
  - The amount and merchant number, with copy.
  - 3 numbered steps, then the Bankily phone and the transaction code.
  - Confirm moves the subscription to **pending**.
- **Status:** each child's card shows its state:
  - **Actif:** teal, with the end date.
  - **En vérification:** gold, with the payment details and a support link.
  - **Expiré:** red, with Renouveler.
  - **Refusé:** red, with the reason and Réessayer.
  - A history list sits below.

---

## 5. States (every data screen)

| State | Pattern |
|---|---|
| Loading | Skeleton mirroring the final layout; no spinners except inside buttons |
| Empty | EmptyState with an icon, a one-line reason and the next action (e.g. "Aucun téléchargement") |
| Error | ErrorState with a plain cause and "Réessayer"; keep the rest of the screen usable |
| Offline | OfflineBanner at the top; show cached data; disable actions that need the network and explain why on tap |
| Protected | Black screen while screen capture is detected |

---

## 6. Motion

Everything is ≤ 400 ms except the splash. Disable or shorten all motion when `disableAnimations` is on.

- **Splash:** about 1.2 s total (see above), with easeOutCubic.
- **Answer feedback:**
  - A right answer pulses the card (scale 1 → 1.02 → 1, 250 ms) and the "+10 XP" chip rises 8 px while fading in.
  - A wrong answer shakes horizontally (3 × 4 px, 240 ms), with a light haptic.
- **Streak celebration:** the flame scales from 0.6 to 1 with a soft spring (380 ms), 3 dots burst outward, then today's circle fills.
- **Transitions:**
  - Push screens with a 280 ms slide in from the end edge (reversed in RTL).
  - Sheets slide up in 300 ms; tabs cross-fade in 200 ms.
  - Progress bars animate to their new value in 400 ms.

## 7. Accessibility and real-world conditions

- **Contrast:** all text meets WCAG AA. Never put white text on gold.
- **Touch targets:** at least 44 pt, even for icon buttons.
- **Screen readers:** semantics labels in the current language.
- **Large text:** support text scale up to 2.0. Cards grow, grids drop to 1 column below 360 dp logical width at large scale, and nothing clips.
- **Low-end phones and costly data:**
  - Compress images.
  - Stream video with adaptive quality and default to low on mobile data.
  - Offer downloads on Wi-Fi.
  - Keep the last data cached for offline viewing.
- **Numbers:** use Western digits (0–9) in both languages. Dates follow the locale (`intl`).
