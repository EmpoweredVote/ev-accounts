<!--
  DRAFT — NOT PUBLISHED. This is the proposed page content for
  https://empowered.vote/crawler, written for founder review.

  Do not publish until the founders approve the wording. When approved, this
  URL must resolve, because our crawler's user-agent links to it:
      EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; ...)

  Source of truth for the policy: ev-cto decision 0003-scraping-toolchain.md.
  Contact address confirmed by Chris on 2026-09-01: info@empowered.vote.
-->

# About EmpoweredVoteBot

**Empowered Vote** is a nonprofit, nonpartisan civic-information project. We
publish neutral, sourced information about elected officials and candidates so
that voters can make informed decisions.

`EmpoweredVoteBot` is the automated fetcher we use to **find and check the
original sources behind that published information**. It does two things:

1. It reads public pages to **find original sources** we can cite for a claim
   about an official — for example, the news report or public record where the
   official said or did something.
2. It **re-fetches those source pages to verify them** — to confirm the quoted
   text is really there and has not changed.

In both cases the goal is the same: accurate, factual information, always
published with a **link back to the original source**. It is not a search engine
and not a training crawler.

## What the bot does

- It requests **public web pages** — both pages we are considering as a source
  and pages we have **already cited**.
- It reads the visible text of a page to find, or to confirm, a quotation we
  attribute to that source.
- Everything it helps us publish carries a **link back to the original source**,
  so a reader can always go and check for themselves.
- It runs at a **low volume** — roughly a few hundred to a thousand pages in a
  normal month.

## What the bot does not do

- It does **not** collect personal data about you or your readers.
- It does **not** fill in forms, log in, or attempt to reach pages behind a
  paywall or a login.
- It does **not** use its data for advertising or to train machine-learning
  models.

## How we identify ourselves

Our requests carry this user-agent, so you can always recognise us in your logs:

```
EmpoweredVoteBot/1.0 (+https://empowered.vote/crawler; nonprofit civic citation verification; contact info@empowered.vote)
```

We identify ourselves honestly. We do **not** disguise the bot as a person's web
browser.

## How we crawl — our commitments

- **We respect `robots.txt`.** Before we fetch a page, we check your site's
  `robots.txt` for the `EmpoweredVoteBot` user-agent. If it disallows a path, we
  do not fetch that page from your site.
- **We do not use stealth tactics.** We do not route requests through
  residential or mobile proxy networks, and we do not rotate fingerprints to
  defeat bot protection.
- **When a site declines, we stop.** If your `robots.txt` excludes us, or your
  server blocks us, we do not try to work around it. Where a public archive
  (such as the Internet Archive's Wayback Machine) holds a copy, we may verify
  against that archived copy instead; otherwise we simply record that the source
  could not be verified.
- **We crawl gently.** We fetch a small number of pages and do not hammer a
  site.

## How to exclude us

If you would prefer that we do not fetch your pages, you can block us in your
`robots.txt`:

```
User-agent: EmpoweredVoteBot
Disallow: /
```

We honour this. You can also disallow specific paths rather than the whole site.

If you would like to reach us directly — to ask us to stop, to report a problem,
or to ask a question — email **info@empowered.vote**. We will respond.

## Why this matters to voters

Every claim we publish about an official is meant to be traceable to a real,
checkable source. Verifying those sources is how we keep that promise. We do it
in the open, under our own name, and within the limits above.
