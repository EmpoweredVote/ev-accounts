/**
 * discoveryService — orchestration layer for v2.1 Claude candidate discovery.
 *
 * WHY THIS FILE EXISTS:
 * Turns a single discovery_jurisdictions.id into a complete discovery run:
 * loads config, calls discoveryAgentRunner, normalizes names, scores confidence,
 * diffs against race_candidates for withdrawal detection, writes staging rows,
 * and logs the run to discovery_runs.
 *
 * IMPORTANT SCHEMA NOTES:
 * The essentials schema is NOT in PostgREST. ALL reads and writes use
 * pool.query() (direct postgres). Never use the supabase client here.
 *
 * CONFIDENCE vs FLAGGED:
 * These are independent dimensions. confidence='official' + flagged=true is
 * valid and means "we're confident this is a real candidate from an official
 * source, but we have no matching race row in the DB." That combination is the
 * ballot-completeness radar (e.g. LA Mayor race never seeded in DB).
 *
 * WITHDRAWAL SCOPE:
 * Only diff races where the agent returned ≥1 candidate. Races the agent
 * didn't touch are left alone — absence of evidence is not evidence of
 * withdrawal.
 *
 * NO TRANSACTION:
 * Steps 4-7 are NOT wrapped in a Postgres transaction. If the agent succeeds
 * but a single INSERT fails mid-loop, we want the partial data preserved and
 * the run marked failed (for audit). The run row IS the audit trail.
 */

import { distance } from 'fastest-levenshtein';
import { pool } from './db.js';
import { sendEmail } from './emailService.js';
import {
  runDiscoveryAgent,
  type DiscoveredCandidate,
  type DiscoveryAgentInput,
  type DiscoveryAgentResult,
} from './discoveryAgentRunner.js';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

export const NAME_MATCH_THRESHOLD = 0.85;

// ---------------------------------------------------------------------------
// Pure helpers (exported for reuse + isolated testing)
// ---------------------------------------------------------------------------

/**
 * Canonical name normalization for fuzzy matching.
 * Lowercase, collapse whitespace, strip common suffixes (Jr, Sr, II, III, IV, V, Esq, PhD, MD).
 * Punctuation (periods, commas, apostrophes) is removed so "O'Brien" and "OBrien" compare equal.
 */
