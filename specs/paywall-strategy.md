# Dander Paywall Strategy: Prestige-First Monetisation

## The Core Principle

**The paywall should feel like an invitation, not a gate.**

Prestige apps (Calm, Strava, Fantastical) convert users by making the free experience genuinely good — then making the paid experience feel like the *natural next step* for someone who's already invested. The user should think "I use this enough that Pro makes sense," not "they're blocking me from something I want."

This means: **never interrupt a session. Never block mid-action. Never make the free experience feel broken.**

---

## Free vs. Pro: The Line

The strategic question is: *what creates the conversion trigger without damaging activation?*

**The answer for Dander: the free tier is a complete single-zone experience. Pro unlocks expansion and depth.**

### Free Tier (genuinely great)

| Feature | Limit | Why it's free |
|---|---|---|
| Fog-of-war exploration | Unlimited | This IS the product. Gating it kills activation. |
| 1 active zone | Full access | One complete loop must work before you ask for money |
| POI discoveries | All in active zone | Discoveries are the dopamine — don't throttle dopamine |
| Street quiz | 10 questions/day | Enough to form the habit, not enough to master |
| Weekly streak | Full | Streaks drive retention — retention drives conversion |
| Basic stats | Distance, fog %, POIs | Enough to feel progress |
| Shareable cards | 1 per week | Growth loop must work on free tier too |

### Dander Pro ($4.99/mo or $34.99/yr)

| Feature | What it adds | Conversion psychology |
|---|---|---|
| Unlimited zones | Travel, commute, holidays | **Primary trigger** — sunk cost + expansion desire |
| Unlimited quiz | All question types, no daily cap | Habit completion — "I want to keep going" |
| Advanced stats | Heat maps, monthly trends, lifetime distance | Investment deepening — makes the map more meaningful |
| Weekly challenges | Curated goals + exclusive badges | Novelty within routine — reason to return |
| Unlimited sharing | All card types, high-res export | Identity signalling at full resolution |
| Monthly wrap | Animated monthly summary | Emotional payoff that compounds over time |
| Faster compass charges | 1 per 500m vs 1 per 1000m | Quality-of-life upgrade for power users |

---

## Conversion Funnel: The Five Touchpoints

No hard gates. No popups. Five natural moments where Pro surfaces organically.

### 1. The Soft Discovery (Day 1-3)

**Where:** Profile screen — a "Dander Pro" pill badge in the screen header area, always visible but never pushed.

**What it does:** Shows a beautifully designed Pro overview screen if tapped. No urgency. No countdown. Just: "Here's what Pro includes." The user learns Pro exists without being sold to.

**Psychology:** Mere exposure effect. They know it's there. When the conversion trigger fires later, there's no surprise.

**UX implementation:**

