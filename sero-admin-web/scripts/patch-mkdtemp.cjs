/*
 * OpenNext-on-Windows bug shim (loaded via NODE_OPTIONS="--require").
 *
 * OpenNext derives the temp-dir name for its per-function dependency install with
 * `outputDir.split("/").pop()` (build/installDeps.js). On Windows `outputDir` is an
 * absolute path with BACKSLASHES (e.g. C:\proj\.open-next\image-optimization-function),
 * so `split("/")` does not split it and the whole path — including the drive colon —
 * becomes the temp-dir name. `fs.mkdtempSync(path.join(os.tmpdir(), "open-next-install-" + name))`
 * then gets a prefix containing an embedded "C:\...", which is an invalid path, and
 * fails with ENOENT. OpenNext's catch block masks the real error with `e.stdout.toString()`.
 *
 * This shim normalizes only that malformed prefix: everything after the
 * "open-next-install-" marker has its path separators / drive colons collapsed to "-",
 * yielding a single valid directory name. No-op on Linux (paths already use "/").
 */
const fs = require("fs");

function sanitize(prefix) {
  if (typeof prefix !== "string") return prefix;
  const marker = "open-next-install-";
  const i = prefix.indexOf(marker);
  if (i === -1) return prefix;
  const head = prefix.slice(0, i + marker.length);
  const tail = prefix.slice(i + marker.length).replace(/[:\\/]+/g, "-");
  return head + tail;
}

const origSync = fs.mkdtempSync;
fs.mkdtempSync = function (prefix, ...rest) {
  return origSync.call(this, sanitize(prefix), ...rest);
};

const origAsync = fs.mkdtemp;
fs.mkdtemp = function (prefix, ...rest) {
  return origAsync.call(this, sanitize(prefix), ...rest);
};

if (fs.promises && fs.promises.mkdtemp) {
  const origP = fs.promises.mkdtemp;
  fs.promises.mkdtemp = function (prefix, ...rest) {
    return origP.call(this, sanitize(prefix), ...rest);
  };
}
