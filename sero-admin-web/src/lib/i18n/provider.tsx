"use client";
import React, { createContext, useContext, useEffect, useState, useCallback } from "react";
import { Lang, translate } from "./dictionaries";

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

  useEffect(() => {
    const saved = (typeof window !== "undefined" &&
      (localStorage.getItem(STORAGE_KEY) as Lang)) || "en";
    setLangState(saved);
  }, []);

  const setLang = useCallback((l: Lang) => {
    setLangState(l);
    try {
      localStorage.setItem(STORAGE_KEY, l);
      document.cookie = `${STORAGE_KEY}=${l}; path=/; max-age=${60 * 60 * 24 * 365}`;
      document.documentElement.lang = l;
    } catch {
      /* ignore */
    }
  }, []);

  const t = useCallback((key: string) => translate(lang, key), [lang]);

  return <Ctx.Provider value={{ lang, setLang, t }}>{children}</Ctx.Provider>;
}

export function useI18n() {
  return useContext(Ctx);
}
