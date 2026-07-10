// OpenNext build wrapper (Windows deploy hardening).
//
// Why this exists: OpenNext bundles the image-optimizer Lambda by running
// `npm install sharp` inside a fresh dir under os.tmpdir(). On this machine the
// default %TEMP% is C:\Users\<user>\AppData\Local\Temp, and C:\Users\<user> contains
// a stray node_modules/package.json. npm walks UP from the temp dir, finds that
// ancestor, and installs sharp THERE instead — leaving the temp dir empty, so
// OpenNext's later `fs.cpSync(tempDir/node_modules, ...)` throws ENOENT (which its
// own logger then masks with a `e.stdout.toString()` crash).
//
// Fix: point os.tmpdir() at C:\sst-tmp, whose only ancestor (C:\) has no
// node_modules/package.json, so `npm install` creates a LOCAL node_modules and the
// copy succeeds. Setting the env HERE (the direct parent of the OpenNext process)
// guarantees propagation — an outer shell export gets scrubbed by pulumi's Command.
//
// No-op friendliness: on Linux/CI TMPDIR is already clean, but forcing a dedicated
// temp dir is harmless there too.
import { spawnSync } from "node:child_process";
import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const scriptsDir = path.dirname(fileURLToPath(import.meta.url));
const isWin = process.platform === "win32";
const tmp = isWin ? "C:/sst-tmp" : (process.env.TMPDIR || "/tmp");
fs.mkdirSync(tmp, { recursive: true });
process.env.TEMP = tmp;
process.env.TMP = tmp;
process.env.TMPDIR = tmp;

// Preload the two Windows build shims INTO the OpenNext child process:
//   patch-readlink.cjs  -> Node-24 Windows readlink EISDIR during `next build`
//   patch-mkdtemp.cjs   -> OpenNext's malformed image-optimizer temp-dir name (drive colon)
// Both are no-ops on Linux. Merge with any existing NODE_OPTIONS.
// Use forward slashes (Node accepts them on Windows) and no quotes — backslashes and
// quotes get mangled when NODE_OPTIONS passes through the shell. The paths have no spaces.
const toPosix = (p) => p.replace(/\\/g, "/");
const requires = [
  toPosix(path.join(scriptsDir, "patch-readlink.cjs")),
  toPosix(path.join(scriptsDir, "patch-mkdtemp.cjs")),
].map((p) => `--require ${p}`).join(" ");
process.env.NODE_OPTIONS = [process.env.NODE_OPTIONS, requires].filter(Boolean).join(" ");

// Same OpenNext version SST selects for Next 14. `npx --yes` reuses the local npx
// cache (no network) when the version already resolved once.
const res = spawnSync(
  "npx",
  ["--yes", "@opennextjs/aws@3.6.6", "build"],
  { stdio: "inherit", shell: true, env: process.env, cwd: process.cwd() }
);
process.exit(res.status ?? 1);
