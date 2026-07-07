/*
 * Node 24 on Windows returns EISDIR from fs.readlink / fs.readlinkSync when the
 * target is an ordinary (non-symlink) file. webpack's enhanced-resolve expects
 * EINVAL ("not a symbolic link") in that situation and aborts on EISDIR, which
 * breaks `next build` on Windows + Node 24.
 *
 * This preload shim (loaded via NODE_OPTIONS="--require") normalizes that single
 * error code so resolution proceeds exactly as it would on Linux/older Node.
 * It changes nothing else and is a no-op on platforms that already return EINVAL.
 */
const fs = require("fs");

function normalize(err) {
  if (err && err.code === "EISDIR" && err.syscall === "readlink") {
    err.code = "EINVAL";
    err.errno = -22;
  }
  return err;
}

const origSync = fs.readlinkSync;
fs.readlinkSync = function (...args) {
  try {
    return origSync.apply(this, args);
  } catch (err) {
    throw normalize(err);
  }
};

const origAsync = fs.readlink;
fs.readlink = function (...args) {
  const cb = args[args.length - 1];
  if (typeof cb === "function") {
    args[args.length - 1] = function (err, ...rest) {
      cb(normalize(err), ...rest);
    };
  }
  return origAsync.apply(this, args);
};

if (fs.promises && fs.promises.readlink) {
  const origP = fs.promises.readlink;
  fs.promises.readlink = function (...args) {
    return origP.apply(this, args).catch((err) => {
      throw normalize(err);
    });
  };
}
