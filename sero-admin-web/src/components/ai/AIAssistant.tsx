"use client";
import { useRef, useState } from "react";
import { Sparkles, X, Send, Mic, Volume2, Loader2, ShieldAlert } from "lucide-react";
import { useI18n } from "@/lib/i18n/provider";
import { useToast } from "@/components/ui/toast";

type Msg = {
  role: "user" | "assistant";
  content: string;
  action?: { label: string; path: string; method: string; body?: any } | null;
};

// Client-side heuristic: does this prompt look like a high-impact write action?
// The server/back-end is the real authority; this only decides whether to show
// an extra confirmation gate in the UI.
function detectHighImpact(text: string): boolean {
  return /\b(send|generate|create|delete|publish|charge|refund|reminder|remind|waive|approve|reject)\b/i.test(
    text
  );
}

export function AIAssistant({ portal }: { portal: string }) {
  const { t } = useI18n();
  const { push } = useToast();
  const [open, setOpen] = useState(false);
  const [input, setInput] = useState("");
  const [busy, setBusy] = useState(false);
  const [speaking, setSpeaking] = useState<number | null>(null);
  const [pendingConfirm, setPendingConfirm] = useState<string | null>(null);
  const [messages, setMessages] = useState<Msg[]>([
    {
      role: "assistant",
      content:
        portal === "super-admin"
          ? "Hi! Ask me about societies, churn risk, revenue adoption, or SLA breaches. I propose actions but never execute high-impact changes without your confirmation."
          : "Hi! Ask about dues, complaints, notices or collections. I propose actions but never execute high-impact changes without your confirmation.",
    },
  ]);
  const audioRef = useRef<HTMLAudioElement | null>(null);

  async function send(text: string, confirmed = false) {
    if (!text.trim()) return;
    if (detectHighImpact(text) && !confirmed) {
      setPendingConfirm(text);
      return;
    }
    setPendingConfirm(null);
    setMessages((m) => [...m, { role: "user", content: text }]);
    setInput("");
    setBusy(true);
    try {
      const res = await fetch("/api/ai/chat", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ message: text, portal, confirmed }),
      });
      const data = await res.json();
      const reply =
        data.reply ||
        data.message ||
        data.answer ||
        data?.data?.reply ||
        (typeof data === "string" ? data : "") ||
        "I couldn't produce a response.";
      setMessages((m) => [...m, { role: "assistant", content: reply }]);
    } catch (e: any) {
      setMessages((m) => [
        ...m,
        { role: "assistant", content: "The assistant is unavailable right now." },
      ]);
      push("error", "AI request failed");
    } finally {
      setBusy(false);
    }
  }

  async function speak(text: string, idx: number) {
    try {
      setSpeaking(idx);
      const res = await fetch("/api/voice/tts", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ text }),
      });
      if (!res.ok) {
        push("error", "Voice unavailable");
        setSpeaking(null);
        return;
      }
      const blob = await res.blob();
      const url = URL.createObjectURL(blob);
      if (audioRef.current) {
        audioRef.current.src = url;
        audioRef.current.onended = () => setSpeaking(null);
        await audioRef.current.play();
      }
    } catch {
      setSpeaking(null);
    }
  }

  function startMic() {
    const SR =
      (window as any).SpeechRecognition || (window as any).webkitSpeechRecognition;
    if (!SR) {
      push("info", "Speech input not supported in this browser");
      return;
    }
    const rec = new SR();
    rec.lang = "en-IN";
    rec.onresult = (e: any) => setInput(e.results[0][0].transcript);
    rec.start();
  }

  return (
    <>
      <audio ref={audioRef} className="hidden" />
      {!open && (
        <button
          onClick={() => setOpen(true)}
          className="fixed bottom-5 right-5 z-40 flex h-14 w-14 items-center justify-center rounded-full bg-brand-600 text-white shadow-lg transition hover:bg-brand-700"
          aria-label="Open AI assistant"
        >
          <Sparkles className="h-6 w-6" />
        </button>
      )}

      {open && (
        <div className="fixed bottom-5 right-5 z-40 flex h-[560px] w-[380px] max-w-[calc(100vw-2rem)] flex-col overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-2xl">
          <div className="flex items-center justify-between bg-brand-600 px-4 py-3 text-white">
            <div className="flex items-center gap-2">
              <Sparkles className="h-5 w-5" />
              <span className="font-semibold">{t("ai.title")}</span>
            </div>
            <button onClick={() => setOpen(false)} aria-label="Close">
              <X className="h-5 w-5" />
            </button>
          </div>

          <div className="flex-1 space-y-3 overflow-y-auto bg-slate-50 p-3">
            {messages.map((m, i) => (
              <div
                key={i}
                className={`flex ${m.role === "user" ? "justify-end" : "justify-start"}`}
              >
                <div
                  className={`max-w-[85%] rounded-2xl px-3 py-2 text-sm ${
                    m.role === "user"
                      ? "bg-brand-600 text-white"
                      : "border border-slate-200 bg-white text-slate-700"
                  }`}
                >
                  <p className="whitespace-pre-wrap">{m.content}</p>
                  {m.role === "assistant" && (
                    <button
                      onClick={() => speak(m.content, i)}
                      className="mt-1.5 flex items-center gap-1 text-xs text-brand-600 hover:underline"
                    >
                      {speaking === i ? (
                        <Loader2 className="h-3 w-3 animate-spin" />
                      ) : (
                        <Volume2 className="h-3 w-3" />
                      )}
                      {t("voice.listen")}
                    </button>
                  )}
                </div>
              </div>
            ))}
            {busy && (
              <div className="flex items-center gap-2 text-xs text-slate-400">
                <Loader2 className="h-3 w-3 animate-spin" /> thinking…
              </div>
            )}
          </div>

          {pendingConfirm && (
            <div className="border-t border-amber-200 bg-amber-50 p-3 text-xs text-amber-800">
              <div className="flex items-start gap-2">
                <ShieldAlert className="mt-0.5 h-4 w-4 shrink-0" />
                <div className="flex-1">
                  <p className="font-medium">{t("ai.confirmAction")}</p>
                  <p className="mt-0.5 opacity-80">&ldquo;{pendingConfirm}&rdquo;</p>
                  <div className="mt-2 flex gap-2">
                    <button
                      className="btn-primary h-7 px-2 text-xs"
                      onClick={() => send(pendingConfirm, true)}
                    >
                      {t("action.confirm")}
                    </button>
                    <button
                      className="btn-outline h-7 px-2 text-xs"
                      onClick={() => setPendingConfirm(null)}
                    >
                      {t("action.cancel")}
                    </button>
                  </div>
                </div>
              </div>
            </div>
          )}

          <div className="border-t border-slate-200 p-2">
            <div className="flex items-end gap-1.5">
              <button className="btn-ghost h-9 w-9 p-0" onClick={startMic} title="Voice input">
                <Mic className="h-4 w-4" />
              </button>
              <textarea
                className="input max-h-24 flex-1 resize-none py-2"
                rows={1}
                placeholder={t("ai.placeholder")}
                value={input}
                onChange={(e) => setInput(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    send(input);
                  }
                }}
              />
              <button
                className="btn-primary h-9 w-9 p-0"
                onClick={() => send(input)}
                disabled={busy}
              >
                <Send className="h-4 w-4" />
              </button>
            </div>
            <p className="mt-1 px-1 text-[10px] text-slate-400">{t("voice.privacy")}</p>
          </div>
        </div>
      )}
    </>
  );
}
