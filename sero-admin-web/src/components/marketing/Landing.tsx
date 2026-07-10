import Link from "next/link";
import {
  Building2,
  ReceiptIndianRupee,
  ShieldCheck,
  Bell,
  Users,
  BarChart3,
  Sparkles,
  ArrowRight,
  CheckCircle2,
  Languages,
  Wallet,
  MessageSquare,
} from "lucide-react";

const FEATURES = [
  {
    icon: ReceiptIndianRupee,
    title: "Smart Billing & Receipts",
    desc: "Auto-generate maintenance invoices with GST, track dues, record payments and download branded PDF receipts in one click.",
  },
  {
    icon: Wallet,
    title: "Online Payments",
    desc: "Residents pay maintenance via UPI & Razorpay. Reconciliation and collection rate update in real time.",
  },
  {
    icon: Bell,
    title: "Instant Notices",
    desc: "Broadcast circulars, alerts and event reminders to every flat. Push, in-app and read receipts.",
  },
  {
    icon: ShieldCheck,
    title: "Visitor & Security",
    desc: "Gate-pass approvals, staff attendance and visitor logs that keep your community safe.",
  },
  {
    icon: MessageSquare,
    title: "Complaints & Helpdesk",
    desc: "Residents raise issues, committee assigns and tracks them to resolution with a clear audit trail.",
  },
  {
    icon: BarChart3,
    title: "Live Analytics",
    desc: "Collections, outstanding dues, occupancy and engagement — a dashboard the committee actually trusts.",
  },
];

const STATS = [
  { value: "100%", label: "Digital collections" },
  { value: "5", label: "Languages supported" },
  { value: "24/7", label: "Resident access" },
  { value: "1-tap", label: "Receipt downloads" },
];

