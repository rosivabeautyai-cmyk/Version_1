/**
 * Vendors the canonical affiliate-sync framework into the Render
 * backend.
 *
 *   canonical:  scripts/affiliate-sync/{lib,connectors,syncEngine.mjs,testConnection.mjs}
 *   vendored:   server/src/affiliate/**            (checked in, generated)
 *
 * Why a copy and not an import: the Render Docker build context is
 * `server/` only (see server/Dockerfile), so the backend cannot import
 * a path outside that folder. GitHub Actions runs the canonical copy
 * directly. Keeping ONE canonical source + a generated, checked-in copy
 * avoids drift while respecting the deploy boundary.
 *
 * Run:  node scripts/sync-vendor.mjs           # write the copy
 *       node scripts/sync-vendor.mjs --check   # exit 1 if out of sync (CI / test)
 */

import { readFileSync, writeFileSync, mkdirSync, readdirSync, statSync, existsSync, rmSync } from "node:fs";
import { join, dirname, relative } from "node:path";
import { fileURLToPath } from "node:url";

const ROOT = join(dirname(fileURLToPath(import.meta.url)), "..");
const SRC = join(ROOT, "scripts", "affiliate-sync");
const DEST = join(ROOT, "server", "src", "affiliate");

const INCLUDE_DIRS = ["lib", "connectors"];
const INCLUDE_FILES = ["syncEngine.mjs", "testConnection.mjs"];

const HEADER =
  "/* AUTO-GENERATED COPY of scripts/affiliate-sync — DO NOT EDIT HERE.\n" +
  "   Edit the canonical files and run `node scripts/sync-vendor.mjs`. */\n";

function collect(dir, base = dir) {
  const out = [];
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    const st = statSync(full);
    if (st.isDirectory()) {
      if (entry === "node_modules" || entry === "test") continue;
      out.push(...collect(full, base));
    } else if (entry.endsWith(".mjs")) {
      out.push(full);
    }
  }
  return out;
}

const files = [
  ...INCLUDE_DIRS.flatMap((d) => collect(join(SRC, d))),
  ...INCLUDE_FILES.map((f) => join(SRC, f)),
];

// The Awin connector imports ../../awin-sync/rosivaClassifier.mjs.
// Vendor that single file too so the path resolves inside server/.
const EXTRA = [
  {
    from: join(ROOT, "scripts", "awin-sync", "rosivaClassifier.mjs"),
    rel: join("awin-sync", "rosivaClassifier.mjs"),
  },
];

const check = process.argv.includes("--check");
let drift = 0;

if (!check && existsSync(DEST)) rmSync(DEST, { recursive: true, force: true });

const work = [
  ...files.map((file) => ({ file, rel: relative(SRC, file) })),
  ...EXTRA.map((e) => ({ file: e.from, rel: e.rel })),
];

for (const { file, rel } of work) {
  const target = join(DEST, rel);
  const body = HEADER + readFileSync(file, "utf8");
  if (check) {
    const current = existsSync(target) ? readFileSync(target, "utf8") : null;
    if (current !== body) {
      drift += 1;
      console.error(`OUT OF SYNC: server/src/affiliate/${rel.replace(/\\/g, "/")}`);
    }
  } else {
    mkdirSync(dirname(target), { recursive: true });
    writeFileSync(target, body);
  }
}

if (check) {
  if (drift) {
    console.error(`\n${drift} vendored file(s) differ. Run: node scripts/sync-vendor.mjs`);
    process.exit(1);
  }
  console.log("server/src/affiliate is in sync with scripts/affiliate-sync ✓");
} else {
  console.log(`Vendored ${work.length} files -> server/src/affiliate/`);
}
