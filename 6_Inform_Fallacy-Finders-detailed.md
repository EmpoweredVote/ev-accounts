# Fallacy Finders - Detailed Feature Documentation

## Overview
**Pillar**: Inform Pillar (One-directional, educational, accessible to anonymous users)

**Purpose**: Educational game teaching citizens to identify logical fallacies in real civic discourse through progressive skill-building. Players watch debate/speech clips and press buttons when spotting assigned fallacies, receiving immediate feedback and detailed analysis to develop "herd immunity" against manipulative rhetoric.

**Core Values**:
- Evidence-based critical thinking
- Supportive learning (no shame for errors)
- Anti-partisan (focus on logic, not politics)
- Individual accountability (no "quarterbacking")
- Accessible to all (no authentication required for v1)

**Tagline**: "Build herd immunity to manipulative rhetoric"

---

## Why This Feature Exists

### The Problem: Fallacies as Cognitive Exploits

**Current State**:
- Logical fallacies are cognitive vulnerabilities exploiting how brains process information
- Many use fallacies accidentally (repeating deceptive logic they heard)
- Others use intentionally to manipulate people away from their interests
- Even educated people struggle to spot fallacies in real time
- Traditional education (reading about fallacies) doesn't create lasting behavioral change
- Democracy ends up representing manipulations of the deceived, not interests of the people

**Example**: Ad Hominem in Healthcare Debate
- **Speaker**: "Don't listen to her healthcare ideas - she's never held a real job"
- **What's happening**: Attacking background instead of addressing proposal
- **Why it works**: Feels like valid criticism, shifts attention from policy to personal credibility
- **Result**: Policy never evaluated; discussion derailed by character attack

**The Manipulation**: Fallacies exploit cognitive shortcuts. We naturally trust authority, follow crowds, fear slippery slopes, respond emotionally. These shortcuts helped us survive, but in civic discourse they become vulnerabilities.

### The Solution: Progressive Skill-Building Through Play

**What Fallacy Finders Does**:
1. **Active Pattern Recognition**: Not passive reading, but active spotting during real content
2. **Immediate Feedback**: Know instantly if you caught it or missed it
3. **Explains Why**: Post-round analysis teaches the cognitive vulnerability
4. **Builds Progressively**: Obvious patterns (Ad Hominem) → Subtle ones (Begging the Question)
5. **Creates Habit**: Daily challenge format reinforces pattern recognition
6. **Rewards Mastery**: Unlock advanced fallacies and platform roles (Arbiter)

**Educational Analogy**: Like a spelling bee—not everyone wins, but everyone improves. Games teach esoteric concepts effectively (soccer fans all know "offsides" because it matters for the game).

---

## The 24 Fallacies: Tier System

### Tier 1: Beginner (Track 1 Fallacy)
Most concrete and observable patterns:

1. **Ad Hominem** - Attack person, not argument
2. **Strawman** - Misrepresent position to attack it
3. **False Dilemma** - Only two options when more exist
4. **Bandwagon** - Everyone believes it = true
5. **Appeal to Authority** - Expert says so = true
6. **Tu Quoque** - "You do it too" deflection

### Tier 2: Intermediate (Track 2 Fallacies)
Requires understanding context:

7. **False Cause** - Correlation ≠ causation
8. **Slippery Slope** - A leads inevitably to Z
9. **Loaded Question** - Question with built-in assumption
10. **Anecdotal** - Personal story as statistical proof

### Tier 3: Advanced (Track 3 Fallacies)
Requires structural analysis:

11. **Appeal to Nature** - Natural = good
12. **Genetic Fallacy** - Judge by origins
13. **Burden of Proof** - Shift who must prove
14. **Begging the Question** - Circular reasoning
15. **Ambiguity** - Double meanings mislead
16. **Personal Incredulity** - Don't understand = false
17. **Composition/Division** - Part/whole confusion
18. **Appeal to Emotion** - Emotion replaces evidence

### Tier 4: Expert (Track 4+ Fallacies)
Requires meta-awareness:

