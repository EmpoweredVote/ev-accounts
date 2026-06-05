# Community Verification System: Distributed Truth Engine

**Design Document v1.0**  
**Created:** February 11, 2026  
**Organization:** Empowered Vote  
**Status:** Draft for Review

---

## Table of Contents

1. [Problem/Solution Framing](#problemsolution-framing)
2. [User Journeys](#user-journeys)
3. [Technical Specifications](#technical-specifications)
4. [Success Metrics](#success-metrics)
5. [Design Principles](#design-principles)
6. [Implementation Phases](#implementation-phases)
7. [Open Questions & Risks](#open-questions--risks)
8. [Appendices](#appendices)

---

## Problem/Solution Framing

### The Problem

Empowered Vote needs accurate, comprehensive data about elected officials at all levels of government—particularly at the local level where information is decentralized, frequently outdated, and lacks authoritative sources. Beyond officials, the platform will need to verify factual claims about policies, voting records, and civic issues as users engage in debates, annotations, and solution-finding.

**Current state challenges:**
- No single authoritative database exists for local officials (school boards, city councils, special districts)
- Officials change constantly through elections, appointments, and resignations
- Existing databases (Ballotpedia, Vote411) have incomplete local coverage
- Manual curation doesn't scale to 50,000+ positions across the U.S.
- Single-source data risks misinformation that undermines platform credibility
- AI agents can hallucinate or pull outdated information
- Traditional fact-checking is too slow and expensive for real-time civic engagement

**Why this matters:**
If we provide incorrect information about who represents someone, we damage trust and civic efficacy. If we allow false claims to circulate in debates or annotations, we undermine the platform's mission of finding broadly shared solutions. Users need confidence that information on Empowered Vote is *verifiable, verified, and constantly maintained*.

### The Solution

A **distributed verification system** where Connected Account holders participate in "verification quests"—structured scavenger hunts that ask them to research and submit factual information with sources. Multiple independent submissions create a delayed consensus engine that:

1. **Builds confidence through redundancy** (7+ aligned submissions = high confidence)
2. **Tracks veracity over time** (rewards accurate contributors, educates inaccurate ones)
3. **Creates retroactive accountability** (when consensus emerges, early correct answers are rewarded; incorrect answers trigger educational feedback)
4. **Enables contestation** (users can challenge consensus with counter-sources)
5. **Scales through gamification** (XP, Empowered Gems, difficulty tiers)

**This is platform-wide infrastructure.** The same system that verifies "Who is the Mayor of Bloomington?" will eventually verify "Did Senator X vote for Bill Y?" and "What percentage of the city budget goes to police?" The architecture supports any factual claim that can be independently confirmed.

**Core principles:**
- **Transparency:** Veracity scoring is visible; reasons for changes are documented
- **Contestability:** Users can challenge consensus with evidence
- **Forgiveness:** Accuracy can be rebuilt; mistakes don't permanently penalize
- **Privacy gradient:** Connected Accounts see own details privately; Empowered Accounts accept full transparency as accountability
- **Early mover advantage:** Reward those who get it right before consensus forms

---

## User Journeys

### Journey 1: New Connected Account - Learning the System

**Persona:** Maya, 22, just upgraded from Anonymous to Connected Account, lives in Bloomington, IN

**Entry point:** After connecting her account, Maya sees a notification: "Help us verify your local officials! Complete 5 verifications to earn your first 50 Empowered Gems."

**Step-by-step:**
1. First quest appears: "Who is your U.S. Representative?" (Easy - federal level)
   - Maya searches "Indiana 9th district representative"
   - Finds official House.gov page, submits "Erin Houchin" with source link
   - System confirms: "Submitted! Your answer is pending verification."

2. Second quest: "Who is the Mayor of Bloomington?"
   - Maya searches city website, submits "Kerry Thomson" with source
   - Three others have already submitted "Kerry Thomson" - she doesn't know this yet

3. Over next few days, completes quests for: Governor, State Senator, Monroe County Council President

4. **One week later:** Notification arrives
   - "Consensus reached on 4 of your verifications!"
   - Mayor of Bloomington: ✓ Correct (+15 gems, +20 XP, +0.3% veracity)
   - U.S. Representative: ✓ Correct (+10 gems, +15 XP, +0.2% veracity)
   - Governor: ✓ Correct (+10 gems, +15 XP, +0.2% veracity)
   - Monroe County Council President: ✗ Incorrect - You submitted "Laura Dwyer," consensus is "Julie Thomas"
     - "Here are the sources: [county website, local news]. Want to review your research process?"
   - **Bonus:** Early correct answer on Mayor (+5 gems) - "You got this right before we had high confidence!"
   - **Net veracity change:** +0.7% - 0.5% = +0.2% for the week

5. Maya's verification accuracy: 75% (3/4 correct)
   - She clicks through to see her mistake, reads the educational prompt about checking official county sites
   - Unlocks next tier of verification quests (county-level officials in neighboring areas)

**Outcome:** Maya understands the system, has earned gems/XP, learned from her mistake, saw her veracity score grow overall, and is ready for harder quests.

---

### Journey 2: Experienced Verifier - Bounty Hunting

**Persona:** James, 34, Connected Account for 6 months, 94% verification accuracy across 60 submissions

**Entry point:** Opens Empowered Vote, navigates to "Verification Bounties" board

**Step-by-step:**
1. Sees three categories of bounties:
   - **High Priority** (missing data, low confidence): +30 gems, +40 XP
   - **Standard** (needs additional verification): +15 gems, +20 XP  
   - **Expert** (complex positions, conflicting sources): +50 gems, +60 XP

2. Selects Expert bounty: "Who is the Superintendent of Plano Independent School District, TX?"
   - System shows: "⭐⭐⭐⭐⭐ Expert difficulty"
   - No mention that AI sources had conflicts

3. James researches thoroughly:
   - Finds official PISD board meeting minutes with signature: "Theresa J. Williams, Ed.D."
   - Checks district press releases: consistently "Theresa"
   - Submits "Theresa Williams" with three authoritative source links

4. **Two days later:** Consensus reached
   - 9 total submissions, 85% now say "Theresa Williams"
   - James gets full Expert bounty (+50 gems, +60 XP, +0.5% veracity)
   - His veracity score rises to 95% (61/64 correct)
   - Those who submitted "Teresa" get feedback: "Close! The official spelling is 'Theresa.' Here are authoritative sources."

5. James now qualifies for "Master Verifier" badge, which:
   - Weights his future submissions more heavily (counts as 1.5x toward consensus)
   - Unlocks highest-tier bounties (judicial appointments, special district boards)
   - Gives him occasional "spot check" quests (verify existing high-confidence data)

**Outcome:** Experienced users are rewarded for accuracy and tackle the hardest verification challenges.

---

### Journey 3: Contested Verification - Learning, Not Punishment

**Persona:** Sofia, 28, Empowered Account, 82% verification accuracy across 120 submissions over 60 days of engagement

**Entry point:** Morning notification bundle (weekly summary)

**Step-by-step:**

1. **Weekly Verification Summary arrives:**
   - "5 of your verifications reached consensus this week!"
   
2. **The results:**
   - ✓ San Antonio City Council District 5: Correct (+0.3%)
   - ✓ Bexar County Judge: Correct (+0.3%)
   - ✓ Texas State Rep District 121: Correct (+0.3%)
   - ✗ San Antonio City Council District 3: Incorrect (submitted "John Martinez," consensus is "Phyllis Viagran")
   - ✓ San Antonio ISD Superintendent: Correct (+0.3%)

3. **Net impact on veracity:**
   - 4 correct verifications: +1.2%
   - 1 incorrect: -1.0% (before acknowledgment)
   - **Current status:** 123/125 = 82.4% (↑0.4% from last week!)

4. **Sofia clicks into the incorrect one:**
   - Sees her source (2022 campaign site) vs. consensus sources (2024 city website, recent news)
   - Acknowledges: "Used outdated source, should have checked current roster"
   - **Adjusted impact:** -0.5% instead of -1.0%
   - **Final veracity:** 82.9% (↑0.9% for the week)

5. **What Sofia experiences:**
   - "Great week! Your veracity improved by 0.9%"
   - "You correctly verified 4 officials and learned from 1 outdated source"
   - Helpful tip appears (not scolding): "Pro tip: Official government sites update faster than campaign pages"

6. **Sofia can view her full verification history:**
   - Clicks "View Verification History" on her own profile
   - Sees all 19 incorrect verifications with full details
   - Each shows: her answer, consensus answer, sources, her acknowledgment/context
   - **Because she's Empowered:** This history is also publicly visible to others

**Outcome:** Veracity is a dynamic score that grows with good work. Mistakes are speed bumps, not roadblocks.

---

### Journey 3B: Pattern Recognition - When Mistakes Become Concerning

**Persona:** Marcus, 31, Connected Account, started strong but recent pattern is troubling

**Timeline:**
- **Month 1:** 45 submissions, 93% accuracy (excellent start)
- **Month 2:** 38 submissions, 89% accuracy (still good)
- **Month 3:** 52 submissions, 71% accuracy (concerning decline)
  - **This week alone:** 15 submissions, 9 incorrect (60% accuracy)
  - **Yesterday:** 4 submissions, 3 incorrect

**System response - graduated escalation:**

1. **After week of low accuracy:**
   - Gentle notification: "We noticed your recent verifications have had more conflicts than usual. Would you like tips on verification best practices?"
   - No penalties yet - maybe Marcus is just rushing or researching new, harder topics

2. **After 3 incorrect submissions in one day:**
   - Stronger notification: "Your verification accuracy has dropped significantly today. We're pausing new quests until you review your recent submissions."
   - Marcus must review the 3 incorrect ones, see the correct answers and sources
   - After review, he can resume (no permanent penalty)

3. **Pattern continues for 2 more days (9 incorrect in 3 days):**
   - "We're concerned about the pattern of incorrect submissions. Your veracity has dropped to 78%."
   - "Options: (1) Take our Verification Best Practices course to reset, or (2) Contest specific submissions with evidence"
   - Limited to 5 verifications per day until accuracy improves to 85%

4. **If Marcus engages positively:**
   - Takes the course, slows down, checks sources more carefully
   - Accuracy climbs back to 85% over next 2 weeks
   - Restrictions lift, old errors begin to decay (older than 30 days count 50% less toward score)
   - **Result:** Redeemed contributor, learned better practices

5. **If Marcus ignores feedback and continues poor submissions:**
   - After 30 incorrect in a month while under restriction:
   - "Your submission pattern suggests unreliable research. Verification quests are paused for 30 days."
   - Can still use platform, just can't contribute to verification system
   - Can appeal with explanation or evidence

**The key difference:** 
- Sofia's single mistake in a week of good work: -0.5%, educational tip, no restrictions
- Marcus's 9 mistakes in 3 days after weeks of declining accuracy: Progressive restrictions, required education

**Outcome:** System distinguishes honest mistakes from problematic patterns. Redemption is always possible.

---

### Journey 4: AI-Led Prototype - Los Angeles County Officials

**Context:** Empowered Vote is launching verification system with Los Angeles as proof-of-concept

**Why LA:**
- 88 incorporated cities (tests scale)
- Well-documented officials (good AI sources)
- Large user base (human verifiers available)
- Multiple levels: Federal, State, County, City, School Districts, Special Districts

**Phase 1: AI Initial Population (Week 1)**

1. **Claude and other AI agents receive structured tasks:**
   - All LA County Board of Supervisors (5 positions)
   - All mayors of 88 cities
   - All LA Unified School District board members (7 positions)
   - All State Assembly/Senate members representing LA (partial coverage of CA legislature)
   - Sample of city council members (focus on 10 largest cities initially)

2. **AI verification process:**
   - Each AI searches independently (different search strategies, sources)
   - Submits official name, title, sources (minimum 2 sources required)
   - AI submissions tagged as "AI-verified, awaiting human confirmation"
   - **Result:** ~200 positions populated in 3 days

3. **Initial confidence levels:**
   - High-profile positions (County Supervisors, LA Mayor): 3-4 AI agents agree immediately = 85% confidence
   - Mid-profile (mayors of mid-size cities): 2-3 AI agents agree = 60% confidence
   - Low-profile (small city council members): AI sources conflict or sparse = 30% confidence

**Phase 2: Human Verification Quests (Week 2-4)**

4. **Connected Accounts in LA region see targeted quests:**

**Quest presentation is neutral:**

✗ **Bad (what we're NOT doing):**
- "AI agents found this answer, can you confirm?"
- "AI sources disagree—who is the current mayor?"

✓ **Good (what we ARE doing):**
- "Who is the Mayor of Torrance, CA?"
- "Who represents District 3 on the San Antonio City Council?"
- Difficulty indicator: ⭐⭐ (Medium - local official)
- Reward: +15 gems, +20 XP

5. **Quest prioritization happens invisibly:**
   - Backend knows: AI had conflicts on Torrance Mayor → priority queue
   - Backend knows: AI agreed on LA Mayor → standard queue  
   - Backend knows: Small city council has no AI data yet → high priority
   - **Users just see:** "Verify your local officials" with gem rewards
   
6. **Example flow for user:**
   - Maya in Torrance sees quest: "Who is the Mayor of Torrance, CA?"
   - She researches independently (doesn't know 2 AI said "Furey," 1 said "Chen")
   - Submits: "Patrick J. Furey" with city website source
   - System: "Submitted! Your answer is pending verification."
   
7. **Behind the scenes consensus building:**
   - AI submissions: 2 for "Furey," 1 for "Chen"
   - Human submissions: Maya + 4 others all submit "Furey"
   - **Final tally:** 7 submissions (2 AI + 5 human), 6 agree = 86% alignment
   - Consensus declared: "Patrick J. Furey" = HIGH CONFIDENCE
   - **Human participation:** 71% (meets the 40% minimum)

8. **What users see when consensus forms:**
   - "Your answer for Torrance Mayor was correct! +15 gems, +20 XP"
   - "+5 bonus gems - you verified this before we had high confidence!"
   - **No mention of AI involvement unless they dig into stats**

9. **Optional transparency (if user requests):**
   - User clicks "How was this verified?"
   - Sees: "7 independent verifications, 86% alignment"
   - Can expand: "2 AI agents, 5 human researchers"
   - Can see sources: [city website, local news, official bio page]
   - **But this is opt-in, not default**

**Phase 3: Validation & Learning (Week 4-8)**

10. **Spot checks by Empowered Vote staff:**
    - Random sample of 20 "high confidence" positions manually verified
    - Success rate: 95% (19/20 correct)
    - One error found: AI + humans all missed that a mayor resigned mid-term
    - **Learning:** Add "last verified date" field, implement re-verification quests for recent positions

11. **AI accuracy tracking:**
    - Claude: 89% accuracy (178/200 positions)
    - Other AI agents: 82-91% accuracy range
    - Common AI errors: Interim vs. permanent appointments, recent resignations, name formatting
    - **Result:** AI accuracy stats inform future AI weights and strategies

12. **System tuning:**
    - Discover 2 AI + 3 humans is usually sufficient for high confidence on straightforward positions
    - But special districts and appointed positions need 5+ human verifications (AI sources too sparse)
    - Implement rule: Consensus requires minimum 40% human participation (can't be 10 AI + 1 human)

**Phase 4: Expansion & Maintenance (Ongoing)**

13. **LA database is now living system:**
    - 200 positions at high confidence
    - Daily AI sweeps check for changes (news mentions of resignations, elections)
    - Quarterly re-verification quests for all positions
    - Users can flag "This might be outdated" to trigger urgent re-verification

14. **Template for other regions:**
    - LA success proves model works
    - Next targets: Bloomington IN (smaller, test rural/small city dynamics), then expand
    - AI-human ratio and confidence thresholds may adjust by region size

**Outcome:** AI accelerates initial data collection, humans provide verification and catch edge cases, system learns optimal AI-human balance.

---

## Technical Specifications

### Data Models

**Verification Quest**
```json
{
  "quest_id": "uuid",
  "quest_type": "official | fact | policy",
  "question": "string",
  "difficulty_tier": "1-5",
  "reward_gems": "integer",
  "reward_xp": "integer",
  "geographic_scope": {
    "country": "string",
    "state": "string",
    "county": "string",
    "city": "string",
    "district": "string"
  },
  "priority_level": "high | standard | low",
  "created_date": "timestamp",
  "status": "active | consensus_reached | under_review | archived",
  "metadata": {
    "position_title": "string",
    "jurisdiction": "string",
    "related_quests": ["uuid"]
  }
}
```

**Verification Submission**
```json
{
  "submission_id": "uuid",
  "quest_id": "uuid",
  "submitter_id": "uuid",
  "submitter_type": "human_connected | human_empowered | ai_agent",
  "answer": "string",
  "sources": [
    {
      "url": "string",
      "source_type": "official_gov | news | database | other",
      "retrieved_date": "timestamp",
      "description": "string"
    }
  ],
  "submission_date": "timestamp",
  "confidence_self_reported": "1-5 (optional)",
  "status": "pending | ratified | challenged | contested",
  "metadata": {
    "time_spent_researching": "integer (seconds)",
    "search_queries_used": ["string (optional)"]
  }
}
```

**Consensus Record**
```json
{
  "consensus_id": "uuid",
  "quest_id": "uuid",
  "consensus_answer": "string",
  "confidence_level": "high | moderate | low | conflicting",
  "total_submissions": "integer",
  "alignment_percentage": "float",
  "submission_breakdown": {
    "human_count": "integer",
    "ai_count": "integer",
    "human_percentage": "float"
  },
  "answer_distribution": [
    {
      "answer": "string",
      "count": "integer",
      "submitter_ids": ["uuid"]
    }
  ],
  "authoritative_sources": ["source objects"],
  "consensus_date": "timestamp",
  "last_verified_date": "timestamp",
  "status": "active | under_review | contested"
}
```

**User Veracity Profile**
```json
{
  "user_id": "uuid",
  "current_veracity_score": "float (0-100)",
  "total_submissions": "integer",
  "correct_submissions": "integer",
  "incorrect_submissions": "integer",
  "pending_submissions": "integer",
  "contested_submissions": "integer",
  
  "accuracy_by_timeframe": {
    "last_7_days": {
      "submissions": "integer",
      "accuracy": "float",
      "trend": "improving | stable | declining"
    },
    "last_30_days": "{ ... }",
    "all_time": "{ ... }"
  },
  
  "accuracy_by_difficulty": {
    "tier_1": "float",
    "tier_2": "float",
    "tier_3": "float",
    "tier_4": "float",
    "tier_5": "float"
  },
  
  "badges_earned": [
    {
      "badge_id": "uuid",
      "badge_name": "string",
      "earned_date": "timestamp"
    }
  ],
  
  "submission_weight": "float (default 1.0, increases with accuracy)",
  
  "restrictions": {
    "daily_limit": "integer (null if unrestricted)",
    "restricted_until": "timestamp (null if unrestricted)",
    "restriction_reason": "string"
  },
  
  "historical_accuracy": [
    {
      "date": "date",
      "accuracy_score": "float"
    }
  ]
}
```

**Veracity Event Log**
```json
{
  "event_id": "uuid",
  "user_id": "uuid",
  "event_type": "correct_verification | incorrect_verification | acknowledged_mistake | contested | restriction_applied | restriction_lifted | badge_earned",
  "quest_id": "uuid",
  "submission_id": "uuid",
  "previous_veracity": "float",
  "new_veracity": "float",
  "delta": "float",
  "event_date": "timestamp",
  "context": {
    "user_response": "string (if acknowledged/contested)",
    "system_action": "string",
    "decay_applied": "boolean"
  }
}
```

### Core Algorithms

**Consensus Determination Algorithm**

```python
def determine_consensus(submissions):
    """
    Determines if consensus has been reached and confidence level
    """
    # Group submissions by answer (normalize for minor variations)
    answer_groups = normalize_and_group(submissions)
    
    # Calculate human vs AI distribution
    total_submissions = len(submissions)
    human_count = sum(1 for s in submissions if s.submitter_type.startswith('human'))
    ai_count = total_submissions - human_count
    human_percentage = human_count / total_submissions if total_submissions > 0 else 0
    
    # Check minimum human participation requirement (40%)
    if human_percentage < 0.4 and total_submissions >= 5:
        return {
            'status': 'needs_more_human_verification',
            'confidence': None
        }
    
    # Find dominant answer
    dominant_answer = max(answer_groups, key=lambda x: x['count'])
    alignment = dominant_answer['count'] / total_submissions
    
    # Determine consensus status
    if total_submissions >= 13 and alignment < 0.85:
        return {
            'status': 'conflicting',
            'confidence': None,
            'flag_for_review': True
        }
    
    if total_submissions >= 7 and alignment >= 0.85:
        confidence = 'high'
    elif total_submissions >= 5 and alignment >= 0.80:
        confidence = 'moderate'
    elif total_submissions >= 4 and alignment >= 0.75:
        confidence = 'low'
    else:
        return {
            'status': 'pending',
            'confidence': None
        }
    
    return {
        'status': 'consensus_reached',
        'confidence': confidence,
        'answer': dominant_answer['answer'],
        'alignment': alignment,
        'submissions': total_submissions,
        'human_percentage': human_percentage
    }
```

**Veracity Score Update Algorithm**

```python
def calculate_veracity_delta(user_profile, verification_result, user_action):
    """
    Calculates change in veracity score based on verification result
    """
    base_impact = 0.0
    
    if verification_result == 'correct':
        # Positive impact scales with difficulty and recency
        difficulty_multiplier = quest.difficulty_tier * 0.1
        base_impact = 0.2 + difficulty_multiplier  # 0.2 to 0.7
        
        # Bonus for early correct answers (before high confidence)
        if was_early_correct(submission):
            base_impact += 0.2
        
        # Master Verifier bonus
        if user_profile.current_veracity_score >= 90:
            base_impact *= 1.5
    
    elif verification_result == 'incorrect':
        # Negative impact depends on acknowledgment and pattern
        base_impact = -1.0
        
        # Check recent error pattern
        recent_errors = count_errors_in_window(user_profile, days=7)
        
        if recent_errors == 0:  # First mistake in a week
            base_impact = -0.5
        elif recent_errors <= 2:  # Occasional mistakes
            base_impact = -0.75
        else:  # Pattern emerging
            base_impact = -1.5
        
        # Reduction for acknowledgment
        if user_action == 'acknowledged':
            base_impact *= 0.5
        elif user_action == 'contested_with_evidence':
            base_impact = 0  # No penalty until contest resolved
        elif user_action == 'ignored':
            base_impact *= 1.5
    
    # Apply time decay to old submissions
    submission_age = days_since(submission.date)
    if submission_age > 30:
        decay_factor = 0.5 if submission_age < 60 else 0.25
        base_impact *= decay_factor
    
    return base_impact

def update_veracity_score(user_id, quest_id, verification_result, user_action=None):
    """
    Updates user's veracity score and logs the event
    """
    user_profile = get_user_veracity_profile(user_id)
    submission = get_submission(user_id, quest_id)
    
    delta = calculate_veracity_delta(user_profile, verification_result, user_action)
    
    # Update counts
    if verification_result == 'correct':
        user_profile.correct_submissions += 1
    elif verification_result == 'incorrect':
        user_profile.incorrect_submissions += 1
    
    # Calculate new score
    total_weighted_submissions = (
        user_profile.correct_submissions * 1.0 +
        user_profile.incorrect_submissions * 0.0
    )
    
    new_veracity = (total_weighted_submissions / 
                    (user_profile.correct_submissions + user_profile.incorrect_submissions)) * 100
    
    # Apply delta adjustment for nuanced impact
    new_veracity += delta
    new_veracity = max(0, min(100, new_veracity))  # Clamp to 0-100
    
    # Log the event
    log_veracity_event(
        user_id=user_id,
        event_type=verification_result,
        previous_veracity=user_profile.current_veracity_score,
        new_veracity=new_veracity,
        delta=delta,
        quest_id=quest_id,
        user_action=user_action
    )
    
    # Check for pattern-based interventions
    check_and_apply_restrictions(user_profile)
    check_and_award_badges(user_profile)
    
    user_profile.current_veracity_score = new_veracity
    user_profile.save()
    
    return new_veracity
```

**Quest Prioritization Algorithm**

```python
def generate_user_quest_feed(user_id):
    """
    Generates personalized quest feed based on user location, 
    skill level, and system needs
    """
    user = get_user(user_id)
    user_profile = get_user_veracity_profile(user_id)
    
    quests = []
    
    # Priority 1: Local officials (user's own area)
    local_quests = get_quests_for_location(
        user.city, 
        user.county, 
        user.state,
        status='active'
    )
    
    # Filter by missing/low confidence data
    high_priority_local = [q for q in local_quests 
                          if q.priority_level == 'high']
    
    # Priority 2: Match difficulty to user skill
    if user_profile.current_veracity_score < 75:
        # New users get easier federal/state officials
        difficulty_range = [1, 2]
    elif user_profile.current_veracity_score < 85:
        # Intermediate users get mix
        difficulty_range = [2, 3, 4]
    else:
        # Expert users get hardest quests
        difficulty_range = [3, 4, 5]
    
    # Priority 3: System needs (bounties)
    bounties = get_bounty_quests(
        difficulty_range=difficulty_range,
        exclude_user_completed=user_id
    )
    
    # Combine and order
    quests.extend(high_priority_local[:5])  # Top 5 local priorities
    quests.extend(bounties[:10])  # Top 10 bounties
    
    # Ensure variety (don't show all same jurisdiction)
    quests = diversify_quest_list(quests)
    
    return quests[:15]  # Return top 15
```

**Submission Weight Calculation**

```python
def calculate_submission_weight(user_profile):
    """
    Determines how much a user's submission counts toward consensus
    """
    base_weight = 1.0
    
    # Veracity multiplier
    if user_profile.current_veracity_score >= 95:
        veracity_multiplier = 1.5  # Master Verifier
    elif user_profile.current_veracity_score >= 90:
        veracity_multiplier = 1.3
    elif user_profile.current_veracity_score >= 85:
        veracity_multiplier = 1.1
    elif user_profile.current_veracity_score >= 70:
        veracity_multiplier = 1.0
    else:
        veracity_multiplier = 0.8  # Lower confidence submissions
    
    # Experience multiplier
    if user_profile.total_submissions >= 500:
        experience_multiplier = 1.2
    elif user_profile.total_submissions >= 200:
        experience_multiplier = 1.1
    else:
        experience_multiplier = 1.0
    
    # Recent pattern adjustment
    recent_accuracy = user_profile.accuracy_by_timeframe['last_7_days']['accuracy']
    if recent_accuracy < 70:
        pattern_multiplier = 0.7  # Recent decline
    else:
        pattern_multiplier = 1.0
    
    final_weight = base_weight * veracity_multiplier * experience_multiplier * pattern_multiplier
    
    # AI agents always 1.0 (equal participant)
    if user_profile.user_type == 'ai_agent':
        final_weight = 1.0
    
    return final_weight
```

### Database Architecture

**Primary Tables:**
- `verification_quests` - All verification tasks
- `verification_submissions` - User/AI submissions
- `consensus_records` - Confirmed answers
- `user_veracity_profiles` - User accuracy tracking
- `veracity_event_logs` - Audit trail of all changes
- `quest_assignments` - Which users see which quests

**Indexes:**
- `idx_quests_location` - (country, state, county, city) for geographic queries
- `idx_submissions_quest` - Fast lookup of all submissions for a quest
- `idx_submissions_user` - User submission history
- `idx_consensus_confidence` - Find low-confidence entries needing verification
- `idx_veracity_score` - Quick user ranking/filtering

**Caching Strategy:**
- Quest feeds cached per user (15 min TTL)
- Consensus results cached (until new submission arrives)
- User veracity scores cached (5 min TTL, invalidate on update)

---

## Success Metrics

### Primary Metrics (Platform Health)

**Coverage Metrics:**
- **Total officials indexed**: Target 50,000+ positions across all levels
- **High-confidence coverage**: % of indexed positions with high confidence rating
  - Target: 80% within 12 months
- **Geographic distribution**: % of US population with local officials indexed
  - Target: 90% within 18 months
- **Recency**: % of high-confidence entries verified within last 90 days
  - Target: 95%

**Accuracy Metrics:**
- **Spot-check accuracy**: Random sample manual verification
  - Target: 95%+ accuracy on high-confidence entries
  - Target: 85%+ accuracy on moderate-confidence entries
- **User-reported errors**: Flagged incorrect data per 1000 entries
  - Target: <5 per 1000
- **Time to correction**: How quickly errors are fixed after being flagged
  - Target: <7 days median

**Consensus Quality:**
- **Consensus formation rate**: % of quests reaching consensus within 30 days
  - Target: 85%
- **Human participation rate**: % human contribution across all consensuses
  - Target: 50-60% (balanced AI-human)
- **Conflict resolution time**: Days to resolve "conflicting" status quests
  - Target: <14 days median

### User Engagement Metrics

**Participation:**
- **Active verifiers**: Users completing ≥1 quest per week
  - Target: 15% of Connected Accounts
- **Quest completion rate**: % of assigned quests completed
  - Target: 60%
- **Retention**: % of users active in verification after 30, 60, 90 days
  - Target: 50% at 30d, 35% at 60d, 25% at 90d
- **Daily active verifiers**: DAU specifically for verification quests
  - Target: 5% of total DAU

**Quality of Participation:**
- **Average veracity score**: Mean score across all active verifiers
  - Target: 82%+
- **Distribution of veracity**: Healthy bell curve vs. bimodal
  - Target: Normal distribution centered at 80-85%
- **Master Verifier rate**: % of users achieving 90%+ accuracy
  - Target: 10-15% of active verifiers
- **Improvement rate**: % of users whose veracity improves over time
  - Target: 60%+

**User Experience:**
- **Time to first reward**: Days until user sees first consensus confirmation
  - Target: <7 days
- **Quest difficulty satisfaction**: User surveys on quest difficulty matching
  - Target: 75% say "just right" difficulty
- **Educational intervention effectiveness**: Accuracy improvement after education
  - Target: 10+ percentage point improvement within 30 days

### System Efficiency Metrics

**AI Performance:**
- **AI accuracy rate**: % of AI submissions that match consensus
  - Current baseline: 85-90%, Target: 90%+
- **AI-human agreement rate**: When AI and humans both verify, % agreement
  - Target: 90%+
- **AI cost per verification**: Compute cost for AI submission
  - Monitor for optimization opportunities

**Operational:**
- **Quest generation speed**: Time from identifying gap to active quest
  - Target: <1 hour automated, <24 hours manual review
- **Staff review burden**: Hours per week spent on conflict resolution
  - Target: <10 hours/week at scale
- **False positive rate**: Quests flagged for review that don't need it
  - Target: <15%

### Business Impact Metrics

**Platform Integration:**
- **Verification-to-feature usage**: % of users who verify officials then use related features
  - (e.g., verify mayor → participate in Civil Civics for that city)
  - Target: 40%+
- **Data usage**: How often official data is accessed/displayed in platform
  - Track pageviews, API calls, annotation references
- **Account upgrade correlation**: Does verification participation correlate with Connected→Empowered upgrades?
  - Hypothesis: Yes, measure correlation coefficient

**Trust & Credibility:**
- **User trust in data**: Survey question "I trust the official information on Empowered Vote"
  - Target: 80%+ agree/strongly agree
- **Error reporting rate**: Users actively flagging potential errors (sign of engagement)
  - Target: 5-10 flags per 1000 entries (healthy skepticism)
- **External validation**: Third-party audits, fact-checker partnerships
  - Target: Annual audit with 95%+ accuracy confirmation

---

## Design Principles

### 1. Truth Over Speed

**Principle:** Accurate information is more valuable than fast information. We optimize for correctness, not velocity.

**Implications:**
- Delayed consensus is acceptable; immediate wrong answers are not
- "Pending verification" is a valid state users should understand and accept
- We won't pressure users to complete quests quickly if it compromises research quality
- Time limits on quests are about freshness, not speed

**Example:** A quest for "Mayor of Springfield" stays pending for 2 weeks until sufficient independent verification, rather than declaring premature consensus.

### 2. Redemption Is Always Possible

**Principle:** Mistakes should be learning opportunities, not permanent marks. Users can always rebuild credibility through good work.

**Implications:**
- Veracity scores decay over time (old mistakes count less)
- Restrictions are temporary, not permanent
- Education is offered before punishment
- Acknowledged mistakes are treated more leniently than ignored ones
- Path from 60% accuracy back to 90% is clearly achievable

**Example:** Marcus (from Journey 3B) can complete verification training and rebuild his score over 6-8 weeks of careful work.

### 3. Transparency With Context

**Principle:** Users deserve to know how the system works, but transparency shouldn't create bias or anxiety.

**Implications:**
- Consensus process is explainable on request
- Veracity calculations are documented and visible
- AI participation is acknowledged but not emphasized in quest presentation
- Users see their own detailed stats; others see appropriate summary based on account type
- System changes are communicated clearly

**Example:** Quest interface doesn't mention "AI disagrees" but users can click through to see all submission sources if curious.

### 4. Community Wisdom Over Individual Authority

**Principle:** No single voice—human or AI—is the final arbiter. Truth emerges from independent convergence.

**Implications:**
- Consensus requires multiple independent verifications
- Even Master Verifiers don't get unilateral authority
- Staff overrides are rare and documented
- AI agents are participants, not oracle sources
- User disagreement with consensus is valued (might reveal new information)

**Example:** Even if a Mayor personally submits "I am the mayor," the system still requires independent community verification.

### 5. Local Knowledge Has Value

**Principle:** Geographic proximity often correlates with better information quality for local officials.

**Implications:**
- Users see their own locality prioritized in quest feeds
- "I verified my own mayor" gets bonus recognition
- Local news is considered alongside official sources
- Community members might catch nuances outsiders miss
- But distance doesn't disqualify (anyone can verify anywhere)

**Example:** Bloomington resident verifying Bloomington mayor likely has fresher information than someone across the country.

### 6. Scale Through Gamification, Not Obligation

**Principle:** Verification participation should feel rewarding and optional, never mandatory or burdensome.

**Implications:**
- Gems, XP, badges make verification fun
- Daily quests suggest but don't require
- No penalties for not participating (only for participating poorly)
- Quest difficulty scales to user skill level
- Social recognition for high-accuracy contributors

**Example:** Quest feed says "5 new quests available" not "You must complete these quests."

### 7. Human-AI Collaboration, Not Competition

**Principle:** AI and humans have complementary strengths. The goal is productive collaboration, not replacement.

**Implications:**
- AI accelerates initial data collection
- Humans validate and catch edge cases
- Neither is privileged in consensus calculation
- System learns from both AI and human patterns
- Users aren't threatened by AI participation

**Example:** LA prototype shows AI populating 200 positions quickly, then humans refining and confirming.

### 8. Contestation Is Healthy

**Principle:** Users who challenge consensus might be right. Dissent should be welcomed, not discouraged.

**Implications:**
- Easy mechanism to contest with evidence
- Contested entries re-open for verification
- No penalties for good-faith challenges
- System tracks "reversals" (times consensus changed after contest)
- Culture celebrates users who caught errors

**Example:** A user contests "John Smith" with evidence it's actually "John Smith Jr." and provides updated source. Consensus re-opens.

### 9. Privacy Proportional to Stakes

**Principle:** Higher privileges (Empowered status) come with appropriate transparency. But Connected users maintain privacy from others while still having full access to their own detailed history.

**Implications:**
- **Connected Account** (viewing own profile): Full interactive transparency - see all mistakes, contexts, contests
- **Connected Account** (viewing someone else's profile): Aggregate only - just overall accuracy percentage
- **Empowered Account** (viewing own profile): Full interactive transparency (same detail as Connected)
- **Empowered Account** (viewing someone else's profile): Full interactive transparency - accountability is public
- **Anonymous**: No verification participation (stakes too high)
- **Staff/moderators**: Highest transparency standards

**Example - Connected Account (Maya viewing her own profile):**
```
Maya Thompson
Connected Account
Verification Accuracy: 87% (↑1.2% this week)
67 total verifications: 57 correct | 9 incorrect | 1 contested

[View Verification History] ← Full access to all details
```
✓ Can see all 9 incorrect verifications with full context
✓ Can see her contested verification and reasoning
✓ Can click through and learn from her mistakes
✓ Gets all the educational benefit

**Example - When James (another Connected user) views Maya's profile:**
```
Maya Thompson
Connected Account
Verification Accuracy: 87%
67 verifications completed
```
✗ Cannot see which verifications were incorrect
✗ Cannot see her contexts or reasoning
✗ Just sees aggregate credibility signal

**Example - Empowered Account (Sofia viewing own or others viewing Sofia):**
```
Sofia Rodriguez
Empowered Account
Verification Accuracy: 82.9% (↑0.9% this week)
123 total verifications: 102 correct | 19 incorrect | 2 contested

[View Verification History] ← Anyone can click and see full details
```

**When clicking "View Verification History" on Empowered Account:**

**Incorrect Verifications (19)** [Expanded by default]

Each entry shows:
```
❌ San Antonio City Council, District 3
Your answer: John Martinez
Consensus answer: Phyllis Viagran (11 submissions, 91% alignment)
Your source: Martinez2022Campaign.com (campaign website)
Consensus sources: SanAntonio.gov, KSAT News (Jan 2025)

Date submitted: Jan 15, 2025
Consensus reached: Jan 22, 2025
Your response: ✓ Acknowledged
Context: "Used outdated campaign site, should have checked current council roster"

Impact: -0.5% veracity (acknowledged quickly)
```

**Contested Verifications (2)** [Expanded by default]
```
⚖️ Travis County Commissioner, Precinct 4
Your answer: Margaret Gómez
Current consensus: Margaret Gomez (8 submissions, 88% alignment)
Your source: Official county newsletter (PDF, Dec 2024)
Consensus sources: TravisCounty.gov, Austin American-Statesman

Date submitted: Dec 20, 2024
Your contest filed: Jan 3, 2025
Your reasoning: "The official county documents spell her name with an accent (Gómez). 
I've provided a PDF from the county showing her signature and official correspondence 
all use the accent. This is her legal name spelling."

Status: Under Review by Empowered Vote staff
Additional evidence: county_newsletter_dec2024.pdf, board_minutes_signature.pdf

[Current discussion: 3 other users have submitted evidence supporting "Gómez" 
with accent. Consensus may be updated.]
```

**Why This Balance Works:**

**Learning without exposure:**
- Connected users get full educational benefit from their mistakes privately
- But don't face public judgment while they're learning
- Creates safe environment for new verifiers

**Accountability with choice:**
- Empowered status is voluntary
- Users choose transparency in exchange for higher privileges
- Public accountability is part of the social contract

**Trust signals at every level:**
- Connected: "87% accuracy" tells you enough to trust or not
- Empowered: Full transparency lets you judge character and patterns
- Both serve their purpose for their privilege level

### 10. Design for Expansion

**Principle:** This system will eventually verify facts beyond officials—policy claims, voting records, budget data. Build flexible infrastructure.

**Implications:**
- Data models are generic ("quest" not "official_quest")
- Algorithms work for any verifiable fact
- Quest types are extensible
- Lessons from official verification inform other use cases
- Platform-wide infrastructure, not siloed feature

**Example:** Same consensus engine that verifies mayors will verify "Did Congress pass HR 1234?" or "What % of students graduate?"

---

## Implementation Phases

### Phase 0: Foundation (Weeks 1-4)

**Goal:** Build core infrastructure and internal tooling

**Deliverables:**
- Database schema implemented
- Core algorithms coded and unit tested
- Admin dashboard for creating quests manually
- Internal testing environment
- AI agent integration (Claude via API)
- Staff tools for manual verification and conflict resolution

**Team:** 2 engineers, 1 product manager

**Success criteria:**
- Can manually create 10 quests
- Staff can submit answers and see consensus logic work
- AI agent can submit answers via API
- Veracity scores calculate correctly

---

### Phase 1: Closed Beta - Los Angeles Prototype (Weeks 5-12)

**Goal:** Prove the model works with real users and AI agents in one major metro area

**Scope:**
- 200 official positions in LA County
- 50 beta users (Connected Accounts recruited from LA area)
- AI agents populating initial data
- Full consensus and veracity system live

**Week 5-6: AI Data Population**
- AI agents verify all 200 positions
- Staff spot-check 20 random entries for accuracy baseline
- Create initial quest pool

**Week 7-8: User Onboarding**
- Invite 50 beta users
- Onboarding flow: verify your own officials first
- Daily quest delivery begins
- Monitor completion rates and time-to-first-reward

**Week 9-10: Consensus Formation**
- Track how quickly consensuses form
- Monitor AI-human agreement rates
- Resolve first "conflicting" cases manually
- Gather user feedback on quest clarity and difficulty

**Week 11-12: Iteration & Learning**
- Adjust consensus thresholds based on data
- Tune veracity scoring based on user behavior
- Fix bugs and UX issues
- Document lessons learned

**Success Criteria:**
- 80% of 200 positions reach high confidence
- 50%+ beta user retention at week 12
- 90%+ accuracy on staff spot-checks
- <20 hours/week staff time on conflict resolution
- Positive user feedback (NPS >50)

**Risks:**
- Not enough users complete enough quests → need better incentives
- AI-human disagreement higher than expected → need better AI or clearer sources
- Quests too hard or too easy → need better difficulty calibration

---

### Phase 2: Expansion - Bloomington + 5 More Cities (Weeks 13-20)

**Goal:** Prove model scales to different city sizes and regions

**Cities selected:**
- Bloomington, IN (small college town) - 50 positions
- Phoenix, AZ (large growing city) - 150 positions
- Portland, OR (medium progressive city) - 100 positions
- Austin, TX (tech hub) - 125 positions
- Richmond, VA (state capital) - 100 positions

**Total new positions:** ~525

**Users:** Expand to 300 Connected Accounts across these cities

**Key Learnings to Validate:**
- Small city dynamics (Bloomington): Does model work with fewer users per location?
- Regional differences: Do some areas have better/worse official data availability?
- Scaling quest generation: Can we create quests faster than manual entry?
- Geographic diversification: Does user feed algorithm work across multiple cities?

**Week 13-14: Setup & AI Population**
- AI agents populate initial data for all 5 cities
- Recruit users in each geography
- Create city-specific quest feeds

**Week 15-18: Active Verification**
- Users complete local quests first, then bounties
- Monitor consensus formation across different city sizes
- Track accuracy by city to identify problem areas

**Week 19-20: Analysis & Optimization**
- Compare LA vs. Bloomington vs. other cities
- Identify bottlenecks and optimization opportunities
- Refine quest generation algorithms
- Prepare for wider launch

**Success Criteria:**
- 75%+ positions reach consensus across all cities
- Bloomington (small) performs as well as LA (large)
- Quest generation latency <2 hours
- User NPS >40 across all cities
- Clear playbook for adding new cities

---

### Phase 3: Regional Expansion - Statewide Coverage (Weeks 21-32)

**Goal:** Achieve statewide coverage in 3-5 states, including county and special district officials

**States selected:**
- Indiana (home state, Bloomington foundation)
- California (LA foundation)
- One swing state (e.g., Pennsylvania, Wisconsin, or Arizona)

**Scope:** ~5,000 positions across federal, state, county, city, school district officials

**Users:** Expand to 2,000 active verifiers

**Key Features Introduced:**
- Automated quest generation from government databases
- Re-verification quests (quarterly freshness checks)
- Special district coverage (water boards, transit authorities, etc.)
- Enhanced difficulty tiers for niche positions

**Week 21-24: Data Infrastructure**
- Build scrapers for state legislature websites
- Partner with data providers (Ballotpedia, LegiScan)
- Create automated quest generation pipeline
- Set up re-verification scheduling

**Week 25-28: Mass Quest Deployment**
- 5,000 quests go live across 3 states
- Recruit users aggressively in target states
- Monitor for bottlenecks in consensus formation
- AI agents work on low-priority positions

**Week 29-32: Maintenance & Iteration**
- Track re-verification success rates
- Measure data freshness
- Optimize quest prioritization
- Handle edge cases (interim appointments, recalls, vacancies)

**Success Criteria:**
- 70%+ of 5,000 positions reach consensus
- <30 day median time to high confidence
- Automated quest generation working for 80%+ positions
- Re-verification system catching 95%+ of changes
- Staff review time <15 hours/week despite 10x scale

---

### Phase 4: National Rollout - All 50 States (Weeks 33-52)

**Goal:** Comprehensive national coverage of federal, state, and major local officials

**Scope:** ~30,000 positions
- All federal officials (535 Congress + Cabinet + key agencies)
- All state legislators (7,383 across 50 states)
- All governors, lt. governors, attorneys general, etc.
- Major city mayors and councils (cities >50k population)
- Key county positions (all 3,143 counties)

**Users:** 10,000+ active verifiers

**Key Features:**
- Public API for verified data (partners can access)
- Bulk verification campaigns ("Verify Your State Week")
- Master Verifier leaderboards and recognition
- Integration with other Empowered Vote features (Civil Civics, Emparks)

**Week 33-40: Infrastructure Scale**
- Database optimization for 30k+ entries
- CDN for fast data access nationwide
- API v1 launch for partners
- Bulk import tools for high-quality external data sources

**Week 41-48: User Growth & Engagement**
- Marketing campaigns to drive verifier signups
- Partnership with civic organizations for recruitment
- Gamification enhancements (seasonal events, competitions)
- Master Verifier spotlights and community building

**Week 49-52: Stabilization & Handoff**
- Achieve steady state: 70%+ national coverage at high confidence
- Automated systems handling 90%+ of verification flow
- Staff focuses on edge cases and quality assurance
- System ready for Phase 5 expansion to non-official facts

**Success Criteria:**
- 70%+ of 30k positions at high confidence
- 10k+ active monthly verifiers
- 95%+ spot-check accuracy maintained at scale
- <20 hours/week staff time
- API serving 1M+ requests/month
- Ready to expand to policy facts and other verification domains

---

### Phase 5: Beyond Officials - Policy & Fact Verification (Weeks 53+)

**Goal:** Extend verification system to policy claims, voting records, and civic facts

**New Quest Types:**
- "Did Senator X vote for Bill Y?" (voting records)
- "What % of City Z's budget goes to police?" (budget facts)
- "When was Executive Order ABC signed?" (policy timeline)
- "How many public schools are in District D?" (civic infrastructure)

**Implications:**
- Same consensus engine, different data sources
- Higher complexity (sources might conflict legitimately)
- Need for temporal versioning (facts change over time)
- Integration with Empowered Listening debates (verify claims made in debates)
- Integration with Emparks annotations (verify context on annotations)

**This phase is intentionally less detailed—we'll learn from Phases 1-4 and adapt.**

---

## Open Questions & Risks

### Open Questions

**Consensus Mechanics:**
1. **When do we declare "no consensus possible"?** If submissions stay at 50/50 split for months, do we eventually archive the quest or keep trying?
   
2. **How do we handle legitimately ambiguous situations?** Example: "Acting Mayor" vs. "Interim Mayor" vs. "Mayor Pro Tem" - are these different enough answers to prevent consensus?

3. **Should submission weight be visible to users?** Or does knowing "I'm only counted as 0.8x" demotivate participation?

4. **Can users see who else verified the same official?** Or is submission anonymity important for independence?

**User Psychology:**

5. **Will users game the system by colluding?** Example: Discord group decides to all submit wrong answer to sabotage. How do we detect coordinated false submissions?

6. **Is weekly veracity feedback too slow?** Should users get immediate notification when their submission is ratified, even if it means more notifications?

7. **How do we handle users who feel "attacked" by veracity decreases?** Even with education and transparency, some users might react emotionally.

8. **What's the right balance of gems/XP?** Too little and no one participates; too much and it cheapens other ways to earn rewards.

**AI Integration:**

9. **Should AI agents identify themselves in submissions?** Currently yes, but does that create bias?

10. **Can we use AI to generate quest descriptions?** Or does human writing ensure clarity?

11. **Should AI agents get "veracity scores" like humans?** If so, do low-performing AI agents get restricted?

12. **What happens if AI models improve dramatically?** Does a future GPT-6 count the same as GPT-4?

**Scale & Maintenance:**

13. **How often should we re-verify?** Currently thinking quarterly for high-confidence entries, but is that too often/not often enough?

14. **What happens when officials retire/resign mid-term?** Do we need real-time alerts, or is quarterly re-verification sufficient?

15. **Should we verify historical officials?** Example: "Who was mayor in 2020?" for historical research.

16. **How do we handle special districts with appointed boards?** These change less frequently but are even harder to verify.

**Expansion to Facts:**

17. **How do we verify subjective interpretations?** Example: "Did this bill increase funding?" might depend on how you count it.

18. **What sources count as authoritative for policy facts?** Government documents only, or can we use academic research?

19. **How do we handle rapidly changing facts?** Example: COVID case counts - verification would be obsolete immediately.

**Business Model:**

20. **Should verified data be public API or paid tier?** Open data philosophy vs. sustainability.

21. **Can verified officials contest their own entries?** If Mayor Smith says "that's not my correct title," do we listen?

---

### Risk Analysis

**HIGH RISK:**

**1. Insufficient Participation**
- **Risk:** Not enough users complete quests → consensuses never form → data remains unverified
- **Likelihood:** Medium-High (especially for small cities and niche positions)
- **Mitigation:** 
  - AI agents as fallback to populate initial data
  - Bounties for high-priority gaps
  - Aggressive gamification and rewards
  - Partner with civic organizations to recruit verifiers
- **Acceptance Criteria:** If <30% of quests reach consensus in 60 days, we need to rethink incentives

**2. AI Hallucination Cascade**
- **Risk:** Multiple AI agents hallucinate the same wrong answer → false consensus forms
- **Likelihood:** Low-Medium (AI models tend to have similar failure modes)
- **Mitigation:**
  - Require 40% human participation
  - Use diverse AI models (Claude, GPT, others)
  - Staff spot-checks on consensuses
  - Users can contest at any time
- **Acceptance Criteria:** If spot-check accuracy falls below 90%, we pause AI submissions and investigate

**3. Coordinated Misinformation Attacks**
- **Risk:** Bad actors create multiple accounts to submit false information and achieve false consensus
- **Likelihood:** Medium (especially for politically charged positions)
- **Mitigation:**
  - Connected Account requirement (tied to email/phone)
  - Rate limiting on new accounts
  - Anomaly detection for suspicious patterns (10 new accounts all verify same obscure official within 1 hour)
  - Empowered Account verification for sensitive positions
  - Manual review for flagged suspicious consensus
- **Acceptance Criteria:** If we detect coordinated attack, pause verification for that position and investigate

**MEDIUM RISK:**

**4. User Burnout / Fatigue**
- **Risk:** Early enthusiastic users lose interest after novelty wears off → participation drops
- **Likelihood:** High (common in gamification)
- **Mitigation:**
  - Rotating quest types and difficulties to maintain interest
  - Seasonal events and competitions
  - Social features (leaderboards, team challenges)
  - Clear progression path (Connected → Empowered)
  - Intrinsic motivation: "I'm helping my community"
- **Acceptance Criteria:** 30% retention at 90 days is acceptable; <15% is concerning

**5. Source Quality Degradation**
- **Risk:** Official government websites become less reliable (budget cuts → outdated sites)
- **Likelihood:** Medium (already happening in some localities)
- **Mitigation:**
  - Accept multiple source types (news, bios, meeting minutes)
  - Community can flag "this source is outdated"
  - Re-verification catches changes
  - Build relationships with local journalists and civic organizations
- **Acceptance Criteria:** If >25% of sources are flagged as unreliable, we need better source discovery

**6. Scope Creep to Unverifiable Claims**
- **Risk:** Users want to verify subjective or opinion-based claims that don't have objective answers
- **Likelihood:** High (especially when expanding beyond officials)
- **Mitigation:**
  - Clear guidelines: "verifiable facts only"
  - Reject quests that ask for interpretations
  - Example acceptable: "Did Senator vote yes?" Not acceptable: "Was this vote good policy?"
  - Community guidelines and staff review
- **Acceptance Criteria:** If >30% of submitted quests are rejected for subjectivity, we need better education

**LOW RISK:**

**7. Database Performance at Scale**
- **Risk:** Slow queries when database reaches millions of submissions
- **Likelihood:** Low (solvable engineering problem)
- **Mitigation:** Standard database optimization, caching, read replicas
- **Acceptance Criteria:** <200ms average query time at 10M submissions

**8. Legal Liability**
- **Risk:** Someone claims our incorrect data caused them harm (missed contacting their official, etc.)
- **Likelihood:** Low-Medium
- **Mitigation:**
  - Clear disclaimers that data is community-verified, not authoritative
  - Terms of Service covering liability
  - Insurance
  - High accuracy standards reduce likelihood
- **Acceptance Criteria:** Legal review before public launch

**9. Official Pushback**
- **Risk:** Officials or governments object to community verification of their positions
- **Likelihood:** Low (public official info is generally public record)
- **Mitigation:**
  - Use only public sources
  - Allow officials to claim/verify their own pages
  - Transparency about methodology
  - High accuracy = credibility
- **Acceptance Criteria:** Build relationships with local governments proactively

---

## Appendices

### A. Sample Quest Templates

**Federal Official (Difficulty 1):**
```
Title: "Who is the U.S. Senator from [State], Seat [Class]?"
Difficulty: ⭐ Easy
Reward: 10 gems, 15 XP
Hint: Check Senate.gov
Estimated time: 2-3 minutes
```

**State Legislator (Difficulty 2):**
```
Title: "Who represents District [X] in the [State] House of Representatives?"
Difficulty: ⭐⭐ Medium  
Reward: 15 gems, 20 XP
Hint: State legislature websites usually have a "Find My Legislator" tool
Estimated time: 5 minutes
```

**City Council (Difficulty 3):**
```
Title: "Who represents District [X] on the [City] City Council?"
Difficulty: ⭐⭐⭐ Medium-Hard
Reward: 20 gems, 30 XP
Hint: Check the official city website under "City Council" or "Government"
Estimated time: 5-10 minutes
```

**School Board (Difficulty 4):**
```
Title: "Who represents District [X] on the [School District] Board of Education?"
Difficulty: ⭐⭐⭐⭐ Hard
Reward: 30 gems, 45 XP
Hint: School district websites often list board members. Local news may help.
Estimated time: 10-15 minutes
```

**Special District (Difficulty 5):**
```
Title: "Who is the Board President of the [Special District Name]?"
Difficulty: ⭐⭐⭐⭐⭐ Expert
Reward: 50 gems, 75 XP
Hint: Special districts often have minimal web presence. Try county websites, meeting minutes, or local news archives.
Estimated time: 15-30 minutes
```

### B. Veracity Badge System

**Verification Novice** (0-20 submissions)
- Icon: Single star
- Unlocks: Basic verification quests

**Diligent Verifier** (20+ submissions, 75%+ accuracy)
- Icon: Two stars
- Unlocks: Medium difficulty quests
- Benefit: +5% gem bonus

**Expert Verifier** (50+ submissions, 85%+ accuracy)
- Icon: Three stars
- Unlocks: Hard and Expert quests
- Benefit: +10% gem bonus, 1.1x submission weight

**Master Verifier** (100+ submissions, 90%+ accuracy)
- Icon: Four stars + laurel
- Unlocks: All quests including special bounties
- Benefit: +15% gem bonus, 1.3x submission weight
- Public recognition on leaderboard

**Legendary Verifier** (500+ submissions, 95%+ accuracy)
- Icon: Five stars + crown
- Exclusive benefits: Early access to new features, consultation on system changes
- Benefit: +25% gem bonus, 1.5x submission weight
- Hall of Fame recognition

**Specialized Badges:**
- **Local Hero**: Verified 50+ officials in home city/county
- **Bounty Hunter**: Completed 100+ bounty quests
- **Early Adopter**: First 100 to verify in a new city launch
- **Error Detector**: Successfully contested 5+ incorrect consensuses
- **Comeback Kid**: Improved veracity score by 20+ percentage points
- **Perfect Month**: 100% accuracy on 20+ submissions in single month

### C. Educational Resources

**Best Practices Guide for New Verifiers:**
1. Always start with official government websites (.gov domains)
2. Check the date on your sources - information should be current
3. Cross-reference with at least 2 independent sources
4. For elected positions, recent election results are reliable
5. For appointed positions, check meeting minutes or press releases
6. Local news often covers transitions (new officials taking office)
7. When in doubt, cite the most recent, most official source

**Common Mistakes to Avoid:**
1. Using campaign websites (often outdated after election)
2. Trusting Wikipedia without checking citations
3. Confusing interim/acting officials with permanent ones
4. Not verifying the date your source was published
5. Assuming info from last year is still current
6. Mixing up similar names (John Smith vs. John A. Smith)
7. Not checking if a position currently has a vacancy

**Verification Cheat Sheet by Position Type:**
- **Federal:** Senate.gov, House.gov (always authoritative)
- **State Legislature:** State .gov sites usually have rosters
- **Governor/State Executive:** State .gov sites
- **County:** County website → Government → Elected Officials
- **City:** City website → City Council / Mayor
- **School Board:** School district website (often .org or .k12.us)
- **Special Districts:** Hardest to find - try county sites, meeting agendas

---

**END OF DESIGN DOCUMENT v1.0**

---

**Document Status:** Ready for review by Opus and implementation by Claude Code

**Next Steps:**
1. Review with leadership and technical team
2. Refine open questions and risk mitigations
3. Finalize Phase 0 technical specifications
4. Begin development of core infrastructure
5. Recruit LA beta users for Phase 1

**Version History:**
- v1.0 (Feb 11, 2026): Initial comprehensive design document
