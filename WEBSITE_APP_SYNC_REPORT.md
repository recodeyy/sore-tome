# Website ↔ App Sync Report — 2026-07-10

## Foundation verified (live)
- Website (CloudFront BFF) and mobile APK hit the **same backend** (`sero-api-live.onrender.com`) and the same databases (Render Postgres + Firestore `sero-73976`) — confirmed by identical login/data responses through both paths. There is no split-brain backend; any admin action lands in the same store the app reads.
- Website admin login + resident app login both live-verified against that single backend.

## Two-session scenario runs (§8.1–8.8): BLOCKED — need a browser session + phone(s)
These are interactive UI flows (approval→notification→dashboard unlock, notice→push, bill→Razorpay→receipt, poll→vote→results, guard→resident visitor approval, complaint→assignment→status, parking, amenity double-booking). They cannot be exercised from this machine alone. API-level preconditions all pass:

| Sync flow | Backend path exists & responds | UI run |
|---|---|---|
| Resident approval | /auth/pending (admin), approvals page (website new `(portal)/approvals/`) | ☐ device |
| Notices | POST /notices-v2 (admin) → GET /notices-v2 200 (resident) | ☐ |
| Bills/payments | funds/invoices endpoints 200; Razorpay Test Mode configured | ☐ |
| Polls | polls-v2 CRUD + results endpoints 200 | ☐ |
| Visitors | /visitors (resident) 200; guard flows need staff creds | ☐ |
| Complaints | /complaints 200 both roles | ☐ |
| Parking | /parking/my 200 | ☐ |
| Amenities | /amenities + bookings/mine 200 | ☐ |

## Run instructions (when you have the devices)
1. Deploy pending fixes first (backend render-live push + sst:deploy + APK rebuild).
2. Browser: login `admin`/123456 → each admin action above.
3. Phone: resident `9876543200`/123456 → verify update + notification within seconds (pull-to-refresh where realtime isn't wired).
4. Record each in this file with timestamp + screenshot; escalate any admin action that never appears in the app as P0 (likely a Firestore-vs-Postgres write-path mismatch — same class as F-2).