19. **Middle Ground** - Compromise = truth
20. **Texas Sharpshooter** - Cherry-pick data
21. **No True Scotsman** - Move goalposts
22. **Special Pleading** - Unjustified exception
23. **Nirvana Fallacy** - Reject because imperfect
24. **Fallacy Fallacy** - Used fallacy = they're wrong

**Progression**: T1→T2: 80% accuracy over 5 clips | T2→T3: 75% over 8 clips | T3→T4: 70% over 10 clips

---

## Core Gameplay Loop

### Phase 1: Pre-Round Assignment
- System assigns fallacy based on player's tier
- Show intro card: definition + example + teaching note
- Player reviews and starts when ready

### Phase 2: During Round - Watch & Spot
- 2-3 minute clip plays (debate, speech, interview)
- Press button when spot assigned fallacy
- Immediate visual feedback (no right/wrong yet)
- Continue watching until clip ends

### Phase 3: Immediate Feedback
- **Correct Hit**: Green flash, +10 XP, soft chime
- **False Positive**: Red shake, -5 XP, muted tone
- **Missed**: No penalty, revealed in retro

### Phase 4: Retro Screen
Complete breakdown:
- **Hits**: What caught + explanations + replay
- **False Positives**: Why logic was sound + teaching
- **Misses**: Supportive "growth opportunity" + explanation
- **Other Fallacies**: Preview of unassigned types in clip

### Phase 5: Daily Challenge Calendar
- Today's featured clip
- Historical clips for practice
- Progress tracker (XP, tier, unlocked fallacies)
- Per-fallacy accuracy stats

**Scoring**: +10 correct, -5 false positive, 0 missed

---

## User Journey: First-Time Player

**Alex, 22, IU political science student, heard about Fallacy Finders from professor.**

### 1. Landing Page
```
FALLACY FINDERS
Learn to spot manipulation in real time

[PLAY FIRST CHALLENGE]
No account • ~10 minutes
```
Alex: "Quick start, no signup. Let me try it."

### 2. Onboarding (30 seconds)
```
Welcome! Logical fallacies are tricks that manipulate you.
Watch real debates, press button when you spot your fallacy.
Like a spelling bee - everyone improves.

1️⃣ GET ASSIGNED → 2️⃣ WATCH & SPOT → 3️⃣ LEARN & IMPROVE
```
Alex: "Simple enough."

### 3. First Fallacy Assignment
```
YOUR FIRST FALLACY: AD HOMINEM
[Icon: Silhouette with ?]

Attacking the person, not the argument

EXAMPLE: "Don't listen to her healthcare ideas - 
she's never held a real job"

WHY FALLACIOUS: Background doesn't determine 
whether logical argument is sound

WATCH FOR: Character attacks, questioning motives

[I UNDERSTAND - START]
```
Alex: "Okay, attack the person. I've heard of this."

### 4. First Clip
**Video**: Indiana Gubernatorial Debate, 2:45

- **0:47**: "She's never run a business. How can we trust her plan?"
  - Alex: "That's attacking her background!" *Presses button*
  - **Green flash. +10 XP. Chime.**
  - Alex: "Yes!"

- **1:23**: Borderline moment, Alex hesitates, moment passes

- **1:58**: Clear Ad Hominem, Alex presses again. **+10 XP**

- Video ends → Retro screen

### 5. First Retro
```
ROUND COMPLETE - NICE JOB!
Score: +20 XP | Accuracy: 67% (2 of 3)

✓ HITS: 2
• @ 0:47 "Questioned credentials instead of policy"
• @ 1:58 "Dismissed based on background"

⊘ MISSED: 1
• @ 1:23 "Subtle - implied education made them 
  'out of touch' vs addressing substance"
  [▶ Replay] [📖 Study This]

FIRST CHALLENGE COMPLETE! 🎉
Keep playing to unlock more fallacies.

[PLAY NEXT CHALLENGE]
```

Alex: "2 out of 3, not bad. Let me see that missed one..." *Replays*
"Ohh, I see it now. Okay." *Plays 2 more challenges, gets better each time*

By challenge 3, accuracy at 80%. She's hooked.

---

## Content Creation Manual

### Clip Selection Criteria

