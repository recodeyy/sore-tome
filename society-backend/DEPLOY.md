# Deploying the Sero backend to Render (one-click Blueprint)

This backend deploys to [Render](https://render.com) via a **Blueprint** (`render.yaml`).
It provisions a Dockerized web service (`sero-api`) and a managed Postgres
database (`sero-postgres`), wires `DATABASE_URL` automatically, and runs knex
migrations on every deploy.

## 1. Push the repo to GitHub

Make sure `render.yaml` exists at the **repo root** (it does — there is also a
reference copy in `society-backend/`). Commit and push:

```bash
git add .
git commit -m "Add Render Blueprint for one-click deploy"
git push origin main
```

Repo: `recodeyy/sore-tome`. The backend lives in `society-backend/`.

## 2. Create the Blueprint on Render

1. Go to <https://dashboard.render.com> → **New** → **Blueprint**.
2. Connect GitHub and pick the repo **`recodeyy/sore-tome`**.
3. Render reads `render.yaml` from the repo root and shows a plan:
   - **`sero-api`** — Docker web service (rootDir `society-backend`).
   - **`sero-postgres`** — managed Postgres (free plan).
4. Click **Apply**. Render creates both resources.

## 3. Add the Firebase secrets (manual)

`render.yaml` declares the Firebase vars with `sync: false`, so the build will
wait for you to provide them.

1. Open the **`sero-api`** service → **Environment** tab.
2. Add / paste these 4 values from your Firebase service-account JSON:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_CLIENT_EMAIL`
   - `FIREBASE_PRIVATE_KEY` — paste the full key. Either paste it with literal
     `\n` escapes (e.g. `-----BEGIN PRIVATE KEY-----\n...\n-----END...`), or
     paste the real multi-line key; the server handles both.
   - `FIREBASE_STORAGE_BUCKET` (e.g. `your-project-id.appspot.com`)
3. (Optional) `REDIS_URL` — only if you add a Render Key Value/Redis instance.
   Redis is **optional**; the app boots and runs without it (caching is simply
   disabled).
4. Save changes → Render redeploys.

> Do **not** commit the Firebase service-account JSON. Credentials are read from
> env vars in production (`config/firebase.js`).

## 4. Wait for build + migrations

- Render builds the Docker image (`node:22-slim` + `canvas` build deps).
- The **pre-deploy** step runs `npx knex migrate:latest` against `sero-postgres`
  (this also creates the pgvector `vector` extension via the migrations).
- Then `npm start` (`tsx server.js`) launches; Render health-checks `/health`.

## 5. Use the API

- Public URL: **`https://sero-api.onrender.com`**
- API base for the app: **`https://sero-api.onrender.com/api/v1`**
- Health: `https://sero-api.onrender.com/health`

---

## Environment variables: auto vs manual

| Variable | Source | Notes |
|---|---|---|
| `DATABASE_URL` | **Auto** — `fromDatabase` (sero-postgres) | Connection string injected by Render |
| `PORT` | **Auto** — set by Render | `server.js` reads `process.env.PORT` |
| `NODE_ENV` | **Auto** — `production` | Selects knexfile `production` (SSL) |
| `CORS_ORIGINS` | **Auto** — `*` | Mobile/native clients send no Origin anyway |
| `LOG_LEVEL` | **Auto** — `info` | |
| `DB_SSL_REJECT_UNAUTHORIZED` | **Auto** — `false` | Required for Render PG SSL |
| `JWT_SECRET` | **Auto** — `generateValue: true` | Generated once by Render |
| `REDIS_URL` | **Manual / optional** (`sync: false`) | Only if you add a Redis service; app runs without it |
| `FIREBASE_PROJECT_ID` | **Manual** (`sync: false`) | Paste in Environment tab |
| `FIREBASE_CLIENT_EMAIL` | **Manual** (`sync: false`) | Paste in Environment tab |
| `FIREBASE_PRIVATE_KEY` | **Manual** (`sync: false`) | Paste in Environment tab (`\n` escapes ok) |
| `FIREBASE_STORAGE_BUCKET` | **Manual** (`sync: false`) | Paste in Environment tab |

Optional extras you may also set in the dashboard (not required to boot):
`SENTRY_DSN`, `HEALTH_CHECK_SECRET` (guards `/health/deep`), `DB_POOL_MAX`.
