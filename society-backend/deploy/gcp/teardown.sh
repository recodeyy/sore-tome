#!/usr/bin/env bash
# Delete the app VM + all k6 VMs + firewall rule so billing stops (and the
# bundled Firebase key is destroyed with the app VM).
#   PROJECT=mediflow-nexus-2026 K6_COUNT=2 ./teardown.sh
set -euo pipefail
PROJECT="${PROJECT:-mediflow-nexus-2026}"
ZONE="${ZONE:-asia-south1-a}"
K6_COUNT="${K6_COUNT:-2}"
gcloud config set project "$PROJECT"

VMS="${APP_VM:-sero-app}"
for i in $(seq 1 "$K6_COUNT"); do VMS="$VMS sero-k6-$i"; done

gcloud compute instances delete $VMS --zone="$ZONE" --quiet || true
gcloud compute firewall-rules delete sero-k6-to-app --quiet 2>/dev/null || true
gcloud compute firewall-rules delete sero-allow-http --quiet 2>/dev/null || true
echo "Torn down ($VMS). No further compute charges; bundled key destroyed with the VM."
