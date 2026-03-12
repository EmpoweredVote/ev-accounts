---
phase: quick-10
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - ev-ui/src/PoliticianProfile.jsx
  - ev-ui/package.json
  - essentials/package.json
autonomous: true
requirements:
  - QUICK-10-contact-refactor
must_haves:
  truths:
    - "Social platform URLs in the websites list render as icon-only links (no text), not plain text links"
    - "Social icons row no longer appears above the contact section — it appears at the bottom of the websites column"
    - "Website display text shows only the domain (e.g., en.wikipedia.org), not the full path"
    - "Phone column is narrower than email column so emails fit on one line without wrapping"
  artifacts:
    - path: "ev-ui/src/PoliticianProfile.jsx"
      provides: "Updated contact section rendering"
    - path: "ev-ui/package.json"
      provides: "Bumped to v0.1.48"
  key_links:
    - from: "PoliticianProfile.jsx contactGrid"
      to: "SocialLinks component"
      via: "Rendered at bottom of websites column, not in hero infoCol"
      pattern: "SocialLinks.*allWebsites"
---

<objective>
Refactor the contact information section in the PoliticianProfile ev-ui component to:
1. Detect social platform URLs in the websites list and render them as icon-only boxed links
2. Move the social icons row from the hero section to the bottom of the websites column
3. Truncate website display URLs to domain only (href still goes to full URL)
4. Adjust column widths so phone is narrower and email is wider

Purpose: Governor Mike Braun's profile (and all politician profiles) currently show full-path URLs that overflow, an email column too narrow to fit email addresses, and redundant social icons both in the hero row and in the websites list as plain text.

Output: Updated PoliticianProfile.jsx, ev-ui rebuilt at v0.1.48, essentials updated to consume it.
</objective>

<execution_context>
@/Users/chrisandrews/.claude/get-shit-done/workflows/execute-plan.md
@/Users/chrisandrews/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@/Users/chrisandrews/Documents/GitHub/ev-ui/src/PoliticianProfile.jsx
@/Users/chrisandrews/Documents/GitHub/ev-ui/src/SocialLinks.jsx
</context>

<tasks>

<task type="auto">
  <name>Task 1: Refactor contact section in PoliticianProfile.jsx</name>
  <files>ev-ui/src/PoliticianProfile.jsx</files>
  <action>
Make these changes to PoliticianProfile.jsx:

**A. Add social platform detection helper (after the existing `isLinkedInUrl` function):**

```js
const SOCIAL_PLATFORMS = [
  { test: /facebook\.com/i,  platform: 'facebook' },
  { test: /twitter\.com|x\.com/i, platform: 'twitter' },
  { test: /instagram\.com/i, platform: 'instagram' },
  { test: /linkedin\.com/i,  platform: 'linkedin' },
  { test: /youtube\.com|youtu\.be/i, platform: 'youtube' },
];

function detectSocialPlatform(url) {
  if (!url) return null;
  for (const { test, platform } of SOCIAL_PLATFORMS) {
    if (test.test(url)) return platform;
  }
  return null;
}
```

**B. Add domain-extraction helper (after `detectSocialPlatform`):**

```js
function extractDomain(url) {
  try {
    return new URL(url).hostname.replace(/^www\./, '');
  } catch {
    return url.replace(/^https?:\/\/(www\.)?/, '').split('/')[0];
  }
}
```

**C. Separate social websites from plain websites during data aggregation.**

In the block that builds `allWebsites` (around line 286–316), split into two arrays instead of one:

```js
const allWebsites = [];        // non-social websites only
const socialWebsiteUrls = [];  // social platform URLs from websites list
```

When pushing to `allWebsites`, check `detectSocialPlatform(url)` first — if it returns a platform, push to `socialWebsiteUrls` instead. Apply this split to both the contacts loop and the `personWebsites.forEach` loop.

**D. Remove the `SocialLinks` row from the hero info column.**

Delete (or comment out) the block starting at line 622:
```jsx
{/* Social icons row */}
{hasSocial && (
  <SocialLinks
    twitter={twitter}
    facebook={facebook}
    instagram={instagram}
    linkedin={linkedinUrl}
    website={personWebsites[0] || null}
    size="sm"
  />
)}
```

**E. Update the websites column in the contact grid.**

Replace the current websites column rendering with:

```jsx
{(hasWebsites || hasSocial || socialWebsiteUrls.length > 0) && (
  <div style={styles.contactGroup}>
    <p style={styles.contactLabel}>
      <GlobeIcon size={12} />
      Websites
    </p>
    {allWebsites.map((url, i) => (
      <p key={i} style={styles.contactValue}>
        <a
          href={url}
          target="_blank"
          rel="noopener noreferrer"
          style={styles.contactLink}
          onMouseEnter={(e) => { e.currentTarget.style.textDecoration = 'underline'; }}
          onMouseLeave={(e) => { e.currentTarget.style.textDecoration = 'none'; }}
        >
          {extractDomain(url)}
        </a>
      </p>
    ))}
    {/* Social icon-only links from websites list + existing social handles */}
    {(twitter || facebook || instagram || linkedinUrl || socialWebsiteUrls.length > 0) && (
      <SocialLinks
        twitter={twitter}
        facebook={facebook}
        instagram={instagram}
        linkedin={linkedinUrl}
        extraLinks={socialWebsiteUrls}
        size="sm"
        style={{ marginTop: allWebsites.length > 0 ? '8px' : 0 }}
      />
    )}
  </div>
)}
```

