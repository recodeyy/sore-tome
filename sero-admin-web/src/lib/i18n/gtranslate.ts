// Whole-site translation via the Google Website Translate widget (§8 demo
// multilingual). The dictionary (dictionaries.ts) covers nav/labels for instant,
// high-quality strings; this layer translates ALL remaining page content
// (tables, headings, body) into hi/mr/gu/kn. Numbers, IDs and receipt numbers
// are left alone by Google Translate, satisfying the "don't mistranslate IDs/
// amounts" requirement.

export const GT_INCLUDED = "en,hi,mr,gu,kn";
const GT_ELEMENT_ID = "google_translate_element";

let injected = false;

/** Inject the Google Translate script + hidden mount point exactly once. */
export function ensureGoogleTranslate(): void {
  if (typeof window === "undefined" || injected) return;
  injected = true;

  if (!document.getElementById(GT_ELEMENT_ID)) {
    const div = document.createElement("div");
    div.id = GT_ELEMENT_ID;
    div.style.display = "none";
    document.body.appendChild(div);
  }

  (window as unknown as Record<string, unknown>).googleTranslateElementInit = () => {
    const g = (window as unknown as { google?: any }).google;
    if (!g?.translate?.TranslateElement) return;
    // eslint-disable-next-line no-new
    new g.translate.TranslateElement(
      { pageLanguage: "en", includedLanguages: GT_INCLUDED, autoDisplay: false },
      GT_ELEMENT_ID
    );
  };

  const s = document.createElement("script");
  s.src =
    "https://translate.google.com/translate_a/element.js?cb=googleTranslateElementInit";
  s.async = true;
  document.body.appendChild(s);
}

function setGoogtransCookie(value: string): void {
  // Path cookie works on any host (incl. *.cloudfront.net where a domain cookie
  // would be rejected by the public-suffix list).
  document.cookie = `googtrans=${value};path=/`;
  try {
    document.cookie = `googtrans=${value};path=/;domain=${location.hostname}`;
    document.cookie = `googtrans=${value};path=/;domain=.${location.hostname}`;
  } catch {
    /* ignore */
  }
}

/**
 * Fully remove every `googtrans` cookie variant we may have set (path-only,
 * host-scoped and dot-host-scoped). This is required to restore English:
 * setting the cookie to "/en/en" does NOT overwrite a differently-scoped
 * leftover like "/en/gu;domain=host", so Google would keep re-applying the old
 * language on reload. Expiring all variants guarantees a clean slate.
 */
function clearGoogtransCookies(): void {
  const expire = "expires=Thu, 01 Jan 1970 00:00:00 GMT";
  document.cookie = `googtrans=;path=/;${expire}`;
  try {
    document.cookie = `googtrans=;path=/;domain=${location.hostname};${expire}`;
    document.cookie = `googtrans=;path=/;domain=.${location.hostname};${expire}`;
  } catch {
    /* ignore */
  }
}

/**
 * Switch the whole page to `lang`. Uses the widget's hidden <select> for an
 * in-place translation (no reload) and persists via the googtrans cookie so
 * subsequent page loads stay translated. English clears the cookie and reloads
 * to fully restore the original text.
 */
export function applyLanguage(lang: string): void {
  if (typeof document === "undefined") return;

  if (lang === "en") {
    // Was the page actually translated? (any non-empty googtrans cookie).
    const wasTranslated = /(^|;\s*)googtrans=\/en\/(?!en\b)/.test(document.cookie);
    // Delete every googtrans cookie variant (not just set "/en/en") so no
    // leftover host-scoped "/en/gu" cookie can re-translate the page on reload.
    clearGoogtransCookies();
    // Google's in-place "restore original" is unreliable; a reload with the
    // cookies cleared guarantees clean English. Only reload if we were
    // translated, so re-selecting English doesn't needlessly refresh.
    if (wasTranslated) location.reload();
    return;
  }

  setGoogtransCookie(`/en/${lang}`);

  let tries = 0;
  const trigger = () => {
    const combo = document.querySelector<HTMLSelectElement>("select.goog-te-combo");
    if (combo) {
      combo.value = lang;
      combo.dispatchEvent(new Event("change"));
      return;
    }
    if (tries++ < 30) setTimeout(trigger, 250); // widget still loading
  };
  trigger();
}
