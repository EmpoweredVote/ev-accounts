---
phase: quick-6
plan: 1
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-ui/src/PoliticianProfile.jsx
autonomous: true
requirements: [QUICK-6]
must_haves:
  truths:
    - "All addresses appear in a single column, grouped together"
    - "All phone numbers appear in a single column, grouped together"
    - "All email addresses appear in a single column, grouped together"
    - "All websites appear in a single column, grouped together"
    - "Contact types (District, Capitol, etc.) are preserved as sub-labels within each column"
  artifacts:
    - path: "ev-ui/src/PoliticianProfile.jsx"
      provides: "Column-grouped contact info section"
      contains: "contactGrid"
  key_links:
    - from: "ev-ui/src/PoliticianProfile.jsx"
      to: "pol.contacts"
      via: "contact data grouping logic"
      pattern: "phonesByType|emailsByType|addresses|allWebsites"
---

<objective>
Refactor the Contact Information section in PoliticianProfile to group contact info by category in columns (Addresses | Phones | Emails | Websites) instead of the current layout where each contact_type (District, Capitol, etc.) gets its own grid cell.

Purpose: When a politician has multiple phone numbers or emails from different offices, they currently each get their own row/cell in the grid. Grouping by category makes the section more compact and scannable.
Output: Updated PoliticianProfile.jsx with column-per-category contact layout.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@ev-ui/src/PoliticianProfile.jsx
@ev-ui/src/tokens.js

<interfaces>
<!-- Current contact data structures (lines 275-321 of PoliticianProfile.jsx) -->

```javascript
// addresses: Array of { type: string, lines: string[] }
// phonesByType: { [contactType: string]: string[] }  e.g. { "District": ["555-1234"], "Capitol": ["555-5678"] }
// emailsByType: { [contactType: string]: string[] }
// allWebsites: string[]
```

<!-- Current grid renders each contactType as its own grid cell (lines 634-720) -->
<!-- Problem: Object.entries(phonesByType).map() creates a separate cell per type -->
</interfaces>
</context>

<tasks>

<task type="auto">
  <name>Task 1: Refactor contact grid to group by category columns</name>
  <files>ev-ui/src/PoliticianProfile.jsx</files>
  <action>
Restructure the Contact Information section (lines 634-720) to use a 4-column layout where each column is a category: Addresses, Phones, Emails, Websites. Only render columns that have data.

Replace the current contactGrid style:
- Change from `repeat(auto-fit, minmax(220px, 1fr))` to a fixed column count based on how many categories have data. Use `gridTemplateColumns: isMobile ? '1fr' : \`repeat(${columnCount}, 1fr)\`` where columnCount is the number of non-empty categories.

Replace the current grid children (lines 636-719) with this structure:

1. **Addresses column** (if hasAddresses): Single grid cell containing ALL addresses. Render each address with its type label (e.g., "District", "Capitol") as a sub-heading, followed by the address lines. Use the existing MapPinIcon + contactLabel style for the column header "Addresses", then for each address render the type as a smaller label and the formatted lines below it.

2. **Phones column** (if hasPhones): Single grid cell containing ALL phone numbers. Column header: PhoneIcon + "Phone". For each contactType in phonesByType, render the type (e.g., "District", "Capitol") as a sub-label, followed by the phone number(s) as clickable tel: links.

3. **Emails column** (if hasEmails): Single grid cell containing ALL emails. Column header: MailIcon + "Email". For each contactType in emailsByType, render the type as a sub-label, followed by email(s) as clickable mailto: links.

4. **Websites column** (if hasWebsites): Single grid cell containing ALL websites. Column header: GlobeIcon + "Websites". List all website links (same rendering as current).

Add a new style for the sub-label (contact type within a column):
```javascript
contactSubLabel: {
  fontFamily: fonts.primary,
  fontWeight: fontWeights.medium,
  fontSize: '12px',
  color: '#9CA3AF',
  margin: 0,
  marginTop: spacing[2],
  marginBottom: spacing[1],
}
```
Do NOT add marginTop on the first sub-label in each column (use `:first-of-type` logic or conditional marginTop: i === 0 ? 0 : spacing[2]).

Keep existing contactLabel style for the column headers (Addresses, Phone, Email, Websites).
Keep existing contactValue and contactLink styles for the actual values.
Keep the existing data grouping logic (lines 275-321) unchanged — only the rendering changes.

After refactoring, rebuild the ev-ui library so essentials picks up the change:
```bash
cd ev-ui && npm run build
```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build</automated>
  </verify>
  <done>Contact info section renders in category columns (Addresses | Phones | Emails | Websites) with contact types as sub-labels within each column. ev-ui builds successfully.</done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>Refactored contact info section to group by category columns instead of one cell per contact type</what-built>
  <how-to-verify>
    1. Start the essentials dev server: `cd essentials && npm run dev`
    2. Navigate to a politician profile that has multiple contact types (e.g., both District and Capitol offices)
    3. Verify the Contact Information section shows columns by category:
       - First column: all addresses grouped, with type labels (District, Capitol) as sub-headings
       - Second column: all phone numbers grouped by type
       - Third column: all emails grouped by type
       - Fourth column: all websites
    4. On mobile viewport (< 768px), verify columns stack vertically (1fr)
    5. Verify links (tel:, mailto:, website) still work correctly
  </how-to-verify>
  <resume-signal>Type "approved" or describe issues</resume-signal>
</task>

</tasks>

<verification>
- ev-ui builds without errors
- Contact info renders grouped by category, not by contact type
- Mobile layout stacks columns vertically
- All links (phone, email, website) remain functional
</verification>

<success_criteria>
Contact Information section displays in category columns (Addresses, Phones, Emails, Websites) with contact types as sub-labels within each column, replacing the current one-cell-per-contact-type layout.
</success_criteria>

<output>
After completion, create `.planning/quick/6-improve-contact-info-section-on-profile-/6-SUMMARY.md`
</output>
