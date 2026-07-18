"use client";
import React, { createContext, useContext, useEffect, useState, useCallback } from "react";
import { usePathname } from "next/navigation";
import { Lang, translate } from "./dictionaries";
import { ensureGoogleTranslate, applyLanguage } from "./gtranslate";

type I18nContext = {
  lang: Lang;
  setLang: (l: Lang) => void;
  t: (key: string) => string;
};

const Ctx = createContext<I18nContext>({
  lang: "en",
  setLang: () => {},
  t: (k) => k,
});

const STORAGE_KEY = "sero_lang";

export function I18nProvider({ children }: { children: React.ReactNode }) {
  const [lang, setLangState] = useState<Lang>("en");
  const pathname = usePathname();

  // Restore saved language. The Google Translate widget is only booted when a
  // non-English language is actually in use: its element.js pulls further
  // el_main css/js resources that can hang in "pending" forever (observed on
  // CloudFront in-region), which keeps the document from ever reaching idle —
  // the page looks hung and automation/lighthouse time out. English users
  // never need the widget, so don't pay that cost on every load.
  useEffect(() => {
    const saved = (typeof window !== "undefined" &&
      (localStorage.getItem(STORAGE_KEY) as Lang)) || "en";
    setLangState(saved);
    if (saved !== "en") {
      ensureGoogleTranslate();
      setTimeout(() => applyLanguage(saved), 600); // let the widget mount first
    }
  }, []);

  // Re-apply the active language after client-side navigation (App Router does
  // not full-reload, so a freshly rendered page would otherwise show English).
  useEffect(() => {
    if (lang !== "en") {
      const id = setTimeout(() => applyLanguage(lang), 400);
      return () => clearTimeout(id);
    }
  }, [pathname, lang]);

  const setLang = useCallback((l: Lang) => {
    setLangState(l);
    try {
      localStorage.setItem(STORAGE_KEY, l);
      document.cookie = `${STORAGE_KEY}=${l}; path=/; max-age=${60 * 60 * 24 * 365}`;
      document.documentElement.lang = l;
    } catch {
      /* ignore */
    }
    if (l !== "en") ensureGoogleTranslate(); // lazy-boot on first real use
    applyLanguage(l); // translate the whole page, not just dictionary strings
  }, []);

  const t = useCallback((key: string) => translate(lang, key), [lang]);

  return <Ctx.Provider value={{ lang, setLang, t }}>{children}</Ctx.Provider>;
}

export function useI18n() {
  return useContext(Ctx);
}