- Place a small pill-shaped badge reading "Pro" with an amber-to-cyan gradient border in the profile screen header, right-aligned next to the screen title
- Badge uses `DanderColors.secondary` (#FF8F00) to `DanderColors.accent` (#4FC3F7) gradient on the border, transparent fill
- Text: `labelMedium` (12px, w600, Inter) in `DanderColors.onSurfaceMuted`
- Touch target: 44x44pt minimum (expand hit area with `hitSlop` beyond the visual badge)
- On tap: navigate to the paywall screen with a slide-right transition (250ms, `Curves.easeOutCubic` — matching existing page transitions)
- No animation on the badge itself — static, quiet, always there. Prestige = restraint

### 2. The Natural Limit (Day 5-14)

**Where:** When the user hits the quiz daily cap (10 questions).

**What it does:** After question 10, transition to a completion screen that celebrates their effort first, then offers expansion.

**Psychology:** Goal-gradient — they're mid-flow, they want to continue. The limit creates desire without frustration because 10 questions is a satisfying session.

**UX implementation:**

The quiz limit screen is **not** a paywall popup — it's a quiz completion screen with a Pro extension option:

```
┌─────────────────────────────────────┐
│                                     │
│         ✦ (accent glow icon)        │
│                                     │
│       "Nice work today"             │  ← headlineSmall (24px, Space Grotesk, w600)
│                                     │
│       "8 out of 10 correct"         │  ← bodyLarge (16px, Inter) in onSurfaceMuted
│                                     │
│    ┌───────────────────────────┐    │
│    │  ● ● ● ● ● ● ● ● ○ ○   │    │  ← 10 dots, correct=accent, wrong=error, remaining=muted
│    └───────────────────────────┘    │
│                                     │
│   ┌───────────────────────────────┐ │
│   │   Want to keep practising?    │ │  ← bodyMedium (14px, Inter)
│   │                               │ │
│   │   ┌─────────────────────┐     │ │
│   │   │  Try Pro free for   │     │ │  ← Filled button, secondary color (#FF8F00)
│   │   │     7 days          │     │ │     titleMedium (16px, Inter, w600)
│   │   └─────────────────────┘     │ │     border-radius: borderRadiusMd (12px)
│   │                               │ │     height: 52px, full-width minus 32px padding
│   │   ┌─────────────────────┐     │ │
│   │   │   Done for today    │     │ │  ← Outlined button, same size, same weight
│   │   └─────────────────────┘     │ │     border: 1px cardBorder
│   └───────────────────────────────┘ │     EQUALLY prominent — no dark patterns
│                                     │
└─────────────────────────────────────┘
```

**Critical design rules:**
- "Done for today" button is **identical in size, weight, and prominence** to the Pro CTA. Same height (52px), same border-radius (12px), same font weight (w600). Only difference: filled vs outlined
- The celebration (score, dots) appears first with a 200ms fade-in. The Pro suggestion fades in 400ms after — it arrives gently, not simultaneously
- Dots animate in sequentially (30ms stagger per dot) to create a satisfying reveal of their performance
- "Done for today" returns to the map screen. No guilt. No friction. No "are you sure?"
- This screen appears maximum once per day — never re-prompts in the same session

### 3. The Expansion Moment (Variable timing)

**Where:** When the user physically travels to a new area outside their active zone.

**What it does:** The fog is visible in the new area. A subtle banner slides down from below the app bar — not a modal, not a dialog, just a contextual inline banner.

**Psychology:** Loss aversion + endowed progress. They can see the opportunity cost of not upgrading in real-time.

**UX implementation:**

```
┌─────────────────────────────────────┐
│  [map content visible behind]       │
│                                     │
│  ┌─────────────────────────────────┐│
│  │ 🗺  You're in a new area.       ││  ← Inline banner, NOT a modal
│  │    Unlock unlimited zones →     ││     Background: surfaceElevated (#111120)
│  └─────────────────────────────────┘│     Border: 0.5px cardBorder
│                                     │     Border-radius: borderRadiusLg (16px)
│  [map continues, fog visible]       │     Margin: 16px horizontal, positioned
│                                     │     below app bar
└─────────────────────────────────────┘
```

**Critical design rules:**
- Banner uses `DanderElevation.level2` shadow for subtle float above map
- Icon: Lucide `map-pin` or similar, 20px, `DanderColors.accent` (#4FC3F7)
- Text: `bodyMedium` (14px, Inter) in `DanderColors.onSurface` (#E8EAF6)
- Arrow: `labelLarge` (14px, Inter, w600) in `DanderColors.secondary` (#FF8F00)
- Banner slides in from top with 250ms ease-out, matching existing page transitions
- Dismissible: swipe up to dismiss, or tap X. Does not reappear for 48 hours after dismissal
- Tap anywhere on the banner navigates to paywall screen
- Touch target: entire banner is tappable (minimum 48px height)
- Banner auto-dismisses after 8 seconds if not interacted with — fade out over 200ms
- **Maximum frequency:** Once per new-area detection, max once per day

### 4. The Stats Tease (Week 2+)

**Where:** Profile screen, below the existing stats cards.

**What it does:** Show basic stats in full. Below them, show locked Pro stats cards with a frosted glass blur effect — the data shapes are visible but unreadable.

**Psychology:** Curiosity gap. The data exists. They generated it. They just can't see it yet.

**UX implementation:**

```
┌─────────────────────────────────────┐
│  [Existing stats: distance,        │
│   fog %, POIs — fully visible]     │
│                                     │
│  ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─  │  ← Subtle divider
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  ││  ← Card with BackdropFilter blur
│  │  ░░░ Heat Map ░░░░░░░░░░░░░░░  ││     sigma: 6.0, saturation: 0.5
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  ││     Behind the blur: actual placeholder
│  │           🔒 Pro               ││     data shapes (bars, dots, lines)
│  └─────────────────────────────────┘│     to create visual intrigue
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  ││  ← Same treatment
│  │  ░░░ Monthly Trends ░░░░░░░░░  ││
│  │  ░░░░░░░░░░░░░░░░░░░░░░░░░░░  ││
│  │           🔒 Pro               ││
│  └─────────────────────────────────┘│
└─────────────────────────────────────┘
```

**Critical design rules:**
- Blurred cards use `BackdropFilter` with `ImageFilter.blur(sigmaX: 6, sigmaY: 6)` over placeholder chart shapes
- Behind the blur, render abstract data visualizations using `DanderColors.accent` at 30% opacity — bars, trend lines, dot clusters. These aren't real data — they're suggestive shapes that look like interesting stats
- Lock icon: Lucide `lock` at 16px in `DanderColors.onSurfaceMuted`
- "Pro" label: `labelMedium` (12px, w600, Inter) in `DanderColors.secondary` (#FF8F00)
- Card background: `DanderColors.cardBackground` (#1A1A2C) with `cardBorder`
- Cards are tappable → navigate to paywall screen
- No tooltip, no popup on hover. Just a quiet lock + "Pro" label. The blur does the selling
- Cards should be same height as the real stats cards above (visual continuity)

### 5. The Milestone Celebration (Ongoing)

**Where:** After a significant achievement — first zone level-up, 50% fog cleared, 7-day streak.

**What it does:** Show the celebration fully (never gate the dopamine). After the animation completes, if relevant, show one Pro feature as an additive suggestion.

**Psychology:** Peak-end rule. The emotional high of the achievement is the peak. The Pro suggestion rides the positive emotion without stealing it.

**UX implementation:**

The celebration overlay runs its full animation (confetti, level-up glow, etc.) exactly as it does today. After the celebration animation completes (typically 1800ms for confetti), a Pro suggestion fades in below the celebration content:

```
┌─────────────────────────────────────┐
│                                     │
│        ✨ Level 3! ✨               │  ← Existing celebration (unchanged)
│     "Explorer of [Zone Name]"       │
│                                     │
│   ┌───────────────────────────────┐ │
│   │  There's more to unlock      │ │  ← Fades in 600ms AFTER celebration
│   │                               │ │     completes. bodyMedium, onSurfaceMuted
│   │  Weekly challenges, exclusive │ │
│   │  badges, advanced stats       │ │     Background: surfaceElevated with
│   │                               │ │     0.5px cardBorder
│   │  Learn about Pro →            │ │     border-radius: borderRadiusLg (16px)
│   └───────────────────────────────┘ │     padding: 16px
│                                     │
│   ┌───────────────────────────────┐ │
│   │        Continue               │ │  ← Primary dismiss button (always present)
│   └───────────────────────────────┘ │     Filled, secondary color
│                                     │     This is the MAIN action
└─────────────────────────────────────┘
```

**Critical design rules:**
- The celebration is **100% complete** without the Pro card. If the user taps "Continue" before the Pro suggestion fades in, they skip it entirely — no delay, no block
- Pro suggestion card: `bodyMedium` (14px, Inter) text in `DanderColors.onSurfaceMuted`, "Learn about Pro" link in `DanderColors.secondary` (#FF8F00)
- "Continue" button is the primary action — filled, prominent, `DanderColors.secondary`. The Pro card is secondary — outlined, subtle
- Pro suggestion is contextual to the achievement:
  - Zone level-up → "Unlock weekly challenges to earn exclusive badges"
  - Fog milestone → "See your exploration heat map with Pro"
  - Streak milestone → "Track your monthly walking trends with Pro"
- Maximum frequency: Pro suggestion appears on **every other** milestone celebration, not every one. Don't train the user to expect a sales pitch after every win

---

## Paywall Screen Design

When the user taps any Pro touchpoint, they land on a single, beautiful full-screen modal.

### Visual Structure

```
┌─────────────────────────────────────┐
│  ✕                                  │  ← Close: top-left, 44x44pt touch target
│                                     │     Icon: 24px, onSurfaceMuted
│                                     │     NO delay before appearing
│                                     │
│     ┌───────────────────────┐       │
│     │                       │       │  ← Hero area: 200px tall
│     │   [Contextual         │       │     Animated preview of the feature
│     │    animated preview]  │       │     that triggered the visit
│     │                       │       │     (see Hero Variants below)
│     └───────────────────────┘       │
│                                     │
│        D A N D E R  P R O           │  ← displaySmall or headlineLarge
│                                     │     Space Grotesk, bold
│     "Take your exploration          │     Letter-spacing: 2px (tracked out)
│          further"                   │     Amber-to-cyan gradient text
│                                     │     (secondary → accent)
│                                     │
│  ┌─────────────────────────────────┐│
│  │  ◈  Unlimited zones            ││  ← 3 benefits with icons
│  │     Map every neighbourhood    ││     Icon: 20px, accent (#4FC3F7)
│  │                                ││     Title: titleSmall (14px, w600, Inter)
│  │  ◈  Full quiz access           ││     Subtitle: bodySmall (12px, Inter)
│  │     All question types, no cap ││     in onSurfaceMuted
│  │                                ││     Spacing: 16px between items
│  │  ◈  Advanced stats & wraps     ││     Stagger fade-in: 50ms per item
│  │     Heat maps, monthly trends  ││
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  $34.99/year                   ││  ← ANNUAL: highlighted plan card
│  │  $2.92/mo · 7 days free       ││     Background: cardBackground
│  │                                ││     Border: 1.5px secondary (#FF8F00)
│  │  ┌─────────────────────────┐   ││     accent glow: DanderElevation.accentGlow
│  │  │  Start free trial       │   ││     CTA: filled, secondary, 52px height
│  │  └─────────────────────────┘   ││     borderRadiusMd (12px)
│  └─────────────────────────────────┘│
│                                     │
│  ┌─────────────────────────────────┐│
│  │  $4.99/month                   ││  ← MONTHLY: quiet alternative
│  │                                ││     Background: cardBackground
│  │  ┌─────────────────────────┐   ││     Border: 0.5px cardBorder (default)
│  │  │     Subscribe           │   ││     No accent glow
│  │  └─────────────────────────┘   ││     CTA: outlined, 52px height
│  └─────────────────────────────────┘│
│                                     │
│  Restore purchases · Terms · Privacy│  ← labelSmall (11px, Inter, w500)
│                                     │     in onSurfaceMuted
│                                     │     Touch targets: 44px height each
│                                     │     Spaced with · separators
└─────────────────────────────────────┘
```

### Hero Variants (Contextual)

The hero area changes based on what brought the user to the paywall:

| Trigger | Hero content | Animation |
|---|---|---|
| Profile Pro badge | Abstract fog-clearing loop — dark circle with fog dissolving outward | 3s loop, 200ms fade-in |
| Quiz limit | Score ring filling to 100% with accent glow pulse | 2s, ease-out-cubic |
| Zone expansion | Miniature map with 3 zone circles pulsing sequentially | 2.5s loop, staggered 300ms |
| Stats tease | Chart lines drawing themselves — heat map dots appearing | 2s, sequential draw |
| Milestone celebration | The badge/achievement that was just earned, with subtle glow | Static with 1s glow pulse |

**Hero rules:**
- All hero animations respect `DanderMotion.isReduced(context)` — if reduced motion, show a static illustration instead
- Hero area: 200px height, full-width, no border, blends into the screen background
- Animations use `Curves.easeOutCubic` (matching existing app motion language)
- Maximum 2 animated elements in the hero at any time (avoid excessive motion)

### Design Principles (Detailed)

**Typography hierarchy on the paywall screen:**

| Element | Style | Font | Color |
|---|---|---|---|
| "DANDER PRO" | headlineLarge (32px) or custom | Space Grotesk, bold | Gradient: secondary → accent |
| Subtitle | bodyLarge (16px) | Inter, normal | onSurfaceMuted |
| Benefit title | titleSmall (14px) | Inter, w600 | onSurface |
| Benefit description | bodySmall (12px) | Inter, normal | onSurfaceMuted |
| Price (annual) | titleLarge (22px) | Space Grotesk, w600 | onSurface |
| Price (monthly) | titleMedium (16px) | Inter, w600 | onSurfaceMuted |
| Per-month breakdown | bodySmall (12px) | Inter, normal | onSurfaceMuted |
| CTA button text | titleMedium (16px) | Inter, w600 | onSecondary (#0F172A) |
| Legal links | labelSmall (11px) | Inter, w500 | onSurfaceMuted |

**Color and surface treatment:**

- Screen background: `DanderColors.surface` (#0A0A14) — deepest dark, cinematic
- Plan cards: `DanderColors.cardBackground` (#1A1A2C)
- Annual card border: 1.5px `DanderColors.secondary` (#FF8F00) with `DanderElevation.accentGlow`
- Monthly card border: 0.5px `DanderColors.cardBorder` (default, quiet)
- Annual CTA button: filled `DanderColors.secondary`, text in `DanderColors.onSecondary`
- Monthly CTA button: outlined with `cardBorder`, text in `DanderColors.onSurface`

**Interaction and animation:**

- Screen enters as a full-screen modal with slide-up from bottom (300ms, `Curves.easeOutCubic`)
- Close button: top-left, visible immediately (no delay), swipe-down to dismiss also supported
- Tap feedback on plan cards: `DanderElevation.level1` → `level2` elevation shift on press (150ms)
- CTA buttons: subtle scale feedback on press (0.97 scale, 100ms, spring curve)
- Benefits list: stagger fade-in 50ms per item after screen transition completes
- "DANDER PRO" text: gradient shimmer animation on first appearance only (600ms, left-to-right, then static). Skip if reduced motion

**Accessibility:**

- VoiceOver/TalkBack: announce "Dander Pro subscription. Close button. Swipe down to dismiss" on screen open
- All prices include accessibility labels: "34 dollars and 99 cents per year, with 7-day free trial"
- Plan cards have `accessibilityHint`: "Double-tap to select this plan"
- Contrast: all text meets 4.5:1 minimum against `surface` background
- "Restore purchases" is keyboard/VoiceOver reachable — never hidden or de-emphasized beyond readability

---

## What NOT to Do

| Anti-pattern | Why it kills prestige feel | UX detail |
|---|---|---|
| Full-screen paywall on launch | User hasn't experienced value yet. Feels desperate. | Never show paywall before the user has completed at least 1 walk |
| Dismissing the paywall returns to a degraded experience | Punishes the user for not paying. Breeds resentment. | Dismiss always returns to exactly where they were, same scroll position, same state |
| "You've been using Dander for 7 days!" popup | Interruptive. The app is counting days, not helping. | No time-based triggers. Only behavior-based triggers (quiz cap, zone expansion, stats view) |
| Limiting fog-clearing on free tier | The fog IS the free experience. Throttling it destroys the core loop. | Fog-clearing is never gated, throttled, or slowed for free users |
| Showing Pro features then locking them after trial ends | Loss aversion works for conversion, but feels like theft for retention. | After trial: freeze non-primary zones (data preserved), revert quiz to 10/day limit. Never delete data. |
| Multiple upsell popups per session | One natural touchpoint per session maximum. | Track `lastProPromptTimestamp` — minimum 4 hours between any Pro surface (excluding user-initiated taps on Pro badge) |
| Animated "upgrade" badges/banners on main screens | Visual noise on core experience. Feels desperate. | The Pro badge on profile is static. No pulsing, no bouncing, no attention-grabbing animation. |
| Skeleton/placeholder where Pro content would be | Suggests the app is incomplete. | Blurred cards with suggestive shapes — the data looks real and interesting, just unreadable |

---

## Pro Badge Design (Profile Screen)

The Pro badge is the permanent, quiet ambassador for the subscription. It must feel native to the app, not bolted on.

### Free user state

```
┌────────────────┐
│  Pro  ›        │  ← Pill shape, borderRadiusFull (100px)
└────────────────┘     Height: 28px, padding: 12px horizontal
                       Border: 1px gradient (secondary → accent)
                       Fill: transparent
                       Text: labelMedium (12px, w600), onSurfaceMuted
                       Chevron: 12px, onSurfaceMuted
                       Touch target: 44x44pt (hitSlop extends beyond visual)
```

### Pro subscriber state

```
┌────────────────┐
│  ✦ Pro         │  ← Same pill, but filled
└────────────────┘     Fill: subtle gradient (secondary at 15% → accent at 15%)
                       Border: 1px gradient (secondary → accent)
                       Text: labelMedium, secondary (#FF8F00)
                       ✦ icon: 10px, secondary
                       No chevron (nothing to navigate to)
```

**Rules:**
- No animation on either state. Static, elegant, quiet.
- Pro subscriber badge is a reward — it looks premium but doesn't flash or demand attention
- Badge position: right side of `ScreenHeader` row, vertically centered with title

---

## RevenueCat Implementation Notes

### Entitlement model

One entitlement: `pro`. Binary. Either active or not.

```
Offerings:
  default:
    - dander_pro_monthly  ($4.99/mo)
    - dander_pro_annual   ($34.99/yr, 7-day trial)
```

### Architecture

```
lib/
  core/
    subscription/
      subscription_service.dart       ← RevenueCat wrapper, exposes isPro stream
      subscription_state.dart         ← Immutable state: free | trial(daysLeft) | pro
      pro_gate.dart                   ← Widget that conditionally shows Pro prompt
      paywall_trigger.dart            ← Enum: profile, quizLimit, zoneExpansion, stats, milestone
  features/
    subscription/
      presentation/
        screens/
          paywall_screen.dart         ← Full-screen modal paywall
        widgets/
          pro_badge.dart              ← Profile pill badge
          plan_card.dart              ← Annual/monthly plan card
          paywall_hero.dart           ← Contextual animated hero
          benefit_row.dart            ← Icon + title + subtitle row
          quiz_limit_screen.dart      ← Post-quiz completion with Pro option
          zone_expansion_banner.dart  ← Inline map banner
          stats_tease_card.dart       ← Blurred Pro stats card
```

### Feature gating pattern

```dart
// SubscriptionService exposes a ValueNotifier<SubscriptionState>
// All gating is reactive — UI rebuilds when state changes

// Check entitlement — never block UI, just adjust it
final isPro = subscriptionService.state.value.isPro;

// Quiz limit
if (!isPro && todayQuizCount >= 10) → navigate to QuizLimitScreen

// Zone creation
if (!isPro && activeZoneCount >= 1) → show ZoneExpansionBanner on map

// Stats
if (!isPro) → show StatsTeaseCard below real stats on profile

// Sharing
if (!isPro && weeklyShareCount >= 1) → show soft prompt with Pro badge
```

### Where to check

| Check | Location | Behaviour |
|---|---|---|
| `isPro` | App launch | Cache entitlement status locally (Hive) for offline access |
| Quiz limit | After each quiz answer | Count against daily limit (reset at midnight local), show QuizLimitScreen at 10 |
| Zone limit | Zone creation flow | Prevent second zone, show ZoneExpansionBanner on map |
| Stats | Profile screen build | Render StatsTeaseCard below real stats |
| Sharing | Share flow | Allow 1/week free, then show soft Pro prompt |
| Pro prompt cooldown | All prompt triggers | Check `lastProPromptTimestamp` — minimum 4 hours between prompts |

### Trial management

- 7-day trial on annual plan only
- Show trial status in profile screen below Pro badge: "Pro trial · 4 days left" in `labelSmall`, `DanderColors.secondary`
- Day 5 local notification: "Your Pro trial ends in 2 days. Keep your unlimited zones?"
- Day 7 local notification: "Your Pro trial ended today. Your zones and data are safe."
- After trial ends: graceful downgrade — keep all zone data, freeze non-primary zones (show lock icon overlay on zone cards), revert quiz to 10/day. **Never delete user data.**

### Purchase flow UX

1. User taps CTA → button shows loading spinner (disable button, show `CircularProgressIndicator` at 20px in button center, 150ms crossfade)
2. System payment sheet appears (StoreKit / Google Play)
3. On success: dismiss paywall with 200ms fade-out, show success toast ("Welcome to Pro") with confetti burst (reuse existing `ConfettiOverlay`, 1800ms)
4. On cancel: re-enable button, no error message, no guilt — they just stay on the paywall
5. On error: show inline error below the plan card ("Something went wrong. Try again.") in `DanderColors.error` (#EF5350), `bodySmall`
6. Restore purchases: show loading indicator, then success/failure toast

---

## Metrics to Track

| Metric | Target | Why it matters |
|---|---|---|
| Paywall view rate | 40-60% of D7 users | Are enough users encountering Pro? |
| Trial start rate | 15-25% of paywall views | Is the paywall compelling? |
| Trial-to-paid conversion | 50-65% | Is the trial experience good enough? |
| Free-to-paid (overall) | 8-12% | Revenue viability |
| Time to first paywall view | Day 3-7 | Too early = annoying. Too late = missed window. |
| Paid churn (monthly) | <8% | Are Pro users getting ongoing value? |
| Paid churn (annual) at renewal | <30% | Long-term sustainability |
| Paywall dismiss rate by trigger | Track per trigger | Which touchpoints feel pushy vs natural? |
| Pro badge tap rate | 5-15% of profile views | Is the badge discoverable without being pushy? |
| Quiz limit → paywall → trial | 10-20% | Is the quiz cap calibrated right? |

### Analytics events

```
paywall_viewed          { trigger: PaywallTrigger, session_day: int }
paywall_dismissed       { trigger: PaywallTrigger, time_on_screen_ms: int }
trial_started           { trigger: PaywallTrigger, plan: annual }
subscription_started    { trigger: PaywallTrigger, plan: monthly|annual }
subscription_renewed    { plan: monthly|annual, months_subscribed: int }
subscription_cancelled  { plan: monthly|annual, months_subscribed: int }
pro_badge_tapped        { is_pro: bool }
quiz_limit_reached      { correct: int, total: int }
zone_expansion_shown    { dismissed: bool, tapped: bool }
stats_tease_tapped      { card_type: heatmap|trends|knowledge }
```

---

## Build Order

1. **RevenueCat SDK integration + `SubscriptionService`** — the plumbing
2. **Paywall screen** — one beautiful screen with contextual hero
3. **Pro badge on profile** — the always-visible quiet ambassador
4. **Quiz daily limit + QuizLimitScreen** — first and most frequent conversion trigger
5. **Zone limit + ZoneExpansionBanner** — highest-converting trigger (but requires travel)
6. **Stats tease cards on profile** — blurred Pro stats
7. **Milestone Pro mentions** — post-celebration suggestions
8. **Trial expiry notifications** — day 5 and day 7
9. **Analytics events** — track everything from day 1

Items 1-4 are your MVP paywall. Ship those first, measure, then add 5-9.

---

## UX Checklist (Pre-Launch)

### Visual Quality
- [ ] All Pro UI uses existing `DanderColors`, `DanderSpacing`, `DanderElevation` tokens — no hardcoded values
- [ ] Paywall screen looks native to the app — same dark surfaces, same typography, same spacing rhythm
- [ ] Pro badge uses gradient border (secondary → accent) consistently across all states
- [ ] Blurred stats cards use `BackdropFilter` with consistent sigma values
- [ ] No emojis as icons — use Lucide/Material icons throughout

### Interaction
- [ ] All tappable elements have 44x44pt minimum touch targets
- [ ] CTA buttons show press feedback (0.97 scale, 100ms spring)
- [ ] Plan cards show elevation shift on press (level1 → level2, 150ms)
- [ ] Purchase flow shows loading state in button during processing
- [ ] Paywall dismissible via close button AND swipe-down gesture
- [ ] "Done for today" on quiz limit screen works instantly — no confirmation dialog

### Animation
- [ ] All animations respect `DanderMotion.isReduced(context)`
- [ ] Hero animations loop smoothly with no jank (test on low-end devices)
- [ ] Benefit rows stagger at 50ms per item
- [ ] Screen transitions match existing app patterns (250-300ms, easeOutCubic)
- [ ] Gradient shimmer on "DANDER PRO" is subtle and fires once only

### Accessibility
- [ ] VoiceOver/TalkBack reads paywall content in logical order
- [ ] All prices have explicit accessibility labels with full currency
- [ ] Close button is first in focus order
- [ ] Color contrast meets 4.5:1 on all text against `surface` background
- [ ] Blurred cards announce "Pro feature. Double-tap to learn more"

### Conversion Integrity
- [ ] No paywall surface before first completed walk
- [ ] Maximum one Pro prompt per session (excluding user-initiated Pro badge taps)
- [ ] Minimum 4-hour cooldown between automated Pro prompts
- [ ] "Done for today" / dismiss buttons are equally prominent to Pro CTAs
- [ ] Trial downgrade preserves all user data — no deletions

---

## The Bottom Line

The conversion funnel for a prestige app is: **fall in love with the free experience, then naturally want more.** Every Pro touchpoint should feel like the app saying "there's more here when you're ready" — never "you can't do that." The fog stays free. The core loop stays free. Pro is expansion, depth, and polish for users who've already decided Dander is part of their routine.

The design language is the same dark, cinematic, amber-and-cyan palette the user already loves. The paywall isn't a separate experience — it's a natural extension of the app they're already enjoying. That's what makes it prestige.
