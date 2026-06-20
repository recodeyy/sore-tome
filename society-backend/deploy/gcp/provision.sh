#!/usr/bin/env bash
# Provision a production-like SERO stack on a GCE app VM + N k6 load-generator
# VMs for 10k-20k load testing. LOCKED DOWN: port 80 is reachable ONLY from the
# k6 VMs (internal, source-tags=sero-k6) — never the public internet.
#
#   gcloud auth login            # (interactive — run yourself first)
#   PROJECT=mediflow-nexus-2026 ./provision.sh
#
# Cost: 1x app + N x k6 e2-standard-8 (~$0.27/hr each). teardown.sh removes them.
set -euo pipefail

PROJECT="${PROJECT:-mediflow-nexus-2026}"
ZONE="${ZONE:-asia-south1-a}"
APP_VM="${APP_VM:-sero-app}"
K6_COUNT="${K6_COUNT:-2}"
APP_MACHINE="${APP_MACHINE:-e2-standard-8}"
K6_MACHINE="${K6_MACHINE:-e2-standard-8}"

gcloud config set project "$PROJECT"
gcloud services enable compute.googleapis.com

echo "==> Firewall: allow tcp:80 ONLY from k6 VMs (sero-k6) to app VM (sero-app)"
gcloud compute firewall-rules create sero-k6-to-app \
  --allow=tcp:80 --source-tags=sero-k6 --target-tags=sero-app --direction=INGRESS 2>/dev/null \
  || echo "   (firewall rule exists)"
# Remove any prior public rule if it exists (safety)
gcloud compute firewall-rules delete sero-allow-http --quiet 2>/dev/null || true

echo "==> Creating app VM ($APP_VM, $APP_MACHINE)"
gcloud compute instances create "$APP_VM" \
  --zone="$ZONE" --machine-type="$APP_MACHINE" --tags=sero-app \
  --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
  --boot-disk-size=50GB 2>/dev/null || echo "   (app VM exists)"

for i in $(seq 1 "$K6_COUNT"); do
  echo "==> Creating k6 VM (sero-k6-$i, $K6_MACHINE)"
  gcloud compute instances create "sero-k6-$i" \
    --zone="$ZONE" --machine-type="$K6_MACHINE" --tags=sero-k6 \
    --image-family=ubuntu-2204-lts --image-project=ubuntu-os-cloud \
    --boot-disk-size=20GB 2>/dev/null || echo "   (sero-k6-$i exists)"
done

echo "==> Installing Docker + bringing up the stack on $APP_VM"
gcloud compute ssh "$APP_VM" --zone="$ZONE" --quiet --command='
  set -e
  if ! command -v docker >/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
  fi
  sudo docker compose version || (echo "compose plugin missing" && exit 1)
  sudo usermod -aG docker $USER || true
'
echo "==> Uploading backend source"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BK_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
# SECURITY: exclude all credentials from the upload. LOADTEST_MODE makes the
# backend boot + authenticate via Postgres, so NO Firebase key is shipped.
tar --exclude=node_modules --exclude=.git \
    --exclude='config/serviceAccountKey.json' \
    --exclude='*serviceAccount*.json' \
    --exclude='*firebase-adminsdk*.json' \
    --exclude='.env' \
    -czf "$SCRIPT_DIR/sero-backend.tgz" -C "$BK_ROOT" .
# pscp.exe (gcloud's scp backend on Windows) reads a Windows path like C:\... as
# host:path. Pass a BARE relative filename from the script dir to avoid that.
( cd "$SCRIPT_DIR" && gcloud compute scp --quiet sero-backend.tgz "$APP_VM":sero-backend.tgz --zone="$ZONE" )

gcloud compute ssh "$APP_VM" --zone="$ZONE" --quiet --command='
  set -e
  mkdir -p ~/sero && tar -xzf ~/sero-backend.tgz -C ~/sero
  cd ~/sero
  sudo docker compose -f docker-compose.loadtest.yml up -d --build --scale backend=4
  echo "Waiting for Postgres + stack to be ready..."; sleep 40
  DIRECT="postgres://sero:sero@postgres:5432/sero_dev"
  CID=$(sudo docker compose -f docker-compose.loadtest.yml ps -q backend | head -1)
  # NODE_ENV=development uses the no-SSL knex connection (local Postgres has no TLS).
  sudo docker exec -e NODE_ENV=development -e DATABASE_URL="$DIRECT" "$CID" npx knex migrate:latest
  # seed_hubtown_sunmist.js seeds society + admin/resident/staff members + data.
  # (seed_test_logins.js needs Firebase, so it is skipped in LOADTEST_MODE.)
  sudo docker exec -e DATABASE_URL="$DIRECT" "$CID" node scripts/seed_hubtown_sunmist.js || true
  curl -s localhost/health && echo " <- app healthy"
'
APP_INT_IP=$(gcloud compute instances describe "$APP_VM" --zone="$ZONE" --format="value(networkInterfaces[0].networkIP)")
echo ""
echo "==> APP VM ready. INTERNAL IP (k6 VMs reach it here): $APP_INT_IP"
echo "    Next: PROJECT=$PROJECT APP_IP=$APP_INT_IP K6_COUNT=$K6_COUNT ./run_load.sh"