export function normalizeName(name: string): string {
  return name
    .toLowerCase()
    .replace(/[.,'`’]/g, '')    // strip punctuation incl. smart apostrophe
    .replace(/\s+/g, ' ')
    .trim()
    .replace(/\s+(jr|sr|ii|iii|iv|v|esq|phd|md)\s*$/i, '')
    .trim();
}

/**
 * Similarity in [0, 1] between two names after normalization.
 * 1.0 = identical; 0.85+ is the project-wide "same person" threshold.
 * Uses Levenshtein distance: 1 - distance / max(len).
 */
export function nameSimilarity(a: string, b: string): number {
  const na = normalizeName(a);
  const nb = normalizeName(b);
  const maxLen = Math.max(na.length, nb.length);
  if (maxLen === 0) return 1.0;
  return 1 - distance(na, nb) / maxLen;
}

/**
 * Score confidence from two signals:
 *   1. domainOnAllowlist — citation URL's domain is on the jurisdiction's allowed_domains
 *   2. nameMatchesExistingCandidate — discovered name fuzzy-matches an existing race_candidate ≥ threshold
 *
 * Rules: official → matched → uncertain (first matching rule wins).
 * When allowedDomains is empty/null, domainOnAllowlist is always false → ceiling is 'matched' or 'uncertain'.
 */
export function scoreConfidence(args: {
  domainOnAllowlist: boolean;
  nameMatchesExistingCandidate: boolean;
}): 'official' | 'matched' | 'uncertain' {
  if (args.domainOnAllowlist) return 'official';
  if (args.nameMatchesExistingCandidate) return 'matched';
  return 'uncertain';
}

/**
 * Extract the registrable hostname from a URL for allowlist comparison.
 * Strips protocol, port, path, query, fragment, and leading "www.".
 * Returns lowercased hostname (e.g. "lavote.gov") or null if URL is unparseable.
 */
export function hostFromUrl(url: string): string | null {
  try {
    const u = new URL(url);
    return u.hostname.toLowerCase().replace(/^www\./, '');
  } catch {
    return null;
  }
}

/**
 * Is the URL's host on the allowlist?
 * Matches the domain itself OR any subdomain
 * (e.g. "registrar.lacounty.gov" matches allowedDomains=["lacounty.gov"]).
 */
export function isDomainAllowlisted(url: string, allowedDomains: string[] | null): boolean {
  if (!allowedDomains || allowedDomains.length === 0) return false;
  const host = hostFromUrl(url);
  if (!host) return false;
  return allowedDomains.some((d) => {
    const ad = d.toLowerCase().replace(/^www\./, '');
    return host === ad || host.endsWith('.' + ad);
  });
}

// ---------------------------------------------------------------------------
// Email helpers
// ---------------------------------------------------------------------------

function buildReviewEmailHtml(args: {
  jurisdictionName: string;
  uncertainStaged: number;
  matchedStaged: number;
  officialStaged: number;
  withdrawalsStaged: number;
  reviewUrl: string;
  daysUntilElection: number | null;
}): string {
  const urgencyLine =
    args.daysUntilElection !== null && args.daysUntilElection <= 30
      ? `<p><strong>Election is ${args.daysUntilElection} day(s) away.</strong></p>`
      : '';
  return `
    <div style="font-family: system-ui, sans-serif; max-width: 560px;">
      <h2 style="margin: 0 0 8px 0;">Candidates need review — ${args.jurisdictionName}</h2>
      ${urgencyLine}
      <ul style="line-height: 1.6;">
        <li><strong>${args.uncertainStaged}</strong> uncertain</li>
        <li><strong>${args.matchedStaged}</strong> matched</li>
        <li><strong>${args.officialStaged}</strong> official</li>
        ${args.withdrawalsStaged > 0 ? `<li><strong>${args.withdrawalsStaged}</strong> possible withdrawal(s)</li>` : ''}
      </ul>
      <p>
        <a href="${args.reviewUrl}"
           style="display:inline-block;padding:10px 16px;background:#1f6feb;color:#fff;border-radius:6px;text-decoration:none;">
          Review queue
        </a>
      </p>
    </div>
  `;
}

// ---------------------------------------------------------------------------
// Run summary type
// ---------------------------------------------------------------------------

export interface DiscoveryRunSummary {
  runId: string;
  jurisdictionId: string;
  candidatesFound: number;
  candidatesStaged: number;
  uncertainStaged: number;
  matchedStaged: number;
  officialStaged: number;
  withdrawalsStaged: number;
  status: 'completed' | 'failed';
  errorMessage: string | null;
}

// ---------------------------------------------------------------------------
// Main orchestrator
// ---------------------------------------------------------------------------

/**
 * Run a complete discovery pass for one registered jurisdiction.
 *
 * Pipeline:
 *   1. Load the discovery_jurisdictions row (throws if missing).
 *   2. Load essentials.races + race_candidates for (election_date, state)
 *      as context for the agent AND for the withdrawal diff.
 *   3. INSERT a discovery_runs row with status='running'.
 *   4. Call runDiscoveryAgent with the jurisdiction config + known races.
 *   5. For each discovered candidate: normalize, score confidence, flag if
 *      no matching race, find matched_candidate_id/race_id, INSERT staging row.
 *   6. Withdrawal diff: for each race the agent touched, compare existing
 *      race_candidates against discovered names. Missing = withdrawal staging row.
 *   7. UPDATE discovery_runs to status='completed' with counts + raw_output.
 *   8. On any error after step 3: UPDATE run to status='failed', re-throw.
 *
 * triggeredBy: label stored on the run row ('on_demand' | 'cron').
 */
export async function runDiscoveryForJurisdiction(
  discoveryJurisdictionId: string,
  opts: { triggeredBy?: string } = {}
): Promise<DiscoveryRunSummary> {
  // --- 1. Load config ---
  const cfgResult = await pool.query<{
    id: string;
    jurisdiction_geoid: string;
    jurisdiction_name: string;
    state: string;
    election_date: Date;
    source_url: string | null;
    allowed_domains: string[] | null;
  }>(
    `SELECT id, jurisdiction_geoid, jurisdiction_name, state, election_date,
            source_url, allowed_domains
       FROM essentials.discovery_jurisdictions
      WHERE id = $1`,
    [discoveryJurisdictionId]
  );
  if (cfgResult.rows.length === 0) {
    throw new Error(
      `[discoveryService] No discovery_jurisdictions row with id=${discoveryJurisdictionId}`
    );
  }
  const cfg = cfgResult.rows[0];
  const electionDateStr = cfg.election_date.toISOString().slice(0, 10);

  // --- 2. Load known races + existing candidates ---
  const racesResult = await pool.query<{
    race_id: string;
    position_name: string;
    primary_party: string | null;
  }>(
    `SELECT r.id AS race_id, r.position_name, r.primary_party
       FROM essentials.races r
       JOIN essentials.elections e ON e.id = r.election_id
      WHERE e.election_date = $1 AND e.state = $2`,
    [cfg.election_date, cfg.state]
  );
  const knownRaces = racesResult.rows;

  const existingCandidates: Array<{ id: string; raceId: string; fullName: string }> =
    knownRaces.length
      ? (
          await pool.query<{ candidate_id: string; race_id: string; full_name: string }>(
            `SELECT rc.id AS candidate_id, rc.race_id, rc.full_name
               FROM essentials.race_candidates rc
              WHERE rc.race_id = ANY($1::uuid[])`,
            [knownRaces.map((r) => r.race_id)]
          )
        ).rows.map((r) => ({ id: r.candidate_id, raceId: r.race_id, fullName: r.full_name }))
      : [];

  // --- 3. Start run row ---
  const runInsert = await pool.query<{ id: string }>(
    `INSERT INTO essentials.discovery_runs
       (discovery_jurisdiction_id, jurisdiction_geoid, election_date, status, triggered_by)
     VALUES ($1, $2, $3, 'running', $4)
     RETURNING id`,
    [cfg.id, cfg.jurisdiction_geoid, cfg.election_date, opts.triggeredBy ?? 'on_demand']
  );
  const runId = runInsert.rows[0].id;

  try {
    // --- 4. Call agent ---
    const agentInput: DiscoveryAgentInput = {
      jurisdictionName: cfg.jurisdiction_name,
      state: cfg.state,
      electionDate: electionDateStr,
      sourceUrl: cfg.source_url,
      allowedDomains: cfg.allowed_domains,
      knownRaces: knownRaces.map((r) => ({
        position_name: r.position_name,
        primary_party: r.primary_party,
      })),
    };
    const agentResult: DiscoveryAgentResult = await runDiscoveryAgent(agentInput);

    // --- 5. Stage each discovered candidate ---
    const allowedDomains = cfg.allowed_domains;
    let candidatesStaged = 0;
    let uncertainStaged = 0;
    let matchedStaged = 0;
    let officialStaged = 0;
    const discoveredByRaceId = new Map<string, DiscoveredCandidate[]>();

    for (const cand of agentResult.candidates) {
      const domainOK = isDomainAllowlisted(cand.citation_url, allowedDomains);

      // Fuzzy match against existing candidates for confidence + matched_candidate_id
      let bestMatch: { candidateId: string; raceId: string; score: number } | null = null;
      for (const ex of existingCandidates) {
        const s = nameSimilarity(cand.full_name, ex.fullName);
        if (s >= NAME_MATCH_THRESHOLD && (!bestMatch || s > bestMatch.score)) {
          bestMatch = { candidateId: ex.id, raceId: ex.raceId, score: s };
        }
      }

      const confidence = scoreConfidence({
        domainOnAllowlist: domainOK,
        nameMatchesExistingCandidate: bestMatch !== null,
      });

      // race_id: from fuzzy match, or infer from race_hint vs position_name
      let raceId: string | null = bestMatch?.raceId ?? null;
      if (!raceId) {
        const raceFromHint = knownRaces.find(
          (r) => nameSimilarity(r.position_name, cand.race_hint) >= NAME_MATCH_THRESHOLD
        );
        if (raceFromHint) raceId = raceFromHint.race_id;
      }

      const flagged = raceId === null;
      const flagReason = flagged ? 'no matching race in DB' : null;

      await pool.query(
        `INSERT INTO essentials.candidate_staging
           (run_id, discovery_jurisdiction_id, full_name, normalized_name,
            citation_url, race_hint, race_id, matched_candidate_id,
            confidence, action, flagged, flag_reason, status)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, 'new', $10, $11, 'pending')`,
        [
          runId,
          cfg.id,
          cand.full_name,
          normalizeName(cand.full_name),
          cand.citation_url,
          cand.race_hint,
          raceId,
          bestMatch?.candidateId ?? null,
          confidence,
          flagged,
          flagReason,
        ]
      );
      candidatesStaged++;
      if (confidence === 'uncertain') uncertainStaged++;
      else if (confidence === 'matched') matchedStaged++;
      else officialStaged++;

      if (raceId) {
        const arr = discoveredByRaceId.get(raceId) ?? [];
        arr.push(cand);
        discoveredByRaceId.set(raceId, arr);
      }
    }

    // --- 6. Withdrawal diff (only for races the agent touched) ---
    let withdrawalsStaged = 0;
    for (const [raceId, discovered] of discoveredByRaceId.entries()) {
      const existingInThisRace = existingCandidates.filter((ex) => ex.raceId === raceId);
      for (const ex of existingInThisRace) {
        const matched = discovered.some(
          (d) => nameSimilarity(d.full_name, ex.fullName) >= NAME_MATCH_THRESHOLD
        );
        if (!matched) {
          await pool.query(
            `INSERT INTO essentials.candidate_staging
               (run_id, discovery_jurisdiction_id, full_name, normalized_name,
                citation_url, race_hint, race_id, matched_candidate_id,
                confidence, action, flagged, flag_reason, status)
             VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'uncertain', 'withdrawal', true, $9, 'pending')`,
            [
              runId,
              cfg.id,
              ex.fullName,
              normalizeName(ex.fullName),
              // citation_url NOT NULL; for withdrawals we use source_url or a stable placeholder
              cfg.source_url ?? `about:withdrawal-diff/${cfg.jurisdiction_geoid}/${electionDateStr}`,
              'withdrawal (diff)',
              raceId,
              ex.id,
              'no longer appears on official source',
            ]
          );
          withdrawalsStaged++;
        }
      }
    }

    // --- 7. Finalize run ---
    await pool.query(
      `UPDATE essentials.discovery_runs
          SET status = 'completed',
              completed_at = now(),
              candidates_found = $2,
              candidates_new = $3,
              candidates_withdrawn = $4,
              raw_output = $5::jsonb
        WHERE id = $1`,
      [
        runId,
        agentResult.candidates.length,
        candidatesStaged,
        withdrawalsStaged,
        JSON.stringify({
          model: agentResult.model,
          input_tokens: agentResult.inputTokens,
          output_tokens: agentResult.outputTokens,
          stop_reason: agentResult.stopReason,
          candidates: agentResult.candidates,
        }),
      ]
    );

    // --- 7b. Email notifications (post-completion) ---
    const adminEmail = process.env.ADMIN_EMAIL;
    const reviewUrl = process.env.ADMIN_REVIEW_URL ?? 'https://essentials.empowered.vote/admin/staging';

    if (adminEmail) {
      const daysUntilElection = Math.ceil((cfg.election_date.getTime() - Date.now()) / 86400000);

      // Review notification — fires when any candidates were staged
      if (candidatesStaged > 0) {
        const isUrgent = daysUntilElection <= 30;
        const subject = isUrgent
          ? `[URGENT] ${uncertainStaged} candidates need review — ${cfg.jurisdiction_name} election in ${daysUntilElection} days`
          : `${uncertainStaged} candidates need review — ${cfg.jurisdiction_name}`;
        const html = buildReviewEmailHtml({
          jurisdictionName: cfg.jurisdiction_name,
          uncertainStaged,
          matchedStaged,
          officialStaged,
          withdrawalsStaged,
          reviewUrl,
          daysUntilElection: isUrgent ? daysUntilElection : null,
        });
        await sendEmail({ to: adminEmail, subject, html });
      }

      // Zero-candidate regression alert — fires when this run returned zero but a previous run did not
      if (agentResult.candidates.length === 0) {
        const prevResult = await pool.query<{ candidates_found: number }>(
          `SELECT candidates_found
             FROM essentials.discovery_runs
            WHERE discovery_jurisdiction_id = $1
              AND status = 'completed'
              AND id <> $2
            ORDER BY completed_at DESC NULLS LAST
            LIMIT 1`,
          [cfg.id, runId]
        );
        const prevCount = prevResult.rows[0]?.candidates_found ?? null;
        if (prevCount !== null && prevCount > 0) {
          await sendEmail({
            to: adminEmail,
            subject: `Zero candidates returned — ${cfg.jurisdiction_name} (was ${prevCount})`,
            html: `
              <div style="font-family: system-ui, sans-serif; max-width: 560px;">
                <h2 style="margin: 0 0 8px 0;">Zero candidates returned</h2>
                <p>Jurisdiction: <strong>${cfg.jurisdiction_name}</strong></p>
                <p>This run found 0 candidates. The previous completed run found <strong>${prevCount}</strong>.</p>
                <p>This may indicate an upstream source change. Investigate the allowed_domains source pages.</p>
              </div>
            `,
          });
        }
      }
    }

    return {
      runId,
      jurisdictionId: cfg.id,
      candidatesFound: agentResult.candidates.length,
      candidatesStaged,
      uncertainStaged,
      matchedStaged,
      officialStaged,
      withdrawalsStaged,
      status: 'completed',
      errorMessage: null,
    };
  } catch (err) {
    // --- 8. Mark run failed and re-throw ---
    const message = err instanceof Error ? err.message : String(err);
    await pool.query(
      `UPDATE essentials.discovery_runs
          SET status = 'failed', completed_at = now(), error_message = $2
        WHERE id = $1`,
      [runId, message]
    );

    // --- 8b. Failure email (fire-and-forget semantics via sendEmail's internal try/catch) ---
    const adminEmail = process.env.ADMIN_EMAIL;
    if (adminEmail) {
      await sendEmail({
        to: adminEmail,
        subject: `Discovery run failed — ${cfg.jurisdiction_name}`,
        html: `
          <div style="font-family: system-ui, sans-serif; max-width: 560px;">
            <h2 style="margin: 0 0 8px 0;">Discovery run failed</h2>
            <p>Jurisdiction: <strong>${cfg.jurisdiction_name}</strong></p>
            <p>Run ID: <code>${runId}</code></p>
            <p>Error:</p>
            <pre style="background:#f5f5f5;padding:10px;border-radius:4px;white-space:pre-wrap;">${message}</pre>
          </div>
        `,
      });
    }

    throw err;
  }
}
