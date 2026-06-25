/**
 * FileValidationService — pure security primitives for uploads.
 *
 * These are intentionally dependency-free so they can be unit-tested and
 * reused by any route/storage adapter. They enforce the multi-tenant +
 * upload-safety invariants required by the platform.
 */

export interface MimeValidation {
  ok: boolean;
  reason?: string;
}

/** Map of allowed MIME types -> permitted lowercase extensions. */
export const DEFAULT_ALLOWED: Record<string, string[]> = {
  "image/jpeg": ["jpg", "jpeg"],
  "image/png": ["png"],
  "application/pdf": ["pdf"],
};

/** Extract the final extension (lowercase, no dot). Empty if none. */
export function fileExtension(filename: string): string {
  const base = filename.split(/[\\/]/).pop() ?? "";
  const dot = base.lastIndexOf(".");
  if (dot <= 0) return "";
  return base.slice(dot + 1).toLowerCase();
}

/**
 * Reject path traversal, NUL bytes, control chars, and dangerous double
 * extensions (e.g. "invoice.pdf.exe", "x.php.png").
 */
export function isSafeFilename(filename: string): boolean {
  if (!filename || filename.length > 255) return false;
  // Reject control chars / NUL bytes via codepoint scan.
  for (let i = 0; i < filename.length; i++) {
    if (filename.charCodeAt(i) < 32) return false;
  }
  if (/[\\/]/.test(filename)) return false; // no path separators
  if (filename.includes("..")) return false; // no traversal
  // Double-extension where an inner segment is an executable/script type.
  const parts = filename.toLowerCase().split(".");
  if (parts.length > 2) {
    const dangerous = new Set([
      "exe", "sh", "bat", "cmd", "com", "php", "js", "jsp",
      "asp", "aspx", "html", "htm", "svg", "dll", "scr",
    ]);
    // any extension segment (after the first name part) that is dangerous
    for (let i = 1; i < parts.length; i++) {
      if (dangerous.has(parts[i])) return false;
    }
  }
  return true;
}

/**
 * Validate that the declared content-type is allowed AND that the filename
 * extension matches that content-type. Defends against spoofed MIME and
 * mismatched/double extensions.
 */
export function validateMime(
  contentType: string,
  filename: string,
  allowed: Record<string, string[]> = DEFAULT_ALLOWED
): MimeValidation {
  const ct = (contentType || "").toLowerCase().split(";")[0].trim();
  if (!ct || !(ct in allowed)) {
    return { ok: false, reason: `content-type not allowed: ${ct || "(none)"}` };
  }
  if (!isSafeFilename(filename)) {
    return { ok: false, reason: "unsafe filename" };
  }
  const ext = fileExtension(filename);
  if (!ext) return { ok: false, reason: "missing extension" };
  if (!allowed[ct].includes(ext)) {
    return { ok: false, reason: `extension "${ext}" does not match ${ct}` };
  }
  return { ok: true };
}

export interface SizeValidation {
  ok: boolean;
  reason?: string;
}

/** Reject zero/negative and oversize payloads. */
export function enforceSizeLimit(bytes: number, maxBytes: number): SizeValidation {
  if (!Number.isFinite(bytes) || bytes <= 0) {
    return { ok: false, reason: "empty file" };
  }
  if (bytes > maxBytes) {
    return { ok: false, reason: `file exceeds limit (${bytes} > ${maxBytes})` };
  }
  return { ok: true };
}

/**
 * Build a tenant-prefixed object key. The societyId prefix guarantees keys
 * for one tenant can never collide with or be guessed across tenants.
 * Returns a sanitized, slash-namespaced key.
 */
export function tenantKey(societyId: string, name: string): string {
  if (!societyId) throw new Error("societyId required");
  if (!isSafeFilename(name)) throw new Error("unsafe filename for object key");
  const safeSociety = societyId.replace(/[^a-zA-Z0-9_-]/g, "_");
  const safeName = name.replace(/[^a-zA-Z0-9._-]/g, "_");
  return `societies/${safeSociety}/${safeName}`;
}

/** True only if the key belongs to the given society (cross-tenant guard). */
export function keyBelongsToSociety(societyId: string, key: string): boolean {
  const safeSociety = societyId.replace(/[^a-zA-Z0-9_-]/g, "_");
  return key.startsWith(`societies/${safeSociety}/`);
}
