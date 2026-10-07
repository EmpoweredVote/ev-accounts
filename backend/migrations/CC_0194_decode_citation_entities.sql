-- CC_0194 — decode HTML character references in published citation spans
--
-- WHY. inform.politician_context_evidence.snippet holds the matched on-page span, and that span is
-- what a voter reads under "why this position?". It was stored exactly as the page's extracted text
-- had it, and verificationFetch's htmlToText does not decode named references — so a citation cut
-- from a news page put a literal "&mdash;" or "&ldquo;" in front of the reader.
--
-- Matching was never affected: the researcher's snippet was copied from the same extracted page and
-- carried the same literal text, so both sides compared equal. Only the published text was wrong.
--
-- Measured 2026-10-06 across all 263 rows of the table: 8 carry a named reference, 0 carry a
-- numeric one. The references present are exactly &sect; &rsquo; &ldquo; &rdquo; &mdash;.
--
-- The companion code change (researchVerifier.ts) decodes the span before storing it, so new rows
-- arrive clean; this migration fixes the rows already written. The two share one entity table —
-- keep them in step if either grows.
--
-- &amp; is decoded LAST, so a doubly-escaped "&amp;mdash;" resolves to "&mdash;" here and is then
-- left alone, rather than collapsing two steps at once in an order that depends on the pass.
--
-- Idempotent: decoding an already-decoded span is a no-op. Post-verify gate raises if any row still
-- carries one of the references this migration knows.

BEGIN;

UPDATE inform.politician_context_evidence
   SET snippet = replace(
                   replace(
                     replace(
                       replace(
                         replace(
                           replace(
                             replace(
                               replace(
                                 replace(
                                   replace(
                                     replace(snippet, '&ldquo;', U&'\201C'),
                                   '&rdquo;', U&'\201D'),
                                 '&lsquo;', U&'\2018'),
                               '&rsquo;', U&'\2019'),
                             '&mdash;', U&'\2014'),
                           '&ndash;', U&'\2013'),
                         '&hellip;', U&'\2026'),
                       '&sect;', U&'\00A7'),
                     '&nbsp;', ' '),
                   '&quot;', '"'),
                 '&amp;', '&')
 WHERE snippet ~ '&(ldquo|rdquo|lsquo|rsquo|mdash|ndash|hellip|sect|nbsp|quot|amp);';

DO $$
DECLARE
  v_left int;
BEGIN
  SELECT count(*) INTO v_left
    FROM inform.politician_context_evidence
   WHERE snippet ~ '&(ldquo|rdquo|lsquo|rsquo|mdash|ndash|hellip|sect|nbsp|quot|amp);';

  IF v_left <> 0 THEN
    RAISE EXCEPTION 'CC_0194: % citation span(s) still carry a decodable reference', v_left;
  END IF;

  -- The table must not have been emptied or mangled by the rewrite.
  IF (SELECT count(*) FROM inform.politician_context_evidence) < 1 THEN
    RAISE EXCEPTION 'CC_0194: politician_context_evidence is empty after the rewrite — refusing';
  END IF;
END $$;

COMMIT;
