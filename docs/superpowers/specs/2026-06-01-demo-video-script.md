# Demo Video Script & Storyboard
## Empowered Vote — Guest User Workflow (Compass + Essentials)

### Context
A 60–90 second social clip for a general audience (voters, funders, press) demonstrating the complete guest user journey across both apps. The central message: Empowered Vote helps you understand your government through issues, not parties — no party labels, no partisan framing anywhere in the flow.

**Demo setup:** Use a Salt Lake County, UT address. The compare + profile scenes must show a **city council member or state legislator** (not a mayor or county executive) who has compass stances loaded — Wave 2 SLC officials have stances.

---

## Script & Storyboard

### Scene 1 — Hook (0:00–0:07)
**Screen:** Black card, white text, Empowered Vote wordmark  
**Visual:** Simple fade-in text only  
**On-screen text:**
> "Most voters can't name half the people on their ballot — let alone where they stand on the issues."

**Narration (VO):** *(same as on-screen text, read slowly)*  
**Timing:** Hold 5s, fade to black, 2s transition

---

### Scene 2 — Compass calibration (0:07–0:20)
**Screen:** `compass.empowered.vote` → FullCalibration page  
**Visual:** 3 quick cuts (~3s each) of answering different policy questions  
- Cut A: A question card with 4–5 stance options visible (no party labels on any stance)  
- Cut B: User clicks a stance; it highlights yellow; page auto-advances  
- Cut C: A different topic, stances listed in the *opposite* order from Cut A (demonstrating random direction flip)  

**Narration (VO):**
> "Empowered Vote starts with what you actually think."

**Key filming note:** Make sure the stance text is legible. Pick topics from different categories (e.g. one economic, one social). The random-direction feature is a differentiator — both cuts should be visible enough to notice the flip.

---

### Scene 3 — Radar chart (0:20–0:30)
**Screen:** `compass.empowered.vote` → `/results` — CombinedPage, radar chart section  
**Visual:** The spider/radar chart animating in as it first renders, showing a complete shape with ~8+ spokes filled  
**On-screen text overlay (bottom third):**
> "Your compass — built from issues, not parties."

**Narration (VO):** *(same as overlay)*  
**Key filming note:** Capture the chart animation on first load. If the shape is already rendered, clear localStorage and redo calibration to trigger a fresh animation.

---

### Scene 4 — Compare mode (0:30–0:47)
**Screen:** `compass.empowered.vote` → CombinedPage, Compare panel open  
**Politician to use:** A Salt Lake County city council member or Utah state legislator with stances (e.g. from the Wave 2 SLC data push). Confirm in the admin that the politician has ≥5 compass answers before filming.  

**Visual sequence:**
1. User clicks the "Compare" button in the toolbar  
2. Search field appears; user types a name and selects the politician  
3. Blue overlay shape appears on top of the pink user shape  
4. Tour tooltip is visible: *"No party labels — just the ideas."*  
5. Slow zoom on 2–3 spokes where the shapes diverge clearly  

**Narration (VO):**
> "Compare your positions with any official, topic by topic. No party labels — just the ideas."

**Key filming note:** The tooltip text "No party labels — just the ideas." is a real UI string (CombinedPage.jsx ~line 785). Make sure it's on screen.

---

### Scene 5 — Essentials address entry → results (0:47–1:02)
**Screen:** `essentials.empowered.vote` → Landing → Results  
**Demo address:** **451 S State St, Salt Lake City, UT 84111** (Salt Lake City Hall)  

**Visual sequence:**
1. Landing page — user types the address into the search bar  
2. Autocomplete suggestion appears; user selects it  
3. Results page loads — cards appearing in sequence: federal (senators, house rep), state (governor, legislators), local (SLC council, county officials)  

**Narration (VO):**
> "Enter your address. See everyone who represents you — from city hall to Congress."

**Key filming note:** Let the progressive loading animation play naturally. The cascade of cards appearing is visually satisfying. Don't skip it.

---

### Scene 6 — Politician profile with stances (1:02–1:15)
**Screen:** `essentials.empowered.vote` → `/politician/:id`  
**Politician to use:** Same city council member used in Scene 4 (consistency), or any SLC council member with verified stances loaded.  
**NOT:** A mayor, county executive, or other administrative official (these don't have policy stances in the system).  

**Visual sequence:**
1. User clicks a council member card from the results page  
2. Profile page loads — bio, office title visible  
3. Scroll to stances section showing verified issue positions  

**Narration (VO):**
> "Their verified positions on the issues that shape your community."

**Key filming note:** Make sure the stances section is visible and has content. If the profile has a compass comparison widget, show that too.

---

### Scene 7 — End card (1:15–1:25)
**Screen:** Clean branded card  
**Visual:** Empowered Vote logo, coral (#ff5740) background  
**On-screen text:**
> **Empowered Vote**  
> Know your ballot.  
> empowered.vote

**Narration (VO):** *(silence or soft music swell)*  
**Timing:** Hold 8–10 seconds

---

## Cutting to 60 Seconds

Drop **Scene 6** (politician profile). The flow still works:  
Hook → Quiz → Chart → Compare → Essentials results → End card.  
Tighten Scene 5 to 10s by cutting to the results grid immediately after address entry.

---

## Filming Checklist

- [ ] Clear localStorage before Scene 3 to trigger fresh chart animation
- [ ] Verify the compare politician has ≥5 compass stances in admin before filming Scene 4
- [ ] Confirm the profile politician is a legislator/council member, not a mayor/executive (Scene 6)
- [ ] Use `451 S State St, Salt Lake City, UT 84111` as the demo address
- [ ] Capture at 1080p minimum; record at 2x for slow-motion options in edit
- [ ] Keep cursor movement slow and deliberate — editing can speed up; can't slow down jerky mouse
- [ ] Use dark mode or light mode consistently across all scenes (pick one before filming)