**Duration**: 2-3 minutes max
**Audio**: Clear, comprehensible
**Type**: Debates, speeches, interviews, testimony, forums
**Source**: Public (YouTube, C-SPAN, gov sites), no copyright issues
**Diversity**: Mix speakers, topics, don't cluster on one person
**Fallacy Density**: 5-10 instances, mixed difficulty

### v1 Content Sources (Bloomington/Indiana Focus)

**Why Local/State**: Reduces partisan heat, relevant to IU students, still contains ample fallacies

**Primary Sources**:
1. **2024 IN Gubernatorial Debate** (15 clips from single 60-min debate)
2. **Bloomington City Council** (10 clips - zoning, budget, development)
3. **Indiana General Assembly** (5 clips - committee hearings, floor debates)

**Launch Target**: 30 clips (1 month of daily challenges)

### Tagging Protocol

**Two-Person Validation** (Chris + collaborator):
1. Watch once (note general impressions)
2. Watch again pausing (identify specific instances with timestamps)
3. Validate each tag ("Can we defend this?")
4. Assign confidence: High / Medium / Low
5. Document in JSON

**Quality Standard**: Better to under-tag than over-tag

### JSON Structure
```json
{
  "clip_id": "indiana_gov_2024_economy_01",
  "title": "IN Gubernatorial Debate - Economy",
  "video_url": "https://youtube.com/...",
  "duration": "2:45",
  "speakers": ["McCormick", "Braun", "Rainwater"],
  "fallacies": [
    {
      "type": "Strawman",
      "tier": 1,
      "start_time": "0:47",
      "end_time": "0:52",
      "confidence": "High",
      "speaker": "McCormick",
      "explanation": "Characterizes 'Republican control' as monolith that 'ignores local needs,' oversimplifying complex structure",
      "quote": "Republican control ignores local needs...",
      "teaching_note": "Watch for complex position reduced to extreme version"
    }
  ]
}
```

### Confidence Levels
- **High**: Textbook example, use for scoring
- **Medium**: Arguable but defensible, mark "disputed" later
- **Low**: Edge case, don't score, include educationally

### Content Calendar (4-Week Arc)
- **Week 1**: Easy Tier 1 (confidence building)
- **Week 2**: Mix Tier 1 + Tier 2 (transition)
- **Week 3**: Balanced across tiers
- **Week 4**: Advanced Tier 1, heavy Tier 2, intro Tier 3

---

## Visual Design

