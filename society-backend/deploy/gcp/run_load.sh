#!/usr/bin/env bash
# Run the staged 10k-20k k6 plan, SHARDED across N k6 VMs (sero-k6-1..N) against
# the app VM's INTERNAL IP. Each VM runs an --execution-segment slice so the load
# sums to the full target (k6 multi-instance pattern).
#
#   PROJECT=mediflow-nexus-2026 APP_IP=<app-internal-ip> K6_COUNT=2 ./run_load.sh
set -euo pipefail
PROJECT="${PROJECT:-mediflow-nexus-2026}"
ZONE="${ZONE:-asia-south1-a}"
K6_COUNT="${K6_COUNT:-2}"
APP_IP="${APP_IP:?Set APP_IP=<app VM internal IP from provision.sh>}"
BASE="http://$APP_IP"
# Load-test auth: Postgres-backed login (no Firebase key). LOGIN_PHONE is a seeded
# society member; all VUs share its society-scoped token.
K6ENV="-e LOADTEST=true -e LOGIN_PHONE=${LOGIN_PHONE:-9876543200}"

gcloud config set project "$PROJECT"

# Build the execution-segment sequence: e.g. for 2 VMs -> "0,1/2,1"
SEQ="0"; for i in $(seq 1 "$K6_COUNT"); do SEQ="$SEQ,$i/$K6_COUNT"; done

echo "==> Preparing $K6_COUNT k6 VMs"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
tar -czf "$SCRIPT_DIR/sero-load.tgz" -C "$(cd "$SCRIPT_DIR/../.." && pwd)/load" .
for i in $(seq 1 "$K6_COUNT"); do
  VM="sero-k6-$i"
  gcloud compute ssh "$VM" --zone="$ZONE" --quiet --command='
    set -e
    if ! command -v k6 >/dev/null; then
      curl -s https://dl.k6.io/key.gpg | sudo gpg --dearmor -o /usr/share/keyrings/k6-archive-keyring.gpg
      echo "deb [signed-by=/usr/share/keyrings/k6-archive-keyring.gpg] https://dl.k6.io/deb stable main" | sudo tee /etc/apt/sources.list.d/k6.list
      sudo apt-get update -qq && sudo apt-get install -y -qq k6
    fi
    echo "* soft nofile 1048576" | sudo tee -a /etc/security/limits.conf
    echo "* hard nofile 1048576" | sudo tee -a /etc/security/limits.conf
  ' &
  ( cd "$SCRIPT_DIR" && gcloud compute scp --quiet sero-load.tgz "$VM":load.tgz --zone="$ZONE" )
done
wait
for i in $(seq 1 "$K6_COUNT"); do
  gcloud compute ssh "sero-k6-$i" --zone="$ZONE" --quiet --command='mkdir -p ~/load && tar -xzf ~/load.tgz -C ~/load' &
done
wait

# Run one k6 script sharded across all VMs in parallel.
run_sharded() { # name  script_and_args
  local name="$1"; shift
  echo "==> STAGE: $name (sharded across $K6_COUNT VMs)"
  for i in $(seq 1 "$K6_COUNT"); do
    local seg="$((i-1))/$K6_COUNT:$i/$K6_COUNT"
    gcloud compute ssh "sero-k6-$i" --zone="$ZONE" --quiet --command="cd ~/load && ulimit -n 1048576; k6 run -e BASE_URL=$BASE $K6ENV --execution-segment '$seg' --execution-segment-sequence '$SEQ' --summary-export=/tmp/$name-$i.json $* 2>&1 | tail -3" &
  done
  wait
  echo "   $name done. Summaries: sero-k6-*:/tmp/$name-*.json"
}

# Smoke + baseline on VM 1 only (cheap)
echo "==> STAGE: smoke (VM1)"
gcloud compute ssh "sero-k6-1" --zone="$ZONE" --quiet --command="cd ~/load && k6 run -e BASE_URL=$BASE k6_smoke.js 2>&1 | tail -4"

run_sharded baseline "k6_load.js"
run_sharded medium   "-e TARGET=3k k6_scale.js"
run_sharded targetA  "k6_10k.js"
run_sharded targetB  "k6_20k.js"

echo ""
echo "==> All stages done. Pull a summary, e.g.:"
echo "   gcloud compute scp sero-k6-1:/tmp/targetB-1.json . --zone=$ZONE"
