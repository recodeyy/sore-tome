import { NextRequest, NextResponse } from "next/server";
import { getToken } from "@/lib/session";

// ElevenLabs TTS proxy. The API key is SERVER-ONLY and never sent to the
// browser. Returns audio/mpeg bytes the client can play. Requires an
// authenticated session so anonymous users cannot burn voice credits.
export async function POST(req: NextRequest) {
  const token = getToken();
  if (!token) {
    return NextResponse.json({ error: "Not authenticated" }, { status: 401 });
  }

  const key = process.env.ELEVENLABS_API_KEY;
  const voiceId = process.env.ELEVENLABS_VOICE_ID || "21m00Tcm4TlvDq8ikWAM";
  if (!key) {
    return NextResponse.json(
      { error: "Voice not configured (ELEVENLABS_API_KEY missing)" },
      { status: 503 }
    );
  }

  let text = "";
  try {
    const body = await req.json();
    text = String(body.text || "").slice(0, 2000);
  } catch {
    return NextResponse.json({ error: "Invalid body" }, { status: 400 });
  }
  if (!text.trim()) {
    return NextResponse.json({ error: "text is required" }, { status: 400 });
  }

  const res = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${voiceId}`,
    {
      method: "POST",
      headers: {
        "xi-api-key": key,
        "Content-Type": "application/json",
        Accept: "audio/mpeg",
      },
      body: JSON.stringify({
        text,
        model_id: "eleven_multilingual_v2",
        voice_settings: { stability: 0.5, similarity_boost: 0.75 },
      }),
    }
  );

  if (!res.ok) {
    const detail = await res.text();
    return NextResponse.json(
      { error: "TTS failed", status: res.status, detail: detail.slice(0, 500) },
      { status: 502 }
    );
  }

  const audio = await res.arrayBuffer();
  return new NextResponse(audio, {
    status: 200,
    headers: {
      "Content-Type": "audio/mpeg",
      "Cache-Control": "no-store",
    },
  });
}