export default function Landing({
  ctaHref = "/login",
  signedIn = false,
}: {
  ctaHref?: string;
  signedIn?: boolean;
}) {
  const cta = signedIn ? "Go to dashboard" : "Sign in";
  return (
    <div className="min-h-screen bg-white text-slate-800">
      {/* ── Nav ─────────────────────────────────────────────── */}
      <header className="sticky top-0 z-30 border-b border-slate-100 bg-white/80 backdrop-blur">
        <div className="mx-auto flex max-w-6xl items-center justify-between px-5 py-4">
          <div className="flex items-center gap-2">
            <div className="flex h-9 w-9 items-center justify-center rounded-xl bg-brand-600 text-white shadow-card">
              <Building2 className="h-5 w-5" />
            </div>
            <span className="font-display text-xl font-extrabold tracking-tight text-navy-800">
              Sero
            </span>
          </div>
          <nav className="hidden items-center gap-8 text-sm font-medium text-slate-600 md:flex">
            <a href="#features" className="hover:text-brand-600">Features</a>
            <a href="#how" className="hover:text-brand-600">How it works</a>
            <a href="#audience" className="hover:text-brand-600">Who it&apos;s for</a>
          </nav>
          <Link
            href={ctaHref}
            className="inline-flex items-center gap-1.5 rounded-full bg-navy-800 px-5 py-2 text-sm font-semibold text-white transition hover:bg-navy-700"
          >
            {cta} <ArrowRight className="h-4 w-4" />
          </Link>
        </div>
      </header>

      {/* ── Hero ────────────────────────────────────────────── */}
      <section className="relative overflow-hidden">
        <div className="pointer-events-none absolute -top-24 right-0 h-96 w-96 rounded-full bg-brand-100 blur-3xl" />
        <div className="pointer-events-none absolute -left-24 top-40 h-80 w-80 rounded-full bg-brand-50 blur-3xl" />
        <div className="relative mx-auto max-w-6xl px-5 pb-20 pt-16 md:pt-24">
          <div className="mx-auto max-w-3xl text-center">
            <span className="inline-flex items-center gap-2 rounded-full border border-brand-200 bg-brand-50 px-4 py-1.5 text-sm font-medium text-brand-700">
              <Sparkles className="h-4 w-4" /> The complete society OS
            </span>
            <h1 className="mt-6 font-display text-4xl font-extrabold leading-tight tracking-tight text-navy-900 md:text-6xl">
              Run your housing society
              <span className="block bg-gradient-to-r from-brand-600 to-brand-400 bg-clip-text text-transparent">
                like it&apos;s effortless.
              </span>
            </h1>
            <p className="mx-auto mt-6 max-w-2xl text-lg text-slate-600">
              Sero brings billing, payments, notices, security and complaints into one
              beautiful app — for committees, admins and residents alike.
            </p>
            <div className="mt-9 flex flex-col items-center justify-center gap-3 sm:flex-row">
              <Link
                href={ctaHref}
                className="inline-flex w-full items-center justify-center gap-2 rounded-full bg-brand-600 px-7 py-3 text-base font-semibold text-white shadow-card transition hover:bg-brand-700 sm:w-auto"
              >
                Open your dashboard <ArrowRight className="h-5 w-5" />
              </Link>
              <a
                href="#features"
                className="inline-flex w-full items-center justify-center gap-2 rounded-full border border-slate-200 bg-white px-7 py-3 text-base font-semibold text-slate-700 transition hover:border-brand-300 hover:text-brand-700 sm:w-auto"
              >
                Explore features
              </a>
            </div>
            <p className="mt-4 flex items-center justify-center gap-2 text-sm text-slate-400">
              <Languages className="h-4 w-4" /> Available in English, हिन्दी, ગુજરાતી, मराठी & ಕನ್ನಡ
            </p>
          </div>

          {/* Stat band */}
          <div className="mx-auto mt-16 grid max-w-4xl grid-cols-2 gap-4 md:grid-cols-4">
            {STATS.map((s) => (
              <div
                key={s.label}
                className="rounded-2xl border border-slate-100 bg-white p-5 text-center shadow-card"
              >
                <p className="font-display text-3xl font-extrabold text-brand-600">{s.value}</p>
                <p className="mt-1 text-sm text-slate-500">{s.label}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Features ────────────────────────────────────────── */}
      <section id="features" className="mx-auto max-w-6xl px-5 py-20">
        <div className="mx-auto max-w-2xl text-center">
          <h2 className="font-display text-3xl font-extrabold tracking-tight text-navy-900 md:text-4xl">
            Everything your society needs
          </h2>
          <p className="mt-4 text-lg text-slate-600">
            One platform replaces the WhatsApp groups, spreadsheets and cash registers.
          </p>
        </div>
        <div className="mt-14 grid gap-6 sm:grid-cols-2 lg:grid-cols-3">
          {FEATURES.map((f) => (
            <div
              key={f.title}
              className="group rounded-2xl border border-slate-100 bg-white p-6 shadow-card transition hover:-translate-y-1 hover:border-brand-200"
            >
              <div className="flex h-12 w-12 items-center justify-center rounded-xl bg-brand-50 text-brand-600 transition group-hover:bg-brand-600 group-hover:text-white">
                <f.icon className="h-6 w-6" />
              </div>
              <h3 className="mt-5 font-display text-lg font-bold text-navy-800">{f.title}</h3>
              <p className="mt-2 text-sm leading-relaxed text-slate-600">{f.desc}</p>
            </div>
          ))}
        </div>
      </section>

      {/* ── How it works ────────────────────────────────────── */}
      <section id="how" className="bg-slate-50 py-20">
        <div className="mx-auto max-w-6xl px-5">
          <div className="mx-auto max-w-2xl text-center">
            <h2 className="font-display text-3xl font-extrabold tracking-tight text-navy-900 md:text-4xl">
              Live in three steps
            </h2>
          </div>
          <div className="mt-14 grid gap-8 md:grid-cols-3">
            {[
              { n: "01", t: "Onboard your society", d: "Add units, members and committee roles. Import your existing member list in minutes." },
              { n: "02", t: "Raise your first bills", d: "Generate maintenance invoices with GST, publish to residents and start collecting online." },
              { n: "03", t: "Manage everything live", d: "Track dues, approve visitors, post notices and resolve complaints — all from one dashboard." },
            ].map((s) => (
              <div key={s.n} className="relative rounded-2xl bg-white p-7 shadow-card">
                <span className="font-display text-5xl font-extrabold text-brand-100">{s.n}</span>
                <h3 className="mt-3 font-display text-xl font-bold text-navy-800">{s.t}</h3>
                <p className="mt-2 text-sm leading-relaxed text-slate-600">{s.d}</p>
              </div>
            ))}
          </div>
        </div>
      </section>

      {/* ── Audience split ──────────────────────────────────── */}
      <section id="audience" className="mx-auto max-w-6xl px-5 py-20">
        <div className="grid gap-6 md:grid-cols-2">
          <div className="rounded-3xl bg-gradient-to-br from-navy-800 to-navy-900 p-9 text-white">
            <Users className="h-9 w-9 text-brand-300" />
            <h3 className="mt-5 font-display text-2xl font-bold">For Admins & Committee</h3>
            <ul className="mt-5 space-y-3 text-slate-200">
              {["Billing, dues & payment reconciliation", "Notices, complaints & visitor approvals", "Collection analytics & audit trails", "Super-admin control across societies"].map((i) => (
                <li key={i} className="flex items-start gap-2.5">
                  <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-brand-400" /> {i}
                </li>
              ))}
            </ul>
          </div>
          <div className="rounded-3xl border border-slate-100 bg-white p-9 shadow-card">
            <Building2 className="h-9 w-9 text-brand-600" />
            <h3 className="mt-5 font-display text-2xl font-bold text-navy-800">For Residents</h3>
            <ul className="mt-5 space-y-3 text-slate-600">
              {["Pay maintenance in seconds via UPI", "Download receipts anytime", "Raise complaints & track resolution", "Get every notice on your phone"].map((i) => (
                <li key={i} className="flex items-start gap-2.5">
                  <CheckCircle2 className="mt-0.5 h-5 w-5 shrink-0 text-brand-500" /> {i}
                </li>
              ))}
            </ul>
          </div>
        </div>
      </section>

      {/* ── CTA ─────────────────────────────────────────────── */}
      <section className="mx-auto max-w-6xl px-5 pb-24">
        <div className="relative overflow-hidden rounded-3xl bg-brand-600 px-8 py-16 text-center text-white">
          <div className="pointer-events-none absolute -right-16 -top-16 h-64 w-64 rounded-full bg-brand-500/60 blur-2xl" />
          <h2 className="relative font-display text-3xl font-extrabold md:text-4xl">
            Ready to modernise your society?
          </h2>
          <p className="relative mx-auto mt-4 max-w-xl text-brand-50">
            Sign in to the Sero control portal and take your community digital today.
          </p>
          <Link
            href={ctaHref}
            className="relative mt-8 inline-flex items-center gap-2 rounded-full bg-white px-8 py-3.5 text-base font-semibold text-brand-700 shadow-card transition hover:bg-brand-50"
          >
            Get started <ArrowRight className="h-5 w-5" />
          </Link>
        </div>
      </section>

      {/* ── Footer ──────────────────────────────────────────── */}
      <footer className="border-t border-slate-100 py-10">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-between gap-4 px-5 text-sm text-slate-500 sm:flex-row">
          <div className="flex items-center gap-2">
            <div className="flex h-7 w-7 items-center justify-center rounded-lg bg-brand-600 text-white">
              <Building2 className="h-4 w-4" />
            </div>
            <span className="font-display font-bold text-navy-800">Sero</span>
          </div>
          <p>© {new Date().getFullYear()} Sero. Society management, simplified.</p>
          <Link href={ctaHref} className="font-medium text-brand-600 hover:text-brand-700">
            {cta}
          </Link>
        </div>
      </footer>
    </div>
  );
}
