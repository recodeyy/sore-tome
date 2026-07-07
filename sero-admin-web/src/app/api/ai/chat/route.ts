import { NextRequest, NextResponse } from "next/server";
import { backendFetch } from "@/lib/backend";
import { getToken } from "@/lib/session";

// AI assistant proxy. Default mode "backend" forwards to the canonical backend
// /ai/chat (which holds the Groq/Gemini keys server-side). Mode "direct" is a
// fallback BFF proxy to Groq using a server-only key — still never exposed to
// the browser bundle. High-impact actions are gated client-side + confirmed
// server-side by the backend tool-execution guard.
export async function POST(req: NextRequest) {
  const token = getToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  let payload: any;
  try {
    payload = await req.json();
  } catch {
    return NextResponse.json({ error: "Invalid body" }, { status: 400 });
  }

  const mode = process.env.AI_PROXY_MODE || "backend";

  if (mode === "backend") {
    const result = await backendFetch("/ai/chat", {
      method: "POST",
      token,
      body: JSON.stringify(payload),
    });
    return NextResponse.json(result.body ?? {}, { status: result.status });
  }

  // Fallback: direct Groq call (server-side key only).
  const key = process.env.GROQ_API_KEY;
  if (!key) {
    return NextResponse.json(
      { error: "AI direct mode not configured" },
      { status: 503 }
    );
  }
  const messages = payload.messages || [
    { role: "user", content: String(payload.message || "") },
  ];
  const groqRes = await fetch(
    "https://api.groq.com/openai/v1/chat/completions",
    {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${key}`,
      },
      body: JSON.stringify({
        model: "llama-3.3-70b-versatile",
        messages: [
          {
            role: "system",
            content:
              "You are the SERO society-management assistant. Be concise. Never claim to have performed an action; propose actions for human confirmation.",
          },
          ...messages,
        ],
        temperature: 0.3,
      }),
    }
  );
  const data = await groqRes.json();
  const reply = data?.choices?.[0]?.message?.content || "";
  return NextResponse.json({ reply, provider: "groq", raw: data }, {
    status: groqRes.ok ? 200 : groqRes.status,
  });
}
