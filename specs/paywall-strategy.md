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

**Where:** Settings or profile screen — a small "Dander Pro" badge, always visible but never pushed.

**What it does:** Shows a beautifully designed Pro overview screen if tapped. No urgency. No countdown. Just: "Here's what Pro includes." The user learns Pro exists without being sold to.

**Psychology:** Mere exposure effect. They know it's there. When the conversion trigger fires later, there's no surprise.

### 2. The Natural Limit (Day 5-14)

**Where:** When the user hits the quiz daily cap (10 questions).

**What it does:** After question 10, show their score and a gentle message: *"You answered 8/10 today. Want to keep practising?"* with a "Try Pro free for 7 days" button alongside a "Done for today" button that's equally prominent.

**Critical design rule:** "Done for today" must be visually equal to the Pro CTA. No dark patterns. No tiny dismiss button. The user should feel respected, not manipulated.

**Psychology:** Goal-gradient — they're mid-flow, they want to continue. The limit creates desire without frustration because 10 questions is a satisfying session.

### 3. The Expansion Moment (Variable timing)

**Where:** When the user physically travels to a new area outside their active zone.

**What it does:** The fog is visible in the new area. A subtle banner appears: *"You're in a new neighbourhood. Unlock unlimited zones to start mapping here too."* The fog still shows. They can see what they'd explore. They just can't clear it yet.

**This is the highest-converting moment.** They've already invested in their home zone (sunk cost). They're in a new place (curiosity gap). The value proposition is immediately tangible — "I could be clearing fog right now."

**Psychology:** Loss aversion + endowed progress. They can see the opportunity cost of not upgrading in real-time.

### 4. The Stats Tease (Week 2+)

**Where:** Profile or stats screen.

**What it does:** Show basic stats (distance, fog %, POIs) for free. Below that, show blurred/locked cards for: heat map, monthly trend, lifetime walking distance, neighbourhood knowledge score. Label them "Pro" with a lock icon. No popup, no prompt — just visible.

**Psychology:** Curiosity gap. The data exists. They generated it. They just can't see it yet. This is the Strava model — your data is the product, and seeing a richer view of your own data feels like an upgrade, not a restriction.

### 5. The Milestone Celebration (Ongoing)

**Where:** After a significant achievement — first zone level-up, 50% fog cleared, 7-day streak.

**What it does:** Show the celebration fully (never gate the dopamine). After the animation completes, if relevant, show one Pro feature as an additive suggestion: *"Unlock weekly challenges to earn exclusive badges"* or *"See your monthly walking trends with Pro."*

**Critical rule:** The celebration is complete without Pro. Pro is mentioned as "there's even more" — not "pay to see your achievement."

**Psychology:** Peak-end rule. The emotional high of the achievement is the peak. The Pro suggestion rides the positive emotion without stealing it.

---

## Paywall Screen Design

When the user taps any Pro touchpoint, they land on a single, beautiful paywall screen.

### Structure

```
[Hero: animated preview of Pro feature that triggered the visit]

"Dander Pro"
"Take your exploration further"

[3 key benefits with icons — contextual to what triggered the visit]
  - Unlimited zones
  - Full quiz access
  - Advanced stats & monthly wraps

[Annual plan — highlighted]
  $34.99/year ($2.92/mo)
  "7 days free"

[Monthly plan]
  $4.99/month

[Restore purchases]    [Terms]    [Privacy]

[X close — top right, clearly visible]
```

### Design principles

- **No countdown timers.** No "limited offer." No artificial urgency. This is a prestige app.
- **Close button is always visible.** Top-right, normal size, no delay before it appears.
- **Annual plan is default.** Highlighted but not the only option. Annual converts better and retains longer.
- **7-day free trial on annual only.** This filters for committed users and reduces trial-abuse.
- **Contextual hero.** If they arrived from the quiz limit, show a quiz animation. If from zone expansion, show a multi-zone map. If from stats, show the heat map. One paywall screen, dynamic hero.
- **No testimonials or social proof yet.** You don't have the user base. When you do, add "Join X,000 explorers" — but only when the number is impressive.

---

## What NOT to Do

| Anti-pattern | Why it kills prestige feel |
|---|---|
| Full-screen paywall on launch | User hasn't experienced value yet. Feels desperate. |
| Dismissing the paywall returns to a degraded experience | Punishes the user for not paying. Breeds resentment. |
| "You've been using Dander for 7 days!" popup | Interruptive. The app is counting days, not helping. |
| Limiting fog-clearing on free tier | The fog IS the free experience. Throttling it destroys the core loop. |
| Showing Pro features then locking them after trial ends | Loss aversion works for conversion, but feels like theft for retention. Better: never let them use a Pro feature without knowing it's Pro. |
| Multiple upsell popups per session | One natural touchpoint per session maximum. |

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

### Feature gating pattern

```dart
// Check entitlement — never block UI, just adjust it
final isPro = customerInfo.entitlements['pro']?.isActive ?? false;

// Quiz limit
if (!isPro && todayQuizCount >= 10) → show soft limit screen

// Zone creation
if (!isPro && activeZoneCount >= 1) → show zone expansion prompt

// Stats
if (!isPro) → show basic stats + blurred Pro cards
```

### Where to check

| Check | Location | Behaviour |
|---|---|---|
| `isPro` | App launch | Cache entitlement status locally for offline access |
| Quiz limit | After each quiz answer | Count against daily limit, show soft cap screen at 10 |
| Zone limit | Zone creation flow | Prevent second zone, show expansion prompt |
| Stats | Stats/profile screen | Render blurred Pro cards |
| Sharing | Share flow | Allow 1/week free, then soft prompt |

### Trial management

- 7-day trial on annual plan only
- Show trial status in settings: "Pro trial: 4 days remaining"
- Day 5 notification: "Your Pro trial ends in 2 days. Keep your unlimited zones?"
- After trial ends: graceful downgrade — keep zone data, just freeze non-primary zones (don't delete)

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

---

## Build Order

1. **RevenueCat SDK integration + entitlement check** — the plumbing
2. **Paywall screen** — one beautiful screen with contextual hero
3. **Quiz daily limit** — first and most frequent conversion trigger
4. **Zone limit** — highest-converting trigger (but requires travel)
5. **Stats tease** — blurred Pro cards on profile
6. **Milestone Pro mentions** — post-celebration suggestions
7. **Trial expiry notifications** — day 5 and day 7

Items 1-3 are your MVP paywall. Ship those first, measure, then add 4-7.

---

## The Bottom Line

The conversion funnel for a prestige app is: **fall in love with the free experience, then naturally want more.** Every Pro touchpoint should feel like the app saying "there's more here when you're ready" — never "you can't do that." The fog stays free. The core loop stays free. Pro is expansion, depth, and polish for users who've already decided Dander is part of their routine.
