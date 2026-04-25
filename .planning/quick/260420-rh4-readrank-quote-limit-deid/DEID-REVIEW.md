# Deidentification review — 260420-rh4

**Approach:** Draft `deidentified_text` only for quotes where the reveal narrows to *this specific person* or a very small group. Leave broad state/demographic references alone ("California", "Indiana", "Hoosier") — too broad to identify.

Originals are preserved in `quote_text`. `deidentified_text` is what read-rank displays. Reveal screen can still show original or updated text.

**Instructions for review:** Scroll through. For each, `APPROVE` takes as drafted, or reply with a specific rewrite. Quotes not listed here stay original (no deidentification needed).

---

## Drafted rewrites (17 quotes)

### Henry / housing — `ea883128` — **role + specific jurisdiction**
- **Original:** "I was on the affordable housing commission in this county, where we declared, once upon a time in 2021 that housing is a human right in Monroe County. And we haven't done anything since to move that needle."
- **Deidentified:** "I served on a county housing commission, where back in 2021 we declared housing is a human right in our county. And we haven't done anything since to move that needle."
- **Why:** "affordable housing commission in this county" + "Monroe County" = Bloomington/Monroe, IN. Specific.

### Henry / housing — `80370fad` — **party self-ID**
- **Original:** "...the courage to stand up to the State House and even people in our own community and in our own Democratic Party to finally get stuff done."
- **Deidentified:** "...the courage to stand up to the statehouse and even people in our own community and in our own party to finally get stuff done."
- **Why:** "Democratic Party" self-outs partisan affiliation — antipartisan principle.

### Henry / homelessness — `2141c13b` — **references own board**
- **Original:** "It shouldn't be the responsibility of our private sector to clean up a mess made by our board of commissioners."
- **Deidentified:** "It shouldn't be the responsibility of the private sector to clean up a mess made by local government."
- **Why:** "our board of commissioners" implies he serves on it.

### Henry / abortion — `c1bcfe58` — **specific clinic**
- **Original:** "When frontline nurses sounded the alarm at the closing of our family planning clinic, I was there in paper, and demanding results and demanding accountability for why we closed that clinic in times of crisis."
- **Deidentified:** "When frontline nurses sounded the alarm at the closing of a family planning clinic in our community, I was there on the record, demanding results and demanding accountability for why we closed that clinic in times of crisis."
- **Why:** "our family planning clinic" + context narrows to specific closure event. Softens to generic.

### Deckard / deportation — `93d67bc5` — **explicit office claim**
- **Original:** "As long as I'm a commissioner—and I will work with any other elected official that will help me championing that—it is our job to stand at the doors…"
- **Deidentified:** "As long as I'm in office—and I will work with any other elected official that will help me champion this—it is our job to stand at the doors…"
- **Why:** "commissioner" names the office directly.

### Kounalakis / abortion — `dd4f4722` — **explicit office**
- **Original:** "The Supreme Court's decision to overturn Roe v. Wade is an unconscionable attack on women's freedom and bodily autonomy. As Lieutenant Governor of California, I will do everything in my power to protect reproductive rights in our state."
- **Deidentified:** "The Supreme Court's decision to overturn Roe v. Wade is an unconscionable attack on women's freedom and bodily autonomy. I will do everything in my power to protect reproductive rights in our state."
- **Why:** "As Lieutenant Governor of California" = only one person.

### Newsom / ai-regulation — `8c88a7ff` — **signing = governor**
- **Original:** "We are signing 17 bills today that address real and specific harms from AI: deepfakes in elections, AI in healthcare decisions, worker protections. California is leading on AI accountability."
- **Deidentified:** "Seventeen new laws in California today address real and specific harms from AI: deepfakes in elections, AI in healthcare decisions, worker protections. California is leading on AI accountability."
- **Why:** "We are signing bills" = only the governor does that.

### Newsom / fossil-fuels — `f2faba45` — **directing = governor**
- **Original:** "I'm directing the state to phase out the sale of all new gas-powered passenger cars by 2035. This is the most impactful step our state can take to fight climate change."
- **Deidentified:** "California is phasing out the sale of all new gas-powered passenger cars by 2035. This is the most impactful step our state can take to fight climate change."
- **Why:** "I'm directing the state" = governor.

