"use client";
import React, { createContext, useContext, useState, useCallback } from "react";
import { CheckCircle2, XCircle, Info, X } from "lucide-react";

type ToastKind = "success" | "error" | "info";
type Toast = { id: number; kind: ToastKind; message: string };

const Ctx = createContext<{ push: (kind: ToastKind, message: string) => void }>({
  push: () => {},
});

let counter = 0;

export function ToastProvider({ children }: { children: React.ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([]);
  const push = useCallback((kind: ToastKind, message: string) => {
    const id = ++counter;
    setToasts((t) => [...t, { id, kind, message }]);
    setTimeout(() => setToasts((t) => t.filter((x) => x.id !== id)), 4500);
  }, []);
  const remove = (id: number) => setToasts((t) => t.filter((x) => x.id !== id));

  return (
    <Ctx.Provider value={{ push }}>
      {children}
      <div className="fixed bottom-4 right-4 z-[100] flex w-80 flex-col gap-2">
        {toasts.map((t) => (
          <div
            key={t.id}
            className="card flex items-start gap-3 p-3 text-sm shadow-lg animate-in"
          >
            {t.kind === "success" && <CheckCircle2 className="mt-0.5 h-5 w-5 text-brand-600" />}
            {t.kind === "error" && <XCircle className="mt-0.5 h-5 w-5 text-red-500" />}
            {t.kind === "info" && <Info className="mt-0.5 h-5 w-5 text-blue-500" />}
            <span className="flex-1 text-slate-700">{t.message}</span>
            <button onClick={() => remove(t.id)} className="text-slate-400 hover:text-slate-600">
              <X className="h-4 w-4" />
            </button>
          </div>
        ))}
      </div>
    </Ctx.Provider>
  );
}

export function useToast() {
  return useContext(Ctx);
}
