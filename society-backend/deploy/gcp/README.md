# SERO 10k–20k Load Test on GCP — One-Command Runbook

Target project: **`sero-73976`** (your Firebase/GCP "Sero" project).
Run from `society-backend/deploy/gcp/`.

This deploys a **production-like** stack on GCE (Postgres tuned + **PgBouncer**
transaction pooling + Redis + 4 API replicas behind nginx) and a separate **k6**
VM, then runs the staged plan from
`../../SERO_10K_20K_Load_Test_Complete_Prompt_Pack.md`.

## ⚠️ Before you run — this spends real money
- 2× `e2-standard-8` VMs ≈ **$0.55/hr combined** while running.
- A full smoke→20k→soak pass is ~1–3 hrs → roughly **$1–3** of compute, plus
  egress. **Always run `./teardown.sh` when finished.**
- Requires **billing enabled** on `sero-73976` and these APIs (the scripts enable
  compute automatically): `compute.googleapis.com`.

## Steps (one command each)

```bash
# 0. Authenticate (interactive — do this yourself once)
gcloud auth login
gcloud config set account avinashgehi3@gmail.com

# 1. Provision app VM + k6 VM, deploy stack, migrate + seed
PROJECT=sero-73976 ./provision.sh
#    -> prints APP_IP at the end

# 2. Run the staged load plan (smoke → 500 → 3k → 10k → 20k)
PROJECT=sero-73976 APP_IP=<app-ip-from-step-1> ./run_load.sh

# 3. Pull result summaries
gcloud compute scp sero-k6:/tmp/targetA.json . --zone=asia-south1-a
gcloud compute scp sero-k6:/tmp/targetB.json . --zone=asia-south1-a

# 4. ALWAYS tear down to stop billing
PROJECT=sero-73976 ./teardown.sh
```

## What each stage asserts (k6 thresholds, pack §21)
- read p95 < 300 ms, write p95 < 500 ms, mixed p99 < 1.5 s
- `http_req_failed` & `business_errors` rate < 1%
- Stages: `k6_smoke` → `k6_load`(500) → `k6_scale TARGET=3k` → `k6_10k` → `k6_20k` → `k6_soak`

## Honest limits
- **A single k6 VM caps out well before 20k long-lived SSE connections** (FD/port
  limits). For a *valid* 20k realtime soak use **k6 Cloud** or 2–3 k6 VMs sharded
  (`--execution-segment`). The HTTP RPS stages (10k/20k VUs, bursty) run fine from
  one `e2-standard-8`.
- This proves capacity of THIS stack sizing. To scale further: bigger Postgres,
  more API replicas (`--scale backend=N`), read replicas, and a managed Redis.
- Scale the dataset first for realistic results:
  `npm run seed:loadtest:10k` (or `:20k`) inside the app VM.

## After the run — data-integrity invariants (pack §24)
Run against the app VM's DB: no cross-tenant rows, debits=credits, no duplicate
payment/receipt/visitor/attendance/vote, dashboard aggregates match source.