### Newsom / abortion — `f5b63987` — **state-wide sanctuary declaration = governor**
- **Original:** "We won't cooperate with any state that tries to prosecute women or doctors for receiving or providing reproductive care. California will be a sanctuary — full stop."
- **Deidentified:** (no change — doesn't uniquely identify without context)
- **Why:** Keep as-is; "we" could be any CA official.

### Whitesides / healthcare — `775bb874` — **specific district**
- **Original:** "In this district, healthcare is not a partisan issue. Families in the Santa Clarita Valley and the Antelope Valley need affordable coverage, and I will work across the aisle to protect and expand access to care for every constituent I represent."
- **Deidentified:** "In this district, healthcare is not a partisan issue. Working families here need affordable coverage, and I will work across the aisle to protect and expand access to care for every constituent I represent."
- **Why:** "Santa Clarita Valley and Antelope Valley" = CA-27 only.

### Bass / housing — `50055d68` — **"declaring a state of emergency" = mayor**
- **Original:** "The time for waiting and talking and planning is over. Today, I am declaring a state of emergency on homelessness. This means we will move faster and do more to get people off the streets and into shelter, services and housing."
- **Deidentified:** "The time for waiting and talking and planning is over. Today, the city is declaring a state of emergency on homelessness. We will move faster and do more to get people off the streets and into shelter, services and housing."
- **Why:** Only a mayor declares city emergencies; combined with LA context = Bass.

### Friedman / healthcare — `33e74fd7` — **state-leg-to-Congress transition**
- **Original:** "Affordable healthcare is not a luxury — it is a necessity for working families across California. I fought for expanded coverage in the state legislature, and I will bring that same commitment to Congress to protect the ACA and expand coverage for every American."
- **Deidentified:** "Affordable healthcare is not a luxury — it is a necessity for working families across California. I've fought for expanded coverage before, and I will bring that same commitment forward to protect the ACA and expand coverage for every American."
- **Why:** "state legislature → Congress" narrows to a small set.

### Beckwith / abortion — `517abf66` — **explicit office**
- **Original:** "I am unashamedly pro-life. Life begins at conception, and it is the government's job to protect innocent human life. Indiana has been a leader in protecting the unborn, and I will continue that work as Lieutenant Governor."
- **Deidentified:** "I am unashamedly pro-life. Life begins at conception, and it is the government's job to protect innocent human life. Indiana has been a leader in protecting the unborn, and I will continue that work in office."
- **Why:** "as Lieutenant Governor" + Indiana = one person.

### Braun / abortion — `64b5e094` — **signed executive order = governor**
- **Original:** "Today I signed an executive order ensuring Indiana continues to be a state that protects life. We will not waver in our commitment to defending the unborn and supporting mothers and families across our state."
- **Deidentified:** "Indiana must continue to be a state that protects life. We will not waver in our commitment to defending the unborn and supporting mothers and families across our state."
- **Why:** "I signed an executive order" = governor.

### Braun / redistricting — `b2478868` — **party self-ID**
- **Original:** "Indiana Republicans drew maps that reflect this state's conservative values and the will of Hoosier voters. The process was transparent, legal, and resulted in fair representation for Indiana communities."
- **Deidentified:** "These maps reflect this state's conservative values and the will of Hoosier voters. The process was transparent, legal, and resulted in fair representation for Indiana communities."
- **Why:** "Indiana Republicans drew" self-outs party affiliation.

### Braun / same-sex-marriage — `51698a95` — **"since I came to the Senate"**
- **Original:** "I think that issue should be up to the states. That's the 10th Amendment. That's what I have believed in since I came to the Senate."
- **Deidentified:** "I think that issue should be up to the states. That's the 10th Amendment. That's what I've long believed."
- **Why:** "since I came to the Senate" = former US Senator.

### Braun / tariffs — `619000dc` — **"I voted yes" + state**
- **Original:** "I voted yes on the USMCA. It is a better deal for Indiana farmers and workers. We need to update these trade agreements to reflect the modern economy and protect American jobs."
- **Deidentified:** "The USMCA is a better deal for Indiana farmers and workers. We need to update these trade agreements to reflect the modern economy and protect American jobs."
- **Why:** "I voted yes" = member of Congress; combined with IN = narrow.

### Pierce / civil-rights — `d80e009e` — **specific IN counties + legislator implication**
- **Original:** "These maps have a very profound impact on the minority voters of Marion County and up in Lake County."
- **Deidentified:** (no change — not a strong stance reveal; weak narrowing)
- **Why:** Keep; "Marion/Lake County" alone doesn't identify him among IN legislators.

---

## Not flagged (deliberate pass)

Quotes referencing only state names ("California", "Indiana", "Hoosiers"), generic "we" as state/community, bill numbers without author claims, and broad policy advocacy without self-office-claim — kept original. If any of these bother you on review, call them out.

---

## Application

After approval: single `BEGIN; UPDATE essentials.quotes SET deidentified_text = ... WHERE id = ...; ... COMMIT;` transaction. `quote_text` untouched. Backend already serves `COALESCE(deidentified_text, quote_text)`.
