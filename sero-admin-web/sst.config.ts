/// <reference path="./.sst/platform/config.d.ts" />

// SST v3/v4 (ion) config — deploys the SERO Admin/Super-Admin Next.js portal
// (SSR + BFF route handlers) to AWS Lambda + CloudFront via OpenNext.
// Builds LOCALLY (no Git repo needed). All secrets are SST Secrets, never in git.
//
// One-time secret setup (values live only in SSM Parameter Store, never committed):
//   npx sst secret set SeroBackendUrl   "https://<render>.onrender.com/api/v1" --stage production
//   npx sst secret set SessionSecret    "<random-64-hex>"                        --stage production
//   npx sst secret set GroqApiKey       "<key>"                                  --stage production
//   npx sst secret set GeminiApiKey     "<key>"                                  --stage production
//   npx sst secret set OpenaiApiKey     "<key>"                                  --stage production
//   npx sst secret set ElevenLabsApiKey "<key>"                                  --stage production
//   npx sst secret set ElevenLabsVoiceId "21m00Tcm4TlvDq8ikWAM"                  --stage production
// Update the backend URL later with the same command + `npx sst deploy` (no rebuild of secrets logic).

export default $config({
  app(input) {
    return {
      name: "sero-admin-web",
      removal: input?.stage === "production" ? "retain" : "remove",
      protect: input?.stage === "production",
      home: "aws",
      providers: { aws: { region: "eu-west-1" } },
    };
  },
  async run() {
    // Server-only secrets (injected as Lambda env at runtime, never in the bundle).
    const seroBackendUrl = new sst.Secret("SeroBackendUrl", "https://PLACEHOLDER-set-before-use.invalid/api/v1");
    const sessionSecret = new sst.Secret("SessionSecret");
    const groqApiKey = new sst.Secret("GroqApiKey", "");
    const geminiApiKey = new sst.Secret("GeminiApiKey", "");
    const openaiApiKey = new sst.Secret("OpenaiApiKey", "");
    const elevenLabsApiKey = new sst.Secret("ElevenLabsApiKey", "");
    const elevenLabsVoiceId = new sst.Secret("ElevenLabsVoiceId", "21m00Tcm4TlvDq8ikWAM");

    // NOTE: on this Windows host the Node-24 readlink shim (scripts/patch-readlink.cjs)
    // is applied to the local `next build` via NODE_OPTIONS="--require ./scripts/patch-readlink.cjs"
    // set in the deploy command (see package.json "deploy" / "sst:deploy"). It is a no-op
    // on AWS Linux, so the default OpenNext build command is left unchanged here.
    const site = new sst.aws.Nextjs("SeroAdminWeb", {
      // Build via an in-project wrapper that forces OpenNext's os.tmpdir() to a clean
      // C:\sst-tmp so its image-optimizer `npm install sharp` doesn't walk up into the
      // user's home node_modules. See scripts/opennext-build.mjs for the full rationale.
      buildCommand: "node ./scripts/opennext-build.mjs",
      environment: {
        NEXT_PUBLIC_APP_NAME: "SERO Control",
        AI_PROXY_MODE: "backend",
        NODE_ENV: "production",
        SERO_BACKEND_URL: seroBackendUrl.value,
        SESSION_SECRET: sessionSecret.value,
        GROQ_API_KEY: groqApiKey.value,
        GEMINI_API_KEY: geminiApiKey.value,
        OPENAI_API_KEY: openaiApiKey.value,
        ELEVENLABS_API_KEY: elevenLabsApiKey.value,
        ELEVENLABS_VOICE_ID: elevenLabsVoiceId.value,
      },
    });

    return {
      url: site.url,
    };
  },
});