### Colors
- **Base**: Black/white
- **Inform Accent**: Yellow (#FED12E) - buttons, highlights, progress
- **Success**: Green (#4CAF50) - correct hits
- **Error**: Red (#F44336) - false positives (sparingly)
- **Neutral**: Gray (#757575) - inactive/locked

### Typography
- **Font**: Manrope
- **H1**: 32px Bold (titles)
- **H2**: 24px Bold (sections)
- **Body**: 16px Regular
- **Buttons**: 16px Medium

### Button States
**Active (Assigned)**:
- 3px yellow border
- White + 10% yellow tint background
- Full color icon, 100% opacity
- Subtle yellow glow
- 100×100px (desktop), 80px (tablet), 70px (mobile)

**Inactive (Unassigned)**:
- 1px gray border
- Light gray background
- Grayscale icon, 40% opacity
- Not clickable

**Correct Hit**:
- Green flash (0.2s)
- "+10 XP" floats up
- Confetti particles
- Soft chime

**False Positive**:
- Red shake (horizontal ±5px, 0.3s)
- "-5 XP" appears
- Muted error tone

### Responsive Design
- **Desktop (1024px+)**: 70% video width, buttons below, 100px
- **Tablet (768-1023px)**: 85% video, 2 rows buttons if needed, 80px
- **Mobile (<768px)**: Full width video, 2-3 buttons per row, 70px

---

## Technical Requirements

### Tech Stack
- **Frontend**: React (recommended) or vanilla HTML/CSS/JS
- **Video**: HTML5 `<video>` with custom controls
- **State**: React hooks (no Redux needed)
- **Styling**: Tailwind or custom CSS Grid/Flexbox
- **Icons**: Custom SVG (24 fallacy icons)
- **Storage (v1)**: Browser localStorage (anonymous play)
- **Hosting**: Netlify/Vercel/GitHub Pages
- **Video Hosting**: YouTube embeds (v1), self-host later

### Core Components
```
<App>
  <Router>
    <LandingPage />
    <GameController>
      <VideoPlayer />
      <FallacyButtonBar />
      <ScoreDisplay />
    </GameController>
    <RetroScreen>
      <StatsPanel />
      <VideoTutorialPanel />
    </RetroScreen>
    <DailyChallenge>
      <CalendarView />
      <ProgressTracker />
    </DailyChallenge>
    <FallacyLibrary />
  </Router>
</App>
```

### Data Flow
1. Load clip library JSON, check localStorage for progress
2. Assign fallacies based on tier
3. Track button presses with timestamps
4. Validate against clip metadata
5. Calculate XP, update localStorage
6. Check for tier unlock
7. Show retro screen

### LocalStorage Schema
```json
{
  "user_id": "uuid",
  "current_tier": 1,
  "total_xp": 180,
  "unlocked_fallacies": ["ad_hominem", "strawman", ...],
  "completed_clips": [
    {
      "clip_id": "...",
      "date": "2026-02-03",
      "assigned": ["ad_hominem"],
      "correct": 3,
      "false_positives": 1,
      "misses": 1,
      "xp_earned": 25,
      "accuracy": 0.75
    }
  ],
  "per_fallacy_stats": {
    "ad_hominem": {
      "encountered": 12,
      "spotted_correctly": 9,
      "accuracy": 0.75
    }
  }
}
```

### Accessibility
- **Keyboard**: Tab, Space, Arrows for controls
- **Screen Reader**: Announce state changes
- **Color**: Don't rely on color alone (add text/icons/sound)
- **Contrast**: WCAG AA compliance (4.5:1 minimum)
- **Focus**: Clear yellow outlines
- **Motion**: Respect `prefers-reduced-motion`

---

## 8-Week Implementation Roadmap

### Phase 1: Foundation (Weeks 1-2)
**Week 1**: Project setup, video player, button interface
- Days 1-2: Initialize React, routing, localStorage utils
- Days 3-4: Build VideoPlayer with custom controls
- Day 5: Create FallacyButton component with states

**Week 2**: Scoring logic, feedback, retro screen
- Days 1-2: Timestamp validation, XP calculation
- Days 3-4: Build RetroScreen with breakdowns
- Day 5: Add animations (flash, shake, float), sounds

**Deliverable**: Complete single-round experience

### Phase 2: Content & Progression (Weeks 3-4)
**Week 3**: Tag clips, integrate
- Days 1-3: Tag first 6 clips (debate excerpts)
- Days 4-5: Build clip loading system, test all 6

**Week 4**: Progression system
- Days 1-2: Tier unlocking logic, XP tracking
- Day 3: Fallacy assignment algorithm
- Days 4-5: Build Fallacy Library UI

**Deliverable**: Tier 1→2 progression with 10 fallacies

### Phase 3: Daily Challenge & Content (Weeks 5-6)
**Week 5**: Daily challenge
- Days 1-2: Calendar UI, completion status
- Day 3: Date-based rotation logic
- Days 4-5: Progress dashboard, stats

**Week 6**: Content sprint
- Days 1-5: Tag remaining 24 clips (30 total)

**Deliverable**: 30 clips for 1 month

### Phase 4: Polish & Launch (Weeks 7-8)
**Week 7**: Polish
- Days 1-2: Visual design pass, responsive
- Day 3: Onboarding flow
- Days 4-5: Accessibility audit

**Week 8**: Testing & launch
- Days 1-2: Bug fixes, optimization
- Day 3: User testing (5-10 alphas)
- Day 4: Iterate on feedback
- Day 5: Deploy to production

**Deliverable**: Production-ready v1

---

## Success Metrics

### Educational Effectiveness
- ✓ 70%+ improve accuracy from clip 1→10
- ✓ Players explain fallacies in own words
- ✓ 60%+ return for 5+ daily challenges

### User Experience
- ✓ 80%+ complete first clip
- ✓ 10-15 min avg session
- ✓ <20% abandon mid-clip

### Content Quality
- ✓ 90%+ tags high confidence
- ✓ 75%+ rate explanations "helpful"
- ✓ 60-75% avg accuracy (balanced difficulty)

### Technical Performance
- ✓ <3s page load
- ✓ <2s video start
- ✓ <1% button errors

### Data to Track
- **Engagement**: DAU, clips completed, time spent, return rates, streaks
- **Learning**: Accuracy by fallacy, improvement over time, false positive rate
- **Content**: Most/least played clips, highest/lowest accuracy clips
- **Progression**: Time to unlock tiers, distribution across tiers

### User Testing (Week 8)
**Alpha (5-10 users)**:
- Observational session (30 min watch them play)
- Semi-structured interview (15 min)
- Quantitative survey (rate clarity, helpfulness, enjoyment)

**Beta (Week 9+, 50-100 users)**:
- Track metrics, weekly surveys, feedback sessions

### Iteration Criteria
**Revise clip if**: <40% or >90% accuracy, high abandonment
**Revise explanation if**: Users ask similar questions, rated "not helpful"
**Adjust progression if**: Users stuck at tier or blow through too fast

---

## Future Vision (v2+)

### Multiplayer Features
- Team-based bar trivia format
- Voice comms for digital play
- Collaborative spotting ("Hey Jamie, watch for Strawman here")
- Prevents quarterbacking via "ping but don't tell" mechanics
- Team leaderboards, competitive modes

### Live Event Integration
- Symposiums real-time fallacy spotting
- Audience participation during live debates
- Aggregate data = community "bullshit detector"

### Content Expansion
- User-submitted clips (Empowered Accounts)
- Community validation (upvote/downvote)
- AI-assisted tagging (human validation required)
- 100+ clips, diverse sources, topic collections

### Platform Integration
- Arbiter role unlocking (Fallacy Finders mastery required)
- Awareness Exchange (fallacy use impacts credibility)
- Common Grounds (mediators trained via FF)

### Advanced Features
- Custom difficulty (choose # fallacies to track)
- Expert mode (spot all 24 simultaneously)
- Marathon mode, time trials
- Personalized learning (adaptive difficulty, spaced repetition)
- Classroom mode (teacher dashboard, assignments, student tracking)

---

## Design Philosophy Summary

**Core Insight**: "Searching for shared solutions requires honest discourse. You cannot manipulate or deceive when looking for a shared solution. On our platform, repeated logical fallacy use reflects poorly on those drenching solutions with manipulation. But this only works if enough people can spot these tactics."

**Educational Model**: Like a spelling bee—not everyone wins, but everyone who competes becomes better. Games teach esoteric concepts effectively because they make learning matter for success.

**Anti-Partisan Approach**: Focus on individual speakers, not political parties. Track fallacy rates by specific politicians/pundits. Use local/state content to reduce partisan heat. Let data speak for itself without creating party scorecards.

**Supportive Learning**: No shame for misses. Missed fallacies framed as "growth opportunities." False positives explained educationally. Celebrate hits with positive reinforcement. Encourage curiosity and self-improvement mindset.

**Progressive Difficulty**: Start concrete (Ad Hominem) → Progress to structural (Begging the Question). Unlock gradually to avoid overwhelming. Higher tiers track multiple fallacies simultaneously. Calibrated for satisfying progression and mastery.

**Platform Integration**: Proficiency qualifies for Arbiter role (moderators who write Empowered Bills and facilitate Common Grounds). Repeated fallacy spotting ability creates accountability for civic leaders. Eventually applies to Symposiums and Awareness Exchange.

---

**Version**: 1.0  
**Status**: Design Complete, Ready for Implementation  
**Last Updated**: February 2026  
**Contact**: chris@empowered.vote

---

*This design document provides complete specifications for Fallacy Finders v1. All decisions grounded in Empowered.Vote's core values: evidence-based, engaging, and anti-partisan. Goal: building herd immunity to manipulative rhetoric through progressive skill-building and supportive feedback.*
