/**
 * GET /api/treasury/coverage — the public, geoid-keyed coverage catalog.
 *
 * Civic Spaces Ask 2. Lets any consumer turn a Census FIPS geoid into a
 * Treasury Tracker deep link. Mirrors the shape TT already consumes from
 * Essentials, plus `slug`.
 *
 * ── ⚠⚠ WHY THIS IS ITS OWN ROUTER, AND WHERE IT MUST BE MOUNTED ────────────
 *
 * The app-wide CORS policy in index.ts is an exact-match allowlist with
 * `credentials: true`. **A browser REJECTS `Access-Control-Allow-Credentials:
 * true` alongside `Access-Control-Allow-Origin: *`.** So a route-level
 * `cors({ origin: '*' })` layered AFTER the global middleware produces a
 * response that fails in exactly the cross-origin consumers this endpoint
 * exists to serve — while passing every server-side test, because the
 * contradiction is enforced by the browser and not by us.
 *
 * Mounting ahead of the global middleware means this endpoint never acquires
 * the credentialed header at all. It needs neither cookies nor a body parser:
 * it is an unauthenticated GET of public data.
 *
 *     app.use(helmet());
 *     app.use('/api/treasury/coverage', publicCoverageRouter);  // ← HERE
 *     app.use(cookieParser());
 *     app.use(cors({ ...allowlist, credentials: true }));
 *
 * publicCoverage.test.ts asserts that `Access-Control-Allow-Credentials` is
 * ABSENT, because that is the header whose presence silently breaks consumers.
 *
 * ── Size ───────────────────────────────────────────────────────────────────
 *
 * The catalog is ~810 kB uncompressed, past the ~500 kB line the consumer drew,
 * and this API has no global compression. Compression is applied to THIS ROUTE
 * ONLY so no other endpoint's response behaviour changes.
 */

import { Router } from 'express';
import cors from 'cors';
import compression from 'compression';
import type { Request, Response } from 'express';
import { getCoverageCatalog } from '../lib/treasuryService.js';

const router = Router();

// ⚠ Public data, any origin, NO credentials. The absence of credentials is the
// point: it is what makes `origin: '*'` legal in a browser.
router.use(cors({ origin: '*', credentials: false }));
router.use(compression());

router.get('/', async (_req: Request, res: Response): Promise<void> => {
  try {
    const catalog = await getCoverageCatalog();
    // The catalog changes only when entities or budgets do. An hour is well
    // inside that, and `generatedAt` lets a consumer see staleness for itself.
    res.set('Cache-Control', 'public, max-age=3600');
    res.status(200).json(catalog);
  } catch (err) {
    console.error('[GET /treasury/coverage] error:', err);
    res.status(500).json({ code: 'INTERNAL_ERROR', message: 'An unexpected error occurred' });
  }
});

export default router;
