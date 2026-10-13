import { describe, it, expect } from 'vitest';
import { readFileSync } from 'node:fs';

const INDEX = new URL('../index.ts', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1');

/**
 * 🔴 THE BUG THIS EXISTS TO PREVENT, BECAUSE IT SHIPPED ONCE.
 *
 * `compassAdmin.ts` opens with a PATH-LESS `router.use(requireAuth,
 * requireAdmin)`. Express runs that for every request that reaches the router,
 * matching route or not — so any router mounted on `/api/compass` AFTER it is
 * unreachable to an anonymous caller. The request falls through the earlier
 * routers, hits the blanket gate, and comes back 401.
 *
 * That is exactly what happened to the public journal routes: merged, deployed
 * live, and answering 401 to everybody. It is also why an unknown
 * /api/compass/* path answers 401 rather than 404.
 *
 * ⚠ NO ROUTE-LEVEL TEST CAN CATCH THIS. Each router's own tests mount that
 * router alone, where there is no gate in front of it, so they all passed. The
 * failure lives in the composition, which only this file looks at.
 *
 * If a new public router joins this prefix, it goes in the list below AND above
 * compassAdminRouter in index.ts.
 */
describe('public /api/compass routers mount before the admin auth gate', () => {
  const src = readFileSync(INDEX, 'utf8');
  const at = (name: string): number =>
    src.indexOf(`app.use('/api/compass', ${name});`);

  const PUBLIC = ['compassContributorRouter', 'compassRouter', 'compassJournalRouter'];

  it.each(PUBLIC)('%s is mounted before compassAdminRouter', (name) => {
    const pub = at(name);
    const gate = at('compassAdminRouter');

    expect(pub, `${name} is not mounted on /api/compass at all`).toBeGreaterThan(-1);
    expect(gate, 'compassAdminRouter is not mounted on /api/compass').toBeGreaterThan(-1);
    expect(
      pub,
      `${name} is mounted AFTER compassAdminRouter, whose path-less ` +
      'requireAuth/requireAdmin runs for every request that reaches it. Every ' +
      'route in ' + name + ' will answer 401 to anonymous callers. Move it above.',
    ).toBeLessThan(gate);
  });

  // The premise. If compassAdmin ever gains a path for its middleware, this
  // guard is measuring something that no longer exists and should be revisited
  // rather than left passing for the wrong reason.
  it('compassAdmin still gates path-lessly, which is why order matters', () => {
    const admin = readFileSync(
      new URL('../routes/compassAdmin.ts', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1'),
      'utf8',
    );
    expect(admin).toMatch(/router\.use\(\s*requireAuth/);
  });
});
