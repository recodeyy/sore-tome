# APP_ONLY_DEPLOYMENT_ENV_MATRIX

> Mobile-app backend env vars × environment. Secrets never committed. See `APP_ONLY_DEPLOYMENT_SECRETS_CHECKLIST.md`.

| Var | Purpose | local | render-demo | Notes |
|---|---|---|---|---|
| `NODE_ENV` | mode | development | production | |
| `PORT` | listen | 3001 | 🔁 Render `$PORT` | |
| `API_BASE_URL` | app→backend base | `http://10.0.2.2:3001/api/v1` (emulator) | `https://sero-api-prod.onrender.com/api/v1` | Flutter `--dart-define` |
| `DATABASE_URL` | Postgres | local pg16 :5544 | 🔐 Neon `…neon.tech/neondb?sslmode=require` | **verified live** |
| `REDIS_URL` | cache/dedup/idempotency | redis :6379 | 🔐 Upstash `rediss://…upstash.io:6379` | **verified live**; optional |
| `JWT_SECRET` | token signing | dev | 🔐 generated | |
| `FIREBASE_PROJECT_ID` | Firebase | sero-73976 | 🔐 | |
| `FIREBASE_CLIENT_EMAIL` | admin SDK | ✅ | 🔐 | |
| `FIREBASE_PRIVATE_KEY` | admin SDK | ✅ (`\n` escaped) | 🔐 | |
| `FIREBASE_STORAGE_BUCKET` | file storage | ✅ | 🔐 | signed URLs |
| `RAZORPAY_KEY_ID` | checkout | test | 🔐 test | |
| `RAZORPAY_KEY_SECRET` | order/verify | 🔐 | 🔐 | server-only |
| `RAZORPAY_WEBHOOK_SECRET` | webhook sig | 🔐 | 🔐 | |
| `OBJECT_STORAGE_*` (endpoint/bucket/keys) | R2/S3 (if used) | — | ⭕ | currently Firebase Storage; R2 optional per prompt §1.5 |
| `GEMINI_API_KEY` | AI (backend only) | ⭕ | 🔐 | app has no AI key; degrades gracefully |
| `GROQ_API_KEY` | AI (backend only) | ⭕ | 🔐 | |
| `UPI_DEMO_VPA` / `UPI_DEMO_NAME` | demo UPI QR | ⭕ | ⭕ | labelled demo |
| `ADMIN_DEMO_MODE` | manual mark-paid | true | true | gated + audited |
| `APP_ENV` | app environment tag | dev | demo | |
| `APP_VERSION` | build tag | 1.0.0+8 | 1.0.0+8 | |

## Flutter build defines

```
flutter build apk --release --dart-define=API_BASE_URL=https://sero-api-prod.onrender.com/api/v1
```

## Verified endpoints (live, this run)

- `GET /health` → 200
- `POST /auth/login` (phone+portal) → token (resident/admin/guard 3/3)
- `POST /notifications/devices` → 401 unauth (mounted), writes device_tokens
- `GET /parcels`, `GET /domestic-help` → 401 unauth; resident token returns seeded rows
- Razorpay webhook path + `/realtime` SSE mounted
