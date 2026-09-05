# Build plan

Ship the spine before the extras. Each phase is a releasable app.

**Status**: Phases 0, 1, 2 and 4 are built (this includes the module picker
and onboarding quiz from Phase 3, minus the account screens). Phase 3's
sign-in/OTP/biometric-lock screens and Phase 5's paywall stay un-built —
they need a real Supabase project and Play Billing setup respectively,
which this build doesn't have. See the README's "Not in this build" section.

## Phase 0 — Foundation

- `flutter create --org ai.aandccreative prakriya`
- Light and dark `ThemeData`, `themeMode: ThemeMode.system`, with a stored override
- Fonts: Archivo Black (headings), Inter (everything else)
- Local database for plans, habits, mantras, journal entries

### Colour tokens

| Token | Dark | Light |
|---|---|---|
| Background | `#150C28` → `#1B0F33` gradient | `#FAF4E9` |
| Surface / card | `rgba(255,255,255,.04)` | `#FFFFFF` |
| Accent | `#F2B93B` | `#E0A419` |
| Accent text | `#FFE9A8` | `#B07E10` |
| Body text | `#E8DFFA` | `#1B0F33` |
| Muted text | `#8A7BB5` | `#9C93AE` |
| Violet | `#4C2A85` | `#4C2A85` |

Card radius 20px, pill buttons 999px, module rows 14–16px.

## Phase 1 — v0.1, the working spine

| Screen | What it is |
|---|---|
| 2g | Home — card stack, reorderable and hideable modules |
| 2h | Habit detail — streak and history |
| 2n | First-run home — empty states |
| 2j | Quote of the day — shareable |

Mantra card and top-3 planner both live on 2g. Habits tick from the home card.

## Phase 2 — v0.2, reminders

| Screen | What it is |
|---|---|
| 2r | Lock-screen notification set |
| 2s | Reminder settings — times, quiet hours |

Three local schedules: 7:30am mantra + top 3, 1pm check (fires only if something
is open), 9pm close the day. Request notification permission when the user turns
reminders on, never at launch. Reschedule on device reboot. Handle exact-alarm and
battery-optimisation prompts. Test on real Xiaomi, Samsung and Oppo hardware —
their battery managers are the usual reason a reminder never arrives.

## Phase 3 — v0.3, setup and accounts

| Screen | What it is |
|---|---|
| 2d | Onboarding quiz — runs once, sets the preset |
| 2e | Module picker |
| 2l | Settings — theme, lock, account |
| 2a, 2b, 2c | Welcome, sign-in, phone OTP |
| 2f | Biometric unlock, PIN fallback |

The quiz runs once and is retakeable from settings. Resume always opens straight
to today — never re-run setup.

## Phase 4 — v0.4, the practice modules

| Screen | What it is |
|---|---|
| 2i | Outcome engineering — scripting entry |
| 2p | Evening reflection — mood, gratitude, repeat tomorrow |
| 2k | Weekly momentum review |
| 2q | Vision board |

## Phase 5 — monetisation, deferred

Screen 2m is the paywall. It is designed but stays switched off while the app is
distributed from GitHub: Google Play Billing only works for apps installed from
Play. Decide between a free v1 and an external payment link before building it.

## Naming

Two vocabulary decisions, applied throughout the design — keep them in the code
and the copy:

- "manifestation" → **outcome engineering**
- "affirmation" → **mantra**
