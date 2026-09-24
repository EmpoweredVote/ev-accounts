/**
 * `node --import` preload for the steward hooks. Lets a linked worktree that has no
 * backend/node_modules or backend/.env run the steward scripts with the MAIN checkout's.
 * Logic and the measured reason: ./main-checkout.mjs (pure, tested).
 *
 *   node --import ./backend/scripts/lib/main-checkout-fallback.mjs backend/scripts/steward.mjs who
 *
 * - A BARE import that fails to resolve here is retried from <main>/backend (module.registerHooks).
 *   Only then: a worktree with its own node_modules resolves exactly as before.
 * - <main>/backend/.env is loaded only if this checkout has no backend/.env. Variables already in the
 *   environment win, and the script's own dotenv call still loads this checkout's .env first.
 *
 * 🔴 IT NEVER THROWS. It runs inside git and session hooks that must never fail because of it; on
 *    any error the script runs exactly as it would have without the preload. The one thing it does
 *    say out loud is a Node too old to borrow modules, because staying silent there is the defect
 *    this file exists to remove.
 */
import { execFileSync } from "node:child_process";
import fs from "node:fs";
import module from "node:module";
import path from "node:path";
import { fileURLToPath, pathToFileURL } from "node:url";

import { mainCheckoutPlan, shouldRetryFromMain } from "./main-checkout.mjs";

try {
  const here = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..", "..");
  const commonDir = execFileSync("git", ["rev-parse", "--path-format=absolute", "--git-common-dir"], {
    cwd: here, encoding: "utf8", stdio: ["ignore", "pipe", "ignore"],
  }).trim();
  const plan = mainCheckoutPlan({ here, commonDir, exists: fs.existsSync });

  if (plan.modules) {
    if (typeof module.registerHooks === "function") {
      const parentURL = pathToFileURL(path.join(plan.mainBackend, "package.json")).href;
      module.registerHooks({
        resolve(specifier, context, nextResolve) {
          try {
            return nextResolve(specifier, context);
          } catch (err) {
            if (!shouldRetryFromMain(specifier, err?.code)) throw err;
            return nextResolve(specifier, { ...context, parentURL });
          }
        },
      });
    } else {
      console.error(`  steward: Node ${process.version} cannot borrow the main checkout's node_modules `
        + "(needs module.registerHooks, Node 22.15+); run `npm ci --prefix backend` in this worktree.");
    }
  }
  if (plan.env) process.loadEnvFile(path.join(plan.mainBackend, ".env"));
} catch {
  // fail open: see the header
}