Update `hasWebsites` and the column count computation to count this column correctly. The websites column should show if `allWebsites.length > 0 || hasSocial || socialWebsiteUrls.length > 0`.

Update the `contactGrid` column template. Instead of `repeat(N, 1fr)`, use explicit column sizing so phone is narrow and email is wider. Use this pattern (when all four columns present):

```js
contactGrid: {
  display: 'grid',
  gridTemplateColumns: isMobile
    ? '1fr'
    : (() => {
        const cols = [];
        if (hasAddresses) cols.push('1fr');
        if (hasPhones) cols.push('140px');       // phone numbers are short
        if (hasEmails) cols.push('minmax(180px, 1fr)'); // emails need room
        if (hasWebsites || hasSocial || socialWebsiteUrls.length > 0) cols.push('1fr');
        return cols.join(' ');
      })(),
  gap: isMobile ? spacing[4] : spacing[6],
},
```

**F. Update `SocialLinks.jsx` to accept an `extraLinks` prop** (array of URLs for social platforms detected from the websites list). For each URL in `extraLinks`, detect the platform via regex and render the appropriate icon. Add this to the existing `links` array construction:

```js
// In SocialLinks.jsx, add extraLinks prop:
export default function SocialLinks({ website, twitter, facebook, instagram, linkedin, size = 'md', style = {}, extraLinks = [] }) {

// After the existing links array, append extraLinks mapped to icons:
const platformIconMap = {
  facebook: /* Facebook SVG */,
  twitter: /* X SVG */,
  instagram: /* Instagram SVG */,
  linkedin: /* LinkedIn SVG */,
  youtube: /* YouTube SVG — simple play button circle */,
};

extraLinks.forEach((url) => {
  const detected = SOCIAL_PLATFORMS.find(({ test }) => test.test(url));
  if (detected && platformIconMap[detected.platform]) {
    // Only add if not already in links (avoid duplicate if handle already detected)
    const alreadyPresent = links.some(l => l.href === url || l.href?.includes(detected.platform));
    if (!alreadyPresent) {
      links.push({
        href: url,
        label: detected.platform.charAt(0).toUpperCase() + detected.platform.slice(1),
        icon: platformIconMap[detected.platform],
      });
    }
  }
});
```

For the YouTube icon use this SVG:
```jsx
<svg style={styles.icon} viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="2" y="5" width="20" height="14" rx="3" stroke="currentColor" strokeWidth="2"/>
  <polygon points="10,9 16,12 10,15" fill="currentColor"/>
</svg>
```

Move `SOCIAL_PLATFORMS` constant to a shared location or duplicate it in SocialLinks.jsx — duplication is fine since this is a small library with no shared module system.

**Summary of all files changed in this task:**
- `ev-ui/src/PoliticianProfile.jsx` — helpers, data split, hero social row removal, websites column update, grid column sizing
- `ev-ui/src/SocialLinks.jsx` — add `extraLinks` prop + YouTube icon + platform detection
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build 2>&1 | tail -5</automated>
  </verify>
  <done>
    - ev-ui build succeeds with no errors
    - SocialLinks accepts extraLinks prop without TypeScript errors
    - No social platform URLs remain in the plain-text website list
    - SocialLinks row is no longer rendered in the hero info column
  </done>
</task>

<task type="auto">
  <name>Task 2: Bump ev-ui version and update essentials</name>
  <files>ev-ui/package.json, essentials/package.json</files>
  <action>
1. In `ev-ui/package.json`, bump version from `0.1.47` to `0.1.48`.

2. Rebuild ev-ui:
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm run build
   ```

3. Publish to GitHub npm registry:
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/ev-ui && npm publish
   ```

4. In `essentials/package.json`, update the ev-ui dependency:
   ```json
   "@chrisandrewsedu/ev-ui": "^0.1.48"
   ```

5. Reinstall in essentials:
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/essentials && npm install
   ```

6. Start the dev server briefly to confirm no import errors:
   ```bash
   cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build 2>&1 | tail -10
   ```
  </action>
  <verify>
    <automated>cd /Users/chrisandrews/Documents/GitHub/essentials && npm run build 2>&1 | grep -E "error|Error|built in" | tail -5</automated>
  </verify>
  <done>
    - ev-ui published at v0.1.48
    - essentials builds successfully with v0.1.48
    - No import resolution errors
  </done>
</task>

</tasks>

<verification>
After both tasks complete, open Governor Mike Braun's profile page in the essentials dev server and confirm:
1. The websites column shows `en.wikipedia.org` (not the full path)
2. Social media URLs from the websites list appear as icon-only boxed links at the bottom of the websites column
3. No floating social icons row appears above the contact section in the hero area
4. Phone column is visibly narrower than the email column
5. Email addresses display on a single line without wrapping
</verification>

<success_criteria>
- Website display truncated to domain only across all politician profiles
- Social platform URLs render as icon-only (no text) in the websites column
- Social icons row moved from hero to bottom of websites column
- Phone column narrower, email column wider, no email wrapping
- ev-ui v0.1.48 published and consumed by essentials
</success_criteria>

<output>
After completion, create `.planning/quick/10-refactor-contact-info-section-on-politic/10-SUMMARY.md` with what was built, files changed, and any notable implementation decisions.
</output>
