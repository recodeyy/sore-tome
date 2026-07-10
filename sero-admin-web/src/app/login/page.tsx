"use client";
import { useState } from "react";
import { useRouter } from "next/navigation";
import { Building2, ShieldCheck, Loader2 } from "lucide-react";

type Portal = "admin" | "super-admin";

// Seeded demo logins per portal — selecting a portal swaps the prefill so the
// Super Admin tab is never submitted with a society-admin account (which the
// backend correctly rejects with PORTAL_MISMATCH).
const DEMO_LOGIN: Record<Portal, { phone: string; hint: string }> = {
  admin: { phone: "9200000001", hint: "Demo (Hubtown Sunkist): admin 9200000001 · password 123456" },
  "super-admin": { phone: "superadmin", hint: "Demo platform owner: superadmin · password 123456" },
};

export default function LoginPage() {
  const router = useRouter();
  const [portal, setPortal] = useState<Portal>("admin");
  const [phone, setPhone] = useState(DEMO_LOGIN.admin.phone);
  const [password, setPassword] = useState("123456");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [waking, setWaking] = useState(false);

  function selectPortal(p: Portal) {
    setPortal(p);
    setError(null);
    // Only replace the login id if the field still holds the other portal's demo
    // value — never clobber something the user typed themselves.
    if (phone === DEMO_LOGIN.admin.phone || phone === DEMO_LOGIN["super-admin"].phone) {
      setPhone(DEMO_LOGIN[p].phone);
    }
  }

  async function onSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError(null);
    setWaking(false);
    try {
      // The backend sleeps on Render's free plan and can take ~60s to wake, which
      // surfaces as a 502/503/504 or network error on the first request. Retry a
      // few times with a "waking up" notice instead of failing the login.
      let res: Response | null = null;
      for (let attempt = 0; attempt < 3; attempt++) {
        try {
          res = await fetch("/api/session/login", {
            method: "POST",
            headers: { "Content-Type": "application/json" },
            body: JSON.stringify({ phone, password, portal }),
          });
        } catch {
          res = null;
        }
        if (res && ![502, 503, 504].includes(res.status)) break;
        setWaking(true);
        await new Promise((r) => setTimeout(r, 5000));
      }
      if (!res) {
        setError("Could not reach the server. It may be waking up — please try again.");
        return;
      }
      const data = await res.json().catch(() => ({}));
      if (!res.ok) {
        setError(data.error || "Login failed");
        return;
      }
      router.push(portal === "super-admin" ? "/super-admin/dashboard" : "/dashboard");
      router.refresh();
    } catch (err: any) {
      setError(err.message || "Network error");
    } finally {
      setLoading(false);
      setWaking(false);
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-50 via-white to-slate-50 p-4">
      <div className="w-full max-w-md">
        <div className="mb-6 flex flex-col items-center text-center">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-brand-600 text-white shadow-lg">
            <Building2 className="h-7 w-7" />
          </div>
          <h1 className="mt-3 text-2xl font-bold text-slate-900">SERO Control</h1>
          <p className="text-sm text-slate-500">Society operations, billing & governance</p>
        </div>

        <div className="card p-6">
          <div className="mb-5 grid grid-cols-2 gap-2 rounded-lg bg-slate-100 p-1">
            <button
              type="button"
              onClick={() => selectPortal("admin")}
              className={`flex items-center justify-center gap-2 rounded-md py-2 text-sm font-medium transition ${
                portal === "admin" ? "bg-white text-brand-700 shadow" : "text-slate-500"
              }`}
            >
              <Building2 className="h-4 w-4" /> Society Admin
            </button>
            <button
              type="button"
              onClick={() => selectPortal("super-admin")}
              className={`flex items-center justify-center gap-2 rounded-md py-2 text-sm font-medium transition ${
                portal === "super-admin" ? "bg-white text-brand-700 shadow" : "text-slate-500"
              }`}
            >
              <ShieldCheck className="h-4 w-4" /> Super Admin
            </button>
          </div>

          <form onSubmit={onSubmit} className="space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">
                Phone or Email
              </label>
              <input
                className="input"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="9200000001"
                autoComplete="username"
              />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700">Password</label>
              <input
                className="input"
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                autoComplete="current-password"
              />
            </div>

            {waking && !error && (
              <div className="rounded-lg bg-amber-50 px-3 py-2 text-sm text-amber-700">
                Server is waking up, retrying…
              </div>
            )}
            {error && (
              <div className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{error}</div>
            )}

            <button type="submit" className="btn-primary w-full" disabled={loading}>
              {loading && <Loader2 className="h-4 w-4 animate-spin" />}
              Sign in
            </button>
          </form>

          <p className="mt-4 text-center text-xs text-slate-400">{DEMO_LOGIN[portal].hint}</p>
        </div>
      </div>
    </div>
  );
}
