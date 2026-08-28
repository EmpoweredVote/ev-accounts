import { describe, it, expect } from 'vitest';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

/**
 * Two boot-time invariants that CI could not see, and that broke two production
 * deploys on 2026-08-28 (#190 and #199 both `update_failed` on Render).
 *
 * NEITHER shows up in lint, typecheck or the unit suite, because all three pass on
 * source while the failures happen when Node INSTANTIATES the compiled ES modules,
 * or when a module-scope constructor runs on the deployed runtime.
 */

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const BACKEND = path.resolve(__dirname, '../..');

// ---------------------------------------------------------------------------
// 1. js-yaml has no default export since v5
// ---------------------------------------------------------------------------

describe('js-yaml is imported by name, not by default', () => {
  // Deploy #199 bumped js-yaml ^4.1.1 -> ^5.4.1. v5 ships a real ESM build whose
  // exports are named only: load, dump, Schema, ... and NO default. So
  // `import yaml from 'js-yaml'` fails at module instantiation:
  //
  //   SyntaxError: The requested module 'js-yaml' does not provide an export named 'default'
  //
  // tsc accepts it (esModuleInterop smooths the types over) and no unit test imported
  // the module, so the first thing to notice was the production boot.

  it('exposes load as a named export and no default at all', async () => {
    const ns = await import('js-yaml');
    expect(typeof ns.load).toBe('function');
    expect('default' in ns).toBe(false);
  });

  it('has no default import of js-yaml anywhere in src or scripts', () => {
    const roots = [path.join(BACKEND, 'src'), path.join(BACKEND, 'scripts')];
    const offenders: string[] = [];

    const walk = (dir: string) => {
      if (!fs.existsSync(dir)) return;
      for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
        const full = path.join(dir, entry.name);
        if (entry.isDirectory()) {
          if (entry.name === 'node_modules' || entry.name === 'dist') continue;
          walk(full);
          continue;
        }
        if (!/\.(ts|mts|mjs|js)$/.test(entry.name)) continue;
        // Strip comments before matching. The first version of this check flagged THIS
        // file, because the offending line is quoted in the comment above as an example.
        // A commented-out import is not an import, and a guard that cannot tell the
        // difference reports work that does not exist.
        const src = fs
          .readFileSync(full, 'utf8')
          .replace(/\/\*[\s\S]*?\*\//g, '')
          .replace(/^\s*\/\/.*$/gm, '');
        // `import yaml from 'js-yaml'` — a bare default import. A namespace import
        // (`import * as yaml`) and a named one (`import { load }`) are both fine.
        if (/import\s+(?!\*|\{|type\b)[A-Za-z_$][\w$]*\s+from\s+['"]js-yaml['"]/.test(src)) {
          offenders.push(path.relative(BACKEND, full).split(path.sep).join('/'));
        }
      }
    };
    roots.forEach(walk);

    expect(offenders).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// 1b. Rate-limit keys must not be a raw IPv6 address
// ---------------------------------------------------------------------------

describe('rate limiters key on a normalised IP, not a raw one', () => {
  // Surfaced by booting the built server after the express-rate-limit 7 -> 8 bump:
  //
  //   ValidationError: Custom keyGenerator appears to use request IP without calling
  //   the ipKeyGenerator helper function for IPv6 addresses. This could allow IPv6
  //   users to bypass limits.
  //
  // NOT a regression from v8 — v8 only started SAYING it. Keying on a bare IPv6
  // address has always been bypassable: a caller holding a /64 rotates addresses and
  // every request looks like a new client. ipKeyGenerator collapses IPv6 to a /56
  // (measured: 2001:db8:1234:5678:... -> 2001:db8:1234:5600::/56) and leaves IPv4
  // untouched, so the limit binds a network rather than a single address.
  //
  // Keying on userId FIRST is still correct and unchanged; this is only the fallback.

  it('has no limiter falling back to a bare req.ip', () => {
    const routes = path.join(BACKEND, 'src', 'routes');
    const offenders: string[] = [];

    for (const entry of fs.readdirSync(routes, { withFileTypes: true })) {
      if (!entry.isFile() || !entry.name.endsWith('.ts') || entry.name.endsWith('.test.ts')) {
        continue;
      }
      const src = fs
        .readFileSync(path.join(routes, entry.name), 'utf8')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/^\s*\/\/.*$/gm, '');

      for (const line of src.split('\n')) {
        if (!line.includes('keyGenerator')) continue;
        // Fine: the IP is routed through the helper. Not fine: `req.ip` on its own.
        if (/\breq\.ip\b/.test(line) && !line.includes('ipKeyGenerator')) {
          offenders.push(`routes/${entry.name}: ${line.trim()}`);
        }
      }
    }

    expect(offenders).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// 2. The deployed Node must satisfy what @supabase/supabase-js needs
// ---------------------------------------------------------------------------

describe('the pinned production Node version supports the supabase client', () => {
  // Deploy #190 bumped @supabase/supabase-js to 2.112.4. Its realtime layer resolves a
  // WebSocket at createClient() time — not lazily — and throws when the global is
  // absent:
  //
  //   Error: Node.js detected but native WebSocket not found.
  //   Suggested solution: Ensure you are running Node.js 22+ or provide a
  //   WebSocket implementation via the transport option.
  //
  // globalThis.WebSocket is stable from Node 22. backend/.node-version pinned 20,
  // so lib/supabase.ts threw at module scope and the server never listened.
  //
  // 🔴 CI DID NOT CATCH THIS BECAUSE CI RUNS NODE 22 AND PRODUCTION RAN NODE 20.
  // Reproduced by deleting globalThis.WebSocket before createClient: it throws.
  // Keep this floor at or above 22 for as long as supabase-js is a dependency.

  const MIN_MAJOR = 22;

  it('pins Node 22 or newer in .node-version', () => {
    const pin = fs.readFileSync(path.join(BACKEND, '.node-version'), 'utf8').trim();
    const major = Number.parseInt(pin.replace(/^v/, '').split('.')[0]!, 10);

    expect(Number.isInteger(major)).toBe(true);
    expect(major).toBeGreaterThanOrEqual(MIN_MAJOR);
  });

  it('runs its own tests on a Node that matches or exceeds that pin', () => {
    // The two drifting apart is what hid the defect. CI on 22 and prod on 20 meant
    // the suite could never exercise the runtime that actually serves traffic.
    const pin = fs.readFileSync(path.join(BACKEND, '.node-version'), 'utf8').trim();
    const pinned = Number.parseInt(pin.replace(/^v/, '').split('.')[0]!, 10);
    const running = Number.parseInt(process.versions.node.split('.')[0]!, 10);

    expect(running).toBeGreaterThanOrEqual(pinned);
  });
});
